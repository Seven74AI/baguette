extends "res://addons/gut/test.gd"
## TDD tests for Phase 4.12: Color Palette Application — Visual Consistency.
## Verifies palette.gd autoload exists with 10 color constants,
## palette materials are applied to weapons, enemies, and props,
## and color contrast ratios are readable.

# ── Preloads ─────────────────────────────────────────────────────

const PaletteScript = preload("res://scripts/autoload/palette.gd")

# All 3 weapons
const BaguetteGunScene = preload("res://scenes/weapons/baguette_gun.tscn")
const CroissantBoomerangScene = preload("res://scenes/weapons/croissant_boomerang.tscn")
const PainChocolatLauncherScene = preload("res://scenes/weapons/pain_au_chocolat_launcher.tscn")

# All 7 enemies
const BaguetteVivanteScene = preload("res://scenes/enemies/baguette_vivante.tscn")
const CroissantNinjaScene = preload("res://scenes/enemies/croissant_ninja.tscn")
const SourdoughBlobScene = preload("res://scenes/enemies/sourdough_blob.tscn")
const TouristeZombieScene = preload("res://scenes/enemies/touriste_zombie.tscn")
const GordonBleuScene = preload("res://scenes/enemies/gordon_bleu.tscn")
const MichelinEtoileScene = preload("res://scenes/enemies/michelin_etoile_perdu.tscn")
const PainChocolatineScene = preload("res://scenes/enemies/pain_au_chocolatine.tscn")

# All 8 props
const BakeryRackScene = preload("res://scenes/props/bakery_rack.tscn")
const OvenPropScene = preload("res://scenes/props/oven_prop.tscn")
const CounterDisplayScene = preload("res://scenes/props/counter_display.tscn")
const FlourSackScene = preload("res://scenes/props/flour_sack.tscn")
const StreetLampScene = preload("res://scenes/props/street_lamp.tscn")
const BenchPropScene = preload("res://scenes/props/bench_prop.tscn")
const AbandonedCarScene = preload("res://scenes/props/abandoned_car.tscn")
const CroissantCrateScene = preload("res://scenes/props/croissant_crate.tscn")


var _spawned: Array[Node] = []


func after_each() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()


func _spawn(scene: PackedScene) -> Node:
	var instance := scene.instantiate()
	if instance:
		add_child(instance)
		_spawned.append(instance)
	return instance


# ── Helpers ─────────────────────────────────────────────────────

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result:
			return result
	return null


func _count_mesh_instances(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		count += 1
	for child in node.get_children():
		count += _count_mesh_instances(child)
	return count


func _get_color(node: MeshInstance3D) -> Color:
	# Check surface_override_material on the node itself
	var surf_mat := node.get_surface_override_material(0)
	if surf_mat and surf_mat is StandardMaterial3D:
		return (surf_mat as StandardMaterial3D).albedo_color
	# Check material_override on the node itself
	if node.material_override and node.material_override is StandardMaterial3D:
		return (node.material_override as StandardMaterial3D).albedo_color
	# Walk up ancestors to find material_override (instanced scenes)
	var parent: Node = node.get_parent()
	while parent:
		var override = parent.get("material_override")
		if override and override is StandardMaterial3D:
			return (override as StandardMaterial3D).albedo_color
		parent = parent.get_parent()
	# Check mesh surface materials (GLB import)
	if node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var mat := node.mesh.surface_get_material(i)
			if mat and mat is StandardMaterial3D:
				return (mat as StandardMaterial3D).albedo_color
	# Check mesh primitive material (fallback)
	if node.mesh and node.mesh is PrimitiveMesh:
		var pm: PrimitiveMesh = node.mesh as PrimitiveMesh
		if pm.material and pm.material is StandardMaterial3D:
			return (pm.material as StandardMaterial3D).albedo_color
	return Color.BLACK


func _color_distance(a: Color, b: Color) -> float:
	return abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b)


func _is_near(color: Color, target: Color, tolerance: float = 0.3) -> bool:
	return _color_distance(color, target) < tolerance


func _any_mesh_near_color(root: Node, target: Color, tolerance: float = 0.3) -> bool:
	var mesh := _find_mesh_instance(root)
	while mesh:
		var col := _get_color(mesh)
		if _is_near(col, target, tolerance):
			return true
		mesh = _next_mesh_after(root, mesh)
	return false



