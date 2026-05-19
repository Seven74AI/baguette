extends "res://addons/gut/test.gd"
## Integration/unit tests for the loot and pickup system.
## Covers LootTable, LootManager, Pickup, inventory, buffs, and enemy integration.

const LootTableScript = preload("res://scripts/loot/loot_table.gd")
const PickupScript = preload("res://scripts/loot/pickup.gd")
const LootManagerScript = preload("res://scripts/loot/loot_manager.gd")
const BaseEnemy = preload("res://scripts/enemies/base_enemy.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

# ── LootTable tests ──────────────────────────────────────────────

func test_loot_table_has_drop_table_dictionary() -> void:
	var lt: Resource = LootTableScript.new()
	lt.drop_table = {"health": 0.5, "ammo": 0.5}
	assert_eq(lt.drop_table.size(), 2, "LootTable should hold a drop_table dictionary")


func test_loot_table_roll_returns_valid_item() -> void:
	var lt: Resource = LootTableScript.new()
	lt.drop_table = {"health_pickup": 1.0}
	var result: String = lt.roll()
	assert_eq(result, "health_pickup", "Roll with single 1.0-weight item should return that item")


func test_loot_table_roll_empty_on_empty_table() -> void:
	var lt: Resource = LootTableScript.new()
	lt.drop_table = {}
	var result: String = lt.roll()
	assert_eq(result, "", "Roll on empty table should return empty string")


func test_loot_table_weighted_distribution() -> void:
	# With 1.0 weight on "ammo" and 0.0 on "health", should always return "ammo"
	var lt: Resource = LootTableScript.new()
	lt.drop_table = {"ammo": 1.0, "health": 0.0}
	var ammo_count: int = 0
	for _i in range(50):
		if lt.roll() == "ammo":
			ammo_count += 1
	assert_eq(ammo_count, 50, "100%-weight item should always be rolled with zero-weight competitor")


func test_loot_table_registry() -> void:
	# LootTable should provide a static registry of item definitions
	var item: Dictionary = LootTableScript.get_item_definition("health")
	assert_true(not item.is_empty(), "get_item_definition should return a dict for known item")
	assert_true(item.has("type"), "Item definition should have a type field")
	assert_true(item.has("value"), "Item definition should have a value field")
	assert_eq(item.type, LootTableScript.LootType.HEALTH)


func test_loot_table_get_known_item_names() -> void:
	var names: PackedStringArray = LootTableScript.get_item_names()
	assert_true(names.has("health"), "Known items should include 'health'")
	assert_true(names.has("ammo"), "Known items should include 'ammo'")
	assert_true(names.has("speed_buff"), "Known items should include 'speed_buff'")
	assert_true(names.has("weapon_upgrade"), "Known items should include 'weapon_upgrade'")


# ── Pickup tests ─────────────────────────────────────────────────

func test_pickup_has_loot_type() -> void:
	var pk: Node = PickupScript.new()
	pk.loot_type = 0  # PickupType.HEALTH
	assert_eq(pk.loot_type, 0)


func test_pickup_has_value() -> void:
	var pk: Node = PickupScript.new()
	pk.pickup_value = 25
	assert_eq(pk.pickup_value, 25)


func test_pickup_has_duration() -> void:
	var pk: Node = PickupScript.new()
	pk.buff_duration = 10.0
	assert_eq(pk.buff_duration, 10.0)


func test_pickup_emit_collected_signal_on_pickup() -> void:
	var pk: Node = PickupScript.new()
	add_child_autofree(pk)
	watch_signals(pk)
	pk.collect()
	assert_signal_emitted(pk, "collected")


func test_pickup_collect_sets_queued_free() -> void:
	var pk: Node = PickupScript.new()
	add_child_autofree(pk)
	pk.collect()
	assert_true(pk.is_queued_for_deletion(), "Pickup should be queued_free after collect()")


# ── LootManager tests ─────────────────────────────────────────────

func test_loot_manager_register_enemy_table() -> void:
	var mgr: Node = LootManagerScript.new()
	add_child_autofree(mgr)
	var lt: Resource = LootTableScript.new()
	lt.drop_table = {"health": 1.0}
	mgr.register_enemy_table("BaguetteVivante", lt)
	var table: Resource = mgr.get_table_for("BaguetteVivante")
	assert_not_null(table, "Should return registered table")


func test_loot_manager_get_table_fallback() -> void:
	var mgr: Node = LootManagerScript.new()
	add_child_autofree(mgr)
	var table: Resource = mgr.get_table_for("NonExistentEnemy")
	assert_not_null(table, "Should return a default table for unknown enemy")
	assert_true(table.drop_table.size() > 0, "Default table should have entries")


func test_loot_manager_spawn_loot() -> void:
	var mgr: Node = LootManagerScript.new()
	add_child_autofree(mgr)
	var pos := Vector3(10, 2, 5)
	var pickup: Node = mgr.spawn_pickup("health", pos)
	assert_not_null(pickup, "spawn_pickup should return a Pickup node")
	assert_eq(pickup.loot_type, 0, "Health pickup should have HEALTH type (0)")
	assert_eq(pickup.pickup_value, 25, "Health should restore 25 HP")
	# Should be a child of the tree
	assert_true(pickup.is_inside_tree(), "Pickup should be in scene tree")


func test_loot_manager_spawn_loot_with_scatter() -> void:
	var mgr: Node = LootManagerScript.new()
	add_child_autofree(mgr)
	var center := Vector3(0, 0, 0)
	var positions: Array = []
	for _i in range(10):
		var pk: Node = mgr.spawn_pickup("ammo", center)
		positions.append(pk.global_position)
		pk.queue_free()
	# At least some positions should differ from center (scatter)
	var any_different: bool = false
	for p in positions:
		if p.distance_to(center) > 0.01:
			any_different = true
			break
	assert_true(any_different, "Spawned loot should have positional scatter")


# ── Inventory tests ───────────────────────────────────────────────

func test_inventory_default_ammo() -> void:
	GameState._reset_for_testing()
	assert_eq(GameState.get_ammo(), 0, "Default ammo should be 0")


func test_inventory_add_ammo() -> void:
	GameState._reset_for_testing()
	GameState.add_ammo(10)
	assert_eq(GameState.get_ammo(), 10)
	GameState.add_ammo(5)
	assert_eq(GameState.get_ammo(), 15)


func test_inventory_ammo_capped_at_max() -> void:
	GameState._reset_for_testing()
	GameState.add_ammo(9999)
	assert_eq(GameState.get_ammo(), GameState.get_max_ammo(), "Ammo should cap at max_ammo")


func test_inventory_add_buff() -> void:
	GameState._reset_for_testing()
	GameState.add_buff("speed", 1.2, 10.0)
	var buffs: Array = GameState.get_active_buffs()
	assert_eq(buffs.size(), 1, "Should have 1 active buff")
	assert_eq(buffs[0].buff_id, "speed")
	assert_eq(buffs[0].multiplier, 1.2)
	assert_eq(buffs[0].duration, 10.0)


func test_inventory_has_buff() -> void:
	GameState._reset_for_testing()
	GameState.add_buff("speed", 1.2, 10.0)
	assert_true(GameState.has_buff("speed"), "has_buff should return true for active buff")


func test_inventory_buff_expires() -> void:
	GameState._reset_for_testing()
	GameState.add_buff("speed", 1.2, 0.1)
	GameState._update_buffs(0.2)
	var buffs: Array = GameState.get_active_buffs()
	assert_eq(buffs.size(), 0, "Buff should expire after duration passes")


func test_inventory_clear_buffs() -> void:
	GameState._reset_for_testing()
	GameState.add_buff("speed", 1.2, 10.0)
	GameState.add_buff("damage", 1.5, 5.0)
	GameState.clear_buffs()
	assert_eq(GameState.get_active_buffs().size(), 0)


# ── Enemy drop_loot integration tests ─────────────────────────────

func test_enemy_drop_loot_on_death() -> void:
	var enemy: Node = BaseEnemy.new()
	var hc: Node = HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 100
	hc.current_health = 100
	hc.invulnerability_duration = 0.0
	enemy.add_child(hc)
	enemy.health_component = hc
	add_child_autofree(enemy)

	# Set a guaranteed drop
	var lt: Resource = LootTableScript.new()
	lt.drop_table = {"health": 1.0}
	enemy.drop_table_ref = lt

	watch_signals(enemy)
	var spawn_count: Array = [0]
	enemy.loot_spawned.connect(func(_pk): spawn_count[0] += 1)

	enemy.take_damage(100)
	assert_signal_emitted(enemy, "died")
	assert_eq(spawn_count[0], 1, "Enemy should spawn loot on death")


func test_enemy_no_loot_when_no_drop_table() -> void:
	var enemy: Node = BaseEnemy.new()
	var hc: Node = HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 100
	hc.current_health = 100
	hc.invulnerability_duration = 0.0
	enemy.add_child(hc)
	enemy.health_component = hc
	add_child_autofree(enemy)

	enemy.drop_table_ref = null
	watch_signals(enemy)
	var pickup_count: int = 0
	enemy.loot_spawned.connect(func(_pk): pickup_count += 1)

	enemy.take_damage(100)
	assert_signal_emitted(enemy, "died")
	assert_eq(pickup_count, 0, "Enemy without drop_table should spawn no loot")


# ── HUD buff display tests ────────────────────────────────────────

func test_inventory_hud_buffs_panel() -> void:
	var inv_hud: Node = _create_inventory_hud()
	add_child_autofree(inv_hud)
	assert_not_null(inv_hud.get_node_or_null("BuffsPanel"), "InventoryHUD should have a BuffsPanel")


func test_inventory_hud_ammo_label() -> void:
	var inv_hud: Node = _create_inventory_hud()
	add_child_autofree(inv_hud)
	assert_not_null(inv_hud.get_node_or_null("AmmoDisplay"), "InventoryHUD should have an AmmoDisplay")
	assert_not_null(inv_hud.get_node_or_null("AmmoDisplay/AmmoLabel"), "InventoryHUD should have an AmmoLabel")


# ── Helpers ───────────────────────────────────────────────────────

func _create_inventory_hud() -> Node:
	var InvHUD: GDScript = load("res://scripts/ui/inventory_hud.gd")
	var hud: Node = InvHUD.new()
	return hud
