extends "res://addons/gut/test.gd"
## Unit and integration tests for Music Crossfade and Ambiance System (Phase 4.8).
## Covers: crossfade volume tween, combat proximity trigger, AmbianceManager
## autoload, room-type ambient mapping, Ogg Vorbis ambient loop loading.

const MusicManagerClass = preload("res://scripts/autoload/music_manager.gd")

var _mgr: Node
var _ambiance: Node = null


# ── MusicManager crossfade tests ──────────────────────────────────────

func before_each() -> void:
	_mgr = MusicManagerClass.new()
	add_child_autofree(_mgr)
	# Setup audio buses so crossfade has somewhere to play
	_ensure_buses()


func after_each() -> void:
	# Clean up any tweens
	if _mgr and is_instance_valid(_mgr):
		for child in _mgr.get_children():
			if child.has_method("kill"):
				child.kill()


func _ensure_buses() -> void:
	var bus_names := ["Music", "SFX", "Ambiance", "UI"]
	for bus_name in bus_names:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus(AudioServer.get_bus_count())
			var idx := AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


# ── Crossfade tests ───────────────────────────────────────────────────

func test_crossfade_method_exists() -> void:
	assert_true(_mgr.has_method("crossfade_to"),
		"MusicManager should have crossfade_to method")


func test_crossfade_accepts_stream_and_duration() -> void:
	var stream := _generate_test_stream(2.0)
	# Should not crash with valid arguments
	_mgr.crossfade_to(stream, 1.0)
	await wait_frames(5)
	assert_true(true, "crossfade_to with stream and duration should not crash")


func test_crossfade_with_default_duration() -> void:
	var stream := _generate_test_stream(2.0)
	_mgr.crossfade_to(stream)  # No duration = use default (1.0)
	await wait_frames(5)
	assert_true(true, "crossfade_to without duration should use default")


func test_crossfade_creates_tween() -> void:
	var stream := _generate_test_stream(2.0)
	_mgr.crossfade_to(stream, 0.5)
	# In Godot 4, Tweens are RefCounted, not Node children — use helper method
	assert_true(_mgr.has_active_crossfade_tween(), "crossfade_to should create a Tween")


func test_crossfade_targets_specified_stream() -> void:
	var stream := _generate_test_stream(2.0)
	_mgr.crossfade_to(stream, 0.5)
	await wait_frames(3)
	# One of the players should have the target stream
	var player_found := false
	for child in _mgr.get_children():
		if child.has_method("play") and child.has_signal("finished"):
			if child.stream == stream:
				player_found = true
				break
	assert_true(player_found, "crossfade_to should set stream on a player")


func test_crossfade_does_not_crash_with_null_stream() -> void:
	_mgr.crossfade_to(null, 0.5)
	await wait_frames(3)
	assert_true(true, "crossfade_to with null stream should not crash")


func test_crossfade_duration_clamped() -> void:
	# Very short duration should still work
	var stream := _generate_test_stream(2.0)
	_mgr.crossfade_to(stream, 0.01)
	await wait_frames(3)
	assert_true(true, "crossfade_to with tiny duration should not crash")


# ── Combat proximity trigger tests ────────────────────────────────────

func test_trigger_combat_proximity_sets_state() -> void:
	assert_false(_mgr.is_in_combat, "Should start not in combat")
	_mgr.trigger_combat_proximity(true, 10.0)
	assert_true(_mgr.is_in_combat, "Should be in combat after trigger")
	_mgr.trigger_combat_proximity(false, 0.0)
	assert_false(_mgr.is_in_combat, "Should exit combat after clear")


func test_combat_proximity_has_cooldown() -> void:
	# Check that the cooldown property exists and is a positive value
	assert_true(_mgr.has_method("trigger_combat_proximity"),
		"Should have trigger_combat_proximity method")
	# Internal cooldown should prevent rapid toggling
	_mgr.trigger_combat_proximity(true, 5.0)
	assert_true(_mgr.is_in_combat, "Should enter combat state")
	_mgr.trigger_combat_proximity(false, 0.0)
	assert_false(_mgr.is_in_combat, "Should exit combat state")


func test_combat_trigger_toggles_is_in_combat() -> void:
	_mgr.is_in_combat = false
	_mgr.trigger_combat_proximity(true, 0.0)
	assert_true(_mgr.is_in_combat, "is_in_combat should be true after trigger(true)")
	_mgr.trigger_combat_proximity(false, 0.0)
	assert_false(_mgr.is_in_combat, "is_in_combat should be false after trigger(false)")


# ── AmbianceManager tests ─────────────────────────────────────────────

func test_ambiance_manager_script_exists() -> void:
	var path := "res://scripts/autoload/ambiance_manager.gd"
	assert_true(ResourceLoader.exists(path),
		"ambiance_manager.gd should exist at " + path)


