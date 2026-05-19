extends "res://addons/gut/test.gd"
## Unit tests for player dash mechanic (PHASE 3 polish).
## Verifies dash state machine, cooldown, and speed boost.

const PlayerScene = preload("res://scenes/player/player.tscn")

var _player: CharacterBody3D


func before_each() -> void:
	var player_instance := PlayerScene.instantiate()
	_player = player_instance
	add_child_autofree(_player)
	await wait_frames(2)


func test_player_has_dash_properties() -> void:
	# Player should expose dash-related export vars
	var dash_speed: float = float(_player.get("dash_speed"))
	var dash_duration: float = float(_player.get("dash_duration"))
	var dash_cooldown: float = float(_player.get("dash_cooldown"))
	var walk_speed: float = float(_player.get("walk_speed"))
	assert_gt(dash_speed, walk_speed, "Dash speed should be faster than walk speed")
	assert_gt(dash_duration, 0.0, "Dash duration should be positive")
	assert_gt(dash_cooldown, 0.0, "Dash cooldown should be positive")


func test_dash_has_cooldown() -> void:
	var cooldown: float = float(_player.dash_cooldown)
	assert_gt(cooldown, 0.2, "Dash cooldown should be at least 0.2 seconds")


func test_dash_speed_exceeds_walk() -> void:
	assert_gt(_player.dash_speed, _player.walk_speed, "Dash speed should exceed walk speed")
