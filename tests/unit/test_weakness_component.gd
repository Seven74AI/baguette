extends "res://addons/gut/test.gd"
## Tests for the WeaknessComponent — damage type weaknesses and resistances.

const WeaknessComponent = preload("res://scripts/components/weakness_component.gd")
const DamageTypes = preload("res://scripts/components/damage_types.gd")

var _weakness: WeaknessComponent


func before_each() -> void:
	_weakness = WeaknessComponent.new()
	add_child_autofree(_weakness)


func test_no_weakness_returns_full_damage() -> void:
	# With no weaknesses set, all damage is normal
	var multiplier := _weakness.get_damage_multiplier(DamageTypes.SLASH)
	assert_eq(multiplier, 1.0, "No weaknesses → multiplier should be 1.0")


func test_set_weakness_applies_multiplier() -> void:
	_weakness.set_weakness(DamageTypes.SLASH, 2.0)
	var multiplier := _weakness.get_damage_multiplier(DamageTypes.SLASH)
	assert_eq(multiplier, 2.0, "SLASH weakness should double damage")


func test_set_resistance_reduces_damage() -> void:
	_weakness.set_resistance(DamageTypes.FIRE, 0.5)
	var multiplier := _weakness.get_damage_multiplier(DamageTypes.FIRE)
	assert_eq(multiplier, 0.5, "FIRE resistance should halve damage")


func test_unrelated_type_not_affected() -> void:
	_weakness.set_weakness(DamageTypes.SLASH, 2.0)
	var multiplier := _weakness.get_damage_multiplier(DamageTypes.BLUNT)
	assert_eq(multiplier, 1.0, "BLUNT should be unaffected by SLASH weakness")


func test_multiple_weaknesses() -> void:
	_weakness.set_weakness(DamageTypes.SLASH, 1.5)
	_weakness.set_resistance(DamageTypes.FIRE, 0.5)

	assert_eq(_weakness.get_damage_multiplier(DamageTypes.SLASH), 1.5)
	assert_eq(_weakness.get_damage_multiplier(DamageTypes.FIRE), 0.5)
	assert_eq(_weakness.get_damage_multiplier(DamageTypes.OVEN), 1.0)


func test_calculate_damage_applies_multiplier() -> void:
	_weakness.set_weakness(DamageTypes.SLASH, 2.0)
	var result := _weakness.calculate_damage(25, DamageTypes.SLASH)
	assert_eq(result, 50, "25 SLASH damage with 2x weakness = 50")


func test_calculate_damage_rounds_down() -> void:
	_weakness.set_weakness(DamageTypes.FIRE, 1.5)
	var result := _weakness.calculate_damage(7, DamageTypes.FIRE)
	assert_eq(result, 10, "7 * 1.5 = 10.5, rounds down to 10")


func test_none_type_always_neutral() -> void:
	_weakness.set_weakness(DamageTypes.NONE, 2.0)  # Should have no effect
	var multiplier := _weakness.get_damage_multiplier(DamageTypes.NONE)
	assert_eq(multiplier, 1.0, "NONE type should always be 1.0")


func test_clamp_minimum_damage() -> void:
	# Even with max resistance, minimum 1 damage if base > 0
	_weakness.set_resistance(DamageTypes.BLUNT, 0.1)
	var result := _weakness.calculate_damage(10, DamageTypes.BLUNT)
	assert_eq(result, 1, "Minimum damage should be 1 when base > 0")


func test_zero_base_damage_stays_zero() -> void:
	var result := _weakness.calculate_damage(0, DamageTypes.SLASH)
	assert_eq(result, 0, "0 damage should stay 0 regardless of weakness")