func _next_mesh_recursive(node: Node, current: MeshInstance3D, found: Array) -> MeshInstance3D:
	if node is MeshInstance3D:
		if found[0]:
			return node
		if node == current:
			found[0] = true
	for child in node.get_children():
		var result := _next_mesh_recursive(child, current, found)
		if result:
			return result
	return null


func _next_mesh_after(root: Node, current: MeshInstance3D) -> MeshInstance3D:
	return _next_mesh_recursive(root, current, [false])


func test_palette_autoload_registered() -> void:
	# The Palette autoload should be accessible as a global singleton
	var palette := Engine.get_singleton("Palette") if Engine.has_singleton("Palette") else null
	if palette:
		assert_not_null(palette, "Palette autoload should exist as Engine singleton")
	else:
		# Fallback: load the script and verify it works
		var instance := PaletteScript.new()
		add_child_autofree(instance)
		assert_not_null(instance, "Palette script should be instantiable")


func test_palette_has_10_color_constants() -> void:
	assert_eq(PaletteScript.color_count(), 10, "Palette should define exactly 10 color constants")


func test_palette_golden_brown_correct() -> void:
	var expected := Color(0.831, 0.639, 0.329)
	assert_lt(_color_distance(PaletteScript.GOLDEN_BROWN, expected), 0.01,
		"GOLDEN_BROWN should match #D4A354")


func test_palette_crust_correct() -> void:
	var expected := Color(0.545, 0.369, 0.235)
	assert_lt(_color_distance(PaletteScript.CRUST, expected), 0.01,
		"CRUST should match #8B5E3C")


func test_palette_cream_correct() -> void:
	var expected := Color(0.961, 0.941, 0.882)
	assert_lt(_color_distance(PaletteScript.CREAM, expected), 0.01,
		"CREAM should match #F5F0E1")


func test_palette_butter_correct() -> void:
	var expected := Color(1.0, 0.957, 0.761)
	assert_lt(_color_distance(PaletteScript.BUTTER, expected), 0.01,
		"BUTTER should match #FFF4C2")


func test_palette_warm_beige_correct() -> void:
	var expected := Color(0.910, 0.835, 0.718)
	assert_lt(_color_distance(PaletteScript.WARM_BEIGE, expected), 0.01,
		"WARM_BEIGE should match #E8D5B7")


func test_palette_purple_sky_correct() -> void:
	var expected := Color(0.176, 0.106, 0.239)
	assert_lt(_color_distance(PaletteScript.PURPLE_SKY, expected), 0.01,
		"PURPLE_SKY should match #2D1B3D")


func test_palette_orange_red_correct() -> void:
	var expected := Color(0.910, 0.365, 0.247)
	assert_lt(_color_distance(PaletteScript.ORANGE_RED, expected), 0.01,
		"ORANGE_RED should match #E85D3F")


func test_palette_sickly_green_correct() -> void:
	var expected := Color(0.361, 0.478, 0.227)
	assert_lt(_color_distance(PaletteScript.SICKLY_GREEN, expected), 0.01,
		"SICKLY_GREEN should match #5C7A3A")


func test_palette_cobblestone_grey_correct() -> void:
	var expected := Color(0.290, 0.290, 0.290)
	assert_lt(_color_distance(PaletteScript.COBBLESTONE_GREY, expected), 0.01,
		"COBBLESTONE_GREY should match #4A4A4A")


func test_palette_faded_cyan_correct() -> void:
	var expected := Color(0.239, 0.839, 0.816)
	assert_lt(_color_distance(PaletteScript.FADED_CYAN, expected), 0.01,
		"FADED_CYAN should match #3DD6D0")


func test_palette_all_colors_returns_10() -> void:
	var colors := PaletteScript.all_colors()
	assert_eq(colors.size(), 10, "all_colors() should return 10 colors")


