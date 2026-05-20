extends "res://addons/gut/test.gd"
## PHASE 5.2c: Reputation meta-progression tests.
## Covers earning, spending, save/load via ConfigFile, cost scaling,
## and upgrade multiplier application.

const ReputationSystem = preload("res://scripts/systems/reputation_system.gd")

var _rep: RefCounted


func before_each() -> void:
	_rep = ReputationSystem.new()
	GameState._reset_for_testing()


# ── Earning ────────────────────────────────────────────────────────────

func test_earn_reputation_from_kills() -> void:
	_rep.award_kill()
	_rep.award_kill()
	_rep.award_kill()
	# 1 rep per kill
	assert_eq(_rep.get_run_reputation(), 3, "3 kills = 3 reputation")


func test_earn_reputation_from_rooms() -> void:
	_rep.award_room_clear()
	_rep.award_room_clear()
	# 5 rep per room
	assert_eq(_rep.get_run_reputation(), 10, "2 rooms = 10 reputation")


func test_earn_reputation_from_boss() -> void:
	_rep.award_boss_kill()
	# 50 rep per boss
	assert_eq(_rep.get_run_reputation(), 50, "1 boss = 50 reputation")


func test_earn_reputation_from_run_completion() -> void:
	_rep.award_run_completion(true)
	assert_eq(_rep.get_run_reputation(), 100, "Victory completion = 100 reputation bonus")

	# New instance for defeat test
	var rep2 = ReputationSystem.new()
	rep2.award_run_completion(false)
	assert_eq(rep2.get_run_reputation(), 25, "Defeat completion = 25 reputation consolation")


func test_combined_reputation_earning() -> void:
	_rep.award_kill()
	_rep.award_kill()
	_rep.award_room_clear()
	_rep.award_boss_kill()
	_rep.award_run_completion(true)
	# 2 kills + 1 room + 1 boss + victory = 2 + 5 + 50 + 100 = 157
	assert_eq(_rep.get_run_reputation(), 157, "Combined earnings should sum correctly")


func test_total_reputation_accumulates_across_runs() -> void:
	# Simulate run 1: earn some rep, finalize it
	_rep.award_kill()
	_rep.award_kill()
	_rep.award_room_clear()
	assert_eq(_rep.get_run_reputation(), 7)
	_rep.finalize_run()
	assert_eq(_rep.get_total_reputation(), 7)
	assert_eq(_rep.get_run_reputation(), 0, "Run rep should reset after finalize")

	# Simulate run 2: earn more rep
	_rep.award_boss_kill()
	assert_eq(_rep.get_run_reputation(), 50)
	_rep.finalize_run()
	assert_eq(_rep.get_total_reputation(), 57)


func test_run_reputation_resets_on_new_run() -> void:
	_rep.award_kill()
	_rep.award_kill()
	_rep.award_room_clear()
	assert_eq(_rep.get_run_reputation(), 7)
	_rep.reset_run_reputation()
	assert_eq(_rep.get_run_reputation(), 0, "Run rep should be 0 after reset")
	# Total should not be affected by run reset
	assert_eq(_rep.get_total_reputation(), 0, "Total should not change on run reset")


# ── Spending ───────────────────────────────────────────────────────────

func test_can_spend_reputation() -> void:
	_rep.add_total_reputation(500)
	assert_true(_rep.can_spend(100), "Should be able to spend 100 with 500 total")
	assert_false(_rep.can_spend(600), "Should not be able to spend 600 with 500 total")


func test_spend_reduces_total() -> void:
	_rep.add_total_reputation(500)
	var result: bool = _rep.spend(300)
	assert_true(result, "Spend should succeed")
	assert_eq(_rep.get_total_reputation(), 200, "500 - 300 = 200 remaining")


func test_spend_fails_when_insufficient() -> void:
	_rep.add_total_reputation(50)
	var result: bool = _rep.spend(100)
	assert_false(result, "Spend should fail when insufficient")
	assert_eq(_rep.get_total_reputation(), 50, "Total should not change on failed spend")


# ── Upgrade Costs ──────────────────────────────────────────────────────

