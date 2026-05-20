extends "res://addons/gut/test.gd"
## Phase 5.2a: GameState zone extension tests — current_zone, zone_progress, carry-forward state.

func before_each() -> void:
	GameState._reset_for_testing()
	ZoneManager.reset_for_testing()


# ═══════════════════════════════════════════════════════════════
# current_zone field
# ═══════════════════════════════════════════════════════════════

func test_current_zone_defaults_to_zero() -> void:
	assert_eq(GameState.current_zone, 0, "current_zone should default to 0")


# ═══════════════════════════════════════════════════════════════
# zone_progress tracking
# ═══════════════════════════════════════════════════════════════

func test_zone_progress_defaults_to_empty() -> void:
	assert_eq(GameState.zone_progress.size(), 0, "zone_progress should be empty dict by default")


# ═══════════════════════════════════════════════════════════════
# start_run resets zone fields
# ═══════════════════════════════════════════════════════════════

func test_start_run_resets_zone_fields() -> void:
	GameState.current_zone = 2
	GameState.zone_progress = {"zone_1": {"floors": 4}}
	GameState.start_run()
	assert_eq(GameState.current_zone, 0, "start_run should reset current_zone to 0")
	assert_eq(GameState.zone_progress.size(), 0, "start_run should reset zone_progress to empty")


# ═══════════════════════════════════════════════════════════════
# Transition state: carry-forward values are preserved
# ═══════════════════════════════════════════════════════════════

func test_carry_forward_preserves_health() -> void:
	GameState.start_run()
	GameState.player_health = 42
	GameState.advance_zone_state()
	assert_eq(GameState.player_health, 42, "Player health should be preserved across zone transition")


func test_carry_forward_preserves_ammo() -> void:
	GameState.start_run()
	GameState.add_ammo(15)
	GameState.advance_zone_state()
	assert_eq(GameState.get_ammo(), 15, "Ammo should be preserved across zone transition")


func test_carry_forward_preserves_upgrade_tokens() -> void:
	GameState.start_run()
	GameState.add_upgrade_token(3)
	GameState.advance_zone_state()
	assert_eq(GameState.get_upgrade_tokens(), 3, "Upgrade tokens should be preserved across zone transition")


func test_carry_forward_preserves_rooms_cleared() -> void:
	GameState.start_run()
	GameState.increment_rooms_cleared()
	GameState.increment_rooms_cleared()
	GameState.increment_rooms_cleared()
	GameState.advance_zone_state()
	assert_eq(GameState.rooms_cleared, 3, "rooms_cleared should be preserved across zone transition")


func test_carry_forward_preserves_enemies_killed() -> void:
	GameState.start_run()
	GameState.record_kill()
	GameState.record_kill()
	GameState.advance_zone_state()
	assert_eq(GameState.enemies_killed, 2, "enemies_killed should be preserved across zone transition")


func test_carry_forward_preserves_run_time() -> void:
	GameState.start_run()
	await wait_seconds(0.2)
	var t := GameState.run_time
	assert_gt(t, 0.0, "run_time should accumulate before transition")
	GameState.advance_zone_state()
	await wait_seconds(0.1)
	assert_gt(GameState.run_time, t, "run_time should continue after zone transition (was %.3f, now %.3f)" % [t, GameState.run_time])


func test_carry_forward_preserves_weapons_used() -> void:
	GameState.start_run()
	GameState.record_weapon_used("Baguette Gun")
	GameState.record_weapon_used("Croissant Boomerang")
	GameState.advance_zone_state()
	assert_eq(GameState.weapons_used.size(), 2, "weapons_used should be preserved across zone transition")
	assert_has(GameState.weapons_used, "Baguette Gun", "Baguette Gun should be in weapons_used after transition")
	assert_has(GameState.weapons_used, "Croissant Boomerang", "Croissant Boomerang should be in weapons_used after transition")


# ═══════════════════════════════════════════════════════════════
# Zone progression via advance_zone_state
# ═══════════════════════════════════════════════════════════════

func test_advance_zone_state_increments_current_zone() -> void:
	GameState.start_run()
	GameState.advance_zone_state()
	assert_eq(GameState.current_zone, 1, "current_zone should be 1 after first advance")

	GameState.advance_zone_state()
	assert_eq(GameState.current_zone, 2, "current_zone should be 2 after second advance")

	GameState.advance_zone_state()
	assert_eq(GameState.current_zone, 3, "current_zone should be 3 after third advance")


func test_advance_zone_state_syncs_with_zone_manager() -> void:
	GameState.start_run()
	GameState.advance_zone_state()
	assert_eq(ZoneManager.get_zone_index(), GameState.current_zone,
		"ZoneManager zone index should match GameState current_zone after advance")


# ═══════════════════════════════════════════════════════════════
# Win condition: reach finale
# ═══════════════════════════════════════════════════════════════

func test_is_run_won_returns_false_before_finale() -> void:
	GameState.start_run()
	assert_false(GameState.is_run_won(), "is_run_won should return false at zone 1")
	GameState.advance_zone_state()
	assert_false(GameState.is_run_won(), "is_run_won should return false at zone 2")
	GameState.advance_zone_state()
	assert_false(GameState.is_run_won(), "is_run_won should return false at zone 3")


func test_is_run_won_returns_true_after_finale() -> void:
	GameState.start_run()
	GameState.advance_zone_state()  # Zone 2
	GameState.advance_zone_state()  # Zone 3
	GameState.advance_zone_state()  # Finale
	assert_true(GameState.is_run_won(), "is_run_won should return true when in finale zone")


# ═══════════════════════════════════════════════════════════════
# _reset_for_testing includes new fields
# ═══════════════════════════════════════════════════════════════

func test_reset_for_testing_includes_zone_fields() -> void:
	GameState.current_zone = 3
	GameState.zone_progress = {"zone_1": {"floors": 4}}
	GameState._reset_for_testing()
	assert_eq(GameState.current_zone, 0, "_reset_for_testing should reset current_zone to 0")
	assert_eq(GameState.zone_progress.size(), 0, "_reset_for_testing should reset zone_progress to empty")
