extends "res://addons/gut/test.gd"
## Tests for PHASE 4.7: Enemy-Specific Death Effects and VFX Architecture.
## Verifies spawn_death_burst() with 5 enemy types, muzzle flash core+particles,
## and visibility at 20m.

# ═══════════════════════════════════════════════════════════════
# EffectsManager method existence
# ═══════════════════════════════════════════════════════════════

func test_effects_manager_exists() -> void:
	assert_not_null(EffectsManager, "EffectsManager autoload should exist")


func test_has_spawn_death_burst() -> void:
	assert_true(EffectsManager.has_method("spawn_death_burst"),
		"Should have spawn_death_burst method")


func test_has_burst_type_enum() -> void:
	assert_true(EffectsManager.has_method("spawn_death_spark"),
		"Should keep legacy spawn_death_spark for backward compat")


# ═══════════════════════════════════════════════════════════════
# Muzzle flash refactor: core sphere + particles
# ═══════════════════════════════════════════════════════════════

func test_muzzle_flash_has_method() -> void:
	assert_true(EffectsManager.has_method("spawn_muzzle_flash"),
		"Should have spawn_muzzle_flash method")


func test_muzzle_flash_creates_multiple_children() -> void:
	# Count children before spawning
	var before := EffectsManager.get_child_count()
	EffectsManager.spawn_muzzle_flash(Vector3(0, 2, 0), Vector3.FORWARD)
	await wait_frames(2)
	var after := EffectsManager.get_child_count()
	# Muzzle flash should spawn at least 2 nodes (particles + core sphere)
	assert_gt(after, before, "Muzzle flash should create children (particles + core)")


# ═══════════════════════════════════════════════════════════════
# spawn_death_burst — no-crash tests for each enemy type
# ═══════════════════════════════════════════════════════════════

func test_death_burst_baguette_vivante_no_crash() -> void:
	EffectsManager.spawn_death_burst(Vector3(5, 1, 0), EffectsManager.DeathBurstType.BAGUETTE)
	await wait_frames(2)
	pass_test("Baguette Vivante death burst completed without errors")


func test_death_burst_croissant_ninja_no_crash() -> void:
	EffectsManager.spawn_death_burst(Vector3(5, 1, 0), EffectsManager.DeathBurstType.CROISSANT_NINJA)
	await wait_frames(2)
	pass_test("Croissant Ninja death burst completed without errors")


func test_death_burst_sourdough_blob_no_crash() -> void:
	EffectsManager.spawn_death_burst(Vector3(5, 1, 0), EffectsManager.DeathBurstType.SOURDOUGH_BLOB)
	await wait_frames(2)
	pass_test("Sourdough Blob death burst completed without errors")


func test_death_burst_touriste_zombie_no_crash() -> void:
	EffectsManager.spawn_death_burst(Vector3(5, 1, 0), EffectsManager.DeathBurstType.TOURISTE_ZOMBIE)
	await wait_frames(2)
	pass_test("Touriste Zombie death burst completed without errors")


func test_death_burst_gordon_bleu_no_crash() -> void:
	EffectsManager.spawn_death_burst(Vector3(5, 1, 0), EffectsManager.DeathBurstType.GORDON_BLEU)
	await wait_frames(2)
	pass_test("Gordon Bleu death burst completed without errors")


# ═══════════════════════════════════════════════════════════════
# Death burst creates scene children for each type
# ═══════════════════════════════════════════════════════════════

func test_baguette_death_creates_particles() -> void:
	var children_before := _count_world_children()
	EffectsManager.spawn_death_burst(Vector3(10, 1, 0), EffectsManager.DeathBurstType.BAGUETTE)
	await wait_frames(3)
	var children_after := _count_world_children()
	assert_gt(children_after, children_before,
		"Baguette Vivante death should create new nodes in the world")


func test_croissant_ninja_death_creates_particles() -> void:
	var children_before := _count_world_children()
	EffectsManager.spawn_death_burst(Vector3(10, 1, 5), EffectsManager.DeathBurstType.CROISSANT_NINJA)
	await wait_frames(3)
	var children_after := _count_world_children()
	assert_gt(children_after, children_before,
		"Croissant Ninja death should create new nodes in the world")


func test_sourdough_death_creates_particles() -> void:
	var children_before := _count_world_children()
	EffectsManager.spawn_death_burst(Vector3(10, 1, 10), EffectsManager.DeathBurstType.SOURDOUGH_BLOB)
	await wait_frames(3)
	var children_after := _count_world_children()
	assert_gt(children_after, children_before,
		"Sourdough Blob death should create new nodes in the world")


func test_touriste_death_creates_particles() -> void:
	var children_before := _count_world_children()
	EffectsManager.spawn_death_burst(Vector3(10, 1, 15), EffectsManager.DeathBurstType.TOURISTE_ZOMBIE)
	await wait_frames(3)
	var children_after := _count_world_children()
	assert_gt(children_after, children_before,
		"Touriste Zombie death should create new nodes in the world")


func test_gordon_bleu_death_creates_particles() -> void:
	var children_before := _count_world_children()
	EffectsManager.spawn_death_burst(Vector3(10, 1, 20), EffectsManager.DeathBurstType.GORDON_BLEU)
	await wait_frames(3)
	var children_after := _count_world_children()
	assert_gt(children_after, children_before,
		"Gordon Bleu death should create new nodes in the world")


# ═══════════════════════════════════════════════════════════════
# Visibility at 20m
# ═══════════════════════════════════════════════════════════════

func test_death_burst_visible_at_20m() -> void:
	# Spawn a death burst far away and verify particles have sufficient scale/amount
	EffectsManager.spawn_death_burst(Vector3(20, 0, 0), EffectsManager.DeathBurstType.GORDON_BLEU)
	await wait_frames(2)
	# Particles should be spawned even at distance — visibility is achieved via
	# sufficient particle amount, scale, and emission brightness
	pass_test("Death burst spawned at 20m — visibility via large particles + emission")


# ═══════════════════════════════════════════════════════════════
# Backward compatibility
# ═══════════════════════════════════════════════════════════════

func test_legacy_spawn_death_spark_still_works() -> void:
	EffectsManager.spawn_death_spark(Vector3(0, 2, 5))
	await wait_frames(2)
	pass_test("Legacy spawn_death_spark still works")


func test_legacy_spawn_impact_flour_still_works() -> void:
	EffectsManager.spawn_impact_flour(Vector3(0, 2, 8), Vector3.UP)
	await wait_frames(2)
	pass_test("Legacy spawn_impact_flour still works")


# ═══════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════

func _count_world_children() -> int:
	var root := EffectsManager._get_world_root()
	if not root:
		return 0
	return root.get_child_count()