func test_upgrade_cost_scaling() -> void:
	# Level 1 = 50, L2 = 100, L3 = 200, L4 = 400, L5 = 800
	assert_eq(_rep.get_upgrade_cost("sante", 0), 50, "Level 1 = 50")
	assert_eq(_rep.get_upgrade_cost("sante", 1), 100, "Level 2 = 100")
	assert_eq(_rep.get_upgrade_cost("sante", 2), 200, "Level 3 = 200")
	assert_eq(_rep.get_upgrade_cost("sante", 3), 400, "Level 4 = 400")
	assert_eq(_rep.get_upgrade_cost("sante", 4), 800, "Level 5 = 800")


func test_upgrade_cost_returns_max_at_level_5() -> void:
	assert_eq(_rep.get_upgrade_cost("sante", 5), -1, "Level 5 is max, cost should be -1 (maxed)")
	assert_eq(_rep.get_upgrade_cost("sante", 6), -1, "Beyond max, cost should be -1")


func test_all_branches_have_same_cost_scaling() -> void:
	var branches := ["sante", "munitions", "degats", "chance"]
	for branch in branches:
		assert_eq(_rep.get_upgrade_cost(branch, 0), 50, branch + " level 1 should be 50")
		assert_eq(_rep.get_upgrade_cost(branch, 4), 800, branch + " level 5 should be 800")


# ── Upgrade Purchase ───────────────────────────────────────────────────

func test_purchase_upgrade_success() -> void:
	_rep.add_total_reputation(500)
	var result: bool = _rep.purchase_upgrade("sante")
	assert_true(result, "Purchase should succeed with 500 rep")
	assert_eq(_rep.get_upgrade_level("sante"), 1, "Should be level 1")
	assert_eq(_rep.get_total_reputation(), 450, "500 - 50 = 450 remaining")


func test_purchase_upgrade_fails_at_max_level() -> void:
	_rep.add_total_reputation(5000)
	# Level up to max (5)
	for _i in range(5):
		_rep.purchase_upgrade("munitions")
	assert_eq(_rep.get_upgrade_level("munitions"), 5)
	var result: bool = _rep.purchase_upgrade("munitions")
	assert_false(result, "Should not be able to purchase beyond level 5")
	assert_eq(_rep.get_upgrade_level("munitions"), 5, "Level should stay at 5")


func test_purchase_upgrade_fails_insufficient_funds() -> void:
	_rep.add_total_reputation(30)
	var result: bool = _rep.purchase_upgrade("degats")
	assert_false(result, "Should fail with only 30 rep")
	assert_eq(_rep.get_upgrade_level("degats"), 0, "Level should stay at 0")


func test_purchase_cost_increases_per_level() -> void:
	_rep.add_total_reputation(5000)
	_rep.purchase_upgrade("chance")
	assert_eq(_rep.get_total_reputation(), 4950, "Level 1 cost 50")
	_rep.purchase_upgrade("chance")
	assert_eq(_rep.get_total_reputation(), 4850, "Level 2 cost 100")
	_rep.purchase_upgrade("chance")
	assert_eq(_rep.get_total_reputation(), 4650, "Level 3 cost 200")
	_rep.purchase_upgrade("chance")
	assert_eq(_rep.get_total_reputation(), 4250, "Level 4 cost 400")
	_rep.purchase_upgrade("chance")
	assert_eq(_rep.get_total_reputation(), 3450, "Level 5 cost 800")
	assert_eq(_rep.get_upgrade_level("chance"), 5)


# ── Upgrade Multipliers ────────────────────────────────────────────────

func test_upgrade_multipliers_at_level_zero() -> void:
	var mults: Dictionary = _rep.get_upgrade_multipliers()
	assert_eq(mults["max_hp_bonus"], 0, "Level 0 Sante = +0 HP")
	assert_eq(mults["max_ammo_bonus"], 0, "Level 0 Munitions = +0 ammo")
	assert_eq(mults["damage_multiplier"], 1.0, "Level 0 Degats = 1.0x damage")
	assert_eq(mults["rare_drop_chance"], 0.0, "Level 0 Chance = 0% rare drops")


