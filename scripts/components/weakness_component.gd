extends Node
## Weakness/Resistance component — calculates effective damage based on damage type.
## Attach to any entity that should have type-based weaknesses or resistances.
##
## Touriste Zombie: weak to SLASH (baguettes), resist BLUNT
## Hipster Sans Gluten: weak to FIRE, resist OVEN
## Critiques Gastronomiques: weak to OVEN (four sacré!), resist FIRE

const DamageTypes = preload("res://scripts/components/damage_types.gd")

# Multiplier per damage type. > 1.0 = weak, < 1.0 = resistant, 1.0 = neutral.
var _weaknesses: Dictionary = {}


func set_weakness(damage_type: int, multiplier: float) -> void:
	assert(multiplier >= 1.0, "Weakness multiplier must be >= 1.0")
	_weaknesses[damage_type] = multiplier


func set_resistance(damage_type: int, multiplier: float) -> void:
	assert(multiplier <= 1.0 and multiplier >= 0.0, "Resistance multiplier must be [0.0, 1.0]")
	_weaknesses[damage_type] = multiplier


func get_damage_multiplier(damage_type: int) -> float:
	if damage_type == DamageTypes.NONE:
		return 1.0
	return _weaknesses.get(damage_type, 1.0)


func calculate_damage(base_damage: int, damage_type: int) -> int:
	if base_damage <= 0:
		return 0
	var multiplier := get_damage_multiplier(damage_type)
	var result := int(float(base_damage) * multiplier)
	return maxi(1, result)  # Minimum 1 damage if base > 0


## Pre-built enemy profiles — callers must preload WeaknessComponent and check types.
## Example: var profile = WeaknessComponent.tourist_zombie_weaknesses()
static func tourist_zombie_weaknesses():
	var w := new()
	w.set_weakness(DamageTypes.SLASH, 1.5)   # Baguettes slice zombies
	w.set_resistance(DamageTypes.BLUNT, 0.75)  # Tough against blunt
	return w


static func hipster_weaknesses():
	var w := new()
	w.set_weakness(DamageTypes.FIRE, 2.0)     # Sans gluten, très inflammable
	w.set_resistance(DamageTypes.OVEN, 0.5)    # Habitué aux fours artisanaux
	return w


static func critique_weaknesses():
	var w := new()
	w.set_weakness(DamageTypes.OVEN, 2.0)      # Le four sacré les détruit
	w.set_resistance(DamageTypes.FIRE, 0.5)     # Blindés contre les flammes normales
	w.set_resistance(DamageTypes.SLASH, 0.75)   # Peau épaisse
	return w


## Pain au Chocolat Launcher matchup: Baguette Vivante is weak to FIRE + SLASH.
## Flaming pastry shrapnel tears through animated bread.
static func baguette_vivante_weaknesses():
	var w := new()
	w.set_weakness(DamageTypes.FIRE, 1.5)   # Pain au chocolat brûlant
	w.set_weakness(DamageTypes.SLASH, 1.3)  # Éclats de pâtisserie tranchants
	return w


## Pain au Chocolat Launcher matchup: Gordon Bleu is weak to FIRE + SLASH.
## Even a Michelin-starred chef can't withstand explosive patisserie.
static func gordon_bleu_weaknesses():
	var w := new()
	w.set_weakness(DamageTypes.FIRE, 1.5)   # Fourrage au chocolat fondu
	w.set_weakness(DamageTypes.SLASH, 1.3)  # Croûte de pâtisserie acérée
	w.set_weakness(DamageTypes.OVEN, 2.0)    # Keep existing OVEN weakness
	return w
