extends "res://addons/gut/test.gd"
## Unit tests for ZoneManager — zone definitions, transitions, difficulty scaling.

# ═══════════════════════════════════════════════════════════════
# Zone definitions
# ═══════════════════════════════════════════════════════════════

func test_zone_manager_has_four_zones() -> void:
	var zones := ZoneManager.get_zones()
	assert_eq(zones.size(), 4, "Should have exactly 4 zones")


func test_zone_1_is_rue_de_la_boulangerie() -> void:
	var zone := ZoneManager.get_zone(0)
	assert_not_null(zone, "Zone 1 should exist")
	assert_eq(zone["name"], "Rue de la Boulangerie", "Zone 1 name should match")
	assert_eq(zone["tileset"], "res://assets/environments/tileset_rue.tres", "Zone 1 tileset should match")
	assert_eq(zone["floor_count"], 4, "Zone 1 should have 4 floors")
	assert_eq(zone["difficulty_multiplier"], 1.0, "Zone 1 difficulty multiplier should be 1.0")
	assert_eq(zone["enemy_count_bonus"], 0, "Zone 1 enemy count bonus should be 0")
	assert_has(zone["enemy_pool"], "Touriste", "Zone 1 pool should include Touriste")
	assert_has(zone["enemy_pool"], "Pigeon", "Zone 1 pool should include Pigeon")
	assert_has(zone["enemy_pool"], "Vendeur", "Zone 1 pool should include Vendeur")
	assert_eq(zone["boss"], "Food Truck Titan", "Zone 1 boss should be Food Truck Titan")


func test_zone_2_is_le_marais() -> void:
	var zone := ZoneManager.get_zone(1)
	assert_not_null(zone, "Zone 2 should exist")
	assert_eq(zone["name"], "Le Marais", "Zone 2 name should match")
	assert_eq(zone["floor_count"], 4, "Zone 2 should have 4 floors")
	assert_eq(zone["difficulty_multiplier"], 1.3, "Zone 2 difficulty multiplier should be 1.3")
	assert_eq(zone["enemy_count_bonus"], 2, "Zone 2 enemy count bonus should be +2")
	assert_has(zone["enemy_pool"], "Hipster", "Zone 2 pool should include Hipster")
	assert_has(zone["enemy_pool"], "Crêpier", "Zone 2 pool should include Crêpier")
	assert_has(zone["enemy_pool"], "Livreur", "Zone 2 pool should include Livreur")
	assert_has(zone["enemy_pool"], "Barista", "Zone 2 pool should include Barista")
	assert_eq(zone["boss"], "Grand Critique", "Zone 2 boss should be Grand Critique")


func test_zone_3_is_les_halles() -> void:
	var zone := ZoneManager.get_zone(2)
	assert_not_null(zone, "Zone 3 should exist")
	assert_eq(zone["name"], "Les Halles", "Zone 3 name should match")
	assert_eq(zone["floor_count"], 4, "Zone 3 should have 4 floors")
	assert_eq(zone["difficulty_multiplier"], 1.7, "Zone 3 difficulty multiplier should be 1.7")
	assert_eq(zone["enemy_count_bonus"], 4, "Zone 3 enemy count bonus should be +4")
	assert_has(zone["enemy_pool"], "Critique", "Zone 3 pool should include Critique")
	assert_has(zone["enemy_pool"], "Brigade", "Zone 3 pool should include Brigade")
	assert_has(zone["enemy_pool"], "Chef", "Zone 3 pool should include Chef")
	assert_has(zone["enemy_pool"], "Mouches", "Zone 3 pool should include Mouches")


func test_zone_4_is_usine_finale() -> void:
	var zone := ZoneManager.get_zone(3)
	assert_not_null(zone, "Finale zone should exist")
	assert_eq(zone["name"], "Usine", "Finale zone name should match")
	assert_eq(zone["floor_count"], 1, "Finale zone should have 1 floor")
	assert_eq(zone["difficulty_multiplier"], 2.2, "Finale difficulty multiplier should be 2.2")
	assert_eq(zone["enemy_count_bonus"], 6, "Finale enemy count bonus should be +6")
	assert_eq(zone["boss"], "La M.A.L.", "Finale boss should be La M.A.L.")


# ═══════════════════════════════════════════════════════════════
# Zone indexing
# ═══════════════════════════════════════════════════════════════

func test_get_zone_out_of_bounds_returns_empty_dict() -> void:
	var zone := ZoneManager.get_zone(-1)
	assert_eq(zone, {}, "Negative index should return empty dict")
	zone = ZoneManager.get_zone(99)
	assert_eq(zone, {}, "Out of range index should return empty dict")


func test_total_zones_returns_four() -> void:
	assert_eq(ZoneManager.get_total_zones(), 4, "Total zones should be 4")


# ═══════════════════════════════════════════════════════════════
# Zone progression
# ═══════════════════════════════════════════════════════════════

func test_zone_index_starts_at_zero() -> void:
	ZoneManager.reset_for_testing()
	assert_eq(ZoneManager.get_zone_index(), 0, "Zone index should start at 0")


func test_get_current_zone_returns_zone_1_initially() -> void:
	ZoneManager.reset_for_testing()
	var zone := ZoneManager.get_current_zone()
	assert_eq(zone["name"], "Rue de la Boulangerie", "Current zone should be Zone 1 initially")


