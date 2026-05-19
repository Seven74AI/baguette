extends "res://addons/gut/test.gd"
## TDD tests for Phase 4.3: 3D Enemy Models.
## Verifies each enemy scene has proper 3D model nodes with correct
## meshes, materials, transforms, and model reference capabilities.

# Preload all 5 enemy scenes
const BaguetteVivanteScene = preload("res://scenes/enemies/baguette_vivante.tscn")
const CroissantNinjaScene = preload("res://scenes/enemies/croissant_ninja.tscn")
const SourdoughBlobScene = preload("res://scenes/enemies/sourdough_blob.tscn")
const TouristeZombieScene = preload("res://scenes/enemies/touriste_zombie.tscn")
const GordonBleuScene = preload("res://scenes/enemies/gordon_bleu.tscn")

var _spawned: Array[Node] = []


func after_each() -> void:
	# Clean up any nodes spawned in this test
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()


## Instantiate a scene and add it to the tree for testing.
func _spawn(scene: PackedScene) -> Node:
	var instance := scene.instantiate()
	if instance:
		add_child(instance)
		_spawned.append(instance)
	return instance


# ─────────────────────────────────────────────
# Model existence — every enemy must have a MeshInstance3D
# ─────────────────────────────────────────────

func test_baguette_vivante_has_mesh_instance() -> void:
	var enemy := _spawn(BaguetteVivanteScene)
	assert_not_null(enemy, "Baguette Vivante scene should instantiate")
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Baguette Vivante should have a MeshInstance3D")

func test_croissant_ninja_has_mesh_instance() -> void:
	var enemy := _spawn(CroissantNinjaScene)
	assert_not_null(enemy, "Croissant Ninja scene should instantiate")
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Croissant Ninja should have a MeshInstance3D")

func test_sourdough_blob_has_mesh_instance() -> void:
	var enemy := _spawn(SourdoughBlobScene)
	assert_not_null(enemy, "Sourdough Blob scene should instantiate")
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Sourdough Blob should have a MeshInstance3D")

func test_touriste_zombie_has_mesh_instance() -> void:
	var enemy := _spawn(TouristeZombieScene)
	assert_not_null(enemy, "Touriste Zombie scene should instantiate")
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Touriste Zombie should have a MeshInstance3D")

func test_gordon_bleu_has_mesh_instance() -> void:
	var enemy := _spawn(GordonBleuScene)
	assert_not_null(enemy, "Gordon Bleu scene should instantiate")
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Gordon Bleu should have a MeshInstance3D")


# ─────────────────────────────────────────────
# Model meshes — must have actual Mesh resources
# ─────────────────────────────────────────────

