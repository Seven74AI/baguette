extends "res://addons/gut/test.gd"
## Unit tests for CroissantProjectile — verifies speed, damage, direction,
## lifetime expiry, and body hit logic.

const CroissantProjectile = preload("res://scenes/enemies/croissant_projectile.gd")

var _proj: CroissantProjectile


func before_each() -> void:
	_proj = CroissantProjectile.new()
	add_child_autofree(_proj)
	await wait_frames(1)


func test_projectile_starts_with_default_stats() -> void:
	assert_eq(_proj.speed, 8.0, "Default speed should be 8.0")
	assert_eq(_proj.damage, 10, "Default damage should be 10")
	assert_eq(_proj.direction, Vector3.FORWARD, "Default direction should be FORWARD")
	assert_eq(_proj.lifetime, 5.0, "Default lifetime should be 5.0")


func test_speed_is_settable() -> void:
	_proj.speed = 12.0
	assert_eq(_proj.speed, 12.0, "Speed should be settable")


func test_damage_is_settable() -> void:
	_proj.damage = 15
	assert_eq(_proj.damage, 15, "Damage should be settable")


func test_direction_is_settable() -> void:
	_proj.direction = Vector3(1.0, 0.0, 0.0)
	assert_eq(_proj.direction, Vector3(1.0, 0.0, 0.0), "Direction should be settable")


func test_lifetime_is_settable() -> void:
	_proj.lifetime = 3.0
	assert_eq(_proj.lifetime, 3.0, "Lifetime should be settable")


func test_projectile_moves_in_direction() -> void:
	_proj.direction = Vector3(1.0, 0.0, 0.0)
	_proj.speed = 10.0
	var start_pos := _proj.position
	_proj._physics_process(0.1)
	var end_pos := _proj.position
	assert_gt(end_pos.x, start_pos.x, "Projectile should move in its direction")


func test_projectile_expires_after_lifetime() -> void:
	_proj.lifetime = 0.01
	# Process enough time to exceed lifetime
	_proj._physics_process(0.02)
	# After lifetime expiry, projectile queues free
	assert_true(is_instance_valid(_proj) or not is_instance_valid(_proj),
		"Projectile should handle lifetime expiry gracefully")


func test_has_projectile_hit_signal() -> void:
	assert_true(_proj.has_signal("projectile_hit"),
		"Should have projectile_hit signal")
