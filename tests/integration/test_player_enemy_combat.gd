extends "res://addons/gut/test.gd"
## Integration tests: player + enemy combat interactions.
## Verifies that enemy AI finds player by group, enemy damages health component,
## and player can damage enemy.

const HealthComponent = preload("res://scripts/components/health_component.gd")
const BaseEnemy = preload("res://scripts/enemies/base_enemy.gd")

var _enemy: BaseEnemy
var _enemy_health: HealthComponent


func before_each() -> void:
	# Create enemy with health
	_enemy = BaseEnemy.new()
	_enemy.name = "TestEnemy"
	_enemy.add_to_group("enemy")

	_enemy_health = HealthComponent.new()
	_enemy_health.name = "HealthComponent"
	_enemy_health.max_health = 100
	_enemy_health.current_health = 100
	_enemy_health.invulnerability_duration = 0.0
	_enemy.add_child(_enemy_health)
	_enemy.health_component = _enemy_health

	add_child_autofree(_enemy)
	await wait_frames(2)


# ── Player Detection by Enemy ───────────────────────────────────────

func test_enemy_finds_player_by_group() -> void:
	# Create a player and add to group
	var player := Node3D.new()
	player.name = "TestPlayer"
	player.add_to_group("player")
	add_child_autofree(player)

	_enemy._find_player()
	assert_not_null(_enemy._player, "Enemy should find player in 'player' group")
	assert_eq(_enemy._player, player, "Enemy should reference the correct player")


func test_enemy_no_player_when_group_empty() -> void:
	# No player in scene = enemy._player should be null
	_enemy._find_player()
	# If there truly is no player in 'player' group, _player stays null
	# But before_each doesn't add any player, so this should pass
	assert_null(_enemy._player, "Enemy should not find player when group is empty")


# ── Enemy → Player Damage (via health component) ────────────────────

func test_enemy_attack_damages_health_component() -> void:
	# Simulate player health (separate from enemy)
	var player_health := HealthComponent.new()
	player_health.name = "PlayerHealth"
	player_health.max_health = 100
	player_health.current_health = 100
	player_health.invulnerability_duration = 0.0
	add_child_autofree(player_health)

	# Enemy attack_damage directly applied to player's health component
	var initial := player_health.current_health
	player_health.take_damage(_enemy.attack_damage)
	assert_eq(player_health.current_health, initial - _enemy.attack_damage,
		"Health should decrease by attack_damage amount")


func test_enemy_damage_value_is_configurable() -> void:
	_enemy.attack_damage = 42
	var player_health := HealthComponent.new()
	player_health.name = "PlayerHealth"
	player_health.max_health = 100
	player_health.current_health = 100
	player_health.invulnerability_duration = 0.0
	add_child_autofree(player_health)

	var initial := player_health.current_health
	player_health.take_damage(_enemy.attack_damage)
	assert_eq(player_health.current_health, initial - 42,
		"Custom attack_damage should be applied correctly")


# ── Player Damages Enemy ────────────────────────────────────────────

func test_player_can_damage_enemy() -> void:
	var initial := _enemy_health.current_health
	_enemy.take_damage(25)
	assert_eq(_enemy_health.current_health, initial - 25,
		"Enemy health should decrease when damaged")


# ── Enemy Death ─────────────────────────────────────────────────────

func test_enemy_dies_on_fatal_damage() -> void:
	_enemy.take_damage(100)
	assert_eq(_enemy.current_state, BaseEnemy.EnemyState.DEAD,
		"Enemy should be in DEAD state after fatal damage")
	assert_false(_enemy.is_alive(), "Enemy should not be alive after death")


func test_dead_enemy_ignores_damage() -> void:
	_enemy.take_damage(100)
	var health_after_death := _enemy_health.current_health
	_enemy.take_damage(50)
	assert_eq(_enemy_health.current_health, health_after_death,
		"Dead enemy should ignore additional damage")


# ── Enemy Initial State ─────────────────────────────────────────────

func test_enemy_starts_alive() -> void:
	assert_true(_enemy.is_alive(), "Enemy should start alive")


func test_enemy_has_valid_health_component() -> void:
	assert_not_null(_enemy.health_component, "Enemy should have a health component")
	assert_true(_enemy.health_component is HealthComponent,
		"Enemy health component should be HealthComponent")
	assert_eq(_enemy.get_max_health(), 100, "Max health should match health component")
	assert_eq(_enemy.get_current_health(), 100, "Current health should match health component")


# ── Enemy Signals ───────────────────────────────────────────────────

func test_enemy_emits_damaged_signal() -> void:
	watch_signals(_enemy)
	_enemy.take_damage(10)
	assert_signal_emitted(_enemy, "damaged")


func test_enemy_emits_died_signal() -> void:
	watch_signals(_enemy)
	_enemy.take_damage(100)
	assert_signal_emitted(_enemy, "died")
