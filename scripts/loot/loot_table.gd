class_name LootTable
extends Resource
## Weighted drop table for enemy loot. Each entry maps item_name → weight (float).
## The static item registry defines what each item does (type, value, duration, etc.).

enum LootType { HEALTH, AMMO, SPEED_BUFF, WEAPON_UPGRADE }

## Dictionary: item_name (String) → weight (float). Sum of weights is the denominator.
@export var drop_table: Dictionary = {}

## Static registry of all known loot items and their properties.
## Each entry: { type=LootType, value=int/float, duration=float (for buffs), description=String }
static var _item_registry: Dictionary = {
	"health": {
		"type": LootType.HEALTH,
		"value": 25,
		"description": "Pain au Chocolat — Restores 25 HP"
	},
	"ammo": {
		"type": LootType.AMMO,
		"value": 10,
		"description": "Baguette Pack — +10 ammo"
	},
	"speed_buff": {
		"type": LootType.SPEED_BUFF,
		"value": 1.2,         # multiplier
		"duration": 10.0,     # seconds
		"description": "Café Espresso — 20% speed for 10s"
	},
	"weapon_upgrade": {
		"type": LootType.WEAPON_UPGRADE,
		"value": 1,           # upgrade token count
		"description": "Croissant d'Or — Weapon upgrade token"
	},
}


## Roll the drop table and return an item_name, or null if nothing drops.
func roll() -> String:
	if drop_table.is_empty():
		_push_error_once("LootTable.roll: drop_table is empty")
		return ""

	var total_weight: float = 0.0
	for w in drop_table.values():
		total_weight += float(w)

	if total_weight <= 0.0:
		return ""

	var roll_value := randf() * total_weight
	var cumulative: float = 0.0
	for item_name in drop_table:
		cumulative += float(drop_table[item_name])
		if roll_value <= cumulative:
			return item_name

	# Fallback: return last item (should not reach here due to roll_value < total_weight)
	var keys := drop_table.keys()
	if keys.size() > 0:
		return keys[keys.size() - 1]
	return ""


## Get the definition dict for a known item, or empty dict.
static func get_item_definition(item_name: String) -> Dictionary:
	return _item_registry.get(item_name, {})


## Return all known item names.
static func get_item_names() -> PackedStringArray:
	var names: Array[String] = []
	for key in _item_registry:
		names.append(key)
	return PackedStringArray(names)


var _error_once: Dictionary = {}

func _push_error_once(msg: String) -> void:
	if not _error_once.has(msg):
		_error_once[msg] = true
		push_error(msg)
