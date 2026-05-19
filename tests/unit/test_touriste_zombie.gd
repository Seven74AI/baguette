extends "res://addons/gut/test.gd"
## Unit tests for TouristeZombie — basic melee enemy with state machine,
## health component, and attack AI.

const TouristeZombieClass = preload("res://scenes/enemies/touriste_zombie.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _zombie: TouristeZombieClass
var _health: HealthComponent


func before_each() -> void:
	_zombie = TouristeZombieClass.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 100
	_health.current_health = 100
	_health.invulnerability_duration = 0.0
	_zombie.add_child(_health)
	_zombie.health_component = _health
	add_child_autofree(_zombie)
	await wait_frames(2)


func test_zombie_starts_with_correct_stats() -> void:
	assert_eq(_zombie.move_speed, 3.0, "Default move speed should be 3.0")
	assert_eq(_zombie.attack_damage, 15, "Default attack damage should be 15")
	assert_eq(_zombie.attack_range, 2.0, "Default attack range should be 2.0")
	assert_eq(_zombie.attack_cooldown, 1.2, "Default attack cooldown should be 1.2")
	assert_eq(_zombie.detection_range, 15.0, "Default detection range should be 15.0")


func test_zombie_has_health_component() -> void:
	assert_not_null(_zombie.health_component, "Should have health component")
	assert_true(_zombie.health_component is HealthComponent, "health_component should be HealthComponent")


func test_zombie_has_state_enum() -> void:
	assert_eq(TouristeZombieClass.EnemyState.IDLE, TouristeZombieClass.EnemyState.IDLE)
	assert_eq(TouristeZombieClass.EnemyState.CHASE, TouristeZombieClass.EnemyState.CHASE)
	assert_eq(TouristeZombieClass.EnemyState.ATTACK, TouristeZombieClass.EnemyState.ATTACK)
	assert_eq(TouristeZombieClass.EnemyState.DEAD, TouristeZombieClass.EnemyState.DEAD)


func test_take_damage_reduces_health() -> void:
	var initial := _health.current_health
	_zombie.take_damage(30)
	assert_eq(_health.current_health, initial - 30, "Health should decrease by damage amount")


func test_death_changes_state() -> void:
	_zombie.take_damage(100)
	await wait_frames(2)
	# After death, state should be DEAD
	assert_eq(_zombie._state, TouristeZombieClass.EnemyState.DEAD,
		"Zombie should be in DEAD state after fatal damage")


func test_exports_are_settable() -> void:
	_zombie.move_speed = 5.0
	_zombie.attack_damage = 25
	_zombie.attack_range = 3.0
	_zombie.attack_cooldown = 2.0
	_zombie.detection_range = 20.0
	assert_eq(_zombie.move_speed, 5.0, "move_speed should be settable")
	assert_eq(_zombie.attack_damage, 25, "attack_damage should be settable")
	assert_eq(_zombie.attack_range, 3.0, "attack_range should be settable")
	assert_eq(_zombie.attack_cooldown, 2.0, "attack_cooldown should be settable")
	assert_eq(_zombie.detection_range, 20.0, "detection_range should be settable")


func test_physics_process_no_player_no_crash() -> void:
	# With no player in group, _find_player sets state to IDLE
	_zombie._physics_process(0.1)
	# Should not crash — just idles
	assert_true(true, "physics_process should not crash without player")


func test_chase_player_no_player_no_crash() -> void:
	_zombie._chase_player(0.1)
	# Should not crash — returns early
	assert_true(true, "_chase_player should not crash without player")


func test_attack_player_no_player_no_crash() -> void:
	_zombie._can_attack = true
	_zombie._attack_player()
	# Should not crash — returns early
	assert_true(true, "_attack_player should not crash without player")
