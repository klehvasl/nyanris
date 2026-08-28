class_name AudioSystem
extends Node

const MIX_RATE := 22050

var music_player: AudioStreamPlayer
var music_enabled := true
var current_music := ""

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -12.0
	add_child(music_player)

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if music_player:
		music_player.stream_paused = not enabled

func play_title_music() -> void:
	play_music("res://assets/source/title song.mp3", "title")

func play_game_music() -> void:
	play_music("res://assets/audio/korobeiniki_strings.mp3", "gameplay")

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
	play_tone(520.0, 0.045, 0.10)

func play_move() -> void:
	play_tone(285.0, 0.022, 0.045)

func play_drop() -> void:
	play_tone(150.0, 0.075, 0.14)

func play_clear(count: int) -> void:
	play_tone(620.0 + count * 90.0, 0.13 if count < 4 else 0.24, 0.16)

func play_game_over() -> void:
	play_tone(105.0, 0.32, 0.14)

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
