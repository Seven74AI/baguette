extends Node
## Zone Manager autoload — defines 4 zones with metadata for the multi-zone run system.
## Zones: Rue de la Boulangerie → Le Marais → Les Halles → Usine (Finale).
## Handles zone progression, difficulty scaling, and enemy pool per zone.

signal zone_changed(zone_index: int, zone_data: Dictionary)
signal zone_advanced(from_index: int, to_index: int)
signal finale_reached

## Ordered list of zone definitions. Each zone is a Dictionary with keys:
##   name, tileset, enemy_pool, boss, floor_count, difficulty_multiplier, enemy_count_bonus
var _zones: Array = []

## Current zone index (0-based).
var _current_zone_index: int = 0


func _ready() -> void:
	_build_zones()


## Build the zone definitions array. Called once on _ready and on reset.
func _build_zones() -> void:
	_zones = [
		{
			"name": "Rue de la Boulangerie",
			"tileset": "res://assets/environments/tileset_rue.tres",
			"enemy_pool": ["Touriste", "Pigeon", "Vendeur"],
			"boss": "Food Truck Titan",
			"floor_count": 4,
			"difficulty_multiplier": 1.0,
			"enemy_count_bonus": 0,
		},
		{
			"name": "Le Marais",
			"tileset": "res://assets/environments/tileset_marais.tres",
			"enemy_pool": ["Hipster", "Crêpier", "Livreur", "Barista"],
			"boss": "Grand Critique",
			"floor_count": 4,
			"difficulty_multiplier": 1.3,
			"enemy_count_bonus": 2,
		},
		{
			"name": "Les Halles",
			"tileset": "res://assets/environments/tileset_halles.tres",
			"enemy_pool": ["Critique", "Brigade", "Chef", "Mouches"],
			"boss": "Grand Critique",
			"floor_count": 4,
			"difficulty_multiplier": 1.7,
			"enemy_count_bonus": 4,
		},
		{
			"name": "Usine",
			"tileset": "res://assets/environments/tileset_usine.tres",
			"enemy_pool": [],
			"boss": "La M.A.L.",
			"floor_count": 1,
			"difficulty_multiplier": 2.2,
			"enemy_count_bonus": 6,
		},
	]


# ── Zone data access ────────────────────────────────────────────

## Returns the full array of zone definitions.
func get_zones() -> Array:
	return _zones


## Returns the zone definition at the given index, or empty dict if out of bounds.
func get_zone(index: int) -> Dictionary:
	if index < 0 or index >= _zones.size():
		return {}
	return _zones[index]


## Returns the total number of zones.
func get_total_zones() -> int:
	return _zones.size()


## Returns the current zone index.
func get_zone_index() -> int:
	return _current_zone_index


## Returns the current zone definition.
func get_current_zone() -> Dictionary:
	if _current_zone_index < 0 or _current_zone_index >= _zones.size():
		return {}
	return _zones[_current_zone_index]


## Returns the current zone's enemy pool.
func get_enemy_pool() -> Array:
	var zone := get_current_zone()
	if zone.is_empty():
		return []
	return zone.get("enemy_pool", [])


# ── Zone progression ────────────────────────────────────────────

## Advance to the next zone. Returns the new zone data, or empty dict if already at the end.
func advance_zone() -> Dictionary:
	var from_index := _current_zone_index
	_current_zone_index += 1

	if _current_zone_index >= _zones.size():
		_current_zone_index = _zones.size()  # Past end
		zone_advanced.emit(from_index, _current_zone_index)
		return {}

	var zone_data: Dictionary = _zones[_current_zone_index]
	zone_changed.emit(_current_zone_index, zone_data)
	zone_advanced.emit(from_index, _current_zone_index)

	if is_finale_zone():
		finale_reached.emit()

	return zone_data


## Returns true if the current zone is the finale (last) zone.
func is_finale_zone() -> bool:
	return _current_zone_index == _zones.size() - 1


# ── Difficulty scaling ───────────────────────────────────────────

## Returns the current zone's difficulty multiplier (enemy HP scaling).
func get_difficulty_multiplier() -> float:
	var zone := get_current_zone()
	if zone.is_empty():
		return 1.0
	return zone.get("difficulty_multiplier", 1.0)


## Returns the current zone's enemy count bonus.
func get_enemy_count_bonus() -> int:
	var zone := get_current_zone()
	if zone.is_empty():
		return 0
	return zone.get("enemy_count_bonus", 0)


# ── Test helpers ─────────────────────────────────────────────────

## Reset zone manager state for testing.
func reset_for_testing() -> void:
	_current_zone_index = 0
	_build_zones()


## Reset to zone 1 (used when starting a new run).
func reset_to_zone_1() -> void:
	_current_zone_index = 0
