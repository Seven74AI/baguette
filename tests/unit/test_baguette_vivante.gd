extends "res://addons/gut/test.gd"
## Tests for BaguetteVivante — living baguette melee enemy.
## Verifies stats, AI states, attack behavior, and death split.

const BaguetteVivante = preload("res://scenes/enemies/baguette_vivante.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: BaguetteVivante
var _health: HealthComponent


func before_each() -> void:
	_enemy = BaguetteVivante.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 150
	_health.current_health = 150
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health

	# Add collision shape (required for CharacterBody3D behavior)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 0.8
	cs.shape = shape
	_enemy.add_child(cs)

	add_child_autofree(_enemy)


func test_starts_with_correct_stats() -> void:
	assert_eq(_enemy.move_speed, 2.0, "Baguette Vivante should be slow (speed 2.0)")
	assert_gt(_enemy.attack_damage, 20, "Should hit hard (20+ damage)")
	assert_lt(_enemy.attack_range, 2.5, "Should be short range (< 2.5)")
	assert_eq(_enemy.get_max_health(), 150, "Should be tanky (150 HP)")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, BaguetteVivante.EnemyState.IDLE)


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(30)
	assert_eq(_enemy.get_current_health(), initial - 30)


func test_death_splits_into_halves() -> void:
	watch_signals(_enemy)
	_enemy.take_damage(150)
	assert_signal_emitted(_enemy, "died")
	# After death, the enemy should emit a signal about splitting
	assert_signal_emitted(_enemy, "split")


func test_has_breadcrumb_trail_enabled() -> void:
	# The breadcrumb trail should be a configurable property
	assert_true(_enemy.has_method("_spawn_breadcrumb"), "Should have breadcrumb spawning method")


func test_chase_behavior_exists() -> void:
	assert_true(_enemy.has_method("_chase_player"), "Should override chase behavior")
