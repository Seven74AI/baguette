extends "res://addons/gut/test.gd"
## TDD tests for Phase 5.3b: Pistolet à Encre — DoT weapon.
## Semi-auto hitscan, applies "Mauvaise critique" debuff.
## 15 direct + 10 DoT over 5s, stacks 3x. 8 ammo, 2s reload. INK damage type.

const DamageTypes = preload("res://scripts/components/damage_types.gd")

# ─── Scene & Model Tests ──────────────────────────────────────────────

func test_pistolet_encre_scene_exists() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pistolet_encre.tscn")
	assert_not_null(scene, "Pistolet à Encre .tscn should be loadable as a PackedScene")


func test_pistolet_encre_scene_instantiates() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pistolet_encre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "Pistolet à Encre should instantiate without errors")


func test_pistolet_encre_has_weapon_model() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pistolet_encre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	assert_not_null(model, "Pistolet à Encre scene should have a 'WeaponModel' MeshInstance3D child")


func test_pistolet_encre_model_has_mesh() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pistolet_encre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model:
		assert_not_null(model.mesh, "WeaponModel should have a Mesh assigned")


# ─── Weapon Stats Tests ────────────────────────────────────────────────

func test_pistolet_encre_has_correct_damage() -> void:
	var weapon = _make_pistolet()
	assert_eq(weapon.damage, 15, "Direct damage should be 15")


func test_pistolet_encre_dot_damage_is_10() -> void:
	var weapon = _make_pistolet()
	assert_eq(weapon.dot_total_damage, 10, "Total DoT damage should be 10 over 5 seconds")


func test_pistolet_encre_dot_duration_is_5() -> void:
	var weapon = _make_pistolet()
	assert_eq(weapon.dot_duration, 5.0, "DoT duration should be 5 seconds")


func test_pistolet_encre_max_ammo_is_8() -> void:
	var weapon = _make_pistolet()
	assert_eq(weapon.max_ammo, 8, "Max ammo should be 8 rounds")


func test_pistolet_encre_reload_time_is_2() -> void:
	var weapon = _make_pistolet()
	assert_eq(weapon.reload_time, 2.0, "Reload time should be 2 seconds")


func test_pistolet_encre_max_stacks_is_3() -> void:
	var weapon = _make_pistolet()
	assert_eq(weapon.max_debuff_stacks, 3, "Max debuff stacks should be 3")


func test_pistolet_encre_dot_per_second() -> void:
	var weapon = _make_pistolet()
	# 10 damage over 5 seconds = 2 damage per second per stack
	assert_eq(weapon.dot_damage_per_second, 2.0, "DoT should be 2 damage per second per stack")


# ─── Ammo Tests ────────────────────────────────────────────────────────

func test_pistolet_starts_with_full_ammo() -> void:
	var weapon = _make_pistolet()
	assert_eq(weapon.get_ammo_count(), 8, "Should start with 8 ammo")


func test_pistolet_firing_reduces_ammo() -> void:
	var weapon = _make_pistolet()
	weapon.fire()
	assert_eq(weapon.get_ammo_count(), 7, "Ammo should decrease after firing")


func test_pistolet_cannot_fire_when_empty() -> void:
	var weapon = _make_pistolet()
	for i in range(8):
		weapon.fire()
	assert_eq(weapon.get_ammo_count(), 0, "Ammo should be depleted")
	weapon.fire()
	assert_eq(weapon.get_ammo_count(), 0, "Should not go below 0 ammo")


func test_pistolet_reload_restores_ammo() -> void:
	var weapon = _make_pistolet()
	for i in range(8):
		weapon.fire()
	assert_eq(weapon.get_ammo_count(), 0, "Ammo depleted")
	weapon.reload()
	assert_eq(weapon.get_ammo_count(), 8, "Reload should restore ammo to 8")


func test_pistolet_reload_does_nothing_when_full() -> void:
	var weapon = _make_pistolet()
	weapon.reload()
	assert_eq(weapon.get_ammo_count(), 8, "Reload with full ammo should not change count")


# ─── Debuff Application Tests ─────────────────────────────────────────

func test_pistolet_applies_debuff_name() -> void:
	var weapon = _make_pistolet()
	assert_eq(weapon.debuff_name, "Mauvaise critique", "Debuff name should be 'Mauvaise critique'")


