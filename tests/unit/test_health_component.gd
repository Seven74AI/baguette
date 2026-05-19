extends GutTest
## Tests for the HealthComponent — verifies health, damage, healing, and invulnerability.

const HealthComponent = preload("res://scripts/components/health_component.gd")

var _health: HealthComponent


func before_each() -> void:
	_health = HealthComponent.new()
	_health.max_health = 100
	_health.current_health = 100
	_health.invulnerability_duration = 0.0  # No invuln for tests
	add_child_autofree(_health)


func test_health_starts_at_max() -> void:
	assert_eq(_health.current_health, 100, "Health should start at max_health")
	assert_true(_health.is_alive(), "Entity should be alive at full health")


func test_take_damage_reduces_health() -> void:
	_health.take_damage(25)
	assert_eq(_health.current_health, 75, "Health should decrease by damage amount")


func test_take_damage_emits_signal() -> void:
	watch_signals(_health)
	_health.take_damage(10)
	assert_signal_emitted(_health, "damage_taken")


func test_health_does_not_go_below_zero() -> void:
	_health.take_damage(150)
	assert_eq(_health.current_health, 0, "Health should not go below 0")


func test_health_depleted_signal() -> void:
	watch_signals(_health)
	_health.take_damage(100)
	assert_signal_emitted(_health, "health_depleted")


func test_is_alive_after_damage() -> void:
	_health.take_damage(50)
	assert_true(_health.is_alive(), "Entity should be alive with partial health")


func test_is_not_alive_after_fatal_damage() -> void:
	_health.take_damage(100)
	assert_false(_health.is_alive(), "Entity should not be alive at 0 health")


func test_heal_restores_health() -> void:
	_health.take_damage(50)
	_health.heal(25)
	assert_eq(_health.current_health, 75, "Healing should restore health")


func test_heal_does_not_exceed_max() -> void:
	_health.take_damage(10)
	_health.heal(50)
	assert_eq(_health.current_health, 100, "Healing should not exceed max_health")


func test_heal_does_nothing_when_dead() -> void:
	_health.take_damage(100)
	_health.heal(50)
	assert_eq(_health.current_health, 0, "Healing should not work on dead entities")


func test_get_health_ratio() -> void:
	assert_eq(_health.get_health_ratio(), 1.0, "Ratio should be 1.0 at full health")
	_health.take_damage(25)
	assert_eq(_health.get_health_ratio(), 0.75, "Ratio should reflect current health")


func test_no_damage_when_dead() -> void:
	_health.take_damage(100)
	var health_after_death := _health.current_health
	_health.take_damage(50)
	assert_eq(_health.current_health, health_after_death, "Dead entities should not take more damage")


func test_invulnerability_prevents_damage() -> void:
	_health.invulnerability_duration = 1.0
	_health.take_damage(10)  # First hit triggers invulnerability
	var health_after_first := _health.current_health
	_health.take_damage(50)  # Should be blocked
	assert_eq(_health.current_health, health_after_first, "Invulnerable entities should not take damage")
