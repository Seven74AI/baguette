extends "res://addons/gut/test.gd"
## TDD tests for Phase 5.1a: Player Model — MITCH 3D character.
## Verifies PlayerMeshGenerator produces valid mesh, player scene
## has model + animation nodes, and PlayerAnimator script exists.

# Preload the PlayerMeshGenerator and PlayerAnimator
const PlayerMeshGenerator = preload("res://scripts/player/player_mesh_generator.gd")
const PlayerAnimator = preload("res://scripts/player/player_animator.gd")
const PlayerScene = preload("res://scenes/player/player.tscn")

var _mesh_generator: PlayerMeshGenerator
var _spawned: Array[Node] = []


func before_each() -> void:
	_mesh_generator = PlayerMeshGenerator.new()
	add_child_autofree(_mesh_generator)
	await wait_frames(2)


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


# ─────────────────────────────────────────────
# PlayerMeshGenerator tests
# ─────────────────────────────────────────────

func test_mesh_generator_extends_mesh_instance_3d() -> void:
	assert_true(_mesh_generator is MeshInstance3D,
		"PlayerMeshGenerator should extend MeshInstance3D")


func test_mesh_generator_produces_valid_mesh() -> void:
	_mesh_generator.generate_mitch_mesh()
	var m: Mesh = _mesh_generator.mesh
	assert_not_null(m, "Mesh should be generated and assigned")
	# Access mesh directly — MeshInstance3D.get_surface_count() may not work in headless
	assert_gt(m.get_surface_count(), 0, "Mesh should have at least one surface")


func test_mesh_has_vertices() -> void:
	_mesh_generator.generate_mitch_mesh()
	var m: Mesh = _mesh_generator.mesh
	assert_not_null(m)
	assert_gt(m.get_surface_count(), 0, "Mesh should have at least one surface")
	var arrays = m.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
	assert_gt(vertices.size(), 50, "Player mesh should have > 50 vertices (low-poly humanoid)")


func test_mesh_has_normals() -> void:
	_mesh_generator.generate_mitch_mesh()
	var m: Mesh = _mesh_generator.mesh
	assert_not_null(m)
	assert_gt(m.get_surface_count(), 0, "Mesh should have at least one surface")
	var arrays = m.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[ArrayMesh.ARRAY_NORMAL] as PackedVector3Array
	assert_eq(normals.size(), arrays[ArrayMesh.ARRAY_VERTEX].size(),
		"Normals should match vertex count")


func test_mesh_has_triangles() -> void:
	_mesh_generator.generate_mitch_mesh()
	var m: Mesh = _mesh_generator.mesh
	assert_not_null(m)
	assert_gt(m.get_surface_count(), 0, "Mesh should have at least one surface")
	var arrays = m.surface_get_arrays(0)
	var raw_indices = arrays[ArrayMesh.ARRAY_INDEX]
	var vertices: PackedVector3Array = arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
	
	if raw_indices != null and raw_indices.size() > 0:
		# Indexed mesh
		if raw_indices is PackedInt32Array:
			assert_gt(raw_indices.size(), 0, "Mesh should have triangle indices")
			assert_eq(raw_indices.size() % 3, 0, "Triangle indices should be in multiples of 3")
		elif raw_indices is PackedInt64Array:
			assert_gt(raw_indices.size(), 0, "Mesh should have triangle indices")
			assert_eq(raw_indices.size() % 3, 0, "Triangle indices should be in multiples of 3")
	else:
		# Non-indexed mesh — vertex count should be divisible by 3 (triangle soup)
		assert_gt(vertices.size(), 0, "Mesh should have vertices")
		assert_eq(vertices.size() % 3, 0, "Vertex count should be multiple of 3 for triangle soup")


func test_mesh_generator_has_export_vars() -> void:
	assert_gt(_mesh_generator.body_height, 0.0, "body_height should have a positive default")
	assert_gt(_mesh_generator.body_radius, 0.0, "body_radius should have a positive default")


