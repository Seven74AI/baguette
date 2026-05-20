extends RefCounted
## PHASE 5.2c: Reputation meta-progression system.
## Tracks Reputation earned during runs and persists upgrade purchases across runs.
## Upgrade branches: sante (HP), munitions (ammo), degats (damage), chance (loot quality).

const UPGRADE_COSTS: Array = [50, 100, 200, 400, 800]
const MAX_UPGRADE_LEVEL: int = 5
const UPGRADE_BRANCHES: Array = ["sante", "munitions", "degats", "chance"]

const RUN_COMPLETION_BONUS_VICTORY: int = 100
const RUN_COMPLETION_BONUS_DEFEAT: int = 25
const REP_PER_KILL: int = 1
const REP_PER_ROOM: int = 5
const REP_PER_BOSS: int = 50

var _total_reputation: int = 0
var _run_reputation: int = 0
var _upgrade_levels: Dictionary = {}


func _init() -> void:
	for branch in UPGRADE_BRANCHES:
		_upgrade_levels[branch] = 0


# ── Earning ────────────────────────────────────────────────────────────

func award_kill() -> void:
	_run_reputation += REP_PER_KILL


func award_room_clear() -> void:
	_run_reputation += REP_PER_ROOM


func award_boss_kill() -> void:
	_run_reputation += REP_PER_BOSS


func award_run_completion(won: bool) -> void:
	if won:
		_run_reputation += RUN_COMPLETION_BONUS_VICTORY
	else:
		_run_reputation += RUN_COMPLETION_BONUS_DEFEAT


# ── Getters ────────────────────────────────────────────────────────────

func get_run_reputation() -> int:
	return _run_reputation


func get_total_reputation() -> int:
	return _total_reputation


# ── Run lifecycle ──────────────────────────────────────────────────────

func reset_run_reputation() -> void:
	_run_reputation = 0


func finalize_run() -> void:
	_total_reputation += _run_reputation
	_run_reputation = 0


func add_total_reputation(amount: int) -> void:
	_total_reputation += amount


# ── Spending ───────────────────────────────────────────────────────────

func can_spend(amount: int) -> bool:
	return _total_reputation >= amount


func spend(amount: int) -> bool:
	if not can_spend(amount):
		return false
	_total_reputation -= amount
	return true


# ── Upgrades ────────────────────────────────────────────────────────────

func get_upgrade_level(branch: String) -> int:
	return _upgrade_levels.get(branch, 0)


func get_upgrade_cost(branch: String, current_level: int) -> int:
	if current_level >= MAX_UPGRADE_LEVEL:
		return -1
	return UPGRADE_COSTS[current_level]


func purchase_upgrade(branch: String) -> bool:
	if not branch in _upgrade_levels:
		return false
	var current_level: int = _upgrade_levels[branch]
	if current_level >= MAX_UPGRADE_LEVEL:
		return false
	var cost: int = UPGRADE_COSTS[current_level]
	if not spend(cost):
		return false
	_upgrade_levels[branch] = current_level + 1
	return true


# ── Multipliers ─────────────────────────────────────────────────────────

func get_upgrade_multipliers() -> Dictionary:
	var sante_level: int = _upgrade_levels.get("sante", 0)
	var munitions_level: int = _upgrade_levels.get("munitions", 0)
	var degats_level: int = _upgrade_levels.get("degats", 0)
	var chance_level: int = _upgrade_levels.get("chance", 0)

	return {
		"max_hp_bonus": sante_level * 10,
		"max_ammo_bonus": munitions_level * 5,
		"damage_multiplier": 1.0 + degats_level * 0.05,
		"rare_drop_chance": chance_level * 0.03,
	}


# ── ConfigFile Persistence ──────────────────────────────────────────────

func save_to_config(path: String) -> void:
	var config := ConfigFile.new()
	config.set_value("meta", "total_reputation", _total_reputation)
	for branch in UPGRADE_BRANCHES:
		config.set_value("upgrades", branch, _upgrade_levels.get(branch, 0))
	config.save(path)


func load_from_config(path: String) -> void:
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		# File doesn't exist or is invalid — stay at defaults
		return
	_total_reputation = config.get_value("meta", "total_reputation", 0)
	for branch in UPGRADE_BRANCHES:
		_upgrade_levels[branch] = config.get_value("upgrades", branch, 0)
