extends "res://addons/gut/test.gd"
## TDD tests for Phase 5.3b: Four Sacré — ultimate weapon.
## Channelled heat beam, cooldown-based (no ammo), 100/sec damage,
## 60s cooldown, kills reduce cooldown by 2s. FIRE damage type.

const DamageTypes = preload("res://scripts/components/damage_types.gd")

# ─── Scene & Model Tests ──────────────────────────────────────────────

func test_four_sacre_scene_exists() -> void:
	var scene: PackedScene = load("res://scenes/weapons/four_sacre.tscn")
	assert_not_null(scene, "Four Sacré .tscn should be loadable as a PackedScene")


func test_four_sacre_scene_instantiates() -> void:
	var scene: PackedScene = load("res://scenes/weapons/four_sacre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "Four Sacré should instantiate without errors")


func test_four_sacre_has_weapon_model() -> void:
	var scene: PackedScene = load("res://scenes/weapons/four_sacre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	assert_not_null(model, "Four Sacré scene should have a 'WeaponModel' MeshInstance3D child")


func test_four_sacre_model_has_mesh() -> void:
	var scene: PackedScene = load("res://scenes/weapons/four_sacre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model:
		assert_not_null(model.mesh, "WeaponModel should have a Mesh assigned")


# ─── Weapon Stats Tests ────────────────────────────────────────────────

func test_four_sacre_damage_is_100_per_sec() -> void:
	var weapon = _make_four_sacre()
	assert_eq(weapon.damage_per_second, 100, "Four Sacré should deal 100 damage per second")


func test_four_sacre_beam_width_is_0_5() -> void:
	var weapon = _make_four_sacre()
	assert_eq(weapon.beam_width, 0.5, "Beam width should be 0.5 meters")


func test_four_sacre_range_is_20() -> void:
	var weapon = _make_four_sacre()
	assert_eq(weapon.max_range, 20.0, "Beam range should be 20 meters")


func test_four_sacre_cooldown_is_60() -> void:
	var weapon = _make_four_sacre()
	assert_eq(weapon.cooldown_time, 60.0, "Cooldown should be 60 seconds")


func test_four_sacre_has_no_ammo() -> void:
	var weapon = _make_four_sacre()
	assert_eq(weapon.max_ammo, 0, "Four Sacré should have no ammo (max_ammo = 0)")


# ─── Charge Mechanic Tests ──────────────────────────────────────────────

func test_four_sacre_starts_uncharged() -> void:
	var weapon = _make_four_sacre()
	assert_eq(weapon.get_charge(), 0.0, "Should start with 0 charge")


func test_four_sacre_charge_fills_over_time() -> void:
	var weapon = _make_four_sacre()
	weapon._process(30.0)  # 30 seconds of charge
	var charge := weapon.get_charge()
	assert_gt(charge, 0.0, "Charge should increase over time")
	assert_lt(charge, 1.0, "Charge should not be full after 30s (60s total)")


func test_four_sacre_charge_reaches_full_after_60s() -> void:
	var weapon = _make_four_sacre()
	weapon._process(60.0)  # Full cooldown elapsed
	assert_eq(weapon.get_charge(), 1.0, "Charge should be full after 60 seconds")


func test_four_sacre_is_ready_when_fully_charged() -> void:
	var weapon = _make_four_sacre()
	weapon._process(60.0)
	assert_true(weapon.is_ready(), "Should be ready when fully charged")


func test_four_sacre_cannot_fire_when_not_charged() -> void:
	var weapon = _make_four_sacre()
	weapon.fire()
	# We need to check if firing actually happened — for an uncharged weapon it should not
	# The weapon should emit nothing or have a way to check
	assert_false(weapon.is_firing(), "Should not be firing when uncharged")


func test_four_sacre_can_fire_when_charged() -> void:
	var weapon = _make_four_sacre()
	weapon._process(60.0)
	weapon.fire()
	assert_true(weapon.is_firing(), "Should be firing when charged and fire() is called")


func test_four_sacre_stops_firing_when_released() -> void:
	var weapon = _make_four_sacre()
	weapon._process(60.0)
	weapon.fire()
	assert_true(weapon.is_firing(), "Should start firing")
	weapon.release()
	assert_false(weapon.is_firing(), "Should stop firing after release()")


func test_four_sacre_firing_consumes_charge() -> void:
	var weapon = _make_four_sacre()
	weapon._process(60.0)
	assert_eq(weapon.get_charge(), 1.0, "Should be fully charged")
	weapon.fire()
	# After some time firing, charge should decrease
	weapon._process(10.0)  # 10 seconds of firing
	assert_lt(weapon.get_charge(), 1.0, "Firing should consume charge")


# ─── Kill Charge Reduction Tests ────────────────────────────────────────

func test_four_sacre_kill_reduces_cooldown_by_2s() -> void:
	var weapon = _make_four_sacre()
	weapon._process(60.0)
	assert_eq(weapon.get_charge(), 1.0, "Fully charged")
	# Fire to drain some charge
	weapon.fire()
	weapon._process(10.0)
	weapon.release()
	var charge_after_firing := weapon.get_charge()
	assert_lt(charge_after_firing, 1.0, "Charge should be less after firing")
	# Record a kill
	weapon.record_kill()
	var charge_after_kill := weapon.get_charge()
	assert_gt(charge_after_kill, charge_after_firing, "Kill should increase charge (reduce cooldown by 2s)")


# ─── Damage Type Tests ──────────────────────────────────────────────────

func test_four_sacre_damage_type_is_fire() -> void:
	var weapon = _make_four_sacre()
	var types: Array = weapon.damage_types
	assert_eq(types.size(), 1, "Should have exactly 1 damage type")
	assert_true(types.has(DamageTypes.FIRE), "Damage type should be FIRE (3)")


# ─── Beam Properties Tests ─────────────────────────────────────────────

func test_four_sacre_has_beam_raycast() -> void:
	var scene: PackedScene = load("res://scenes/weapons/four_sacre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var raycast: RayCast3D = instance.get_node_or_null("BeamRayCast")
	assert_not_null(raycast, "Four Sacré should have a 'BeamRayCast' RayCast3D for beam hitscan")


func test_four_sacre_has_beam_timer() -> void:
	var scene: PackedScene = load("res://scenes/weapons/four_sacre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var timer: Timer = instance.get_node_or_null("BeamTimer")
	assert_not_null(timer, "Four Sacré should have a 'BeamTimer' Timer for damage ticks")


# ─── GameState Registry Tests ───────────────────────────────────────────

func test_weapon_registry_has_four_sacre() -> void:
	GameState._reset_for_testing()
	GameState._register_all_weapons()
	assert_true(GameState.weapon_registry.has("four_sacre"),
		"weapon_registry should contain 'four_sacre'")


func test_weapon_registry_four_sacre_damage() -> void:
	GameState._reset_for_testing()
	GameState._register_all_weapons()
	var data: Dictionary = GameState.weapon_registry.get("four_sacre", {})
	assert_eq(data.get("damage", 0), 100, "Registry damage should be 100")


func test_weapon_registry_four_sacre_type_fire() -> void:
	GameState._reset_for_testing()
	GameState._register_all_weapons()
	var data: Dictionary = GameState.weapon_registry.get("four_sacre", {})
	var types: Array = data.get("damage_types", [])
	assert_true(types.has(DamageTypes.FIRE), "Registry should have FIRE damage type")


# ─── Helper Functions ───────────────────────────────────────────────────

func _make_four_sacre():
	var FourSacreClass = load("res://scripts/weapons/four_sacre.gd")
	var weapon = FourSacreClass.new()
	add_child_autofree(weapon)
	return weapon
