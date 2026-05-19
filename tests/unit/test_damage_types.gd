extends "res://addons/gut/test.gd"
## Tests for the DamageType enum — verifies all damage types exist and are distinct.

const DamageTypes = preload("res://scripts/components/damage_types.gd")


func test_damage_type_enum_exists() -> void:
	# DamageType should be an enum or constants
	assert_not_null(DamageTypes, "DamageTypes script should load")


func test_slashing_type_defined() -> void:
	assert_not_null(DamageTypes.SLASH, "SLASH damage type should be defined")


func test_blunt_type_defined() -> void:
	assert_not_null(DamageTypes.BLUNT, "BLUNT damage type should be defined")


func test_fire_type_defined() -> void:
	assert_not_null(DamageTypes.FIRE, "FIRE damage type should be defined")


func test_oven_type_defined() -> void:
	assert_not_null(DamageTypes.OVEN, "OVEN damage type should be defined")


func test_all_types_distinct() -> void:
	var types := [
		DamageTypes.SLASH,
		DamageTypes.BLUNT,
		DamageTypes.FIRE,
		DamageTypes.OVEN,
	]
	for i in range(types.size()):
		for j in range(i + 1, types.size()):
			assert_ne(types[i], types[j], "All damage types should be distinct")


func test_none_type_is_default() -> void:
	# None = 0 should be the neutral/no-damage-type default
	assert_eq(DamageTypes.NONE, 0, "NONE type should be 0 as default")