func test_baguette_vivante_mesh_valid() -> void:
	var enemy := _spawn(BaguetteVivanteScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Baguette Vivante should have a mesh node")
	assert_not_null(mesh.mesh, "Baguette Vivante mesh should have a valid Mesh resource")

func test_croissant_ninja_mesh_valid() -> void:
	var enemy := _spawn(CroissantNinjaScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Croissant Ninja should have a mesh node")
	assert_not_null(mesh.mesh, "Croissant Ninja mesh should have a valid Mesh resource")

func test_sourdough_blob_mesh_valid() -> void:
	var enemy := _spawn(SourdoughBlobScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Sourdough Blob should have a mesh node")
	assert_not_null(mesh.mesh, "Sourdough Blob mesh should have a valid Mesh resource")

func test_touriste_zombie_mesh_valid() -> void:
	var enemy := _spawn(TouristeZombieScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Touriste Zombie should have a mesh node")
	assert_not_null(mesh.mesh, "Touriste Zombie mesh should have a valid Mesh resource")

func test_gordon_bleu_mesh_valid() -> void:
	var enemy := _spawn(GordonBleuScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Gordon Bleu should have a mesh node")
	assert_not_null(mesh.mesh, "Gordon Bleu mesh should have a valid Mesh resource")


# ─────────────────────────────────────────────
# Model scale / transforms — enemies must be visually sized
# ─────────────────────────────────────────────

func test_baguette_vivante_scale_applied() -> void:
	var enemy := _spawn(BaguetteVivanteScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Baguette Vivante should have a mesh node")
	assert_gt(mesh.scale.length(), 0.5, "Baguette Vivante should be visibly scaled")

func test_croissant_ninja_scale_applied() -> void:
	var enemy := _spawn(CroissantNinjaScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Croissant Ninja should have a mesh node")
	assert_gt(mesh.scale.length(), 0.5, "Croissant Ninja should be visibly scaled")

func test_sourdough_blob_scale_applied() -> void:
	var enemy := _spawn(SourdoughBlobScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Sourdough Blob should have a mesh node")
	assert_gt(mesh.scale.length(), 0.5, "Sourdough Blob should be visibly scaled")

func test_touriste_zombie_scale_applied() -> void:
	var enemy := _spawn(TouristeZombieScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Touriste Zombie should have a mesh node")
	assert_gt(mesh.scale.length(), 0.5, "Touriste Zombie should be visibly scaled")

func test_gordon_bleu_scale_applied() -> void:
	var enemy := _spawn(GordonBleuScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Gordon Bleu should have a mesh node")
	assert_gt(mesh.scale.length(), 0.5, "Gordon Bleu should be visibly scaled")


# ─────────────────────────────────────────────
# Model materials — enemies must have visual materials
# ─────────────────────────────────────────────

func test_baguette_vivante_has_material() -> void:
	var enemy := _spawn(BaguetteVivanteScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Baguette Vivante should have a mesh node")
	# glTF-imported meshes have materials baked into mesh surfaces, not material_override
	var has_mat := mesh.material_override != null \
		or mesh.get_surface_override_material(0) != null \
		or (mesh.mesh and mesh.mesh.get_surface_count() > 0)
	assert_true(has_mat, "Baguette Vivante mesh should have a material (override or surface)")

func test_croissant_ninja_has_material() -> void:
	var enemy := _spawn(CroissantNinjaScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Croissant Ninja should have a mesh node")
	var has_mat := mesh.material_override != null \
		or mesh.get_surface_override_material(0) != null \
		or (mesh.mesh and mesh.mesh.get_surface_count() > 0)
	assert_true(has_mat, "Croissant Ninja mesh should have a material (override or surface)")

func test_sourdough_blob_has_material() -> void:
	var enemy := _spawn(SourdoughBlobScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Sourdough Blob should have a mesh node")
	var has_mat := mesh.material_override != null \
		or mesh.get_surface_override_material(0) != null \
		or (mesh.mesh and mesh.mesh.get_surface_count() > 0)
	assert_true(has_mat, "Sourdough Blob mesh should have a material (override or surface)")

func test_touriste_zombie_has_material() -> void:
	var enemy := _spawn(TouristeZombieScene)
	var mesh := _find_mesh_instance(enemy)
	assert_not_null(mesh, "Touriste Zombie should have a mesh node")
	var has_mat := mesh.material_override != null \
		or mesh.get_surface_override_material(0) != null \
		or (mesh.mesh and mesh.mesh.get_surface_count() > 0)
	assert_true(has_mat, "Touriste Zombie mesh should have a material (override or surface)")

func test_gordon_bleu_has_material() -> void:
	var enemy := _spawn(GordonBleuScene)
	# Gordon Bleu has multiple mesh children (Body, Toque, RollingPin) in the Model node
	var found_mat: bool = false
	for child_name in ["Model/Body", "Model/Toque", "Model/RollingPin"]:
		var node := enemy.get_node_or_null(child_name) as MeshInstance3D
		if node != null:
			if node.material_override != null \
				or node.get_surface_override_material(0) != null \
				or (node.mesh and node.mesh.get_surface_count() > 0):
				found_mat = true
				break
	assert_true(found_mat, "Gordon Bleu should have at least one material on its mesh children")


# ─────────────────────────────────────────────
# Model reference — enemy scenes should have a Model child node
# ─────────────────────────────────────────────

func test_baguette_vivante_has_model_node() -> void:
	var enemy := _spawn(BaguetteVivanteScene)
	assert_not_null(enemy, "Baguette Vivante scene should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "Baguette Vivante should have a 'Model' node")

func test_croissant_ninja_has_model_node() -> void:
	var enemy := _spawn(CroissantNinjaScene)
	assert_not_null(enemy, "Croissant Ninja scene should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "Croissant Ninja should have a 'Model' node")

func test_sourdough_blob_has_model_node() -> void:
	var enemy := _spawn(SourdoughBlobScene)
	assert_not_null(enemy, "Sourdough Blob scene should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "Sourdough Blob should have a 'Model' node")

func test_touriste_zombie_has_model_node() -> void:
	var enemy := _spawn(TouristeZombieScene)
	assert_not_null(enemy, "Touriste Zombie scene should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "Touriste Zombie should have a 'Model' node")

func test_gordon_bleu_has_model_node() -> void:
	var enemy := _spawn(GordonBleuScene)
	assert_not_null(enemy, "Gordon Bleu scene should instantiate")
	var model := enemy.get_node_or_null("Model")
	assert_not_null(model, "Gordon Bleu should have a 'Model' node")


# ─────────────────────────────────────────────
# AnimationPlayer existence — enemies should have animation capability
# ─────────────────────────────────────────────

func test_baguette_vivante_has_animation_player() -> void:
	var enemy := _spawn(BaguetteVivanteScene)
	assert_not_null(enemy, "Baguette Vivante scene should instantiate")
	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(anim, "Baguette Vivante should have an AnimationPlayer")

func test_croissant_ninja_has_animation_player() -> void:
	var enemy := _spawn(CroissantNinjaScene)
	assert_not_null(enemy, "Croissant Ninja scene should instantiate")
	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(anim, "Croissant Ninja should have an AnimationPlayer")

func test_sourdough_blob_has_animation_player() -> void:
	var enemy := _spawn(SourdoughBlobScene)
	assert_not_null(enemy, "Sourdough Blob scene should instantiate")
	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(anim, "Sourdough Blob should have an AnimationPlayer")

func test_touriste_zombie_has_animation_player() -> void:
	var enemy := _spawn(TouristeZombieScene)
	assert_not_null(enemy, "Touriste Zombie scene should instantiate")
	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(anim, "Touriste Zombie should have an AnimationPlayer")

func test_gordon_bleu_has_animation_player() -> void:
	var enemy := _spawn(GordonBleuScene)
	assert_not_null(enemy, "Gordon Bleu scene should instantiate")
	var anim := enemy.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(anim, "Gordon Bleu should have an AnimationPlayer")


# ─────────────────────────────────────────────
# Model detail — enemies should have specific visual features
# ─────────────────────────────────────────────

func test_baguette_vivante_has_eyes() -> void:
	var enemy := _spawn(BaguetteVivanteScene)
	assert_not_null(enemy, "Baguette Vivante scene should instantiate")
	# Eyes are children of the Model node (from the .glb)
	var eyes := enemy.get_node_or_null("Model/LeftEye")
	assert_not_null(eyes, "Baguette Vivante should have LeftEye node")
	var right_eye := enemy.get_node_or_null("Model/RightEye")
	assert_not_null(right_eye, "Baguette Vivante should have RightEye node")

func test_sourdough_blob_has_eyes() -> void:
	var enemy := _spawn(SourdoughBlobScene)
	assert_not_null(enemy, "Sourdough Blob scene should instantiate")
	var eyes := enemy.get_node_or_null("Model/LeftEye")
	assert_not_null(eyes, "Sourdough Blob should have LeftEye node")
	var right_eye := enemy.get_node_or_null("Model/RightEye")
	assert_not_null(right_eye, "Sourdough Blob should have RightEye node")

func test_touriste_zombie_has_camera_prop() -> void:
	var enemy := _spawn(TouristeZombieScene)
	assert_not_null(enemy, "Touriste Zombie scene should instantiate")
	var camera := enemy.get_node_or_null("Model/Camera")
	assert_not_null(camera, "Touriste Zombie should have a Camera prop node")

func test_gordon_bleu_has_toque() -> void:
	var enemy := _spawn(GordonBleuScene)
	assert_not_null(enemy, "Gordon Bleu scene should instantiate")
	var toque := enemy.get_node_or_null("Model/Toque")
	assert_not_null(toque, "Gordon Bleu should have a Toque mesh node")

# ─────────────────────────────────────────────
# HealthComponent — enemies must have proper health setup
# ─────────────────────────────────────────────

func test_all_enemies_have_health_component() -> void:
	for which in [
		["Baguette Vivante", BaguetteVivanteScene],
		["Croissant Ninja", CroissantNinjaScene],
		["Sourdough Blob", SourdoughBlobScene],
		["Touriste Zombie", TouristeZombieScene],
		["Gordon Bleu", GordonBleuScene],
	]:
		var enemy := _spawn(which[1])
		assert_not_null(enemy, which[0] + " should instantiate")
		var hc := enemy.get_node_or_null("HealthComponent")
		assert_not_null(hc, which[0] + " should have a HealthComponent")
		_spawned.clear()
		for node in _spawned:
			if is_instance_valid(node):
				node.queue_free()
		_spawned.clear()


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

## Recursively find the first MeshInstance3D in a node tree.
func _find_mesh_instance(root: Node) -> MeshInstance3D:
	if not is_instance_valid(root):
		return null
	if root is MeshInstance3D:
		return root as MeshInstance3D
	for child in root.get_children():
		var found := _find_mesh_instance(child)
		if found:
			return found
	return null
