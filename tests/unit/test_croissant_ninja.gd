extends "res://addons/gut/test.gd"
## Tests for CroissantNinja — fast, evasive ranged enemy.
## Verifies stats, dodge behavior, projectile attack, and butter trail.

const CroissantNinja = preload("res://scenes/enemies/croissant_ninja.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: CroissantNinja
var _health: HealthComponent


func before_each() -> void:
	_enemy = CroissantNinja.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 40
	_health.current_health = 40
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.0
	cs.shape = shape
	_enemy.add_child(cs)

	add_child_autofree(_enemy)


func test_starts_with_correct_stats() -> void:
	assert_gt(_enemy.move_speed, 5.0, "Croissant Ninja should be fast (speed > 5.0)")
	assert_eq(_enemy.get_max_health(), 40, "Should have low HP (40)")
	assert_lt(_enemy.get_max_health(), 60, "Should be fragile (< 60 HP)")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, CroissantNinja.EnemyState.IDLE)


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(15)
	assert_eq(_enemy.get_current_health(), initial - 15)


func test_has_dodge_ability() -> void:
	assert_true(_enemy.has_method("_perform_dodge"), "Should have dodge method")


func test_has_projectile_attack() -> void:
	# Croissant ninja should have a projectile scene reference
	assert_not_null(_enemy.projectile_scene, "Should have a projectile_scene assigned")
	# And it should have a method to throw projectiles
	assert_true(_enemy.has_method("_throw_projectile"), "Should have projectile throwing method")


func test_has_butter_trail_effect() -> void:
	assert_true(_enemy.has_method("_spawn_butter_trail"), "Should have butter trail effect")


func test_ranged_attack_has_long_range() -> void:
	assert_gt(_enemy.attack_range, 8.0, "Ranged attack should have > 8.0 range")


func test_fragile_dies_quickly() -> void:
	_enemy.take_damage(40)
	assert_eq(_enemy.current_state, CroissantNinja.EnemyState.DEAD)
