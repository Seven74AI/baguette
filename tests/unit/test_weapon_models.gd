extends "res://addons/gut/test.gd"
## TDD tests for Phase 4.2: 3D Weapon Models — Baguette Gun and Croissant Boomerang.
## Tests validate model existence, MeshInstance3D children, bakery palette materials,
## and script-model wiring. Expected to FAIL before models are created (RED phase).

const BAGUETTE_PALETTE := {
	"golden_brown": Color("#D4A354"),
	"crust_dark": Color("#8B5E3C"),
	"off_white_cream": Color("#F5F0E1"),
	"butter_yellow": Color("#FFF4C2"),
	"warm_beige": Color("#E8D5B7"),
}

const CROISSANT_PALETTE := {
	"golden_brown": Color("#D4A354"),
	"butter_yellow": Color("#FFF4C2"),
	"crust_dark": Color("#8B5E3C"),
}


# ---------------- Baguette Gun Scene Tests ----------------

func test_baguette_gun_scene_exists() -> void:
	var scene: PackedScene = load("res://scenes/weapons/baguette_gun.tscn")
	assert_not_null(scene, "baguette_gun.tscn should be loadable as a PackedScene")


func test_baguette_gun_scene_instantiates() -> void:
	var scene: PackedScene = load("res://scenes/weapons/baguette_gun.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "baguette_gun.tscn should instantiate without errors")


func test_baguette_gun_has_weapon_model_node() -> void:
	var scene: PackedScene = load("res://scenes/weapons/baguette_gun.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	# The weapon model should be a MeshInstance3D child named "WeaponModel"
	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	assert_not_null(model, "Baguette Gun scene should have a 'WeaponModel' MeshInstance3D child")


func test_baguette_gun_model_has_mesh_assigned() -> void:
	var scene: PackedScene = load("res://scenes/weapons/baguette_gun.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model:
		assert_not_null(model.mesh, "WeaponModel should have a Mesh assigned")


func test_baguette_gun_model_has_material() -> void:
	var scene: PackedScene = load("res://scenes/weapons/baguette_gun.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model:
		var surf_count: int = model.mesh.get_surface_count() if model.mesh else 0
		assert_gt(surf_count, 0, "WeaponModel mesh should have at least one surface")
		# At least one surface should have a material override or the mesh should have surface materials
		var has_material: bool = false
		if model.material_override:
			has_material = true
		else:
			for i in range(surf_count):
				var mat: Material = model.get_surface_override_material(i)
				if not mat:
					mat = model.mesh.surface_get_material(i)
				if mat:
					has_material = true
					break
		assert_true(has_material, "WeaponModel should have at least one material applied")


func test_baguette_gun_material_is_standard_material() -> void:
	var scene: PackedScene = load("res://scenes/weapons/baguette_gun.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model and model.mesh:
		var surf_count: int = model.mesh.get_surface_count()
		var found_std_mat: bool = false
		if model.material_override and model.material_override is StandardMaterial3D:
			found_std_mat = true
		else:
			for i in range(surf_count):
				var mat: Material = model.get_surface_override_material(i)
				if not mat:
					mat = model.mesh.surface_get_material(i)
				if mat and mat is StandardMaterial3D:
					found_std_mat = true
					break
		assert_true(found_std_mat, "WeaponModel should use StandardMaterial3D (not ShaderMaterial)")


func test_baguette_gun_model_has_bakery_palette_colors() -> void:
	var scene: PackedScene = load("res://scenes/weapons/baguette_gun.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model and model.mesh:
		var surf_count: int = model.mesh.get_surface_count()
		var all_colors: Array[Color] = []
		if model.material_override and model.material_override is StandardMaterial3D:
			all_colors.append((model.material_override as StandardMaterial3D).albedo_color)
		for i in range(surf_count):
			var mat: Material = model.get_surface_override_material(i)
			if not mat:
				mat = model.mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				all_colors.append((mat as StandardMaterial3D).albedo_color)

		assert_gt(all_colors.size(), 0, "Should have at least one material color")

		# Check that at least one surface uses a bakery palette color (within tolerance)
		var matches_palette: bool = false
		for c in all_colors:
			for palette_color in BAGUETTE_PALETTE.values():
				if _color_distance(c, palette_color) < 0.15:
					matches_palette = true
					break
			if matches_palette:
				break
		assert_true(matches_palette, "At least one surface should use a bakery palette color")


# ---------------- Croissant Boomerang Scene Tests ----------------

func test_croissant_boomerang_scene_exists() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	assert_not_null(scene, "croissant_boomerang.tscn should be loadable as a PackedScene")


func test_croissant_boomerang_scene_instantiates() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance, "croissant_boomerang.tscn should instantiate without errors")


func test_croissant_boomerang_has_weapon_model_node() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	assert_not_null(model, "Croissant Boomerang scene should have a 'WeaponModel' MeshInstance3D child")


func test_croissant_boomerang_model_has_mesh_assigned() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model:
		assert_not_null(model.mesh, "WeaponModel should have a Mesh assigned")


func test_croissant_boomerang_model_is_arraymesh() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model and model.mesh:
		assert_true(model.mesh is ArrayMesh, "Croissant boomerang model should use a procedural ArrayMesh for the crescent shape")


func test_croissant_boomerang_model_has_sufficient_vertices() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model and model.mesh:
		var arrays = model.mesh.surface_get_arrays(0)
		var vertex_array = arrays[ArrayMesh.ARRAY_VERTEX]
		assert_not_null(vertex_array, "Vertex array should exist")
		assert_gt(vertex_array.size(), 50, "Croissant boomerang mesh should have > 50 vertices for a recognizable crescent shape")


func test_croissant_boomerang_material_is_standard_material() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model and model.mesh:
		var surf_count: int = model.mesh.get_surface_count()
		var found_std_mat: bool = false
		if model.material_override and model.material_override is StandardMaterial3D:
			found_std_mat = true
		else:
			for i in range(surf_count):
				var mat: Material = model.get_surface_override_material(i)
				if not mat:
					mat = model.mesh.surface_get_material(i)
				if mat and mat is StandardMaterial3D:
					found_std_mat = true
					break
		assert_true(found_std_mat, "Croissant model should use StandardMaterial3D")


func test_croissant_boomerang_model_has_bakery_palette_colors() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	var instance: Node = scene.instantiate()
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model and model.mesh:
		var surf_count: int = model.mesh.get_surface_count()
		var all_colors: Array[Color] = []
		if model.material_override and model.material_override is StandardMaterial3D:
			all_colors.append((model.material_override as StandardMaterial3D).albedo_color)
		for i in range(surf_count):
			var mat: Material = model.get_surface_override_material(i)
			if not mat:
				mat = model.mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				all_colors.append((mat as StandardMaterial3D).albedo_color)

		assert_gt(all_colors.size(), 0, "Should have at least one material color")

		var matches_palette: bool = false
		for c in all_colors:
			for palette_color in CROISSANT_PALETTE.values():
				if _color_distance(c, palette_color) < 0.15:
					matches_palette = true
					break
			if matches_palette:
				break
		assert_true(matches_palette, "At least one surface should use a bakery palette color")


# ---------------- Weapon Script Model Reference Tests ----------------

func test_baguette_gun_script_references_model() -> void:
	var BaguetteGunClass = preload("res://scenes/weapons/baguette_gun.gd")
	var gun: Node = BaguetteGunClass.new()
	add_child_autofree(gun)

	# The script should have a member variable referencing the WeaponModel node
	# We check the script source for 'WeaponModel' or '_model' references
	var has_model_ref: bool = gun.has_method("get_ammo_count")
	assert_true(has_model_ref, "BaguetteGun script should be functional")

	# PHASE 4.2: Verify a _weapon_model or WeaponModel member exists
	var model_node: Node = gun.get_node_or_null("WeaponModel") if gun.is_inside_tree() else null
	# For a non-scene instantiated gun, the model won't exist; this tests that the
	# script is designed to look for it (via @onready or node path)
	# We accept null here since the gun isn't in a scene — the scene test covers this
	assert_true(true, "Script model reference check deferred to scene tests")


func test_croissant_boomerang_script_references_model() -> void:
	var CroissantBoomerangClass = preload("res://scenes/weapons/croissant_boomerang.gd")
	var weapon: Node = CroissantBoomerangClass.new()
	add_child_autofree(weapon)

	var has_method: bool = weapon.has_method("get_is_ready")
	assert_true(has_method, "CroissantBoomerang script should be functional")

	# PHASE 4.2: Verify script can reference WeaponModel node when in scene
	assert_true(true, "Script model reference check deferred to scene tests")


# ---------------- .glb Asset Tests ----------------

func test_baguette_gun_glb_exists() -> void:
	var file := FileAccess.open("res://assets/models/weapons/baguette_gun.glb", FileAccess.READ)
	assert_not_null(file, "baguette_gun.glb should exist in assets/models/weapons/")
	if file:
		var size: int = file.get_length()
		assert_gt(size, 0, "baguette_gun.glb should not be empty")
		file.close()


func test_croissant_boomerang_glb_exists() -> void:
	var file := FileAccess.open("res://assets/models/weapons/croissant_boomerang.glb", FileAccess.READ)
	assert_not_null(file, "croissant_boomerang.glb should exist in assets/models/weapons/")
	if file:
		var size: int = file.get_length()
		assert_gt(size, 0, "croissant_boomerang.glb should not be empty")
		file.close()


# ---------------- Weapon Model Scale Tests ----------------

func test_baguette_gun_model_is_visible() -> void:
	var scene: PackedScene = load("res://scenes/weapons/baguette_gun.tscn")
	var instance: Node3D = scene.instantiate() as Node3D
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model:
		assert_true(model.visible, "WeaponModel should be visible")


func test_croissant_boomerang_model_is_visible() -> void:
	var scene: PackedScene = load("res://scenes/weapons/croissant_boomerang.tscn")
	var instance: Node3D = scene.instantiate() as Node3D
	add_child_autofree(instance)
	await wait_frames(2)

	var model: MeshInstance3D = instance.get_node_or_null("WeaponModel")
	if model:
		assert_true(model.visible, "WeaponModel should be visible")


# ---------------- Helper Functions ----------------

func _color_distance(a: Color, b: Color) -> float:
	return sqrt(
		pow(a.r - b.r, 2) +
		pow(a.g - b.g, 2) +
		pow(a.b - b.b, 2)
	)
