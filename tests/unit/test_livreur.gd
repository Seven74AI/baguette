extends "res://addons/gut/test.gd"
## Tests for Livreur à Vélo — Rusher/Flanker enemy.
## Verifies stats, charge attack, pizza projectile, sonnette stun, weakness, elite variant.

const LivreurVelo = preload("res://scripts/enemies/livreur_velo.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: LivreurVelo
var _health: HealthComponent


func before_each() -> void:
	_enemy = LivreurVelo.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 50
	_health.current_health = 50
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.3
	cs.shape = shape
	_enemy.add_child(cs)

	add_child_autofree(_enemy)


func test_spawns_with_correct_stats() -> void:
	assert_eq(_enemy.get_max_health(), 50, "Should have 50 HP (low-medium)")
	assert_gt(_enemy.move_speed, 6.0, "Should be fast (> 6.0 speed)")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, LivreurVelo.EnemyState.IDLE)


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(15)
	assert_eq(_enemy.get_current_health(), initial - 15)


func test_has_charge_attack() -> void:
	assert_true(_enemy.has_method("_charge_player"), "Should have charge attack")
	assert_gt(_enemy.charge_speed_multiplier, 1.0, "Charge should boost speed")
	assert_gt(_enemy.charge_damage, 0, "Charge should deal damage")


func test_has_pizza_throw_attack() -> void:
	assert_true(_enemy.has_method("_throw_pizza"), "Should have pizza throw attack")


func test_has_sonnette_stun_attack() -> void:
	assert_true(_enemy.has_method("_coup_de_sonnette"), "Should have sonnette stun attack")
	assert_gt(_enemy.sonnette_stun_duration, 0.0, "Sonnette should stun")


func test_charge_telegraphed() -> void:
	assert_true(_enemy.charge_telegraphed, "Charge should be telegraphed")
	assert_gt(_enemy.charge_windup_duration, 0.0, "Charge should have windup")


func test_vulnerable_after_missed_charge() -> void:
	assert_true(_enemy.vulnerable_after_missed_charge, "Should be vulnerable after missed charge")
	assert_gt(_enemy.missed_charge_stun_duration, 0.0, "Should be stunned longer after missed charge")


func test_shot_during_charge_causes_chute() -> void:
	assert_true(_enemy.chute_on_charge_shot, "Shot during charge should cause chute")
	assert_gt(_enemy.chute_stun_duration, 0.0, "Chute should stun")


func test_circles_player() -> void:
	assert_true(_enemy.has_method("_circle_player"), "Should circle the player")


func test_has_elite_variant() -> void:
	assert_true(_enemy.has_method("_apply_elite_modifier"), "Should support elite variants")
	assert_true(_enemy.get("is_elite") != null, "Should have is_elite property")


func test_dies_correctly() -> void:
	_enemy.take_damage(50)
	assert_eq(_enemy.current_state, LivreurVelo.EnemyState.DEAD)
