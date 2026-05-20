extends RefCounted
## Damage type constants for the BAGUETTE combat system.
## Used by weapons, enemies, and the weakness/resistance system.
##
## Use `const DamageTypes = preload("res://scripts/components/damage_types.gd")`
## in scripts that need damage type references.

# Neutral / no type — default for basic attacks
const NONE: int = 0

# Physical damage
const SLASH: int = 1     # Tranchant — baguettes, couteaux
const BLUNT: int = 2     # Contondant — gourdins, rouleaux à pâtisserie

# Elemental damage
const FIRE: int = 3      # Feu — dégâts de brûlure
const OVEN: int = 4      # Four — chaleur extrême, ultime
const INK: int = 5       # Encre — DoT debuff (Mauvaise critique)

# Helper: human-readable names for UI/debug
const _NAME_MAP: Dictionary = {
	NONE: "None",
	SLASH: "Tranchant",
	BLUNT: "Contondant",
	FIRE: "Feu",
	OVEN: "Four",
	INK: "Encre",
}


static func get_name(damage_type: int) -> String:
	return _NAME_MAP.get(damage_type, "Unknown")