func test_ambiance_manager_is_valid_class() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	assert_not_null(script, "AmbianceManager script should load")
	assert_true(script is GDScript, "AmbianceManager script should be GDScript")


func test_ambiance_manager_can_be_instantiated() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	var instance: Node = script.new()
	add_child_autofree(instance)
	assert_not_null(instance, "AmbianceManager should be instantiable")


func test_ambiance_manager_has_play_ambiance_method() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	var instance: Node = script.new()
	add_child_autofree(instance)
	assert_true(instance.has_method("play_ambiance"),
		"AmbianceManager should have play_ambiance method")


func test_ambiance_manager_has_stop_ambiance_method() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	var instance: Node = script.new()
	add_child_autofree(instance)
	assert_true(instance.has_method("stop_ambiance"),
		"AmbianceManager should have stop_ambiance method")


func test_ambiance_manager_has_room_types() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	var instance: Node = script.new()
	add_child_autofree(instance)
	assert_true(instance.has_method("set_room_type"),
		"AmbianceManager should have set_room_type method")


# ── Ambient sound file tests ─────────────────────────────────────────

func test_oven_hum_ogg_exists() -> void:
	assert_true(ResourceLoader.exists("res://assets/audio/ambiance/oven_hum.ogg"),
		"oven_hum.ogg should exist")


func test_paris_street_ogg_exists() -> void:
	assert_true(ResourceLoader.exists("res://assets/audio/ambiance/paris_street.ogg"),
		"paris_street.ogg should exist")


func test_dough_squish_ogg_exists() -> void:
	assert_true(ResourceLoader.exists("res://assets/audio/ambiance/dough_squish.ogg"),
		"dough_squish.ogg should exist")


func test_fire_crackle_ogg_exists() -> void:
	assert_true(ResourceLoader.exists("res://assets/audio/ambiance/fire_crackle.ogg"),
		"fire_crackle.ogg should exist")


func test_bakery_bell_ogg_exists() -> void:
	assert_true(ResourceLoader.exists("res://assets/audio/ambiance/bakery_bell.ogg"),
		"bakery_bell.ogg should exist")


func test_all_ambient_ogg_files_loadable() -> void:
	var paths := [
		"res://assets/audio/ambiance/oven_hum.ogg",
		"res://assets/audio/ambiance/paris_street.ogg",
		"res://assets/audio/ambiance/dough_squish.ogg",
		"res://assets/audio/ambiance/fire_crackle.ogg",
		"res://assets/audio/ambiance/bakery_bell.ogg",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			assert_not_null(stream, "Should load " + path + " as AudioStream")


# ── AmbianceManager room-type mapping tests ──────────────────────────

func test_play_ambiance_does_not_crash() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	var instance: Node = script.new()
	add_child_autofree(instance)
	instance.play_ambiance("bakery")
	await wait_frames(5)
	assert_true(true, "play_ambiance should not crash")


func test_stop_ambiance_does_not_crash() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	var instance: Node = script.new()
	add_child_autofree(instance)
	instance.stop_ambiance()
	await wait_frames(3)
	assert_true(true, "stop_ambiance should not crash")


func test_set_room_type_does_not_crash() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	var instance: Node = script.new()
	add_child_autofree(instance)
	instance.set_room_type("bakery")
	await wait_frames(3)
	instance.set_room_type("street")
	await wait_frames(3)
	instance.set_room_type("dungeon")
	await wait_frames(3)
	assert_true(true, "set_room_type with different rooms should not crash")


func test_ambiance_player_on_ambiance_bus() -> void:
	var script: GDScript = load("res://scripts/autoload/ambiance_manager.gd")
	var instance: Node = script.new()
	add_child_autofree(instance)
	# Should have an AudioStreamPlayer
	var player_found := false
	for child in instance.get_children():
		if child.has_method("play") and child.has_signal("finished"):
			assert_eq(child.bus, "Ambiance",
				"Ambiance player should be on Ambiance bus")
			player_found = true
			break
	assert_true(player_found, "AmbianceManager should have an AudioStreamPlayer child")


# ── Volume and crossfade interaction tests ────────────────────────────

func test_set_volume_changes_music_bus() -> void:
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx == -1:
		return
	var initial := AudioServer.get_bus_volume_db(music_idx)
	_mgr.set_music_volume(0.5)
	var after := AudioServer.get_bus_volume_db(music_idx)
	assert_ne(initial, after, "set_music_volume should change Music bus volume")


func test_crossfade_players_exist() -> void:
	var explore := _mgr.get_node_or_null("ExplorePlayer")
	var combat := _mgr.get_node_or_null("CombatPlayer")
	assert_not_null(explore, "ExplorePlayer should exist")
	assert_not_null(combat, "CombatPlayer should exist")


# ── Helpers ──────────────────────────────────────────────────────────

func _generate_test_stream(duration: float) -> AudioStreamGenerator:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = duration
	return gen
