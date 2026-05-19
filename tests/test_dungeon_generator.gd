extends "res://addons/gut/test.gd"
## Tests for the procedural dungeon generator.
## Verifies room placement, connectivity, theme assignment, seed reproducibility,
## and configurable parameters.

const DungeonGenerator = preload("res://scripts/procedural/dungeon_generator.gd")
const DungeonRoom = preload("res://scripts/procedural/room.gd")
const DungeonCorridor = preload("res://scripts/procedural/corridor.gd")

var _gen: Node


func before_each() -> void:
	_gen = DungeonGenerator.new()
	_gen.floor_size = Vector2(100.0, 100.0)
	_gen.room_count = 8
	_gen.min_room_size = 4.0
	_gen.max_room_size = 12.0
	_gen.corridor_width = 2.0
	_gen.seed = 42
	add_child_autofree(_gen)


# ── Seed Reproducibility ──────────────────────────────────────────

func test_seed_reproducibility() -> void:
	_gen.seed = 12345
	_gen.generate()

	var rooms_a: Array = _gen.rooms.duplicate()
	var corridors_a: Array = _gen.corridors.duplicate()

	var gen_b = DungeonGenerator.new()
	gen_b.floor_size = _gen.floor_size
	gen_b.room_count = _gen.room_count
	gen_b.min_room_size = _gen.min_room_size
	gen_b.max_room_size = _gen.max_room_size
	gen_b.corridor_width = _gen.corridor_width
	gen_b.seed = 12345
	add_child_autofree(gen_b)
	gen_b.generate()

	assert_eq(gen_b.rooms.size(), rooms_a.size(), "Same seed should produce same room count")
	for i in range(rooms_a.size()):
		var ra = rooms_a[i] as DungeonRoom
		var rb = gen_b.rooms[i] as DungeonRoom
		assert_eq(ra.position, rb.position, "Same seed: room %d position should match" % i)
		assert_eq(ra.size, rb.size, "Same seed: room %d size should match" % i)
		assert_eq(ra.theme, rb.theme, "Same seed: room %d theme should match" % i)
	assert_eq(gen_b.corridors.size(), corridors_a.size(), "Same seed should produce same corridor count")


# ── Room Count ────────────────────────────────────────────────────

func test_room_count_exact() -> void:
	_gen.room_count = 6
	_gen.generate()
	assert_eq(_gen.rooms.size(), 6, "Should generate exactly the requested number of rooms")


func test_room_count_large() -> void:
	_gen.room_count = 20
	_gen.floor_size = Vector2(200.0, 200.0)
	_gen.generate()
	assert_eq(_gen.rooms.size(), 20, "Should generate 20 rooms with enough space")


# ── No Overlapping Rooms ──────────────────────────────────────────

func test_no_overlapping_rooms() -> void:
	_gen.room_count = 10
	_gen.generate()

	var rooms: Array = _gen.rooms
	for i in range(rooms.size()):
		for j in range(i + 1, rooms.size()):
			var a = rooms[i] as DungeonRoom
			var b = rooms[j] as DungeonRoom
			assert_false(a.overlaps(b),
				"Room %d and %d should not overlap" % [i, j])


# ── Floor Bounds ──────────────────────────────────────────────────

func test_rooms_within_floor_bounds() -> void:
	_gen.floor_size = Vector2(80.0, 80.0)
	_gen.room_count = 5
	_gen.max_room_size = 10.0
	_gen.generate()

	for room in _gen.rooms:
		var r = room as DungeonRoom
		assert_gte(r.position.x, 0.0, "Room min_x should be >= 0")
		assert_gte(r.position.y, 0.0, "Room min_y should be >= 0")
		assert_lte(r.position.x + r.size.x, 80.0, "Room max_x should be <= floor_size.x")
		assert_lte(r.position.y + r.size.y, 80.0, "Room max_y should be <= floor_size.y")


# ── Theme Assignment ──────────────────────────────────────────────

