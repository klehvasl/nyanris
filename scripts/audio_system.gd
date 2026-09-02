class_name AudioSystem
extends Node

const MIX_RATE := 48000
const MOVE_SAMPLE_PATH := "res://assets/audio/sfx/move_tick.mp3"
const LINE_CLEAR_SAMPLE_PATH := "res://assets/audio/sfx/line_clear.mp3"
const TETRIS_CLEAR_SAMPLE_PATH := "res://assets/audio/sfx/tetris_clear.mp3"
const ENDING_MUSIC_PATH := "res://assets/audio/kantele_drop_loop.mp3"
enum Waveform { SINE, TRIANGLE, SQUARE }

var music_player: AudioStreamPlayer
var music_enabled := true
var current_music := ""
var move_sample: AudioStream
var line_clear_sample: AudioStream
var tetris_clear_sample: AudioStream
var move_sample_player: AudioStreamPlayer
var synth_effects: Dictionary = {}
var last_soft_drop_msec := -1000000

func _ready() -> void:
	install_master_limiter()
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -12.0
	add_child(music_player)
	move_sample = load_sample(MOVE_SAMPLE_PATH)
	line_clear_sample = load_sample(LINE_CLEAR_SAMPLE_PATH)
	tetris_clear_sample = load_sample(TETRIS_CLEAR_SAMPLE_PATH)
	build_synth_palette()

func install_master_limiter() -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	if master_bus < 0:
		return
	for effect_index in AudioServer.get_bus_effect_count(master_bus):
		if AudioServer.get_bus_effect(master_bus, effect_index) is AudioEffectLimiter:
			return
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = -0.8
	limiter.threshold_db = -2.0
	limiter.soft_clip_db = 2.0
	limiter.soft_clip_ratio = 8.0
	AudioServer.add_bus_effect(master_bus, limiter)

func load_sample(path: String) -> AudioStream:
	return load(path) if ResourceLoader.exists(path) else null

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if music_player:
		music_player.stream_paused = not enabled

func play_title_music() -> void:
	play_music("res://assets/source/title song.mp3", "title")

func play_game_music() -> void:
	play_music("res://assets/audio/kantele_grid.mp3", "gameplay")

func play_music(path: String, music_id: String) -> void:
	if current_music == music_id and music_player.playing:
		music_player.stream_paused = not music_enabled
		return
	if not ResourceLoader.exists(path):
		return
	var stream = load(path)
	if stream is AudioStreamMP3:
		stream.loop = true
	music_player.stream = stream
	current_music = music_id
	music_player.play()
	music_player.stream_paused = not music_enabled

func stop_music() -> void:
	current_music = ""
	if music_player:
		music_player.stop()

func set_gameplay_paused(paused: bool) -> void:
	if music_player and music_enabled:
		music_player.stream_paused = paused

func play_rotate() -> void:
	play_effect("rotate")

func play_invalid() -> void:
	play_effect("invalid")

func play_move() -> void:
	if move_sample:
		# Lateral auto-repeat can fire every 55 ms. Restart one short voice rather
		# than layering the original one-second clip into a noisy wall of sound.
		if is_instance_valid(move_sample_player):
			move_sample_player.stop()
			move_sample_player.queue_free()
		move_sample_player = play_sample(move_sample, 0.12, 1.0, -5.0)
	else:
		play_tone(285.0, 0.022, 0.045)

func play_drop(distance := 0) -> void:
	# Long drops gain a little weight, but the narrow range keeps expert play
	# comfortable when hard drops happen repeatedly.
	var strength := clampf(float(distance) / 15.0, 0.0, 1.0)
	play_effect("hard_drop", lerpf(-4.0, 0.0, strength))

func play_lock() -> void:
	play_effect("lock")

func play_soft_drop() -> void:
	var now := Time.get_ticks_msec()
	if now - last_soft_drop_msec < 120:
		return
	last_soft_drop_msec = now
	play_effect("soft_drop")

func play_clear(count: int) -> void:
	if count == 5 and tetris_clear_sample:
		play_sample(tetris_clear_sample, 1.60, 1.0, -3.0)
	elif line_clear_sample:
		# The supplied one-line sound stays recognizable for doubles and triples;
		# a small pitch lift communicates the stronger result without a new sample.
		var pitch := 1.0 + 0.07 * maxi(0, count - 1)
		var duration := 0.82 + 0.10 * maxi(0, count - 1)
		play_sample(line_clear_sample, duration, pitch, -3.0)
		if count == 2:
			play_effect("double_clear", -7.0)
		elif count == 3:
			play_effect("triple_clear", -6.0)
	else:
		play_tone(620.0 + count * 90.0, 0.13 if count < 4 else 0.24, 0.16)

