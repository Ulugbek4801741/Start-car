extends Node

# Lightweight engine tone synthesized on-device. No audio files or network needed.
var player: AudioStreamPlayer
var generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback
var engine_hz := 90.0
var phase := 0.0
var sample_rate := 22050.0
var master_volume := 0.12

func _ready() -> void:
	generator = AudioStreamGenerator.new()
	generator.mix_rate = int(sample_rate)
	generator.buffer_length = 0.12
	player = AudioStreamPlayer.new()
	player.stream = generator
	player.volume_db = -12.0
	add_child(player)
	player.play()
	playback = player.get_stream_playback() as AudioStreamGeneratorPlayback

func set_engine_speed(kmh: float) -> void:
	engine_hz = lerp(65.0, 230.0, clamp(kmh / 140.0, 0.0, 1.0))

func _process(_delta: float) -> void:
	if playback == null:
		return
	var available := playback.get_frames_available()
	if available <= 0:
		return
	var frames := PackedVector2Array()
	frames.resize(available)
	for i in range(available):
		var base := sin(phase) * 0.45
		var harmonic := sin(phase * 2.0) * 0.2 + sin(phase * 3.0) * 0.08
		var sample := (base + harmonic) * master_volume
		frames[i] = Vector2(sample, sample)
		phase += TAU * engine_hz / sample_rate
		if phase >= TAU:
			phase = fmod(phase, TAU)
	playback.push_buffer(frames)