func test_advance_zone_moves_to_next_zone() -> void:
	ZoneManager.reset_for_testing()
	var next_zone := ZoneManager.advance_zone()
	assert_eq(next_zone["name"], "Le Marais", "After advance, should be at Zone 2")
	assert_eq(ZoneManager.get_zone_index(), 1, "Zone index should be 1 after one advance")


func test_advance_zone_through_all_zones() -> void:
	ZoneManager.reset_for_testing()
	ZoneManager.advance_zone()  # → Zone 2
	ZoneManager.advance_zone()  # → Zone 3
	var finale := ZoneManager.advance_zone()  # → Finale
	assert_eq(finale["name"], "Usine", "After 3 advances, should be at Finale zone")
	assert_eq(ZoneManager.get_zone_index(), 3, "Zone index should be 3")


func test_advance_zone_past_finale_returns_empty() -> void:
	ZoneManager.reset_for_testing()
	ZoneManager.advance_zone()  # → 2
	ZoneManager.advance_zone()  # → 3
	ZoneManager.advance_zone()  # → Finale
	var past := ZoneManager.advance_zone()  # Past end
	assert_eq(past, {}, "Advancing past finale should return empty dict")


# ═══════════════════════════════════════════════════════════════
# Finale detection
# ═══════════════════════════════════════════════════════════════

func test_is_finale_zone_returns_true_for_zone_4() -> void:
	ZoneManager.reset_for_testing()
	ZoneManager.advance_zone()
	ZoneManager.advance_zone()
	ZoneManager.advance_zone()
	assert_true(ZoneManager.is_finale_zone(), "Should detect finale zone")


func test_is_finale_zone_returns_false_for_other_zones() -> void:
	ZoneManager.reset_for_testing()
	assert_false(ZoneManager.is_finale_zone(), "Zone 1 should not be finale")
	ZoneManager.advance_zone()
	assert_false(ZoneManager.is_finale_zone(), "Zone 2 should not be finale")


# ═══════════════════════════════════════════════════════════════
# Difficulty scaling
# ═══════════════════════════════════════════════════════════════

func test_difficulty_multiplier_per_zone() -> void:
	ZoneManager.reset_for_testing()
	assert_eq(ZoneManager.get_difficulty_multiplier(), 1.0, "Zone 1 HP multiplier should be 1.0")
	ZoneManager.advance_zone()
	assert_eq(ZoneManager.get_difficulty_multiplier(), 1.3, "Zone 2 HP multiplier should be 1.3")
	ZoneManager.advance_zone()
	assert_eq(ZoneManager.get_difficulty_multiplier(), 1.7, "Zone 3 HP multiplier should be 1.7")
	ZoneManager.advance_zone()
	assert_eq(ZoneManager.get_difficulty_multiplier(), 2.2, "Finale HP multiplier should be 2.2")


func test_enemy_count_bonus_per_zone() -> void:
	ZoneManager.reset_for_testing()
	assert_eq(ZoneManager.get_enemy_count_bonus(), 0, "Zone 1 enemy count bonus should be 0")
	ZoneManager.advance_zone()
	assert_eq(ZoneManager.get_enemy_count_bonus(), 2, "Zone 2 enemy count bonus should be 2")
	ZoneManager.advance_zone()
	assert_eq(ZoneManager.get_enemy_count_bonus(), 4, "Zone 3 enemy count bonus should be 4")
	ZoneManager.advance_zone()
	assert_eq(ZoneManager.get_enemy_count_bonus(), 6, "Finale enemy count bonus should be 6")


# ═══════════════════════════════════════════════════════════════
# Enemy pool for zone
# ═══════════════════════════════════════════════════════════════

func test_get_enemy_pool_returns_zone_specific_list() -> void:
	ZoneManager.reset_for_testing()
	var pool := ZoneManager.get_enemy_pool()
	assert_eq(pool.size(), 3, "Zone 1 should have 3 enemy types")
	ZoneManager.advance_zone()
	pool = ZoneManager.get_enemy_pool()
	assert_eq(pool.size(), 4, "Zone 2 should have 4 enemy types")
	ZoneManager.advance_zone()
	pool = ZoneManager.get_enemy_pool()
	assert_eq(pool.size(), 4, "Zone 3 should have 4 enemy types")


# ═══════════════════════════════════════════════════════════════
# Zone data carries keys
# ═══════════════════════════════════════════════════════════════

func test_zone_data_has_required_keys() -> void:
	var zone := ZoneManager.get_zone(0)
	assert_true(zone.has("name"), "Zone data should have 'name'")
	assert_true(zone.has("tileset"), "Zone data should have 'tileset'")
	assert_true(zone.has("enemy_pool"), "Zone data should have 'enemy_pool'")
	assert_true(zone.has("boss"), "Zone data should have 'boss'")
	assert_true(zone.has("floor_count"), "Zone data should have 'floor_count'")
	assert_true(zone.has("difficulty_multiplier"), "Zone data should have 'difficulty_multiplier'")
	assert_true(zone.has("enemy_count_bonus"), "Zone data should have 'enemy_count_bonus'")