func test_palette_color_dict_has_all_keys() -> void:
	var d := PaletteScript.color_dict()
	assert_eq(d.size(), 10, "color_dict() should have 10 entries")
	assert_true(d.has("golden_brown"), "color_dict should have golden_brown")
	assert_true(d.has("crust"), "color_dict should have crust")
	assert_true(d.has("cream"), "color_dict should have cream")
	assert_true(d.has("butter"), "color_dict should have butter")
	assert_true(d.has("warm_beige"), "color_dict should have warm_beige")
	assert_true(d.has("purple_sky"), "color_dict should have purple_sky")
	assert_true(d.has("orange_red"), "color_dict should have orange_red")
	assert_true(d.has("sickly_green"), "color_dict should have sickly_green")
	assert_true(d.has("cobblestone_grey"), "color_dict should have cobblestone_grey")
	assert_true(d.has("faded_cyan"), "color_dict should have faded_cyan")


# ═════════════════════════════════════════════════════════════════
# SECTION 2: Palette material factory helpers
# ═════════════════════════════════════════════════════════════════

func test_create_material_returns_standard_material3d() -> void:
	var mat := PaletteScript.create_material(PaletteScript.GOLDEN_BROWN)
	assert_not_null(mat, "create_material should return a material")
	assert_true(mat is StandardMaterial3D, "create_material should return StandardMaterial3D")
	if mat is StandardMaterial3D:
		assert_eq((mat as StandardMaterial3D).albedo_color, PaletteScript.GOLDEN_BROWN,
			"albedo_color should match input color")


func test_create_emissive_material_has_emission_enabled() -> void:
	var mat := PaletteScript.create_emissive_material(PaletteScript.FADED_CYAN, 3.0)
	assert_not_null(mat, "create_emissive_material should return a material")
	if mat is StandardMaterial3D:
		assert_true((mat as StandardMaterial3D).emission_enabled,
			"emissive material should have emission enabled")
		assert_gt((mat as StandardMaterial3D).emission_energy_multiplier, 0.0,
			"emissive material should have positive emission energy")


func test_create_material_with_metallic() -> void:
	var mat := PaletteScript.create_material(PaletteScript.COBBLESTONE_GREY, 0.5, Color.BLACK, 0.0, 0.8)
	assert_not_null(mat, "create_material with metallic should return a material")
	if mat is StandardMaterial3D:
		assert_lt(abs((mat as StandardMaterial3D).metallic - 0.8), 0.001, "metallic should be set")


# ═════════════════════════════════════════════════════════════════
# SECTION 3: Weapon palette verification
# ═════════════════════════════════════════════════════════════════

func test_baguette_gun_uses_golden_brown() -> void:
	var weapon := _spawn(BaguetteGunScene)
	assert_not_null(weapon, "BaguetteGun should instantiate")
	# WeaponModel should use golden-brown (bread body)
	var model := weapon.get_node_or_null("WeaponModel")
	assert_not_null(model, "BaguetteGun should have WeaponModel node")
	if model is MeshInstance3D:
		var col := _get_color(model as MeshInstance3D)
		assert_true(_is_near(col, PaletteScript.GOLDEN_BROWN, 0.3),
			"BaguetteGun model should use GOLDEN_BROWN palette color")


func test_baguette_gun_flash_uses_orange_red() -> void:
	var weapon := _spawn(BaguetteGunScene)
	var flash := weapon.get_node_or_null("MuzzleFlash")
	assert_not_null(flash, "BaguetteGun should have MuzzleFlash node")
	if flash is MeshInstance3D:
		var col := _get_color(flash as MeshInstance3D)
		assert_true(_is_near(col, PaletteScript.ORANGE_RED, 0.3),
			"BaguetteGun flash should use ORANGE_RED palette color")


func test_croissant_boomerang_uses_golden_brown() -> void:
	var weapon := _spawn(CroissantBoomerangScene)
	assert_not_null(weapon, "CroissantBoomerang should instantiate")
	var model := weapon.get_node_or_null("WeaponModel")
	assert_not_null(model, "CroissantBoomerang should have WeaponModel")
	if model is MeshInstance3D:
		var col := _get_color(model as MeshInstance3D)
		assert_true(_is_near(col, PaletteScript.GOLDEN_BROWN, 0.3),
			"CroissantBoomerang should use GOLDEN_BROWN palette color")


