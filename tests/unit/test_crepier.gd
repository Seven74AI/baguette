extends "res://addons/gut/test.gd"
## Tests for Crêpier Démoniaque — Area Denial enemy.
## Verifies stats, nappe AoE, crêpe projectile, melee AoE, weakness, elite variant.

const CrepierDemoniaque = preload("res://scripts/enemies/crepier_demoniaque.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: CrepierDemoniaque
var _health: HealthComponent


func before_each() -> void:
	_enemy = CrepierDemoniaque.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 120
	_health.current_health = 120
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 2.0
	cs.shape = shape
	_enemy.add_child(cs)

	add_child_autofree(_enemy)


func test_spawns_with_correct_stats() -> void:
	assert_eq(_enemy.get_max_health(), 120, "Should have 120 HP (elevated)")
	assert_lt(_enemy.move_speed, 3.0, "Should be slow (< 3.0 speed)")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, CrepierDemoniaque.EnemyState.IDLE)


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(25)
	assert_eq(_enemy.get_current_health(), initial - 25)


func test_has_nappe_attack() -> void:
	assert_true(_enemy.has_method("_spawn_nappe"), "Should have nappe spawn method")
	assert_gt(_enemy.nappe_damage, 0, "Nappe should deal damage")
	assert_gt(_enemy.nappe_duration, 0.0, "Nappe should have duration")


func test_has_crepe_suzette_attack() -> void:
	assert_true(_enemy.has_method("_throw_crepe_suzette"), "Should have crêpe suzette throw method")
	assert_gt(_enemy.crepe_damage, 0, "Crêpe should deal damage")


func test_has_melee_aoe_attack() -> void:
	assert_true(_enemy.has_method("_retournement_crepe"), "Should have melee AoE attack")


func test_nappes_can_be_ignited() -> void:
	assert_true(_enemy.nappes_ignitable, "Nappes should be ignitable by crêpes")


func test_four_sacre_cleans_nappes() -> void:
	assert_true(_enemy.has_method("_clean_all_nappes"), "Should have method to clean all nappes")


func test_is_area_denial_enemy() -> void:
	assert_gt(_enemy.attack_range, 6.0, "Should have area denial range")
	assert_true(_enemy.has_method("_get_active_nappe_count"), "Should track active nappe count")


func test_has_elite_variant() -> void:
	assert_true(_enemy.has_method("_apply_elite_modifier"), "Should support elite variants")
	assert_true(_enemy.get("is_elite") != null, "Should have is_elite property")


func test_dies_correctly() -> void:
	_enemy.take_damage(120)
	assert_eq(_enemy.current_state, CrepierDemoniaque.EnemyState.DEAD)