func test_all_three_themes_used() -> void:
	_gen.room_count = 12
	_gen.generate()

	var themes := {}
	for room in _gen.rooms:
		var r = room as DungeonRoom
		themes[r.theme] = true
	assert_true(themes.has("cuisine"), "Should have at least one Cuisine room")
	assert_true(themes.has("boulangerie"), "Should have at least one Boulangerie room")
	assert_true(themes.has("rue"), "Should have at least one Rue room")


func test_theme_is_valid() -> void:
	_gen.generate()
	var valid_themes := ["cuisine", "boulangerie", "rue"]
	for room in _gen.rooms:
		var r = room as DungeonRoom
		assert_has(valid_themes, r.theme, "Theme '%s' should be valid" % r.theme)


# ── Spawn Points ──────────────────────────────────────────────────

func test_spawn_rooms_exist() -> void:
	_gen.generate()
	var start = _gen.start_room
	var boss = _gen.boss_room
	assert_not_null(start, "Start room should be assigned")
	assert_not_null(boss, "Boss room should be assigned")
	assert_true(start.is_start, "Start room should be marked as start")
	assert_true(boss.is_boss, "Boss room should be marked as boss")


func test_start_and_boss_are_different() -> void:
	_gen.room_count = 5
	_gen.generate()
	assert_ne(_gen.start_room, _gen.boss_room, "Start and boss rooms should be different")


# ── Connectivity ──────────────────────────────────────────────────

func test_all_rooms_connected() -> void:
	_gen.generate()

	var rooms: Array = _gen.rooms
	var room_ids := {}
	for i in range(rooms.size()):
		room_ids[rooms[i]] = i

	# Build adjacency list from corridors
	var adj: Array = []
	for _i in range(rooms.size()):
		adj.append([])

	for corr in _gen.corridors:
		var c = corr as DungeonCorridor
		var a := room_ids.get(c.from_room, -1)
		var b := room_ids.get(c.to_room, -1)
		if a >= 0 and b >= 0:
			adj[a].append(b)
			adj[b].append(a)

	# BFS from room 0
	var visited: Array = []
	for _i in range(rooms.size()):
		visited.append(false)
	var queue: Array = [0]
	visited[0] = true

	while not queue.is_empty():
		var current: int = queue.pop_front()
		for neighbor in adj[current]:
			if not visited[neighbor]:
				visited[neighbor] = true
				queue.append(neighbor)

	for vi in range(visited.size()):
		assert_true(visited[vi], "Room %d should be reachable from room 0" % vi)


func test_corridors_exist() -> void:
	_gen.generate()
	assert_gt(_gen.corridors.size(), 0, "Should generate at least one corridor")
	assert_lte(_gen.corridors.size(), _gen.rooms.size() * 2, "Corridor count should be reasonable")


# ── Configurable Parameters ───────────────────────────────────────

func test_different_seeds_different_layouts() -> void:
	_gen.seed = 42
	_gen.generate()
	var pos_42: Vector2 = (_gen.rooms[0] as DungeonRoom).position

	var gen2 = DungeonGenerator.new()
	gen2.floor_size = _gen.floor_size
	gen2.room_count = _gen.room_count
	gen2.min_room_size = _gen.min_room_size
	gen2.max_room_size = _gen.max_room_size
	gen2.corridor_width = _gen.corridor_width
	gen2.seed = 99
	add_child_autofree(gen2)
	gen2.generate()

	assert_ne((gen2.rooms[0] as DungeonRoom).position, pos_42,
		"Different seeds should produce different layouts")


func test_configurable_floor_size() -> void:
	var small_gen = DungeonGenerator.new()
	small_gen.floor_size = Vector2(30.0, 30.0)
	small_gen.room_count = 3
	small_gen.min_room_size = 4.0
	small_gen.max_room_size = 8.0
	small_gen.seed = 1
	add_child_autofree(small_gen)
	small_gen.generate()

	var large_gen = DungeonGenerator.new()
	large_gen.floor_size = Vector2(200.0, 200.0)
	large_gen.room_count = 3
	large_gen.min_room_size = 4.0
	large_gen.max_room_size = 8.0
	large_gen.seed = 1
	add_child_autofree(large_gen)
	large_gen.generate()

	assert_ne((small_gen.rooms[0] as DungeonRoom).position,
		(large_gen.rooms[0] as DungeonRoom).position,
		"Different floor sizes should yield different layouts with same seed")


