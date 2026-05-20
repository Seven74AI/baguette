extends "res://addons/gut/test.gd"
## Tests for Barista Possédé — Support/Spawner enemy.
## Verifies stats, minion spawn, expresso steam, Latte Art buff, counter, elite variant.

const BaristaPossede = preload("res://scripts/enemies/barista_possede.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: BaristaPossede
var _health: HealthComponent


func before_each() -> void:
	_enemy = BaristaPossede.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 160
	_health.current_health = 160
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
	assert_eq(_enemy.get_max_health(), 160, "Should have 160 HP (high)")
	assert_lt(_enemy.move_speed, 1.0, "Should be static (< 1.0 speed)")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, BaristaPossede.EnemyState.IDLE)


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(20)
	assert_eq(_enemy.get_current_health(), initial - 20)


func test_can_spawn_minions() -> void:
	assert_true(_enemy.has_method("_spawn_stagiaire"), "Should have minion spawn method")
	assert_gt(_enemy.spawn_interval, 0.0, "Should have spawn interval")
	assert_gt(_enemy.max_active_minions, 0, "Should have max minion count")


func test_has_expresso_steam_attack() -> void:
	assert_true(_enemy.has_method("_machine_expresso"), "Should have expresso steam attack")
	assert_gt(_enemy.expresso_damage, 0, "Expresso steam should deal damage")
	assert_gt(_enemy.expresso_push_force, 0.0, "Expresso steam should push player")


func test_has_latte_art_buff() -> void:
	assert_true(_enemy.has_method("_latte_art_maudit"), "Should have Latte Art buff")
	assert_gt(_enemy.latte_speed_bonus, 0.0, "Latte Art should buff speed")
	assert_gt(_enemy.latte_damage_bonus, 0.0, "Latte Art should buff damage")


func test_has_destructible_counter() -> void:
	assert_true(_enemy.has_counter, "Should have a counter")
	assert_gt(_enemy.counter_health, 0, "Counter should have health")


func test_latte_art_interruptible() -> void:
	assert_true(_enemy.latte_art_interruptible, "Latte Art should be interruptible")


func test_expresso_is_cone_attack() -> void:
	assert_true(_enemy.expresso_is_cone, "Expresso should be a cone attack")


func test_static_when_counter_intact() -> void:
	assert_true(_enemy.is_static, "Should be static when counter is intact")


func test_has_elite_variant() -> void:
	assert_true(_enemy.has_method("_apply_elite_modifier"), "Should support elite variants")
	assert_true(_enemy.get("is_elite") != null, "Should have is_elite property")


func test_dies_correctly() -> void:
	_enemy.take_damage(160)
	assert_eq(_enemy.current_state, BaristaPossede.EnemyState.DEAD)
