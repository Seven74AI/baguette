extends "res://addons/gut/test.gd"
## TDD tests for Pain au Chocolatine — charger enemy that explodes on contact.
## Verifies stats, charge behavior, contact explosion, AoE damage, and chocolate puddle.

const PainAuChocolatine = preload("res://scripts/enemies/pain_au_chocolatine.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: PainAuChocolatine
var _health: HealthComponent


func before_each() -> void:
	_enemy = PainAuChocolatine.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 30
	_health.current_health = 30
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
	assert_eq(_enemy.get_max_health(), 30, "Chocolatine should have 30 HP")
	assert_gt(_enemy.move_speed, 8.0, "Chocolatine should be very fast (> 8.0 speed)")
	assert_eq(_enemy.move_speed, 9.0, "Chocolatine should have speed 9.0")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, PainAuChocolatine.EnemyState.IDLE)


func test_is_fragile() -> void:
	# Pain au Chocolatine should die quickly from its own explosion or attacks
	assert_lt(_enemy.get_max_health(), 50, "Chocolatine should be fragile (< 50 HP)")


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(10)
	assert_eq(_enemy.get_current_health(), initial - 10)


func test_has_charge_behavior() -> void:
	assert_true(_enemy.has_method("_charge_player"), "Should have charge behavior")
	assert_gt(_enemy.charge_speed_multiplier, 1.0, "Charge should multiply base speed")


func test_explodes_on_contact() -> void:
	# The enemy should self-destruct on player contact
	assert_true(_enemy.self_destructs_on_contact, "Should self-destruct on contact")
	assert_gt(_enemy.explosion_damage, 0, "Explosion should deal damage")
	assert_eq(_enemy.explosion_damage, 40, "Explosion should deal 40 damage")


func test_explosion_is_aoe() -> void:
	assert_gt(_enemy.explosion_radius, 2.0, "Explosion should have AoE radius > 2.0")
	assert_true(_enemy.has_method("_detonate"), "Should have a detonate method")


func test_leaves_chocolate_puddle() -> void:
	assert_true(_enemy.has_method("_spawn_chocolate_puddle"), "Should leave chocolate puddle on death")
	assert_gt(_enemy.chocolate_slow_factor, 0.0, "Chocolate puddle should have slow factor")
	assert_lt(_enemy.chocolate_slow_factor, 1.0, "Chocolate puddle slow factor < 1.0")


func test_death_leaves_puddle() -> void:
	watch_signals(_enemy)
	_enemy.take_damage(30)
	assert_signal_emitted(_enemy, "died")
	assert_true(_enemy.has_method("_spawn_chocolate_puddle"), "Death should leave chocolate puddle")


func test_puddle_slows_player() -> void:
	assert_lt(_enemy.chocolate_slow_factor, 0.7, "Chocolate should slow significantly (< 0.7)")
	assert_gt(_enemy.puddle_lifetime, 2.0, "Puddle should persist > 2 seconds")
