extends "res://addons/gut/test.gd"
## Phase 5.2a: Integration tests for multi-zone run system.
## Verifies: zone progression, carry-forward state, difficulty scaling, win/loss conditions.

func before_each() -> void:
	GameState._reset_for_testing()
	ZoneManager.reset_for_testing()


# ═══════════════════════════════════════════════════════════════
# Full multi-zone run flow
# ═══════════════════════════════════════════════════════════════

func test_full_multi_zone_progression() -> void:
	GameState.start_run()
	assert_eq(GameState.current_zone, 0, "Run should start at zone 0")
	assert_eq(ZoneManager.get_zone_index(), 0, "ZoneManager should start at zone 0")

	# Advance through all 4 zones
	GameState.advance_zone_state()  # → Zone 2
	assert_eq(GameState.current_zone, 1)
	assert_eq(ZoneManager.get_zone(1)["name"], "Le Marais")

	GameState.advance_zone_state()  # → Zone 3
	assert_eq(GameState.current_zone, 2)
	assert_eq(ZoneManager.get_zone(2)["name"], "Les Halles")

	GameState.advance_zone_state()  # → Finale
	assert_eq(GameState.current_zone, 3)
	assert_eq(ZoneManager.get_zone(3)["name"], "Usine")
	assert_true(GameState.is_run_won(), "Should register as won in finale zone")


# ═══════════════════════════════════════════════════════════════
# Carry-forward state verified through full run
# ═══════════════════════════════════════════════════════════════

func test_carry_forward_through_all_zones() -> void:
	GameState.start_run()

	# Zone 1: accumulate some state
	GameState.player_health = 75
	GameState.add_ammo(10)
	GameState.add_upgrade_token(2)
	GameState.record_kill()
	GameState.record_kill()
	GameState.record_kill()
	GameState.increment_rooms_cleared()
	GameState.increment_rooms_cleared()
	GameState.record_weapon_used("Baguette Gun")
	GameState.record_damage_dealt(100)

	# Advance to Zone 2
	GameState.advance_zone_state()
	assert_eq(GameState.player_health, 75, "Health should carry forward to zone 2")
	assert_eq(GameState.get_ammo(), 10, "Ammo should carry forward to zone 2")
	assert_eq(GameState.get_upgrade_tokens(), 2, "Tokens should carry forward to zone 2")
	assert_eq(GameState.enemies_killed, 3, "Kills should carry forward to zone 2")
	assert_eq(GameState.rooms_cleared, 2, "Rooms should carry forward to zone 2")
	assert_eq(GameState.total_damage_dealt, 100, "Damage should carry forward to zone 2")

	# Advance to Zone 3
	GameState.advance_zone_state()
	assert_eq(GameState.player_health, 75, "Health should carry forward to zone 3")

	# Advance to Finale
	GameState.advance_zone_state()
	assert_eq(GameState.player_health, 75, "Health should carry forward to finale")
	assert_eq(GameState.enemies_killed, 3, "Kills should carry forward to finale")


# ═══════════════════════════════════════════════════════════════
# Difficulty scaling through zones
# ═══════════════════════════════════════════════════════════════

func test_difficulty_scales_per_zone() -> void:
	GameState.start_run()

	# Zone 1: multiplier 1.0, bonus 0
	assert_eq(ZoneManager.get_difficulty_multiplier(), 1.0)
	assert_eq(ZoneManager.get_enemy_count_bonus(), 0)

	# Zone 2: multiplier 1.3, bonus 2
	GameState.advance_zone_state()
	assert_eq(ZoneManager.get_difficulty_multiplier(), 1.3)
	assert_eq(ZoneManager.get_enemy_count_bonus(), 2)

	# Zone 3: multiplier 1.7, bonus 4
	GameState.advance_zone_state()
	assert_eq(ZoneManager.get_difficulty_multiplier(), 1.7)
	assert_eq(ZoneManager.get_enemy_count_bonus(), 4)

	# Finale: multiplier 2.2, bonus 6
	GameState.advance_zone_state()
	assert_eq(ZoneManager.get_difficulty_multiplier(), 2.2)
	assert_eq(ZoneManager.get_enemy_count_bonus(), 6)


# ═══════════════════════════════════════════════════════════════
# Zone-specific data
# ═══════════════════════════════════════════════════════════════

func test_zone_data_changes_with_progression() -> void:
	GameState.start_run()
	assert_eq(ZoneManager.get_current_zone()["name"], "Rue de la Boulangerie")

	GameState.advance_zone_state()
	assert_eq(ZoneManager.get_current_zone()["name"], "Le Marais")
	assert_eq(ZoneManager.get_current_zone()["boss"], "Grand Critique")

	GameState.advance_zone_state()
	assert_eq(ZoneManager.get_current_zone()["name"], "Les Halles")

	GameState.advance_zone_state()
	assert_eq(ZoneManager.get_current_zone()["name"], "Usine")
	assert_eq(ZoneManager.get_current_zone()["boss"], "La M.A.L.")


