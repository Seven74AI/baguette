extends "res://addons/gut/test.gd"
## Tests for BossArena — arena creation, door locking, boss integration.
## Verifies arena geometry, doors, thematic elements, and boss spawning.

const BossArena = preload("res://scripts/procedural/boss_arena.gd")
const GordonBleu = preload("res://scenes/enemies/gordon_bleu.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _arena: BossArena


func before_each() -> void:
	_arena = BossArena.new()
	_arena.name = "TestArena"
	_arena.arena_radius = 12.0
	add_child_autofree(_arena)
	# _build_arena is called automatically by _ready()


# ═══════════════════════════════════════════════════════════════
# Arena creation
# ═══════════════════════════════════════════════════════════════

func test_arena_creates_floor() -> void:
	var floor := _arena.get_node_or_null("ArenaFloor")
	assert_not_null(floor, "Arena should have a floor")

func test_arena_creates_walls() -> void:
	var walls := _arena.get_node_or_null("ArenaWalls")
	assert_not_null(walls, "Arena should have walls parent node")
	assert_gt(walls.get_child_count(), 0, "Arena walls should have wall segments")

func test_arena_creates_entrance_doors() -> void:
	var left_door := _arena.get_node_or_null("LeftDoor")
	var right_door := _arena.get_node_or_null("RightDoor")
	assert_not_null(left_door, "Arena should have a left door")
	assert_not_null(right_door, "Arena should have a right door")

func test_arena_creates_oven_backdrop() -> void:
	var oven := _arena.get_node_or_null("GiantOven")
	assert_not_null(oven, "Arena should have a giant oven backdrop")

func test_arena_creates_dough_pits() -> void:
	# Count dough pit nodes (named DoughPit_i)
	var pit_count := 0
	for child in _arena.get_children():
		if child.name.begins_with("DoughPit_"):
			pit_count += 1
	assert_eq(pit_count, _arena.dough_pit_count, "Should have correct number of dough pits")

func test_arena_creates_flour_particles() -> void:
	var particle_count := 0
	for child in _arena.get_children():
		if child.name.begins_with("FlourParticle_"):
			particle_count += 1
	assert_eq(particle_count, _arena.flour_particle_count, "Should have correct number of flour particles")

func test_arena_creates_boss_spawn_point() -> void:
	var spawn := _arena.get_node_or_null("BossSpawnPoint")
	assert_not_null(spawn, "Arena should have a boss spawn point")

func test_get_boss_spawn_position_returns_vector3() -> void:
	var pos := _arena.get_boss_spawn_position()
	assert_not_null(pos, "get_boss_spawn_position should return a value")
	assert_true(pos is Vector3, "Should return a Vector3")


# ═══════════════════════════════════════════════════════════════
# Door locking
# ═══════════════════════════════════════════════════════════════

func test_doors_start_unlocked() -> void:
	assert_false(_arena.are_doors_locked(), "Doors should start unlocked")

func test_lock_doors_locks_them() -> void:
	watch_signals(_arena)
	_arena.lock_doors()
	assert_true(_arena.are_doors_locked(), "Doors should be locked after lock_doors()")
	assert_signal_emitted(_arena, "doors_locked")

func test_unlock_doors_unlocks_them() -> void:
	_arena.lock_doors()
	watch_signals(_arena)
	_arena.unlock_doors()
	assert_false(_arena.are_doors_locked(), "Doors should be unlocked after unlock_doors()")
	assert_signal_emitted(_arena, "doors_unlocked")


# ═══════════════════════════════════════════════════════════════
# Boss spawning
# ═══════════════════════════════════════════════════════════════

func test_spawn_boss_creates_gordon_bleu_instance() -> void:
	# Create a minimal health component for the boss
	var boss := _arena.spawn_boss()
	assert_not_null(boss, "spawn_boss should return a boss instance")
	assert_true(boss is GordonBleu, "Boss should be a GordonBleu")

func test_spawn_boss_is_idempotent() -> void:
	var boss1 := _arena.spawn_boss()
	var boss2 := _arena.spawn_boss()
	assert_eq(boss1, boss2, "spawn_boss should return the same instance on second call")

func test_boss_death_unlocks_doors() -> void:
	_arena.lock_doors()
	assert_true(_arena.are_doors_locked(), "Doors should be locked to start")

	var boss := _arena.spawn_boss()
	watch_signals(boss)
	watch_signals(_arena)

	# Kill the boss (spawn_boss already created a health component)
	boss.take_damage(2000)

	assert_signal_emitted(boss, "died")
	assert_signal_emitted(_arena, "boss_defeated")
	assert_false(_arena.are_doors_locked(), "Doors should be unlocked when boss dies")


# ═══════════════════════════════════════════════════════════════
# Arena dimensions
# ═══════════════════════════════════════════════════════════════

func test_arena_respects_radius_parameter() -> void:
	# Rebuild with custom radius
	_arena.arena_radius = 15.0
	_arena._build_arena()
	# Floor box should match diameter
	var floor := _arena.get_node_or_null("ArenaFloor") as CSGBox3D
	if floor:
		assert_eq(floor.size.x, 30.0, "Floor width should be 2x arena_radius")
		assert_eq(floor.size.z, 30.0, "Floor depth should be 2x arena_radius")

func test_arena_can_rebuild() -> void:
	# Rebuild should not crash
	_arena.arena_radius = 10.0
	_arena.wall_segments = 16
	_arena._build_arena()
	assert_not_null(_arena.get_node_or_null("ArenaFloor"), "Arena should have floor after rebuild")
	assert_not_null(_arena.get_node_or_null("ArenaWalls"), "Arena should have walls after rebuild")


# ═══════════════════════════════════════════════════════════════
# Room data integration
# ═══════════════════════════════════════════════════════════════

func test_room_data_can_be_assigned() -> void:
	_arena.room_data = {"is_boss": true, "theme": "cuisine"}
	assert_not_null(_arena.room_data, "room_data should accept room info")
	assert_eq(_arena.room_data["is_boss"], true, "room_data should indicate boss room")
