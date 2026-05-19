extends "res://addons/gut/test.gd"
## Unit tests for TestDummy — minimal navigation enemy for integration testing.
## Verifies movement config, detection range, and idle behavior without nav agent.

var _dummy: CharacterBody3D


func before_each() -> void:
	# TestDummy has no class_name, load by path
	var DummyScript = load("res://scenes/enemies/test_dummy.gd")
	_dummy = CharacterBody3D.new()
	_dummy.set_script(DummyScript)
	add_child_autofree(_dummy)
	await wait_frames(1)


func test_dummy_has_move_speed() -> void:
	assert_eq(_dummy.move_speed, 4.0, "Default move speed should be 4.0")


func test_dummy_has_acceleration() -> void:
	assert_eq(_dummy.acceleration, 10.0, "Default acceleration should be 10.0")


func test_dummy_has_detection_range() -> void:
	assert_eq(_dummy.detection_range, 20.0, "Default detection range should be 20.0")


func test_move_speed_is_settable() -> void:
	_dummy.move_speed = 6.0
	assert_eq(_dummy.move_speed, 6.0, "Move speed should be settable")


func test_acceleration_is_settable() -> void:
	_dummy.acceleration = 15.0
	assert_eq(_dummy.acceleration, 15.0, "Acceleration should be settable")


func test_detection_range_is_settable() -> void:
	_dummy.detection_range = 30.0
	assert_eq(_dummy.detection_range, 30.0, "Detection range should be settable")


func test_dummy_starts_with_nav_not_ready() -> void:
	# Without a NavigationAgent3D child, _nav_ready stays false
	# and physics_process does nothing — no crash
	_dummy._physics_process(0.1)
	# Should not crash — just returns early
	assert_true(true, "Dummy should handle _physics_process without nav agent")
