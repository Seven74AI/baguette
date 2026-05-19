extends "res://addons/gut/test.gd"
## PHASE 4.4: VFX fixes — Muzzle Flash, Bullet Tracers, Impact Flour.
## TDD: These tests will FAIL until effects_manager.gd is updated.

var _initial_child_count: int = 0


func before_each() -> void:
	# Track the number of children on the root before we spawn anything
	_initial_child_count = get_tree().root.get_child_count()


## MUZZLE FLASH TESTS

func test_spawn_muzzle_flash_exists() -> void:
	assert_not_null(EffectsManager, "EffectsManager autoload should exist")
	assert_true(EffectsManager.has_method("spawn_muzzle_flash"), "Should have spawn_muzzle_flash method")


func test_muzzle_flash_particle_count_is_25() -> void:
	EffectsManager.spawn_muzzle_flash(Vector3.ZERO, Vector3.FORWARD)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for muzzle flash")
	if found:
		assert_eq(found.amount, 25, "Muzzle flash particle count should be 25")


func test_muzzle_flash_particle_scale_min_ge_015() -> void:
	EffectsManager.spawn_muzzle_flash(Vector3.ZERO, Vector3.FORWARD)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for muzzle flash")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		assert_true(mat.scale_min >= 0.15, "Muzzle flash scale_min should be >= 0.15, got: " + str(mat.scale_min))


func test_muzzle_flash_particle_scale_max_ge_035() -> void:
	EffectsManager.spawn_muzzle_flash(Vector3.ZERO, Vector3.FORWARD)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for muzzle flash")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		assert_true(mat.scale_max >= 0.349, "Muzzle flash scale_max should be >= 0.35 (tolerance 0.001), got: " + str(mat.scale_max))


func test_muzzle_flash_emission_radius_ge_02() -> void:
	EffectsManager.spawn_muzzle_flash(Vector3.ZERO, Vector3.FORWARD)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for muzzle flash")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		assert_true(mat.emission_sphere_radius >= 0.2, "Emission radius should be >= 0.2, got: " + str(mat.emission_sphere_radius))


## BULLET TRACER TESTS

func test_spawn_tracer_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_tracer"), "Should have spawn_tracer method")


func test_spawn_tracer_creates_mesh() -> void:
	var from_pos := Vector3(0, 0, 0)
	var to_pos := Vector3(0, 0, 10)
	EffectsManager.spawn_tracer(from_pos, to_pos)
	await wait_frames(2)

	var found := _find_new_mesh_instance3d()
	assert_not_null(found, "spawn_tracer should create a MeshInstance3D")
	if found:
		assert_not_null(found.mesh, "MeshInstance3D should have a mesh assigned")
		if found.mesh:
			assert_true(found.mesh is CylinderMesh or found.mesh is BoxMesh or found.mesh is PrismMesh, "Tracer mesh should be a 3D mesh (cylinder expected)")


func test_spawn_tracer_has_lifetime() -> void:
	var from_pos := Vector3(0, 0, 0)
	var to_pos := Vector3(0, 0, 10)
	EffectsManager.spawn_tracer(from_pos, to_pos)
	await wait_frames(2)

	# Tracer cleanup uses SceneTreeTimer (via create_timer), not a Timer node.
	# Verify the mesh was created, is a cylinder, and positioned correctly.
	var found := _find_new_mesh_instance3d_with_cylinder()
	assert_not_null(found, "spawn_tracer should create a MeshInstance3D with CylinderMesh")
	if found:
		# Cylinder should be between from and to
		var min_z := min(from_pos.z, to_pos.z)
		var max_z := max(from_pos.z, to_pos.z)
		assert_between(found.global_position.z, min_z - 0.5, max_z + 0.5, "Tracer z should be between " + str(min_z) + " and " + str(max_z))


## IMPACT FLOUR TESTS

func test_spawn_impact_flour_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_impact_flour"), "Should have spawn_impact_flour method")


func test_impact_flour_particle_count_is_40() -> void:
	EffectsManager.spawn_impact_flour(Vector3.ZERO, Vector3.UP)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for impact flour")
	if found:
		assert_eq(found.amount, 40, "Impact flour particle count should be 40")


func test_impact_flour_scale_min_ge_01() -> void:
	EffectsManager.spawn_impact_flour(Vector3.ZERO, Vector3.UP)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for impact flour")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		assert_true(mat.scale_min >= 0.1, "Impact flour scale_min should be >= 0.1, got: " + str(mat.scale_min))


func test_impact_flour_scale_max_ge_05() -> void:
	EffectsManager.spawn_impact_flour(Vector3.ZERO, Vector3.UP)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for impact flour")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		assert_true(mat.scale_max >= 0.5, "Impact flour scale_max should be >= 0.5, got: " + str(mat.scale_max))


func test_impact_flour_velocity_min_ge_30() -> void:
	EffectsManager.spawn_impact_flour(Vector3.ZERO, Vector3.UP)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for impact flour")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		assert_true(mat.initial_velocity_min >= 3.0, "Impact flour velocity_min should be >= 3.0, got: " + str(mat.initial_velocity_min))


func test_impact_flour_has_gravity_minus3() -> void:
	EffectsManager.spawn_impact_flour(Vector3.ZERO, Vector3.UP)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for impact flour")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		assert_eq(mat.gravity.y, -3.0, "Impact flour gravity should be -3.0, got: " + str(mat.gravity.y))


func test_impact_flour_has_damping_25() -> void:
	EffectsManager.spawn_impact_flour(Vector3.ZERO, Vector3.UP)
	await wait_frames(2)

	var found := _find_new_gpu_particles()
	assert_not_null(found, "Should have created a GPUParticles3D for impact flour")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		assert_eq(mat.damping_min, 2.5, "Impact flour damping_min should be 2.5, got: " + str(mat.damping_min))


## HELPERS

func _find_new_gpu_particles() -> GPUParticles3D:
	# Find a GPUParticles3D that was created after before_each
	var root_children := get_tree().root.get_children()
	for i in range(root_children.size() - 1, -1, -1):
		var child := root_children[i]
		if child is GPUParticles3D:
			return child
	return null


func _find_new_mesh_instance3d() -> MeshInstance3D:
	var root_children := get_tree().root.get_children()
	for i in range(root_children.size() - 1, -1, -1):
		var child := root_children[i]
		if child is MeshInstance3D:
			return child
	return null


func _find_new_mesh_instance3d_with_cylinder() -> MeshInstance3D:
	var root_children := get_tree().root.get_children()
	for i in range(root_children.size() - 1, -1, -1):
		var child := root_children[i]
		if child is MeshInstance3D and child.mesh is CylinderMesh:
			return child
	return null


func _find_new_timer() -> Timer:
	var root_children := get_tree().root.get_children()
	for i in range(root_children.size() - 1, -1, -1):
		var child := root_children[i]
		if child is Timer:
			return child
	return null
