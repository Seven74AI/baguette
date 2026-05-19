extends "res://addons/gut/test.gd"
## Tests for the WeaponUpgrade component — levels, XP, mod slots, stats.

const WeaponUpgrade = preload("res://scripts/components/weapon_upgrade.gd")

var _upgrade: WeaponUpgrade


func before_each() -> void:
	_upgrade = WeaponUpgrade.new()
	add_child_autofree(_upgrade)


func test_starts_at_level_1() -> void:
	assert_eq(_upgrade.get_level(), 1, "Weapon should start at level 1")
	assert_eq(_upgrade.get_xp(), 0, "XP should start at 0")


func test_xp_to_next_level_positive() -> void:
	var needed := _upgrade.get_xp_to_next_level()
	assert_gt(needed, 0, "XP required for next level should be positive")


func test_add_xp_increases_total() -> void:
	_upgrade.add_xp(50)
	assert_eq(_upgrade.get_xp(), 50, "XP should increase when added")


func test_level_up_on_enough_xp() -> void:
	watch_signals(_upgrade)
	var needed := _upgrade.get_xp_to_next_level()
	_upgrade.add_xp(needed)
	assert_signal_emitted(_upgrade, "leveled_up")
	assert_eq(_upgrade.get_level(), 2, "Should advance to level 2")


func test_xp_resets_on_level_up() -> void:
	var needed := _upgrade.get_xp_to_next_level()
	_upgrade.add_xp(needed)
	assert_eq(_upgrade.get_xp(), 0, "XP should reset after level up")


func test_excess_xp_carries_over() -> void:
	var needed := _upgrade.get_xp_to_next_level()
	_upgrade.add_xp(needed + 30)
	assert_eq(_upgrade.get_xp(), 30, "Excess XP should carry over")


func test_max_level_caps_at_5() -> void:
	# Give enough XP for many levels
	for _i in range(10):
		var needed := _upgrade.get_xp_to_next_level()
		if needed <= 0:
			break
		_upgrade.add_xp(needed)
	assert_eq(_upgrade.get_level(), 5, "Weapon should cap at level 5")


func test_mod_slots_available() -> void:
	assert_eq(_upgrade.get_mod_slot_count(), 0, "Level 1 should have 0 mod slots")


func test_mod_slots_unlock_at_levels() -> void:
	# Level 1 → 2: 1 slot
	var needed := _upgrade.get_xp_to_next_level()
	_upgrade.add_xp(needed)
	assert_eq(_upgrade.get_mod_slot_count(), 1, "Level 2 should unlock 1 mod slot")

	# Level 2 → 3: 2 slots
	needed = _upgrade.get_xp_to_next_level()
	_upgrade.add_xp(needed)
	assert_eq(_upgrade.get_mod_slot_count(), 2, "Level 3 should have 2 mod slots")


func test_install_mod() -> void:
	# Level up to get a slot
	var needed := _upgrade.get_xp_to_next_level()
	_upgrade.add_xp(needed)

	var installed := _upgrade.install_mod(WeaponUpgrade.ModType.DAMAGE_BONUS)
	assert_true(installed, "Should be able to install a mod")
	assert_eq(_upgrade.get_installed_mods().size(), 1, "Should have 1 installed mod")


func test_cannot_install_mod_without_slot() -> void:
	var installed := _upgrade.install_mod(WeaponUpgrade.ModType.DAMAGE_BONUS)
	assert_false(installed, "Should not install mod without available slot")


func test_cannot_install_duplicate_mod() -> void:
	# Get a slot
	_upgrade.add_xp(_upgrade.get_xp_to_next_level())
	_upgrade.install_mod(WeaponUpgrade.ModType.DAMAGE_BONUS)

	var installed := _upgrade.install_mod(WeaponUpgrade.ModType.DAMAGE_BONUS)
	assert_false(installed, "Should not install duplicate mod")


func test_mod_affects_stats() -> void:
	# Get 2 slots
	_upgrade.add_xp(_upgrade.get_xp_to_next_level())  # L1→L2
	_upgrade.add_xp(_upgrade.get_xp_to_next_level())  # L2→L3

	_upgrade.install_mod(WeaponUpgrade.ModType.DAMAGE_BONUS)
	_upgrade.install_mod(WeaponUpgrade.ModType.FIRE_RATE)

	var multipliers := _upgrade.get_stat_multipliers()
	assert_eq(multipliers["damage"], 1.15, "Damage mod should give +15%")
	assert_eq(multipliers["fire_rate"], 1.10, "Fire rate mod should give +10%")


func test_elemental_mod_changes_damage_type() -> void:
	# Get a slot
	_upgrade.add_xp(_upgrade.get_xp_to_next_level())
	_upgrade.install_mod(WeaponUpgrade.ModType.FIRE_ELEMENT)

	var dt := _upgrade.get_effective_damage_type(0)  # 0 = NONE base
	assert_eq(dt, 3, "Fire element mod should set damage type to FIRE (3)")
