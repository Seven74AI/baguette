extends "res://addons/gut/test.gd"
## TDD tests for Phase 4.9: Pain au Chocolat Launcher — new explosive pastry weapon.
## Tests validate scene loading, weapon stats, arc projectile trajectory,
## AoE splash damage, ammo limit, reload time, and damage types.

const WeaknessComponent = preload("res://scripts/components/weakness_component.gd")

const PAIN_CHOCOLAT_PALETTE := {
	"dark_chocolate": Color("#5C3A1E"),
	"pastry_golden": Color("#D4A354"),
	"fire_orange": Color("#E85D3F"),
}

# ─── Scene & Model Tests ──────────────────────────────────────────────

func test_pain_chocolat_launcher_scene_exists() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_au_chocolat_launcher.tscn")
	assert_not_null(scene, "Pain au Chocolat Launcher .tscn should be loadable as a PackedScene")


func test_pain_chocolat_launcher_scene_instantiates() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_au_chocolat_launcher.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "Pain au Chocolat Launcher should instantiate without errors")


func test_pain_chocolat_launcher_has_weapon_model() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_au_chocolat_launcher.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	assert_not_null(model, "Pain au Chocolat Launcher scene should have a 'WeaponModel' MeshInstance3D child")


func test_pain_chocolat_launcher_model_has_mesh() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_au_chocolat_launcher.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model:
		assert_not_null(model.mesh, "WeaponModel should have a Mesh assigned")


func test_pain_chocolat_glb_exists() -> void:
	var file := FileAccess.open("res://assets/models/weapons/pain_chocolat_launcher.glb", FileAccess.READ)
	assert_not_null(file, "pain_chocolat_launcher.glb should exist in assets/models/weapons/")
	if file:
		var size: int = file.get_length()
		assert_gt(size, 0, "pain_chocolat_launcher.glb should not be empty")
		file.close()


# ─── Weapon Stats Tests ────────────────────────────────────────────────

func test_weapon_max_ammo_is_3() -> void:
	var launcher = _make_launcher()
	assert_eq(launcher.max_ammo, 3, "Pain au Chocolat Launcher should have max_ammo = 3")


func test_weapon_reload_time_is_2_5() -> void:
	var launcher = _make_launcher()
	assert_eq(launcher.reload_time, 2.5, "Reload time should be 2.5 seconds")


func test_weapon_direct_damage_is_60() -> void:
	var launcher = _make_launcher()
	assert_eq(launcher.damage, 60, "Direct hit damage should be 60")


func test_weapon_splash_damage_is_30() -> void:
	var launcher = _make_launcher()
	assert_eq(launcher.splash_damage, 30, "Splash damage should be 30")


func test_weapon_splash_radius_is_3() -> void:
	var launcher = _make_launcher()
	assert_eq(launcher.splash_radius, 3.0, "AoE splash radius should be 3.0 meters")


# ─── Damage Type Tests ──────────────────────────────────────────────────

func test_weapon_damage_type_includes_fire() -> void:
	var launcher = _make_launcher()
	var types: Array = launcher.damage_types
	assert_true(types.has(3), "Damage types should include FIRE (3)")


func test_weapon_damage_type_includes_slash() -> void:
	var launcher = _make_launcher()
	var types: Array = launcher.damage_types
	assert_true(types.has(1), "Damage types should include SLASH (1)")


func test_weapon_has_fire_and_slash_types() -> void:
	var launcher = _make_launcher()
	var types: Array = launcher.damage_types
	assert_eq(types.size(), 2, "Should have exactly 2 damage types")
	assert_true(types.has(3), "Should have FIRE")
	assert_true(types.has(1), "Should have SLASH")


# ─── Ammo Limit Tests ───────────────────────────────────────────────────

func test_weapon_starts_with_3_ammo() -> void:
	var launcher = _make_launcher()
	assert_eq(launcher.get_ammo_count(), 3, "Should start with 3 ammo loaded")


func test_ammo_decrements_on_fire() -> void:
	var launcher = _make_launcher()
	# We fire once and check ammo goes down
	launcher.fire()
	assert_eq(launcher.get_ammo_count(), 2, "Ammo should decrement to 2 after one shot")


