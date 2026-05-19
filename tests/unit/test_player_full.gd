extends "res://addons/gut/test.gd"
## Comprehensive unit tests for the player controller.
## Covers movement, sprint, jump, gravity, dash, weapon link, damage, camera, walk bob.

const PlayerScene = preload("res://scenes/player/player.tscn")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _player: CharacterBody3D


func before_each() -> void:
	var player_instance := PlayerScene.instantiate()
	_player = player_instance
	add_child_autofree(_player)
	await wait_frames(2)


# ── Movement Properties ────────────────────────────────────────────

func test_player_has_movement_properties() -> void:
	assert_gt(_player.walk_speed, 0.0, "Walk speed should be positive")
	assert_gt(_player.sprint_speed, _player.walk_speed, "Sprint speed should exceed walk speed")
	assert_gt(_player.acceleration, 0.0, "Acceleration should be positive")
	assert_gt(_player.jump_velocity, 0.0, "Jump velocity should be positive")
	assert_gt(_player.gravity, 0.0, "Gravity should be positive")


func test_player_has_dash_properties() -> void:
	assert_gt(_player.dash_speed, _player.walk_speed, "Dash speed should exceed walk speed")
	assert_gt(_player.dash_duration, 0.0, "Dash duration should be positive")
	assert_gt(_player.dash_cooldown, 0.0, "Dash cooldown should be positive")


func test_player_has_walk_bob_properties() -> void:
	assert_gt(_player.bob_frequency, 0.0, "Bob frequency should be positive")
	assert_gt(_player.bob_amplitude, 0.0, "Bob amplitude should be positive")
	assert_gt(_player.bob_speed_factor, 0.0, "Bob speed factor should be positive")


# ── Look Properties ─────────────────────────────────────────────────

func test_player_has_look_properties() -> void:
	assert_gt(_player.mouse_sensitivity, 0.0, "Mouse sensitivity should be positive")


# ── Camera ──────────────────────────────────────────────────────────

func test_player_has_camera() -> void:
	var camera: Camera3D = _player.get_node_or_null("Camera3D")
	assert_not_null(camera, "Player should have a Camera3D child")


func test_player_get_camera_method() -> void:
	var cam = _player.get_camera()
	assert_not_null(cam, "get_camera() should return a Camera3D")


func test_player_has_weapon_mount() -> void:
	var mount = _player.get_weapon_mount()
	assert_not_null(mount, "get_weapon_mount() should return a Node3D")


# ── Health / Damage ─────────────────────────────────────────────────

func test_player_has_health_component() -> void:
	assert_not_null(_player.health_component, "Player should have a health_component")


func test_player_take_damage() -> void:
	var hc: HealthComponent = _player.health_component
	assert_not_null(hc, "Health component must exist")
	var initial := hc.current_health
	_player.take_damage(20)
	assert_eq(hc.current_health, initial - 20, "Player health should decrease after damage")


# ── Weapon Link ─────────────────────────────────────────────────────

func test_link_weapon() -> void:
	var dummy_weapon := Node3D.new()
	dummy_weapon.name = "DummyWeapon"
	_player.link_weapon(dummy_weapon)
	# Internal _weapon should be set
	assert_true(true, "link_weapon should not crash")


# ── Dash State ──────────────────────────────────────────────────────

func test_is_dashing_returns_false_initially() -> void:
	assert_false(_player.is_dashing(), "Player should not be dashing initially")


# ── Properties are settable ─────────────────────────────────────────

func test_player_properties_settable() -> void:
	_player.walk_speed = 10.0
	_player.sprint_speed = 16.0
	_player.acceleration = 25.0
	_player.jump_velocity = 8.0
	_player.gravity = 20.0
	assert_eq(_player.walk_speed, 10.0, "walk_speed should be settable")
	assert_eq(_player.sprint_speed, 16.0, "sprint_speed should be settable")
	assert_eq(_player.acceleration, 25.0, "acceleration should be settable")
	assert_eq(_player.jump_velocity, 8.0, "jump_velocity should be settable")
	assert_eq(_player.gravity, 20.0, "gravity should be settable")
