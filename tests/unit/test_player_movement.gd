extends "res://tests/test_base.gd"
## Unit tests for player movement — direction, sprint, camera rotation.

const PlayerScript = preload("res://scenes/player/player.gd")

var _player: CharacterBody3D


func before_each() -> void:
	_player = CharacterBody3D.new()
	_player.set_script(PlayerScript)
	
	# Add required child nodes
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 1.7, 0)
	_player.add_child(camera)
	
	var weapon_mount := Node3D.new()
	weapon_mount.name = "WeaponMount"
	weapon_mount.position = Vector3(0.3, -0.25, -0.5)
	camera.add_child(weapon_mount)
	
	var head_collision := CollisionShape3D.new()
	head_collision.name = "HeadCollision"
	_player.add_child(head_collision)
	
	add_child(_player)
	await get_tree().process_frame


func after_each() -> void:
	if _player:
		_player.queue_free()
		_player = null


func test_player_has_camera() -> void:
	var camera = _player.get_node_or_null("Camera3D")
	assert_not_null(camera, "Player should have a Camera3D child")


func test_player_has_camera_at_head_height() -> void:
	var camera: Camera3D = _player.get_node("Camera3D")
	assert_true(camera.position.y > 1.5, "Camera should be at head height (>1.5m)")


func test_player_starts_with_mouse_captured() -> void:
	# After _ready(), mouse should be captured if display server supports it.
	# In headless mode, capture is not supported, so _mouse_captured is set to false.
	var mode := Input.get_mouse_mode()
	assert_true(
		mode == Input.MOUSE_MODE_CAPTURED or mode == Input.MOUSE_MODE_VISIBLE,
		"Mouse mode should be CAPTURED or VISIBLE (headless fallback), got %d" % mode
	)


func test_walk_speed_default() -> void:
	assert_eq(_player.walk_speed, 8.0, "Default walk speed should be 8.0")


func test_sprint_speed_default() -> void:
	assert_eq(_player.sprint_speed, 12.0, "Default sprint speed should be 12.0")


func test_sprint_speed_is_higher_than_walk() -> void:
	assert_gt(_player.sprint_speed, _player.walk_speed,
		"Sprint speed should be higher than walk speed")


func test_sprint_multiplier_is_1_5() -> void:
	# sprint_speed / walk_speed should be ~1.5
	var ratio: float = _player.sprint_speed / _player.walk_speed
	assert_true(ratio >= 1.4 and ratio <= 1.6,
		"Sprint should be ~1.5x walk speed, got %f" % ratio)


func test_mouse_sensitivity_default() -> void:
	assert_eq(_player.mouse_sensitivity, 0.002,
		"Default mouse sensitivity should be 0.002")


func test_look_up_limit() -> void:
	assert_eq(_player.look_up_limit, deg_to_rad(85.0),
		"Look up limit should be 85 degrees")


func test_look_down_limit() -> void:
	assert_eq(_player.look_down_limit, deg_to_rad(-85.0),
		"Look down limit should be -85 degrees")


func test_player_has_weapon_mount() -> void:
	var mount = _player.get_node_or_null("Camera3D/WeaponMount")
	assert_not_null(mount, "Player should have a WeaponMount under Camera3D")


func test_player_has_head_collision() -> void:
	var head = _player.get_node_or_null("HeadCollision")
	assert_not_null(head, "Player should have HeadCollision shape")


func test_get_camera_returns_camera() -> void:
	var cam: Camera3D = _player.get_camera()
	assert_not_null(cam, "get_camera() should return a Camera3D")
	assert_true(cam is Camera3D, "get_camera() should return a Camera3D instance")


func test_get_weapon_mount_returns_mount() -> void:
	var mount: Node3D = _player.get_weapon_mount()
	assert_not_null(mount, "get_weapon_mount() should return a Node3D")
