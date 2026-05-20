extends Node
## Floor Mutator System — random modifiers applied at floor start.
## 8 mutators from BESTIARY.md §7.2. No repeats within the same zone.
## Effects communicated via signals; HUD gets display text and duration.

signal mutator_applied(mutator: Dictionary)

# ── Mutator data ──────────────────────────────────────────────────

const MUTATORS: Array[Dictionary] = [
	{
		"name": "Nuit Sans Lune",
		"icon": "🌑",
		"description": "Enemies +20% aggro, +15% speed",
		"effects": {
			"enemy_speed_mult": 1.15,
			"enemy_aggro_mult": 1.20,
		},
	},
	{
		"name": "Pâte Qui Lève",
		"icon": "🍞",
		"description": "Enemies grow +10% size every 30s",
		"effects": {
			"enemy_size_growth_percent": 10.0,
			"enemy_size_growth_interval": 30.0,
		},
	},
	{
		"name": "Inspection Sanitaire",
		"icon": "🔍",
		"description": "+50% enemies, -25% HP each",
		"effects": {
			"enemy_count_mult": 1.50,
			"enemy_hp_mult": 0.75,
		},
	},
	{
		"name": "Pénurie de Farine",
		"icon": "🌾",
		"description": "Healing -50%, ammo +50%",
		"effects": {
			"healing_mult": 0.50,
			"ammo_drop_mult": 1.50,
		},
	},
	{
		"name": "Jour de Marché",
		"icon": "🏪",
		"description": "Drops ×2, enemies +20% HP",
		"effects": {
			"drop_mult": 2.0,
			"enemy_hp_mult": 1.20,
		},
	},
	{
		"name": "Grève des Livreurs",
		"icon": "🚫",
		"description": "No Livreurs/Vendeurs, +30% other enemies",
		"effects": {
			"excluded_enemy_types": ["Livreur", "Vendeur"],
			"other_enemy_count_mult": 1.30,
		},
	},
	{
		"name": "Four Surchauffé",
		"icon": "🔥",
		"description": "Four Sacré charges 2× faster, fire damage everywhere",
		"effects": {
			"four_sacre_charge_mult": 2.0,
			"fire_damage_aura": true,
		},
	},
	{
		"name": "Vent de Farine",
		"icon": "💨",
		"description": "Visibility -30%, enemy accuracy -20%",
		"effects": {
			"visibility_mult": 0.70,
			"enemy_accuracy_mult": 0.80,
		},
	},
]

var _current_mutator: Dictionary = {}
var _used_in_zone: Array[String] = []
var _display_duration: float = 3.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# ── Public API ────────────────────────────────────────────────────

func get_all_mutators() -> Array:
	return MUTATORS


func get_mutator_names() -> Array:
	var names: Array = []
	for m in MUTATORS:
		names.append(m["name"])
	return names


func get_mutator_by_name(p_name: String) -> Dictionary:
	for m in MUTATORS:
		if m["name"] == p_name:
			return m
	return {}


func select_random(p_used_names: Array = []) -> Dictionary:
	var available: Array = []
	for m in MUTATORS:
		if not p_used_names.has(m["name"]):
			available.append(m)
	if available.is_empty():
		return {}
	return available[_rng.randi() % available.size()]


func apply_mutator(p_mutator: Dictionary) -> void:
	_current_mutator = p_mutator
	_used_in_zone.append(p_mutator.get("name", ""))
	mutator_applied.emit(p_mutator)


func get_current_mutator() -> Dictionary:
	return _current_mutator


func get_display_text(p_mutator: Dictionary) -> String:
	var name: String = p_mutator.get("name", "???")
	var desc: String = p_mutator.get("description", "")
	var icon: String = p_mutator.get("icon", "")
	return icon + " " + name + " — " + desc


func get_display_duration() -> float:
	return _display_duration


func get_mutator_icon(p_mutator: Dictionary) -> String:
	return p_mutator.get("icon", "")


func reset_zone() -> void:
	_used_in_zone.clear()
	_current_mutator = {}


# ── Test helpers ──────────────────────────────────────────────────

func _reset_used_for_testing() -> void:
	_used_in_zone.clear()
	_current_mutator = {}
