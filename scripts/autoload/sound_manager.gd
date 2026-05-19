extends Node
## PHASE 3: Global sound manager autoload.
## Plays procedural sound effects using AudioStreamGenerator for weapons, enemies, UI.
## All sounds are generated programmatically — no external audio files needed.

const SAMPLE_RATE: float = 44100.0
const MASTER_VOLUME: float = 0.6


func _ready() -> void:
	_ensure_sfx_bus()


func play_shoot_sound() -> void:
	_play_tone(220.0, 0.08, 0.3, "square")


func play_hit_sound() -> void:
	_play_tone(80.0, 0.12, 0.4, "sawtooth")


func play_enemy_death_sound() -> void:
	_play_tone(60.0, 0.3, 0.5, "noise")


func play_reload_sound() -> void:
	_play_tone(440.0, 0.06, 0.2, "square")


func play_dash_sound() -> void:
	_play_sweep(200.0, 600.0, 0.15, 0.3)


func play_ui_click() -> void:
	_play_tone(880.0, 0.03, 0.15, "square")


func _play_tone(frequency: float, duration: float, volume: float, waveform: String) -> void:
	var player: AudioStreamPlayer = _create_stream_player(duration)
	if not player:
		return
	
	var stream: AudioStream = player.stream
	var playback = stream.get_playback()  # AudioStreamGeneratorPlayback
	if not playback:
		return
	
	var num_samples: int = int(SAMPLE_RATE * duration)
	var i: int = 0
	while i < num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var sample: float = _generate_sample(t, frequency, waveform)
		var env: float = _envelope(t, duration)
		var amp: float = sample * volume * env * MASTER_VOLUME
		playback.push_frame(Vector2(amp, amp))
		i += 1
	
	player.play()


func _play_sweep(start_freq: float, end_freq: float, duration: float, volume: float) -> void:
	var player: AudioStreamPlayer = _create_stream_player(duration)
	if not player:
		return
	
	var stream: AudioStream = player.stream
	var playback = stream.get_playback()
	if not playback:
		return
	
	var num_samples: int = int(SAMPLE_RATE * duration)
	var i: int = 0
	while i < num_samples:
		var t: float = float(i) / SAMPLE_RATE
		var freq: float = lerpf(start_freq, end_freq, t / duration)
		var sample: float = _generate_sample(t, freq, "square")
		var env: float = _envelope(t, duration)
		var amp: float = sample * volume * env * MASTER_VOLUME
		playback.push_frame(Vector2(amp, amp))
		i += 1
	
	player.play()


func _generate_sample(t: float, frequency: float, waveform: String) -> float:
	match waveform:
		"square":
			if sin(TAU * frequency * t) >= 0:
				return 1.0
			return -1.0
		"sawtooth":
			return 2.0 * (frequency * fmod(t, 1.0 / frequency)) - 1.0
		"noise":
			return randf_range(-1.0, 1.0)
		_:
			return sin(TAU * frequency * t)


func _envelope(t: float, duration: float) -> float:
	var attack: float = 0.005
	var release: float = 0.02
	if t < attack:
		return t / attack
	if t > duration - release:
		return (duration - t) / release
	return 1.0


func _create_stream_player(duration: float) -> AudioStreamPlayer:
	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = duration + 0.1
	
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = generator
	player.bus = "SFX"
	add_child(player)
	
	get_tree().create_timer(duration + 0.2).timeout.connect(
		_cleanup_player.bind(player)
	)
	
	return player


func _cleanup_player(p: AudioStreamPlayer) -> void:
	if is_instance_valid(p):
		p.queue_free()


func _ensure_sfx_bus() -> void:
	var idx: int = AudioServer.get_bus_index("SFX")
	if idx == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "SFX")
	AudioServer.set_bus_volume_db(idx, linear_to_db(0.8))
