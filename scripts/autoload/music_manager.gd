extends Node
## MusicManager autoload — manages background music with 2 AudioStreamPlayer channels.
## Channels: ExplorePlayer (calm exploration), CombatPlayer (energetic combat).
## Audio bus structure: Music, SFX, Ambiance, UI (siblings of Master).

var is_in_combat: bool = false
var _explore_player: AudioStreamPlayer
var _combat_player: AudioStreamPlayer
var _explore_stream: AudioStream = null
var _combat_stream: AudioStream = null
var _crossfade_duration: float = 1.0
var _combat_cooldown_timer: float = 0.0
var _combat_cooldown: float = 3.0
var _detection_radius: float = 15.0


func _ready() -> void:
	_ensure_audio_buses()
	_create_players()
	_load_music_streams()
	# Start playing exploration music by default
	play_exploration_music()


func _process(delta: float) -> void:
	# Auto-detect enemies near player and trigger combat/explore music
	var player := _get_player()
	if not player:
		return

	var enemies_nearby := false
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		# Check if enemy has health and is alive
		if enemy.has_method("is_alive") and not enemy.is_alive():
			continue
		var dist := player.global_position.distance_to((enemy as Node3D).global_position)
		if dist <= _detection_radius:
			enemies_nearby = true
			break

	if enemies_nearby:
		_combat_cooldown_timer = 0.0
		trigger_combat_proximity(true, 0.0)
	else:
		_combat_cooldown_timer += delta
		if _combat_cooldown_timer >= _combat_cooldown:
			trigger_combat_proximity(false, 0.0)


func _get_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		return players[0] as Node3D
	return null


func _ensure_audio_buses() -> void:
	# Ensure Music, SFX, Ambiance, UI buses exist as siblings of Master
	_ensure_bus("Music", "Master")
	_ensure_bus("SFX", "Master")
	_ensure_bus("Ambiance", "Master")
	_ensure_bus("UI", "Master")


func _ensure_bus(bus_name: String, send_to: String) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		AudioServer.add_bus(AudioServer.get_bus_count())
		idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, send_to)
	# Set reasonable default volume
	if bus_name == "Music":
		AudioServer.set_bus_volume_db(idx, linear_to_db(0.7))
	elif bus_name == "SFX":
		AudioServer.set_bus_volume_db(idx, linear_to_db(0.8))
	elif bus_name == "Ambiance":
		AudioServer.set_bus_volume_db(idx, linear_to_db(0.5))
	elif bus_name == "UI":
		AudioServer.set_bus_volume_db(idx, linear_to_db(0.9))


func _create_players() -> void:
	_explore_player = AudioStreamPlayer.new()
	_explore_player.name = "ExplorePlayer"
	_explore_player.bus = "Music"
	add_child(_explore_player)

	_combat_player = AudioStreamPlayer.new()
	_combat_player.name = "CombatPlayer"
	_combat_player.bus = "Music"
	add_child(_combat_player)


func _load_music_streams() -> void:
	# Try to load real music files, fall back to generated placeholder
	_explore_stream = _load_ogg("res://assets/audio/music/explore.ogg")
	_combat_stream = _load_ogg("res://assets/audio/music/combat.ogg")


func _load_ogg(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	# Generate silent placeholder when real files not available
	return _generate_silent_stream(5.0)


func _generate_silent_stream(_duration: float) -> AudioStream:
	# Return null to gracefully fall back when .ogg files are missing.
	# Real .ogg files should be placed in assets/audio/music/.
	return null


func play_exploration_music() -> void:
	if _explore_stream and _explore_player:
		_explore_player.stream = _explore_stream
		_explore_player.play()


func play_combat_music() -> void:
	if _combat_stream and _combat_player:
		_combat_player.stream = _combat_stream
		_combat_player.play()


func stop_music() -> void:
	if _explore_player:
		_explore_player.stop()
	if _combat_player:
		_combat_player.stop()


func crossfade_to(_target_stream: AudioStream, _duration: float = 1.0) -> void:
	# Minimal implementation — detailed crossfade will be refined in Task 8
	pass


func set_music_volume(volume: float) -> void:
	var idx: int = AudioServer.get_bus_index("Music")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(volume, 0.0, 1.0)))


func trigger_combat_proximity(enemies_nearby: bool, _distance: float = -1.0) -> void:
	if enemies_nearby and not is_in_combat:
		is_in_combat = true
		play_combat_music()
	elif not enemies_nearby and is_in_combat:
		is_in_combat = false
		_combat_cooldown_timer = 0.0
		play_exploration_music()