func test_upgrade_multipliers_at_level_three() -> void:
	_rep.add_total_reputation(5000)
	for _i in range(3):
		_rep.purchase_upgrade("sante")
		_rep.purchase_upgrade("munitions")
		_rep.purchase_upgrade("degats")
		_rep.purchase_upgrade("chance")

	var mults: Dictionary = _rep.get_upgrade_multipliers()
	# Santé: +10 per level → +30 HP
	assert_eq(mults["max_hp_bonus"], 30)
	# Munitions: +5 per level → +15 ammo
	assert_eq(mults["max_ammo_bonus"], 15)
	# Dégâts: +5% per level → 1.15x
	assert_true(abs(mults["damage_multiplier"] - 1.15) < 0.001, "Damage mult should be ~1.15")
	# Chance: +3% per level → 9% rare drops
	assert_true(abs(mults["rare_drop_chance"] - 0.09) < 0.001, "Rare drop chance should be ~0.09")


func test_upgrade_multipliers_at_max_level() -> void:
	_rep.add_total_reputation(50000)
	for _i in range(5):
		_rep.purchase_upgrade("sante")
		_rep.purchase_upgrade("munitions")
		_rep.purchase_upgrade("degats")
		_rep.purchase_upgrade("chance")

	var mults: Dictionary = _rep.get_upgrade_multipliers()
	assert_eq(mults["max_hp_bonus"], 50, "Level 5 Sante = +50 HP")
	assert_eq(mults["max_ammo_bonus"], 25, "Level 5 Munitions = +25 ammo")
	assert_true(abs(mults["damage_multiplier"] - 1.25) < 0.001, "Level 5 Degats = 1.25x")
	assert_true(abs(mults["rare_drop_chance"] - 0.15) < 0.001, "Level 5 Chance = 15%")


# ── ConfigFile Save/Load ───────────────────────────────────────────────

func test_save_and_load_preserves_total_reputation() -> void:
	_rep.add_total_reputation(1234)
	var path: String = "user://test_reputation_save.cfg"
	_rep.save_to_config(path)

	var rep2 = ReputationSystem.new()
	rep2.load_from_config(path)
	assert_eq(rep2.get_total_reputation(), 1234, "Total rep should be preserved across save/load")


func test_save_and_load_preserves_upgrade_levels() -> void:
	_rep.add_total_reputation(5000)
	_rep.purchase_upgrade("sante")
	_rep.purchase_upgrade("sante")       # level 2
	_rep.purchase_upgrade("munitions")   # level 1
	_rep.purchase_upgrade("degats")
	_rep.purchase_upgrade("degats")
	_rep.purchase_upgrade("degats")      # level 3

	var path: String = "user://test_reputation_upgrade_save.cfg"
	_rep.save_to_config(path)

	var rep2 = ReputationSystem.new()
	rep2.load_from_config(path)
	assert_eq(rep2.get_upgrade_level("sante"), 2)
	assert_eq(rep2.get_upgrade_level("munitions"), 1)
	assert_eq(rep2.get_upgrade_level("degats"), 3)
	assert_eq(rep2.get_upgrade_level("chance"), 0)


func test_load_from_nonexistent_file_defaults_to_zero() -> void:
	var rep2 = ReputationSystem.new()
	rep2.load_from_config("user://nonexistent_file_xyz.cfg")
	assert_eq(rep2.get_total_reputation(), 0, "Should default to 0 when file doesn't exist")
	assert_eq(rep2.get_upgrade_level("sante"), 0)
	assert_eq(rep2.get_upgrade_level("munitions"), 0)
	assert_eq(rep2.get_upgrade_level("degats"), 0)
	assert_eq(rep2.get_upgrade_level("chance"), 0)


func test_save_and_load_preserves_run_reputation_is_zero() -> void:
	# Run reputation should NOT be saved (only total)
	_rep.award_kill()
	_rep.award_room_clear()
	_rep.finalize_run()  # total=6, run=0

	var path: String = "user://test_reputation_run_save.cfg"
	_rep.save_to_config(path)

	var rep2 = ReputationSystem.new()
	rep2.load_from_config(path)
	assert_eq(rep2.get_total_reputation(), 6)
	assert_eq(rep2.get_run_reputation(), 0, "Run reputation should always be 0 on fresh load")


# ── New instance defaults ──────────────────────────────────────────────

func test_new_instance_has_zero_values() -> void:
	assert_eq(_rep.get_total_reputation(), 0)
	assert_eq(_rep.get_run_reputation(), 0)
	assert_eq(_rep.get_upgrade_level("sante"), 0)
	assert_eq(_rep.get_upgrade_level("munitions"), 0)
	assert_eq(_rep.get_upgrade_level("degats"), 0)
	assert_eq(_rep.get_upgrade_level("chance"), 0)