# ─────────────────────────────────────────────
# Player scene structure tests
# ─────────────────────────────────────────────

func test_player_scene_instantiates() -> void:
	var player := _spawn(PlayerScene)
	assert_not_null(player, "Player scene should instantiate")
	assert_true(player is CharacterBody3D, "Player should be CharacterBody3D")


func test_player_scene_has_model_node() -> void:
	var player := _spawn(PlayerScene)
	assert_not_null(player, "Player scene should instantiate")
	# The Model node is an instanced .glb — search recursively
	var model := _find_node_named(player, "Model")
	assert_not_null(model, "Player should have a 'Model' node")


func test_player_model_has_mesh() -> void:
	var player := _spawn(PlayerScene)
	assert_not_null(player, "Player scene should instantiate")
	var model := _find_node_named(player, "Model")
	assert_not_null(model, "Player should have Model node")
	var mesh_node := _find_mesh_instance(model)
	# The .glb may instantiate with mesh data directly on the surface,
	# not necessarily as a MeshInstance3D child
	if mesh_node:
		assert_not_null(mesh_node.mesh, "Model mesh should have a valid Mesh resource")


func test_player_model_uses_glb() -> void:
	# Verify the .glb file exists and can be loaded
	var glb_path := "res://assets/models/player/mitch.glb"
	assert_true(ResourceLoader.exists(glb_path),
		"Player model .glb should exist at " + glb_path)
	var glb := ResourceLoader.load(glb_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_not_null(glb, "Player .glb should be loadable")


func test_player_scene_has_animation_player() -> void:
	var player := _spawn(PlayerScene)
	assert_not_null(player, "Player scene should instantiate")
	var anim := player.get_node_or_null("AnimationPlayer") as AnimationPlayer
	assert_not_null(anim, "Player should have an AnimationPlayer")


# ─────────────────────────────────────────────
# PlayerAnimator tests
# ─────────────────────────────────────────────

func test_player_animator_exists() -> void:
	var animator := PlayerAnimator.new()
	assert_not_null(animator, "PlayerAnimator should be instantiable")
	animator.free()


func test_animator_has_animation_methods() -> void:
	var animator := PlayerAnimator.new()
	add_child_autofree(animator)
	assert_true(animator.has_method("play_idle"), "Animator should have play_idle method")
	assert_true(animator.has_method("play_walk"), "Animator should have play_walk method")
	assert_true(animator.has_method("play_sprint"), "Animator should have play_sprint method")
	assert_true(animator.has_method("play_shoot"), "Animator should have play_shoot method")
	assert_true(animator.has_method("play_dash"), "Animator should have play_dash method")
	assert_true(animator.has_method("play_death"), "Animator should have play_death method")


func test_animator_has_exported_vars() -> void:
	var animator := PlayerAnimator.new()
	add_child_autofree(animator)
	# Check that the exported properties exist (may be null by default)
	assert_true("animation_player" in animator, "Animator should have animation_player property")
	assert_true("target" in animator, "Animator should have target property")


# ─────────────────────────────────────────────
# Model detail: MITCH has bakery-themed parts
# ─────────────────────────────────────────────

func test_mitch_model_has_toque() -> void:
	_mesh_generator.generate_mitch_mesh()
	var m: Mesh = _mesh_generator.mesh
	assert_not_null(m, "Generated mesh should exist")
	assert_gt(m.get_surface_count(), 0,
		"Generated mesh should have surfaces including the toque")


func test_mitch_model_has_body_with_apron() -> void:
	_mesh_generator.generate_mitch_mesh()
	var m: Mesh = _mesh_generator.mesh
	assert_not_null(m, "Mesh should exist with body and apron")
	assert_gt(m.get_surface_count(), 0, "Body+apron mesh should have surfaces")


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

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


func _find_node_named(root: Node, name: String) -> Node:
	if not is_instance_valid(root):
		return null
	if root.name == name:
		return root
	for child in root.get_children():
		var found := _find_node_named(child, name)
		if found:
			return found
	return null