func test_pistolet_apply_debuff_returns_dot_data() -> void:
	var weapon = _make_pistolet()
	var dot_data: Dictionary = weapon.get_debuff_data()
	assert_eq(dot_data.get("name", ""), "Mauvaise critique", "Debuff data should include name")
	assert_eq(dot_data.get("damage_per_second", 0.0), 2.0, "Debuff DPS should be 2")
	assert_eq(dot_data.get("duration", 0.0), 5.0, "Debuff duration should be 5s")
	assert_eq(dot_data.get("max_stacks", 0), 3, "Debuff max stacks should be 3")


# ─── Stacking Tests ────────────────────────────────────────────────────

func test_pistolet_debuff_stacks_up_to_3() -> void:
	var weapon = _make_pistolet()
	# Max stacks is 3 — we just verify the property
	assert_eq(weapon.max_debuff_stacks, 3, "Max debuff stacks should be 3")


func test_pistolet_full_stacks_dps() -> void:
	var weapon = _make_pistolet()
	# 3 stacks x 2 damage/sec = 6 damage/sec total
	var full_dps: float = weapon.dot_damage_per_second * weapon.max_debuff_stacks
	assert_eq(full_dps, 6.0, "3 stacks should deal 6 damage/sec total")


# ─── Damage Type Tests ──────────────────────────────────────────────────

func test_pistolet_damage_type_is_ink() -> void:
	var weapon = _make_pistolet()
	var types: Array = weapon.damage_types
	assert_eq(types.size(), 1, "Should have exactly 1 damage type")
	assert_true(types.has(DamageTypes.INK), "Damage type should be INK (5)")


# ─── Hitscan Tests ─────────────────────────────────────────────────────

func test_pistolet_has_raycast() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pistolet_encre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var raycast: RayCast3D = instance.get_node_or_null("RayCast3D")
	assert_not_null(raycast, "Pistolet à Encre should have a 'RayCast3D' for hitscan")


func test_pistolet_has_fire_timer() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pistolet_encre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var timer: Timer = instance.get_node_or_null("FireTimer")
	assert_not_null(timer, "Pistolet à Encre should have a 'FireTimer'")


func test_pistolet_has_reload_timer() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pistolet_encre.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var timer: Timer = instance.get_node_or_null("ReloadTimer")
	assert_not_null(timer, "Pistolet à Encre should have a 'ReloadTimer'")


# ─── Signals Tests ──────────────────────────────────────────────────────

func test_pistolet_emits_fired_signal() -> void:
	var weapon = _make_pistolet()
	watch_signals(weapon)
	weapon.fire()
	assert_signal_emitted(weapon, "fired")


func test_pistolet_emits_ammo_depleted_when_empty() -> void:
	var weapon = _make_pistolet()
	for i in range(8):
		weapon.fire()
	watch_signals(weapon)
	weapon.fire()
	assert_signal_emitted(weapon, "ammo_depleted")


func test_pistolet_emits_reloaded_signal() -> void:
	var weapon = _make_pistolet()
	for i in range(8):
		weapon.fire()
	watch_signals(weapon)
	weapon.reload()
	assert_signal_emitted(weapon, "reloaded")


# ─── GameState Registry Tests ───────────────────────────────────────────

func test_weapon_registry_has_pistolet_encre() -> void:
	GameState._reset_for_testing()
	GameState._register_all_weapons()
	assert_true(GameState.weapon_registry.has("pistolet_encre"),
		"weapon_registry should contain 'pistolet_encre'")


func test_weapon_registry_pistolet_encre_damage() -> void:
	GameState._reset_for_testing()
	GameState._register_all_weapons()
	var data: Dictionary = GameState.weapon_registry.get("pistolet_encre", {})
	assert_eq(data.get("damage", 0), 15, "Registry damage should be 15")


func test_weapon_registry_pistolet_encre_type_ink() -> void:
	GameState._reset_for_testing()
	GameState._register_all_weapons()
	var data: Dictionary = GameState.weapon_registry.get("pistolet_encre", {})
	var types: Array = data.get("damage_types", [])
	assert_true(types.has(DamageTypes.INK), "Registry should have INK damage type")


# ─── Helper Functions ───────────────────────────────────────────────────

func _make_pistolet():
	var PistoletEncreClass = load("res://scripts/weapons/pistolet_encre.gd")
	var weapon = PistoletEncreClass.new()
	add_child_autofree(weapon)
	return weapon
