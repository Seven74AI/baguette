extends Node
## Weapon upgrade system — tracks level, XP, and mod slots.
## Attach to any weapon that should gain levels and accept mods.
##
## Levels 1-5, XP from kills. Mod slots unlock at levels 2, 3, 4, 5.
## Mods provide stat multipliers or elemental damage conversion.

signal leveled_up(new_level: int)

# Level thresholds: XP required to go from N to N+1
const XP_THRESHOLDS: Array[int] = [0, 100, 250, 500, 1000]  # index = current level

# Mod types players can install
enum ModType {
	DAMAGE_BONUS,     # +15% damage
	FIRE_RATE,        # +10% fire rate
	AMMO_CAPACITY,    # +2 ammo
	RANGE_EXTEND,     # +20% range
	FIRE_ELEMENT,     # Adds fire damage type
	OVEN_ELEMENT,     # Adds oven damage type
}

# Stat multipliers per mod
const MOD_MULTIPLIERS: Dictionary = {
	ModType.DAMAGE_BONUS: {"damage": 1.15},
	ModType.FIRE_RATE: {"fire_rate": 1.10},
	ModType.AMMO_CAPACITY: {"ammo": 2},       # absolute bonus
	ModType.RANGE_EXTEND: {"range": 1.20},
	ModType.FIRE_ELEMENT: {"damage_type": 3},   # FIRE
	ModType.OVEN_ELEMENT: {"damage_type": 4},   # OVEN
}

# Mod slots per level: index = level → slot count
const SLOTS_PER_LEVEL: Array[int] = [0, 0, 1, 2, 3, 4]

var _level: int = 1
var _xp: int = 0
var _installed_mods: Array[int] = []


func get_level() -> int:
	return _level


func get_xp() -> int:
	return _xp


func get_xp_to_next_level() -> int:
	if _level >= 5:
		return 0
	return XP_THRESHOLDS[_level]


func add_xp(amount: int) -> void:
	if _level >= 5:
		return
	
	_xp += amount
	
	while _level < 5 and _xp >= get_xp_to_next_level():
		_xp -= get_xp_to_next_level()
		_level += 1
		leveled_up.emit(_level)


func get_mod_slot_count() -> int:
	return SLOTS_PER_LEVEL[_level]


func install_mod(mod: int) -> bool:
	if _installed_mods.size() >= get_mod_slot_count():
		return false
	if _installed_mods.has(mod):
		return false
	_installed_mods.append(mod)
	return true


func get_installed_mods() -> Array:
	return _installed_mods.duplicate()


func get_stat_multipliers() -> Dictionary:
	var result: Dictionary = {
		"damage": 1.0,
		"fire_rate": 1.0,
		"ammo": 0,
		"range": 1.0,
	}
	for mod in _installed_mods:
		var mod_data: Dictionary = MOD_MULTIPLIERS.get(mod, {})
		for key in mod_data:
			if key == "damage_type":
				continue  # handled by get_effective_damage_type
			if key == "ammo":
				result[key] = result[key] + mod_data[key]
			else:
				result[key] = result[key] * mod_data[key]
	return result


func get_effective_damage_type(base_type: int) -> int:
	for mod in _installed_mods:
		var mod_data: Dictionary = MOD_MULTIPLIERS.get(mod, {})
		if mod_data.has("damage_type"):
			return mod_data["damage_type"]
	return base_type