# ═══════════════════════════════════════════════════════════════
# Death during any zone
# ═══════════════════════════════════════════════════════════════

func test_death_in_zone_2_ends_run() -> void:
	GameState.start_run()
	GameState.advance_zone_state()  # Now in zone 2
	assert_eq(GameState.current_zone, 1)

	GameState.player_health = 1
	GameState.damage_player(1)
	assert_false(GameState.run_active, "run_active should be false after death in zone 2")


func test_death_in_finale_does_not_win() -> void:
	GameState.start_run()
	GameState.advance_zone_state()  # Zone 2
	GameState.advance_zone_state()  # Zone 3
	GameState.advance_zone_state()  # Finale
	assert_true(GameState.is_run_won(), "Should be in finale zone")
	assert_true(GameState.run_active, "Run should still be active in finale")

	GameState.player_health = 1
	GameState.damage_player(1)
	assert_false(GameState.run_active, "Run should end after death in finale")


# ═══════════════════════════════════════════════════════════════
# Start new run resets zones
# ═══════════════════════════════════════════════════════════════

func test_new_run_resets_all_zones() -> void:
	GameState.start_run()
	GameState.advance_zone_state()
	GameState.advance_zone_state()
	assert_eq(GameState.current_zone, 2)

	GameState.end_run(false)
	GameState.start_run()
	assert_eq(GameState.current_zone, 0, "New run should start at zone 0")
	assert_eq(ZoneManager.get_zone_index(), 0, "ZoneManager should reset to 0")


# ═══════════════════════════════════════════════════════════════
# Win condition: reach and complete Finale
# ═══════════════════════════════════════════════════════════════

func test_win_condition_finale_reached() -> void:
	GameState.start_run()
	assert_false(GameState.is_run_won())

	GameState.advance_zone_state()
	GameState.advance_zone_state()
	GameState.advance_zone_state()

	assert_true(GameState.is_run_won(), "Should win when finale zone is reached")
	assert_true(GameState.run_active, "Run should still be active in finale until boss is defeated")


# ═══════════════════════════════════════════════════════════════
# Zone Manager signals
# ═══════════════════════════════════════════════════════════════

func test_zone_manager_emits_zone_advanced_signal() -> void:
	ZoneManager.reset_for_testing()
	watch_signals(ZoneManager)

	ZoneManager.advance_zone()

	assert_signal_emitted(ZoneManager, "zone_advanced")
	assert_signal_emitted_with_parameters(ZoneManager, "zone_advanced", [0, 1])


func test_zone_manager_emits_finale_reached_signal() -> void:
	ZoneManager.reset_for_testing()
	ZoneManager.advance_zone()  # → 2
	ZoneManager.advance_zone()  # → 3
	watch_signals(ZoneManager)
	ZoneManager.advance_zone()  # → Finale

	assert_signal_emitted(ZoneManager, "finale_reached")


# ═══════════════════════════════════════════════════════════════
# End to end: full run simulation
# ═══════════════════════════════════════════════════════════════

func test_e2e_full_run_simulation() -> void:
	# Simulate a complete run: zone 1 → zone 2 → zone 3 → finale → victory
	GameState.start_run()

	# Zone 1 gameplay
	GameState.record_kill()
	GameState.record_kill()
	GameState.increment_rooms_cleared()
	GameState.record_weapon_used("Baguette Gun")
	GameState.player_health = 90

	# Zone 1 complete → Zone 2
	GameState.advance_zone_state()
	assert_eq(GameState.current_zone, 1)
	assert_eq(GameState.enemies_killed, 2)
	assert_eq(GameState.player_health, 90)

	# Zone 2 gameplay
	GameState.record_kill()
	GameState.add_upgrade_token(1)
	GameState.player_health = 70

	# Zone 2 complete → Zone 3
	GameState.advance_zone_state()
	assert_eq(GameState.current_zone, 2)
	assert_eq(GameState.enemies_killed, 3)
	assert_eq(GameState.get_upgrade_tokens(), 1)

	# Zone 3 gameplay
	GameState.player_health = 50

	# Zone 3 complete → Finale
	GameState.advance_zone_state()
	assert_eq(GameState.current_zone, 3)
	assert_true(GameState.is_run_won())

	# Defeat the boss!
	GameState.end_run(true)
	assert_false(GameState.run_active, "Run should end after victory")