func play_sample(stream: AudioStream, max_duration: float, pitch_scale := 1.0, volume_db := 0.0) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.pitch_scale = pitch_scale
	player.volume_db = volume_db
	player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
	player.play()
	fade_sample_after(player, max_duration)
	return player

func fade_sample_after(player: AudioStreamPlayer, duration: float) -> void:
	var fade_seconds := minf(0.05, duration * 0.25)
	await get_tree().create_timer(maxf(0.0, duration - fade_seconds)).timeout
	if not is_instance_valid(player):
		return
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -40.0, fade_seconds)
	await tween.finished
	if is_instance_valid(player):
		player.stop()
		player.queue_free()

func play_game_over() -> void:
	play_effect("game_over")

func play_ending_music() -> void:
	play_music(ENDING_MUSIC_PATH, "ending")

func play_level_up() -> void:
	play_effect_after("level_up", 0.22)

func play_high_score() -> void:
	play_effect("high_score")

func play_name_saved() -> void:
	play_effect("name_saved")

func play_ui_select() -> void:
	play_effect("ui_select")

func play_ui_confirm() -> void:
	play_effect("ui_confirm")

func play_ui_cancel() -> void:
	play_effect("ui_cancel")

func play_pause(paused: bool) -> void:
	play_effect("pause" if paused else "resume")

func play_effect(effect_id: String, volume_offset_db := 0.0) -> void:
	var stream: AudioStream = synth_effects.get(effect_id)
	if stream:
		play_sample(stream, stream.get_length() + 0.02, 1.0, volume_offset_db)