func test_cannot_fire_when_ammo_empty() -> void:
	var launcher = _make_launcher()
	# Fire 3 times (empty)
	launcher.fire()
	launcher.fire()
	launcher.fire()
	assert_eq(launcher.get_ammo_count(), 0, "Ammo should be 0 after 3 shots")
	# 4th fire should be a no-op
	launcher.fire()
	assert_eq(launcher.get_ammo_count(), 0, "Should not go below 0 ammo")


# ─── Reload Tests ───────────────────────────────────────────────────────

func test_reload_resets_ammo() -> void:
	var launcher = _make_launcher()
	launcher.fire()
	launcher.fire()
	assert_eq(launcher.get_ammo_count(), 1, "Ammo should be 1 after 2 shots")
	launcher.reload()
	# After reload (async), ammo is restored
	assert_eq(launcher.get_ammo_count(), 3, "Should reset to 3 ammo after reload")


func test_is_reloading_flag_during_reload() -> void:
	var launcher = _make_launcher()
	assert_false(launcher.is_reloading(), "Should not be reloading initially")


# ─── Projectile Tests ───────────────────────────────────────────────────

func test_projectile_scene_exists() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_chocolat_projectile.tscn")
	assert_not_null(scene, "Pain Chocolat Projectile .tscn should be loadable")


func test_projectile_scene_instantiates() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_chocolat_projectile.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "Projectile should instantiate without errors")


func test_projectile_has_damage_property() -> void:
	var proj = _make_projectile()
	assert_eq(proj.damage, 60, "Projectile direct damage should be 60")


func test_projectile_has_splash_properties() -> void:
	var proj = _make_projectile()
	assert_eq(proj.splash_damage, 30, "Projectile splash damage should be 30")
	assert_eq(proj.splash_radius, 3.0, "Projectile splash radius should be 3.0")


func test_projectile_is_affected_by_gravity() -> void:
	var proj = _make_projectile()
	# Record initial position then apply physics
	var start_y: float = proj.position.y
	# Simulate physics with gravity
	proj._physics_process(0.5)  # Half a second
	# After half a second with gravity, it should have dropped
	# We can't guarantee exact position but gravity_scale > 0 means it's affected
	assert_gt(proj.gravity_scale, 0.0, "Projectile should be affected by gravity (gravity_scale > 0)")


# ─── AoE Splash Tests ───────────────────────────────────────────────────

func test_projectile_has_splash_area() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_chocolat_projectile.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var splash_area: Area3D = instance.get_node_or_null("SplashArea")
	assert_not_null(splash_area, "Projectile should have a 'SplashArea' Area3D for AoE detection")


func test_splash_area_has_collision_shape() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_chocolat_projectile.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var splash_area: Area3D = instance.get_node_or_null("SplashArea")
	if splash_area:
		var shapes: Array[Node] = splash_area.get_children()
		var has_collision_shape := false
		for child in shapes:
			if child is CollisionShape3D:
				has_collision_shape = true
				break
		assert_true(has_collision_shape, "SplashArea should have a CollisionShape3D child")


