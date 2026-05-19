extends "res://addons/gut/test.gd"
## Tests for BaseEnemy — verifies health, damage, death, state transitions, and drop hooks.

const BaseEnemy = preload("res://scripts/enemies/base_enemy.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: BaseEnemy


func before_each() -> void:
	_enemy = BaseEnemy.new()
	# Create and attach a HealthComponent for testing
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 100
	hc.current_health = 100
	hc.invulnerability_duration = 0.0
	_enemy.add_child(hc)
	_enemy.health_component = hc
	add_child_autofree(_enemy)


func test_enemy_has_health_component() -> void:
	assert_not_null(_enemy.health_component, "BaseEnemy should have a health_component")
	assert_true(_enemy.health_component is HealthComponent, "health_component should be a HealthComponent")


func test_enemy_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, BaseEnemy.EnemyState.IDLE, "Enemy should start in IDLE state")


func test_enemy_has_max_health() -> void:
	assert_eq(_enemy.get_max_health(), 100, "get_max_health() should return max_health")
	assert_eq(_enemy.get_current_health(), 100, "get_current_health() should return current_health")


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(30)
	assert_eq(_enemy.get_current_health(), initial - 30, "Health should decrease by damage amount")


func test_take_damage_emits_signal() -> void:
	watch_signals(_enemy)
	_enemy.take_damage(10)
	assert_signal_emitted(_enemy, "damaged")


func test_enemy_dies_when_health_reaches_zero() -> void:
	watch_signals(_enemy)
	_enemy.take_damage(100)
	assert_signal_emitted(_enemy, "died")
	assert_eq(_enemy.current_state, BaseEnemy.EnemyState.DEAD, "Enemy should be in DEAD state after fatal damage")


func test_enemy_is_alive_method() -> void:
	assert_true(_enemy.is_alive(), "Enemy should be alive at full health")
	_enemy.take_damage(100)
	assert_false(_enemy.is_alive(), "Enemy should not be alive after fatal damage")


func test_dead_enemy_does_not_take_more_damage() -> void:
	_enemy.take_damage(100)
	var health_after_death := _enemy.get_current_health()
	_enemy.take_damage(50)
	assert_eq(_enemy.get_current_health(), health_after_death, "Dead enemy should not take more damage")


func test_drop_table_hook() -> void:
	# drop_table should be a callable or dictionary
	_enemy.drop_table = {"baguette_crumb": 1.0}
	assert_not_null(_enemy.drop_table, "drop_table should be assignable")


func test_enemy_has_move_speed() -> void:
	_enemy.move_speed = 3.0
	assert_eq(_enemy.move_speed, 3.0, "move_speed should be settable")


func test_enemy_has_attack_damage() -> void:
	_enemy.attack_damage = 15
	assert_eq(_enemy.attack_damage, 15, "attack_damage should be settable")


func test_enemy_has_attack_range() -> void:
	_enemy.attack_range = 2.0
	assert_eq(_enemy.attack_range, 2.0, "attack_range should be settable")


func test_enemy_has_detection_range() -> void:
	_enemy.detection_range = 15.0
	assert_eq(_enemy.detection_range, 15.0, "detection_range should be settable")


func test_on_death_hook() -> void:
	# _on_death should be overridable; verify the signal triggers state change
	watch_signals(_enemy)
	_enemy.take_damage(100)
	assert_signal_emitted(_enemy, "died")
	assert_eq(_enemy.current_state, BaseEnemy.EnemyState.DEAD)