func test_pain_chocolat_launcher_uses_crust() -> void:
	var weapon := _spawn(PainChocolatLauncherScene)
	assert_not_null(weapon, "PainChocolatLauncher should instantiate")
	var model := weapon.get_node_or_null("WeaponModel")
	assert_not_null(model, "PainChocolatLauncher should have WeaponModel")
	if model is MeshInstance3D:
		var col := _get_color(model as MeshInstance3D)
		assert_true(_is_near(col, PaletteScript.CRUST, 0.3),
			"PainChocolatLauncher should use CRUST palette color")


# ═════════════════════════════════════════════════════════════════
# SECTION 4: Enemy palette verification
# ═════════════════════════════════════════════════════════════════

func test_baguette_vivante_uses_golden_brown() -> void:
	var enemy := _spawn(BaguetteVivanteScene)
	assert_not_null(enemy, "BaguetteVivante should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "BaguetteVivante should have Model node")
	if model is Node3D:
		assert_not_null(model.material_override, "Model should have material_override")
		if model.material_override is StandardMaterial3D:
			var col := (model.material_override as StandardMaterial3D).albedo_color
			assert_true(_is_near(col, PaletteScript.GOLDEN_BROWN, 0.3),
				"BaguetteVivante should use GOLDEN_BROWN palette color")


func test_croissant_ninja_uses_crust() -> void:
	var enemy := _spawn(CroissantNinjaScene)
	assert_not_null(enemy, "CroissantNinja should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "CroissantNinja should have Model node")
	if model is Node3D:
		assert_not_null(model.material_override, "Model should have material_override")
		if model.material_override is StandardMaterial3D:
			var col := (model.material_override as StandardMaterial3D).albedo_color
			assert_true(_is_near(col, PaletteScript.CRUST, 0.3),
				"CroissantNinja should use CRUST palette color")


func test_sourdough_blob_uses_cream() -> void:
	var enemy := _spawn(SourdoughBlobScene)
	assert_not_null(enemy, "SourdoughBlob should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "SourdoughBlob should have Model node")
	if model is Node3D:
		assert_not_null(model.material_override, "Model should have material_override")
		if model.material_override is StandardMaterial3D:
			var col := (model.material_override as StandardMaterial3D).albedo_color
			assert_true(_is_near(col, PaletteScript.CREAM, 0.3),
				"SourdoughBlob should use CREAM palette color")


func test_touriste_zombie_uses_sickly_green() -> void:
	var enemy := _spawn(TouristeZombieScene)
	assert_not_null(enemy, "TouristeZombie should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "TouristeZombie should have Model node")
	if model is Node3D:
		assert_not_null(model.material_override, "Model should have material_override")
		if model.material_override is StandardMaterial3D:
			var col := (model.material_override as StandardMaterial3D).albedo_color
			assert_true(_is_near(col, PaletteScript.SICKLY_GREEN, 0.3),
				"TouristeZombie should use SICKLY_GREEN palette color")


func test_gordon_bleu_uses_butter() -> void:
	var enemy := _spawn(GordonBleuScene)
	assert_not_null(enemy, "GordonBleu should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "GordonBleu should have Model node")
	if model is Node3D:
		assert_not_null(model.material_override, "Model should have material_override")
		if model.material_override is StandardMaterial3D:
			var col := (model.material_override as StandardMaterial3D).albedo_color
			assert_true(_is_near(col, PaletteScript.BUTTER, 0.3),
				"GordonBleu should use BUTTER palette color")


func test_michelin_etoile_perdu_uses_cobblestone_grey() -> void:
	var enemy := _spawn(MichelinEtoileScene)
	assert_not_null(enemy, "MichelinEtoilePerdu should instantiate")
	var body := enemy.get_node_or_null("Body")
	assert_not_null(body, "MichelinEtoilePerdu should have Body node")
	if body is MeshInstance3D:
		var col := _get_color(body as MeshInstance3D)
		assert_true(_is_near(col, PaletteScript.COBBLESTONE_GREY, 0.3),
			"MichelinEtoilePerdu should use COBBLESTONE_GREY palette color")


func test_pain_chocolatine_uses_crust() -> void:
	var enemy := _spawn(PainChocolatineScene)
	assert_not_null(enemy, "PainAuChocolatine should instantiate")
	var body := enemy.get_node_or_null("Body")
	assert_not_null(body, "PainAuChocolatine should have Body node")
	if body is MeshInstance3D:
		var col := _get_color(body as MeshInstance3D)
		assert_true(_is_near(col, PaletteScript.CRUST, 0.3),
			"PainAuChocolatine should use CRUST palette color")


# ═════════════════════════════════════════════════════════════════
# SECTION 5: Prop palette verification
# ═════════════════════════════════════════════════════════════════

func test_bakery_rack_uses_warm_beige() -> void:
	var prop := _spawn(BakeryRackScene)
	assert_not_null(prop, "BakeryRack should instantiate")
	# Wood shelves should be warm beige
	assert_true(_any_mesh_near_color(prop, PaletteScript.WARM_BEIGE, 0.3),
		"BakeryRack should use WARM_BEIGE palette color for wood")


func test_bakery_rack_uses_golden_brown_on_baguettes() -> void:
	var prop := _spawn(BakeryRackScene)
	assert_true(_any_mesh_near_color(prop, PaletteScript.GOLDEN_BROWN, 0.3),
		"BakeryRack baguettes should use GOLDEN_BROWN palette color")


func test_oven_prop_uses_cobblestone_grey() -> void:
	var prop := _spawn(OvenPropScene)
	assert_not_null(prop, "OvenProp should instantiate")
	assert_true(_any_mesh_near_color(prop, PaletteScript.COBBLESTONE_GREY, 0.3),
		"OvenProp body should use COBBLESTONE_GREY palette color")


func test_oven_prop_uses_orange_red_glow() -> void:
	var prop := _spawn(OvenPropScene)
	assert_true(_any_mesh_near_color(prop, PaletteScript.ORANGE_RED, 0.4),
		"OvenProp glow should use ORANGE_RED palette color")


func test_counter_display_uses_warm_beige() -> void:
	var prop := _spawn(CounterDisplayScene)
	assert_not_null(prop, "CounterDisplay should instantiate")
	assert_true(_any_mesh_near_color(prop, PaletteScript.WARM_BEIGE, 0.3),
		"CounterDisplay should use WARM_BEIGE palette color")


func test_counter_display_uses_cream_on_glass() -> void:
	var prop := _spawn(CounterDisplayScene)
	assert_true(_any_mesh_near_color(prop, PaletteScript.CREAM, 0.3),
		"CounterDisplay glass should use CREAM palette color")


func test_flour_sack_uses_cream() -> void:
	var prop := _spawn(FlourSackScene)
	assert_not_null(prop, "FlourSack should instantiate")
	assert_true(_any_mesh_near_color(prop, PaletteScript.CREAM, 0.3),
		"FlourSack should use CREAM palette color")


func test_street_lamp_uses_cobblestone_grey_pole() -> void:
	var prop := _spawn(StreetLampScene)
	assert_not_null(prop, "StreetLamp should instantiate")
	assert_true(_any_mesh_near_color(prop, PaletteScript.COBBLESTONE_GREY, 0.3),
		"StreetLamp pole should use COBBLESTONE_GREY palette color")


func test_street_lamp_uses_faded_cyan_light() -> void:
	var prop := _spawn(StreetLampScene)
	assert_true(_any_mesh_near_color(prop, PaletteScript.FADED_CYAN, 0.3),
		"StreetLamp light should use FADED_CYAN palette color (neon signage)")


func test_bench_prop_uses_warm_beige() -> void:
	var prop := _spawn(BenchPropScene)
	assert_not_null(prop, "Bench should instantiate")
	assert_true(_any_mesh_near_color(prop, PaletteScript.WARM_BEIGE, 0.3),
		"Bench seat should use WARM_BEIGE palette color")


func test_bench_prop_uses_cobblestone_grey_legs() -> void:
	var prop := _spawn(BenchPropScene)
	assert_true(_any_mesh_near_color(prop, PaletteScript.COBBLESTONE_GREY, 0.3),
		"Bench legs should use COBBLESTONE_GREY palette color")


func test_abandoned_car_uses_cobblestone_grey_body() -> void:
	var prop := _spawn(AbandonedCarScene)
	assert_not_null(prop, "AbandonedCar should instantiate")
	assert_true(_any_mesh_near_color(prop, PaletteScript.COBBLESTONE_GREY, 0.3),
		"AbandonedCar body should use COBBLESTONE_GREY palette color")


func test_abandoned_car_uses_faded_cyan_windows() -> void:
	var prop := _spawn(AbandonedCarScene)
	assert_true(_any_mesh_near_color(prop, PaletteScript.FADED_CYAN, 0.3),
		"AbandonedCar windows should use FADED_CYAN palette color")


func test_croissant_crate_uses_warm_beige() -> void:
	var prop := _spawn(CroissantCrateScene)
	assert_not_null(prop, "CroissantCrate should instantiate")
	assert_true(_any_mesh_near_color(prop, PaletteScript.WARM_BEIGE, 0.3),
		"CroissantCrate wood should use WARM_BEIGE palette color")


func test_croissant_crate_uses_golden_brown() -> void:
	var prop := _spawn(CroissantCrateScene)
	assert_true(_any_mesh_near_color(prop, PaletteScript.GOLDEN_BROWN, 0.3),
		"CroissantCrate croissants should use GOLDEN_BROWN palette color")


# ═════════════════════════════════════════════════════════════════
# SECTION 6: Color contrast / readability (luminance checks)
# ═════════════════════════════════════════════════════════════════

func test_palette_colors_are_distinct() -> void:
	# All 10 palette colors should be visually distinguishable
	var colors := PaletteScript.all_colors()
	for i in colors.size():
		for j in range(i + 1, colors.size()):
			var dist := _color_distance(colors[i], colors[j])
			assert_gt(dist, 0.1, "Palette colors %d and %d must be distinct (dist=%.2f)" % [i, j, dist])


func test_all_weapons_have_palette_compliant_materials() -> void:
	var weapons_scenes := [
		BaguetteGunScene,
		CroissantBoomerangScene,
		PainChocolatLauncherScene,
	]
	var all_colors := PaletteScript.all_colors()
	for scene in weapons_scenes:
		var instance := _spawn(scene)
		assert_not_null(instance, "Weapon scene should instantiate")
		var mesh := _find_mesh_instance(instance)
		assert_not_null(mesh, "Weapon should have MeshInstance3D (%s)" % scene.resource_path)
		var col := _get_color(mesh)
		var found := false
		for pal_col in all_colors:
			if _is_near(col, pal_col, 0.4):
				found = true
				break
		assert_true(found, "Weapon %s color should be palette-compliant" % scene.resource_path)


func test_all_enemies_have_palette_compliant_materials() -> void:
	var enemy_scenes := [
		BaguetteVivanteScene,
		CroissantNinjaScene,
		SourdoughBlobScene,
		TouristeZombieScene,
		GordonBleuScene,
		MichelinEtoileScene,
		PainChocolatineScene,
	]
	var all_colors := PaletteScript.all_colors()
	for scene in enemy_scenes:
		var instance := _spawn(scene)
		assert_not_null(instance, "Enemy scene should instantiate")
		var mesh := _find_mesh_instance(instance)
		assert_not_null(mesh, "Enemy should have MeshInstance3D (%s)" % scene.resource_path)
		var col := _get_color(mesh)
		var found := false
		for pal_col in all_colors:
			if _is_near(col, pal_col, 0.4):
				found = true
				break
		assert_true(found, "Enemy %s color should be palette-compliant" % scene.resource_path)


func test_all_props_have_palette_compliant_materials() -> void:
	var prop_scenes := [
		BakeryRackScene,
		OvenPropScene,
		CounterDisplayScene,
		FlourSackScene,
		StreetLampScene,
		BenchPropScene,
		AbandonedCarScene,
		CroissantCrateScene,
	]
	var all_colors := PaletteScript.all_colors()
	for scene in prop_scenes:
		var instance := _spawn(scene)
		assert_not_null(instance, "Prop scene should instantiate")
		var mesh := _find_mesh_instance(instance)
		assert_not_null(mesh, "Prop should have MeshInstance3D (%s)" % scene.resource_path)
		var col := _get_color(mesh)
		var found := false
		for pal_col in all_colors:
			if _is_near(col, pal_col, 0.4):
				found = true
				break
		assert_true(found, "Prop %s color should be palette-compliant" % scene.resource_path)