func play_effect_after(effect_id: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	play_effect(effect_id)

func build_synth_palette() -> void:
	# One warm, restrained palette: triangle waves carry most interactions,
	# while brief square/noise accents are reserved for impacts and boundaries.
	synth_effects = {
		"rotate": synth_sequence([[520.0, 0.045, 700.0], [760.0, 0.045, 840.0]], 0.115, Waveform.TRIANGLE),
		"invalid": synth_sequence([[155.0, 0.045, 135.0]], 0.045, Waveform.SQUARE, 0.08),
		"soft_drop": synth_sequence([[250.0, 0.045, 205.0]], 0.040, Waveform.TRIANGLE),
		"lock": synth_sequence([[205.0, 0.105, 125.0]], 0.135, Waveform.TRIANGLE, 0.12),
		"hard_drop": synth_hard_drop(),
		"double_clear": synth_sequence([[523.0, 0.085, 570.0], [659.0, 0.120, 720.0]], 0.085, Waveform.TRIANGLE),
		"triple_clear": synth_sequence([[523.0, 0.075, 570.0], [659.0, 0.075, 710.0], [784.0, 0.140, 860.0]], 0.090, Waveform.TRIANGLE),
		"level_up": synth_sequence([[440.0, 0.105, 470.0], [554.0, 0.105, 590.0], [659.0, 0.105, 700.0], [880.0, 0.260, 920.0]], 0.105, Waveform.TRIANGLE),
		"ui_select": synth_sequence([[610.0, 0.060, 650.0]], 0.050, Waveform.TRIANGLE),
		"ui_confirm": synth_sequence([[520.0, 0.070, 560.0], [720.0, 0.105, 780.0]], 0.070, Waveform.TRIANGLE),
		"ui_cancel": synth_sequence([[560.0, 0.070, 520.0], [390.0, 0.100, 350.0]], 0.060, Waveform.TRIANGLE),
		"pause": synth_sequence([[470.0, 0.085, 430.0], [320.0, 0.130, 290.0]], 0.070, Waveform.TRIANGLE),
		"resume": synth_sequence([[310.0, 0.085, 350.0], [480.0, 0.130, 540.0]], 0.070, Waveform.TRIANGLE),
		"game_over": synth_sequence([[392.0, 0.230, 360.0], [294.0, 0.260, 270.0], [196.0, 0.480, 165.0]], 0.105, Waveform.TRIANGLE),
		"high_score": synth_sequence([[523.0, 0.105, 570.0], [659.0, 0.105, 710.0], [784.0, 0.105, 850.0], [1047.0, 0.420, 1120.0]], 0.095, Waveform.TRIANGLE, 0.025),
		"name_saved": synth_sequence([[720.0, 0.080, 780.0], [960.0, 0.220, 1040.0]], 0.075, Waveform.TRIANGLE, 0.02),
	}

func synth_sequence(notes: Array, volume: float, waveform: Waveform, noise_amount := 0.0) -> AudioStreamWAV:
	var total_seconds := 0.0
	for note: Array in notes:
		total_seconds += float(note[1])
	var sample_count := maxi(1, int(MIX_RATE * total_seconds))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var note_index := 0
	var note_start := 0.0
	var phase := 0.0
	for i in sample_count:
		var time := float(i) / MIX_RATE
		while note_index < notes.size() - 1 and time >= note_start + float(notes[note_index][1]):
			note_start += float(notes[note_index][1])
			note_index += 1
			phase = 0.0
		var note: Array = notes[note_index]
		var note_duration := float(note[1])
		var local_time := time - note_start
		var progress := clampf(local_time / note_duration, 0.0, 1.0)
		var frequency := lerpf(float(note[0]), float(note[2]), progress)
		phase += TAU * frequency / MIX_RATE
		var wave := sin(phase)
		if waveform == Waveform.TRIANGLE:
			wave = 2.0 / PI * asin(wave)
		elif waveform == Waveform.SQUARE:
			wave = 1.0 if wave >= 0.0 else -1.0
		var attack := minf(0.008, note_duration * 0.15)
		var release := minf(0.055, note_duration * 0.45)
		var envelope := minf(1.0, local_time / maxf(attack, 0.001))
		envelope *= minf(1.0, (note_duration - local_time) / maxf(release, 0.001))
		var noise := fposmod(sin(float(i) * 12.9898) * 43758.5453, 2.0) - 1.0
		var mixed := wave * (1.0 - noise_amount) + noise * noise_amount
		pcm.encode_s16(i * 2, clampi(int(mixed * envelope * volume * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = pcm
	return stream

func synth_hard_drop() -> AudioStreamWAV:
	# Three distinct layers make this read as contact rather than a long synth
	# dive: a bright transient, a compact body, and a short floor resonance.
	const DURATION := 0.155
	var sample_count := int(MIX_RATE * DURATION)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	var click_phase := 0.0
	var body_phase := 0.0
	var tail_phase := 0.0
	for i in sample_count:
		var time := float(i) / MIX_RATE
		var mixed := 0.0

		# 22 ms bright wooden/ceramic contact transient.
		if time < 0.022:
			var click_progress := time / 0.022
			click_phase += TAU * lerpf(1450.0, 760.0, click_progress) / MIX_RATE
			var click_wave := 2.0 / PI * asin(sin(click_phase))
			var click_envelope := pow(1.0 - click_progress, 2.4)
			mixed += click_wave * click_envelope * 0.16

		# The physical body arrives just behind the click and stops quickly.
		if time >= 0.008 and time < 0.108:
			var body_time := time - 0.008
			var body_progress := body_time / 0.100
			body_phase += TAU * lerpf(205.0, 82.0, body_progress) / MIX_RATE
			var body_wave := 2.0 / PI * asin(sin(body_phase))
			var body_attack := minf(1.0, body_time / 0.006)
			var body_decay := pow(1.0 - body_progress, 1.35)
			mixed += body_wave * body_attack * body_decay * 0.20

		# A quiet resonance makes the board feel solid without a boomy tail.
		if time >= 0.070:
			var tail_time := time - 0.070
			var tail_progress := clampf(tail_time / 0.085, 0.0, 1.0)
			tail_phase += TAU * lerpf(94.0, 72.0, tail_progress) / MIX_RATE
			mixed += sin(tail_phase) * pow(1.0 - tail_progress, 1.8) * 0.075

		# Deterministic texture is concentrated at the moment of contact.
		if time < 0.032:
			var noise := fposmod(sin(float(i) * 12.9898) * 43758.5453, 2.0) - 1.0
			mixed += noise * pow(1.0 - time / 0.032, 2.0) * 0.055

		pcm.encode_s16(i * 2, clampi(int(mixed * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = pcm
	return stream

func play_tone(frequency: float, duration: float, volume: float) -> void:
	var sample_count := maxi(1, int(MIX_RATE * duration))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for i in sample_count:
		var envelope := 1.0 - float(i) / sample_count
		var wave := sin(TAU * frequency * float(i) / MIX_RATE)
		pcm.encode_s16(i * 2, int(wave * 32767.0 * volume * envelope))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = pcm
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.finished.connect(player.queue_free)
	player.play()
