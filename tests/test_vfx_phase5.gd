extends "res://addons/gut/test.gd"
## PHASE 5.1b: Advanced VFX — weapon-specific effects + boss VFX + environmental particles.
## TDD RED: These tests will FAIL until effects_manager.gd is updated with new spawn_* methods.

var _initial_child_count: int = 0


func before_each() -> void:
	_initial_child_count = get_tree().root.get_child_count()


# ═══════════════════════════════════════════════════════════════
# WEAPON-SPECIFIC: Croissant boomerang — golden trail ribbon
# ═══════════════════════════════════════════════════════════════

func test_spawn_croissant_trail_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_croissant_trail"),
		"Should have spawn_croissant_trail method")


func test_croissant_trail_creates_particles() -> void:
	var children_before := _count_world_children()
	EffectsManager.spawn_croissant_trail(Vector3(0, 2, 0), Vector3.FORWARD)
	await wait_frames(2)
	var children_after := _count_world_children()
	assert_gt(children_after, children_before,
		"spawn_croissant_trail should create new nodes in the world")


func test_croissant_trail_golden_color() -> void:
	EffectsManager.spawn_croissant_trail(Vector3(0, 2, 0), Vector3.FORWARD)
	await wait_frames(2)
	var found := _find_new_gpu_particles()
	assert_not_null(found, "spawn_croissant_trail should create a GPUParticles3D")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		# Golden color: R > 0.8, G > 0.6, B < 0.5
		assert_true(mat.color.r >= 0.7, "Croissant trail color R should be >= 0.7 (golden)")
		assert_true(mat.color.g >= 0.5, "Croissant trail color G should be >= 0.5 (golden)")


func test_croissant_trail_is_continuous() -> void:
	# Trail should be continuous (not one_shot), following the projectile
	EffectsManager.spawn_croissant_trail(Vector3(0, 2, 0), Vector3.FORWARD)
	await wait_frames(2)
	var found := _find_new_gpu_particles()
	assert_not_null(found, "spawn_croissant_trail should create a GPUParticles3D")
	if found:
		# Continuous trail: one_shot should be false
		assert_false(found.one_shot, "Croissant trail should be continuous (one_shot=false)")


# ═══════════════════════════════════════════════════════════════
# WEAPON-SPECIFIC: Pain au chocolat launcher — fire/explosion burst
# ═══════════════════════════════════════════════════════════════

func test_spawn_pain_au_chocolat_burst_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_pain_au_chocolat_burst"),
		"Should have spawn_pain_au_chocolat_burst method")


func test_pain_au_chocolat_burst_creates_particles() -> void:
	var children_before := _count_world_children()
	EffectsManager.spawn_pain_au_chocolat_burst(Vector3(0, 2, 0), Vector3.UP)
	await wait_frames(2)
	var children_after := _count_world_children()
	assert_gt(children_after, children_before,
		"spawn_pain_au_chocolat_burst should create new nodes in the world")


func test_pain_au_chocolat_burst_fire_colors() -> void:
	EffectsManager.spawn_pain_au_chocolat_burst(Vector3(0, 2, 0), Vector3.UP)
	await wait_frames(2)
	var found := _find_new_gpu_particles()
	assert_not_null(found, "spawn_pain_au_chocolat_burst should create a GPUParticles3D")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		# Fire colors: orange/red — R high, G medium, B low
		assert_true(mat.color.r >= 0.8, "Pain au chocolat burst should have fire color (R high)")
		assert_true(mat.color.b <= 0.3, "Pain au chocolat burst should have fire color (B low)")


func test_pain_au_chocolat_burst_particle_count_ge_30() -> void:
	EffectsManager.spawn_pain_au_chocolat_burst(Vector3(0, 2, 0), Vector3.UP)
	await wait_frames(2)
	var found := _find_new_gpu_particles()
	assert_not_null(found, "spawn_pain_au_chocolat_burst should create a GPUParticles3D")
	if found:
		assert_true(found.amount >= 30,
			"Pain au chocolat burst should have >= 30 particles for dramatic fireburst")


# ═══════════════════════════════════════════════════════════════
# WEAPON-SPECIFIC: Baguette gun — enhanced pierce flash
# ═══════════════════════════════════════════════════════════════

func test_spawn_baguette_pierce_flash_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_baguette_pierce_flash"),
		"Should have spawn_baguette_pierce_flash method")


func test_baguette_pierce_flash_creates_streak_mesh() -> void:
	var children_before := _count_world_children()
	EffectsManager.spawn_baguette_pierce_flash(Vector3(0, 2, 0), Vector3(0, 2, 10))
	await wait_frames(2)
	var children_after := _count_world_children()
	assert_gt(children_after, children_before,
		"spawn_baguette_pierce_flash should create new nodes (streak + spark)")


func test_baguette_pierce_flash_creates_spark_particles() -> void:
	EffectsManager.spawn_baguette_pierce_flash(Vector3(0, 2, 0), Vector3(0, 2, 10))
	await wait_frames(2)
	var found := _find_new_gpu_particles()
	# Should have spark particles as part of the pierce flash
	assert_not_null(found, "spawn_baguette_pierce_flash should create spark particles")


# ═══════════════════════════════════════════════════════════════
# BOSS VFX PLACEHOLDERS: Energy aura
# ═══════════════════════════════════════════════════════════════

func test_spawn_boss_aura_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_boss_aura"),
		"Should have spawn_boss_aura method")


