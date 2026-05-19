extends Node
## Global game state autoload — tracks player stats, run state, inventory, buffs, and settings.
## Persists across scene changes. Proto: lightweight in-memory only.

class BuffData:
	var buff_id: String = ""
	var multiplier: float = 1.0
	var duration: float = 0.0

	func _init(p_id: String, p_mult: float, p_dur: float) -> void:
		buff_id = p_id
		multiplier = p_mult
		duration = p_dur


signal player_died
signal run_started
signal run_ended(won: bool)
signal ammo_changed(current: int, maximum: int)
signal buffs_changed(buffs: Array)

var player_health: int = 100
var player_max_health: int = 100
var enemies_killed: int = 0
var current_weapon_name: String = "Pistolet à Baguettes"
var run_active: bool = false

## Phase 4.1: New game loop tracking fields.
var rooms_cleared: int = 0
var run_time: float = 0.0
var total_damage_dealt: int = 0

## Weapon registry — maps weapon_id (String) to weapon data (Dictionary).
var weapon_registry: Dictionary = {}

## Shared ammo pool (proto: single pool for all weapons).
var _ammo_count: int = 0
var _max_ammo: int = 30

## Active buffs — Array of BuffData.
var _active_buffs: Array = []

## Weapon upgrade tokens.
var _upgrade_tokens: int = 0


func _ready() -> void:
	_register_all_weapons()


func start_run() -> void:
	player_health = player_max_health
	enemies_killed = 0
	rooms_cleared = 0
	run_time = 0.0
	total_damage_dealt = 0
	_ammo_count = 0
	_active_buffs.clear()
	_upgrade_tokens = 0
	run_active = true
	run_started.emit()


func _process(delta: float) -> void:
	if run_active:
		run_time += delta
		_update_buffs(delta)


func damage_player(amount: int) -> void:
	player_health = max(0, player_health - amount)
	if player_health <= 0:
		run_active = false
		player_died.emit()


func heal_player(amount: int) -> void:
	if player_health >= player_max_health:
		return
	player_health = min(player_health + amount, player_max_health)


func record_kill() -> void:
	enemies_killed += 1


func increment_rooms_cleared() -> void:
	rooms_cleared += 1


func record_damage_dealt(amount: int) -> void:
	total_damage_dealt += amount


func end_run(won: bool) -> void:
	run_active = false
	run_ended.emit(won)


# ── Ammo ──────────────────────────────────────────────────────────

func get_ammo() -> int:
	return _ammo_count


func get_max_ammo() -> int:
	return _max_ammo


func add_ammo(amount: int) -> void:
	_ammo_count = min(_ammo_count + amount, _max_ammo)
	ammo_changed.emit(_ammo_count, _max_ammo)


func consume_ammo(amount: int) -> bool:
	if _ammo_count < amount:
		return false
	_ammo_count -= amount
	ammo_changed.emit(_ammo_count, _max_ammo)
	return true


# ── Buffs ─────────────────────────────────────────────────────────

func add_buff(buff_id: String, multiplier: float, duration: float) -> void:
	# Remove existing buff of same type (refresh)
	for i in range(_active_buffs.size()):
		if _active_buffs[i].buff_id == buff_id:
			_active_buffs.remove_at(i)
			break

	var bd := BuffData.new(buff_id, multiplier, duration)
	_active_buffs.append(bd)
	buffs_changed.emit(_active_buffs)


func has_buff(buff_id: String) -> bool:
	for bd in _active_buffs:
		if bd.buff_id == buff_id:
			return true
	return false


func get_active_buffs() -> Array:
	return _active_buffs


func clear_buffs() -> void:
	_active_buffs.clear()
	buffs_changed.emit(_active_buffs)


## Call every frame (or physics tick) to tick buff durations.
func _update_buffs(delta: float) -> void:
	var changed := false
	var i := _active_buffs.size() - 1
	while i >= 0:
		_active_buffs[i].duration -= delta
		if _active_buffs[i].duration <= 0.0:
			_active_buffs.remove_at(i)
			changed = true
		i -= 1
	if changed:
		buffs_changed.emit(_active_buffs)


# ── Upgrade tokens ────────────────────────────────────────────────

func add_upgrade_token(count: int) -> void:
	_upgrade_tokens += count


func get_upgrade_tokens() -> int:
	return _upgrade_tokens


# ── Weapon Registry ──────────────────────────────────────────────────

## Register a weapon in the central registry.
func register_weapon(weapon_id: String, damage: int, damage_types: Array, max_ammo: int = 1, reload_time: float = 1.0) -> void:
	weapon_registry[weapon_id] = {
		"damage": damage,
		"damage_types": damage_types,
		"max_ammo": max_ammo,
		"reload_time": reload_time,
	}


## Retrieve weapon data from the registry. Returns empty Dictionary if not found.
func get_weapon_data(weapon_id: String) -> Dictionary:
	return weapon_registry.get(weapon_id, {})


func _register_all_weapons() -> void:
	# Existing weapons
	register_weapon("baguette_gun", 25, [1], 6, 1.5)     # SLASH
	register_weapon("croissant_boomerang", 12, [2], 0, 0)  # BLUNT, no ammo

	# Pain au Chocolat Launcher — Phase 4.9
	register_weapon("pain_au_chocolat_launcher", 60, [3, 1], 3, 2.5)  # FIRE + SLASH


# ── Test helpers ──────────────────────────────────────────────────

## Reset all state for unit testing.
func _reset_for_testing() -> void:
	player_health = 100
	player_max_health = 100
	enemies_killed = 0
	rooms_cleared = 0
	run_time = 0.0
	total_damage_dealt = 0
	_ammo_count = 0
	_max_ammo = 30
	_active_buffs.clear()
	_upgrade_tokens = 0
	run_active = false