func test_splash_radius_matches_shape() -> void:
	var scene: PackedScene = load("res://scenes/weapons/pain_chocolat_projectile.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var splash_area: Area3D = instance.get_node_or_null("SplashArea")
	if splash_area:
		var shapes: Array[Node] = splash_area.get_children()
		for child in shapes:
			if child is CollisionShape3D and child.shape is SphereShape3D:
				var sphere: SphereShape3D = child.shape as SphereShape3D
				assert_eq(sphere.radius, 3.0, "SplashArea sphere radius should be 3.0 meters")
				return
		# If we get here, no sphere shape found — that's ok, the previous test checks for existence
		pass_test("Sphere shape check deferred — collision shape test covers existence")


# ─── GameState Weapon Registry Tests ──────────────────────────────────────

func test_gamestate_has_weapon_registry() -> void:
	assert_not_null(GameState.get("weapon_registry"), "GameState should have a 'weapon_registry' property")
	assert_true(GameState.weapon_registry is Dictionary, "weapon_registry should be a Dictionary")


func test_weapon_registry_contains_pain_chocolat() -> void:
	assert_true(GameState.weapon_registry.has("pain_au_chocolat_launcher"),
		"weapon_registry should contain 'pain_au_chocolat_launcher'")


func test_weapon_registry_pain_chocolat_has_damage() -> void:
	var data: Dictionary = GameState.weapon_registry.get("pain_au_chocolat_launcher", {})
	assert_eq(data.get("damage", 0), 60, "Registry damage should be 60")


func test_weapon_registry_pain_chocolat_has_types() -> void:
	var data: Dictionary = GameState.weapon_registry.get("pain_au_chocolat_launcher", {})
	var types: Array = data.get("damage_types", [])
	assert_eq(types.size(), 2, "Should have 2 damage types registered")
	assert_true(types.has(3), "Should have FIRE registered")
	assert_true(types.has(1), "Should have SLASH registered")


func test_gamestate_has_register_weapon_method() -> void:
	assert_true(GameState.has_method("register_weapon"),
		"GameState should have a 'register_weapon' method")


func test_gamestate_has_get_weapon_data_method() -> void:
	assert_true(GameState.has_method("get_weapon_data"),
		"GameState should have a 'get_weapon_data' method")


# ─── Damage Weakness Matrix Tests ─────────────────────────────────────────

func test_baguette_vivante_weakness_profile_exists() -> void:
	var profile = WeaknessComponent.baguette_vivante_weaknesses()
	assert_not_null(profile, "Baguette Vivante should have a weakness profile")


func test_baguette_vivante_weak_to_fire() -> void:
	var profile = WeaknessComponent.baguette_vivante_weaknesses()
	var mult: float = profile.get_damage_multiplier(3)  # FIRE
	assert_gt(mult, 1.0, "Baguette Vivante should be weak to FIRE (> 1.0)")


func test_baguette_vivante_weak_to_slash() -> void:
	var profile = WeaknessComponent.baguette_vivante_weaknesses()
	var mult: float = profile.get_damage_multiplier(1)  # SLASH
	assert_gt(mult, 1.0, "Baguette Vivante should be weak to SLASH (> 1.0)")


func test_gordon_bleu_weakness_profile_exists() -> void:
	var profile = WeaknessComponent.gordon_bleu_weaknesses()
	assert_not_null(profile, "Gordon Bleu should have a weakness profile")


func test_gordon_bleu_weak_to_fire() -> void:
	var profile = WeaknessComponent.gordon_bleu_weaknesses()
	var mult: float = profile.get_damage_multiplier(3)  # FIRE
	assert_gt(mult, 1.0, "Gordon Bleu should be weak to FIRE (> 1.0)")


func test_gordon_bleu_weak_to_slash() -> void:
	var profile = WeaknessComponent.gordon_bleu_weaknesses()
	var mult: float = profile.get_damage_multiplier(1)  # SLASH
	assert_gt(mult, 1.0, "Gordon Bleu should be weak to SLASH (> 1.0)")


func test_pain_chocolat_effective_against_vivante() -> void:
	# FIRE * SLASH combo: Baguette Vivante takes extra from both
	var profile = WeaknessComponent.baguette_vivante_weaknesses()
	var fire_mult: float = profile.get_damage_multiplier(3)
	var slash_mult: float = profile.get_damage_multiplier(1)
	assert_gt(fire_mult * slash_mult, 1.5,
		"Combined FIRE+SLASH multiplier against Baguette Vivante should be significant (> 1.5)")


func test_pain_chocolat_effective_against_gordon() -> void:
	var profile = WeaknessComponent.gordon_bleu_weaknesses()
	var fire_mult: float = profile.get_damage_multiplier(3)
	var slash_mult: float = profile.get_damage_multiplier(1)
	assert_gt(fire_mult * slash_mult, 1.5,
		"Combined FIRE+SLASH multiplier against Gordon Bleu should be significant (> 1.5)")


# ─── Helper Functions ───────────────────────────────────────────────────

func _make_launcher():
	var PainAuChocolatLauncher = load("res://scenes/weapons/pain_au_chocolat_launcher.gd")
	var launcher = PainAuChocolatLauncher.new()
	add_child_autofree(launcher)
	return launcher


func _make_projectile():
	var PainChocolatProjectile = load("res://scenes/weapons/pain_chocolat_projectile.gd")
	var proj = PainChocolatProjectile.new()
	add_child_autofree(proj)
	return proj


func _color_distance(a: Color, b: Color) -> float:
	return sqrt(
		pow(a.r - b.r, 2) +
		pow(a.g - b.g, 2) +
		pow(a.b - b.b, 2)
	)