func test_boss_aura_creates_glow_mesh() -> void:
	EffectsManager.spawn_boss_aura(Vector3(0, 2, 0), 3.0)
	await wait_frames(2)
	var found := _find_new_mesh_instance3d()
	assert_not_null(found, "spawn_boss_aura should create a glow outline mesh node")


func test_boss_aura_emission_enabled() -> void:
	EffectsManager.spawn_boss_aura(Vector3(0, 2, 0), 3.0)
	await wait_frames(2)
	var found := _find_new_mesh_instance3d()
	assert_not_null(found, "spawn_boss_aura should create a MeshInstance3D")
	if found and found.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = found.material_override
		assert_true(mat.emission_enabled, "Boss aura should have emission enabled for glow")


# ═══════════════════════════════════════════════════════════════
# BOSS VFX PLACEHOLDERS: Phase transition burst
# ═══════════════════════════════════════════════════════════════

func test_spawn_phase_transition_burst_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_phase_transition_burst"),
		"Should have spawn_phase_transition_burst method")


func test_phase_transition_burst_creates_effect() -> void:
	EffectsManager.spawn_phase_transition_burst(Vector3(0, 2, 0), 5.0)
	await wait_frames(2)
	var found := _find_new_mesh_instance3d()
	assert_not_null(found, "spawn_phase_transition_burst should create expanding ring + particles")


# ═══════════════════════════════════════════════════════════════
# ENVIRONMENTAL: Flour dust motes
# ═══════════════════════════════════════════════════════════════

func test_spawn_flour_dust_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_flour_dust"),
		"Should have spawn_flour_dust method")


func test_flour_dust_creates_warm_white_particles() -> void:
	EffectsManager.spawn_flour_dust(Vector3(0, 2, 0), 5.0)
	await wait_frames(2)
	var found := _find_new_gpu_particles()
	assert_not_null(found, "spawn_flour_dust should create floating particles")


func test_flour_dust_warm_white_color() -> void:
	EffectsManager.spawn_flour_dust(Vector3(0, 2, 0), 5.0)
	await wait_frames(2)
	var found := _find_new_gpu_particles()
	assert_not_null(found, "spawn_flour_dust should create a GPUParticles3D")
	if found and found.process_material is ParticleProcessMaterial:
		var mat: ParticleProcessMaterial = found.process_material
		# Warm white: R ~ G ~ B, all > 0.8
		assert_true(mat.color.r >= 0.8, "Flour dust color should be warm white (R high)")
		assert_true(mat.color.g >= 0.8, "Flour dust color should be warm white (G high)")
		assert_true(mat.color.b >= 0.7, "Flour dust color should be warm white (B high)")


# ═══════════════════════════════════════════════════════════════
# ENVIRONMENTAL: Oven heat shimmer
# ═══════════════════════════════════════════════════════════════

func test_spawn_oven_heat_shimmer_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_oven_heat_shimmer"),
		"Should have spawn_oven_heat_shimmer method")


func test_oven_heat_shimmer_creates_warm_glow() -> void:
	EffectsManager.spawn_oven_heat_shimmer(Vector3(0, 2, 0), 2.0)
	await wait_frames(2)
	var found := _find_new_mesh_instance3d()
	assert_not_null(found, "spawn_oven_heat_shimmer should create heat distortion + warm glow")


# ═══════════════════════════════════════════════════════════════
# ENVIRONMENTAL: Parisian street ambiance
# ═══════════════════════════════════════════════════════════════

func test_spawn_street_ambiance_exists() -> void:
	assert_true(EffectsManager.has_method("spawn_street_ambiance"),
		"Should have spawn_street_ambiance method")


func test_street_ambiance_creates_particles() -> void:
	EffectsManager.spawn_street_ambiance(Vector3(0, 2, 0), 8.0)
	await wait_frames(2)
	var found := _find_new_gpu_particles()
	assert_not_null(found, "spawn_street_ambiance should create ambient particles (dust/papers/pigeons)")


# ═══════════════════════════════════════════════════════════════
# CLEANUP / NON-CRASH VERIFICATION
# ═══════════════════════════════════════════════════════════════

func test_all_new_effects_non_crash() -> void:
	# Verify all new effects can be called without errors
	EffectsManager.spawn_croissant_trail(Vector3(0, 2, 0), Vector3.FORWARD)
	EffectsManager.spawn_pain_au_chocolat_burst(Vector3(1, 2, 1), Vector3.UP)
	EffectsManager.spawn_baguette_pierce_flash(Vector3(2, 2, 0), Vector3(3, 2, 0))
	EffectsManager.spawn_boss_aura(Vector3(3, 2, 0), 3.0)
	EffectsManager.spawn_phase_transition_burst(Vector3(4, 2, 0), 5.0)
	EffectsManager.spawn_flour_dust(Vector3(5, 2, 0), 5.0)
	EffectsManager.spawn_oven_heat_shimmer(Vector3(6, 2, 0), 2.0)
	EffectsManager.spawn_street_ambiance(Vector3(7, 2, 0), 8.0)
	await wait_frames(3)
	pass_test("All 8 new VFX methods completed without errors")


# ═══════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════

func _count_world_children() -> int:
	var root: Node = EffectsManager._get_world_root()
	if not root:
		return 0
	return root.get_child_count()


func _find_new_gpu_particles() -> GPUParticles3D:
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
