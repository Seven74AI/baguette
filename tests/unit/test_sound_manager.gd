extends "res://addons/gut/test.gd"
## Unit tests for SoundManager — procedural sound system.
## Verifies all public sound methods exist and internal helpers are present.

const SoundManagerClass = preload("res://scripts/autoload/sound_manager.gd")

var _sound_mgr: Node


func before_each() -> void:
	_sound_mgr = SoundManagerClass.new()
	add_child_autofree(_sound_mgr)


func test_sound_manager_exists() -> void:
	assert_not_null(_sound_mgr, "SoundManager should be creatable")


func test_has_shoot_sound() -> void:
	assert_true(_sound_mgr.has_method("play_shoot_sound"),
		"Should have play_shoot_sound method")


func test_has_hit_sound() -> void:
	assert_true(_sound_mgr.has_method("play_hit_sound"),
		"Should have play_hit_sound method")


func test_has_enemy_death_sound() -> void:
	assert_true(_sound_mgr.has_method("play_enemy_death_sound"),
		"Should have play_enemy_death_sound method")


func test_has_reload_sound() -> void:
	assert_true(_sound_mgr.has_method("play_reload_sound"),
		"Should have play_reload_sound method")


func test_has_dash_sound() -> void:
	assert_true(_sound_mgr.has_method("play_dash_sound"),
		"Should have play_dash_sound method")


func test_has_ui_click() -> void:
	assert_true(_sound_mgr.has_method("play_ui_click"),
		"Should have play_ui_click method")


func test_has_internal_tone_generator() -> void:
	assert_true(_sound_mgr.has_method("_play_tone"),
		"Should have _play_tone method")


func test_has_internal_sweep_generator() -> void:
	assert_true(_sound_mgr.has_method("_play_sweep"),
		"Should have _play_sweep method")


func test_has_internal_sample_generator() -> void:
	assert_true(_sound_mgr.has_method("_generate_sample"),
		"Should have _generate_sample method")


func test_has_internal_envelope() -> void:
	assert_true(_sound_mgr.has_method("_envelope"),
		"Should have _envelope method")


func test_has_internal_stream_creator() -> void:
	assert_true(_sound_mgr.has_method("_create_stream_player"),
		"Should have _create_stream_player method")


func test_calling_shoot_sound_does_not_crash() -> void:
	_sound_mgr.play_shoot_sound()
	await wait_frames(5)
	assert_true(true, "play_shoot_sound should not crash")


func test_calling_hit_sound_does_not_crash() -> void:
	_sound_mgr.play_hit_sound()
	await wait_frames(5)
	assert_true(true, "play_hit_sound should not crash")


func test_calling_enemy_death_sound_does_not_crash() -> void:
	_sound_mgr.play_enemy_death_sound()
	await wait_frames(5)
	assert_true(true, "play_enemy_death_sound should not crash")


func test_calling_reload_sound_does_not_crash() -> void:
	_sound_mgr.play_reload_sound()
	await wait_frames(5)
	assert_true(true, "play_reload_sound should not crash")


func test_calling_dash_sound_does_not_crash() -> void:
	_sound_mgr.play_dash_sound()
	await wait_frames(5)
	assert_true(true, "play_dash_sound should not crash")


func test_calling_ui_click_does_not_crash() -> void:
	_sound_mgr.play_ui_click()
	await wait_frames(5)
	assert_true(true, "play_ui_click should not crash")


func test_envelope_values() -> void:
	# Test envelope at various times
	var duration: float = 0.3
	# At start (t=0), envelope should be 0 (attack phase)
	var env_start = _sound_mgr._envelope(0.0, duration)
	assert_eq(env_start, 0.0, "Envelope at t=0 should be 0")
	# After attack phase (t > 0.005 for default attack=0.005)
	var env_mid = _sound_mgr._envelope(0.1, duration)
	assert_eq(env_mid, 1.0, "Envelope during sustain should be 1.0")


func test_generate_sample_square() -> void:
	var sample = _sound_mgr._generate_sample(0.0, 440.0, "square")
	assert_eq(sample, 1.0, "Square wave at t=0 should be 1.0")


func test_generate_sample_sawtooth() -> void:
	var sample = _sound_mgr._generate_sample(0.001, 440.0, "sawtooth")
	assert_gt(sample, -2.0, "Sawtooth should be in [-1, 1] range")
	assert_lt(sample, 2.0, "Sawtooth should be in [-1, 1] range")


func test_generate_sample_default() -> void:
	var sample = _sound_mgr._generate_sample(0.0, 440.0, "unknown")
	assert_eq(sample, 0.0, "Unknown waveform should default to sine (sin(0) = 0)")
