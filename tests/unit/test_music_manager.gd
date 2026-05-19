extends "res://addons/gut/test.gd"
## Unit tests for MusicManager — background music system.
## Verifies autoload setup, audio channels, bus structure, and combat/explore triggers.

const MusicManagerClass = preload("res://scripts/autoload/music_manager.gd")

var _mgr: Node


func before_each() -> void:
	_mgr = MusicManagerClass.new()
	add_child_autofree(_mgr)


func test_music_manager_can_be_created() -> void:
	assert_not_null(_mgr, "MusicManager should be creatable")


func test_has_explore_player() -> void:
	var player = _mgr.get_node_or_null("ExplorePlayer")
	assert_not_null(player, "Should have ExplorePlayer child")
	assert_true(player is AudioStreamPlayer, "ExplorePlayer should be an AudioStreamPlayer")


func test_has_combat_player() -> void:
	var player = _mgr.get_node_or_null("CombatPlayer")
	assert_not_null(player, "Should have CombatPlayer child")
	assert_true(player is AudioStreamPlayer, "CombatPlayer should be an AudioStreamPlayer")


func test_has_two_audio_channels() -> void:
	var audio_children: int = 0
	for child in _mgr.get_children():
		if child is AudioStreamPlayer:
			audio_children += 1
	assert_eq(audio_children, 2, "Should have exactly 2 AudioStreamPlayer children")


func test_explore_player_on_music_bus() -> void:
	var player = _mgr.get_node_or_null("ExplorePlayer")
	if player:
		assert_eq(player.bus, "Music", "ExplorePlayer should be on Music bus")


func test_combat_player_on_music_bus() -> void:
	var player = _mgr.get_node_or_null("CombatPlayer")
	if player:
		assert_eq(player.bus, "Music", "CombatPlayer should be on Music bus")


func test_has_play_exploration_music_method() -> void:
	assert_true(_mgr.has_method("play_exploration_music"),
		"Should have play_exploration_music method")


func test_has_play_combat_music_method() -> void:
	assert_true(_mgr.has_method("play_combat_music"),
		"Should have play_combat_music method")


func test_has_stop_music_method() -> void:
	assert_true(_mgr.has_method("stop_music"),
		"Should have stop_music method")


func test_has_crossfade_method() -> void:
	assert_true(_mgr.has_method("crossfade_to"),
		"Should have crossfade_to method")


func test_has_set_volume_method() -> void:
	assert_true(_mgr.has_method("set_music_volume"),
		"Should have set_music_volume method")


func test_has_trigger_combat_method() -> void:
	assert_true(_mgr.has_method("trigger_combat_proximity"),
		"Should have trigger_combat_proximity method")


func test_play_exploration_does_not_crash() -> void:
	_mgr.play_exploration_music()
	await wait_frames(5)
	assert_true(true, "play_exploration_music should not crash")


func test_play_combat_does_not_crash() -> void:
	_mgr.play_combat_music()
	await wait_frames(5)
	assert_true(true, "play_combat_music should not crash")


func test_stop_music_does_not_crash() -> void:
	_mgr.stop_music()
	await wait_frames(5)
	assert_true(true, "stop_music should not crash")


func test_crossfade_does_not_crash() -> void:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100.0
	stream.buffer_length = 1.0
	_mgr.crossfade_to(stream, 0.5)
	await wait_frames(5)
	assert_true(true, "crossfade_to should not crash")


func test_set_volume_changes_bus_volume() -> void:
	var initial_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	_mgr.set_music_volume(0.5)
	var new_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	# Volume should change from the initial value
	assert_ne(initial_volume, new_volume, "set_music_volume should change Music bus volume")


func test_trigger_combat_proximity_does_not_crash() -> void:
	_mgr.trigger_combat_proximity(true, 15.0)
	await wait_frames(3)
	assert_true(true, "trigger_combat_proximity should not crash")


func test_trigger_combat_proximity_clear_does_not_crash() -> void:
	_mgr.trigger_combat_proximity(false, 0.0)
	await wait_frames(3)
	assert_true(true, "trigger_combat_proximity (clear) should not crash")


func test_combat_state_tracking() -> void:
	assert_false(_mgr.is_in_combat, "Should start not in combat")
	_mgr.trigger_combat_proximity(true, 10.0)
	assert_true(_mgr.is_in_combat, "Should be in combat after trigger")
	_mgr.trigger_combat_proximity(false, 0.0)
	assert_false(_mgr.is_in_combat, "Should not be in combat after clear")


func test_music_bus_exists() -> void:
	var music_idx = AudioServer.get_bus_index("Music")
	assert_ne(music_idx, -1, "Music audio bus should exist")


func test_sfx_bus_exists() -> void:
	var sfx_idx = AudioServer.get_bus_index("SFX")
	assert_ne(sfx_idx, -1, "SFX audio bus should exist")


func test_ambiance_bus_exists() -> void:
	var ambiance_idx = AudioServer.get_bus_index("Ambiance")
	assert_ne(ambiance_idx, -1, "Ambiance audio bus should exist")


func test_ui_bus_exists() -> void:
	var ui_idx = AudioServer.get_bus_index("UI")
	assert_ne(ui_idx, -1, "UI audio bus should exist")


func test_music_bus_is_child_of_master() -> void:
	var music_idx = AudioServer.get_bus_index("Music")
	var master_idx = AudioServer.get_bus_index("Master")
	if music_idx != -1:
		var send_to_master = AudioServer.get_bus_send(music_idx)
		assert_eq(send_to_master, "Master", "Music bus should send to Master")


func test_ambiance_bus_is_child_of_master() -> void:
	var ambiance_idx = AudioServer.get_bus_index("Ambiance")
	if ambiance_idx != -1:
		var send_to = AudioServer.get_bus_send(ambiance_idx)
		assert_eq(send_to, "Master", "Ambiance bus should send to Master")


func test_ui_bus_is_child_of_master() -> void:
	var ui_idx = AudioServer.get_bus_index("UI")
	if ui_idx != -1:
		var send_to = AudioServer.get_bus_send(ui_idx)
		assert_eq(send_to, "Master", "UI bus should send to Master")