# ── Room Dimensions ───────────────────────────────────────────────

func test_rooms_have_minimum_size() -> void:
	_gen.min_room_size = 5.0
	_gen.max_room_size = 15.0
	_gen.generate()

	for room in _gen.rooms:
		var r = room as DungeonRoom
		assert_gte(r.size.x, 5.0, "Room width should be >= min_room_size")
		assert_gte(r.size.y, 5.0, "Room height should be >= min_room_size")


func test_rooms_do_not_exceed_max_size() -> void:
	_gen.min_room_size = 3.0
	_gen.max_room_size = 10.0
	_gen.generate()

	for room in _gen.rooms:
		var r = room as DungeonRoom
		assert_lte(r.size.x, 10.0, "Room width should be <= max_room_size")
		assert_lte(r.size.y, 10.0, "Room height should be <= max_room_size")


# ── Room Centers ──────────────────────────────────────────────────

func test_room_center_is_correct() -> void:
	var room := DungeonRoom.new()
	room.position = Vector2(10.0, 20.0)
	room.size = Vector2(6.0, 4.0)

	var center := room.get_center()
	assert_eq(center.x, 13.0, "Center X should be position.x + size.x/2")
	assert_eq(center.y, 22.0, "Center Y should be position.y + size.y/2")


# ── Room Overlap Detection ───────────────────────────────────────

func test_room_overlap_detection() -> void:
	var a := DungeonRoom.new()
	a.position = Vector2(0.0, 0.0)
	a.size = Vector2(10.0, 10.0)

	var b := DungeonRoom.new()
	b.position = Vector2(5.0, 5.0)
	b.size = Vector2(10.0, 10.0)
	assert_true(a.overlaps(b), "Overlapping rooms should be detected")

	var c := DungeonRoom.new()
	c.position = Vector2(15.0, 0.0)
	c.size = Vector2(5.0, 5.0)
	assert_false(a.overlaps(c), "Non-overlapping rooms should not overlap")


func test_room_overlap_same_position() -> void:
	var a := DungeonRoom.new()
	a.position = Vector2(5.0, 5.0)
	a.size = Vector2(8.0, 8.0)

	var b := DungeonRoom.new()
	b.position = Vector2(5.0, 5.0)
	b.size = Vector2(8.0, 8.0)

	assert_true(a.overlaps(b), "Same position should be overlapping")


# ── Corridor Path Points ─────────────────────────────────────────

func test_corridor_has_path_points() -> void:
	_gen.generate()
	for corr in _gen.corridors:
		var c = corr as DungeonCorridor
		assert_gt(c.path_points.size(), 0, "Each corridor should have path points")


# ── Edge Cases ────────────────────────────────────────────────────

func test_single_room() -> void:
	var gen = DungeonGenerator.new()
	gen.floor_size = Vector2(50.0, 50.0)
	gen.room_count = 1
	gen.min_room_size = 5.0
	gen.max_room_size = 10.0
	gen.seed = 7
	add_child_autofree(gen)
	gen.generate()

	assert_eq(gen.rooms.size(), 1, "Should generate exactly 1 room")
	assert_eq(gen.corridors.size(), 0, "Single room should have no corridors")
	assert_not_null(gen.start_room, "Start room should still be assigned")


func test_generate_is_idempotent() -> void:
	_gen.generate()
	var room_count: int = _gen.rooms.size()
	var corr_count: int = _gen.corridors.size()

	_gen.generate()
	assert_eq(_gen.rooms.size(), room_count, "Second generate should not add rooms")
	assert_eq(_gen.corridors.size(), corr_count, "Second generate should not add corridors")
