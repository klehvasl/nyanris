class_name AudioSystem
extends Node

const MIX_RATE := 22050

func play_rotate() -> void:
	play_tone(520.0, 0.045, 0.10)

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
