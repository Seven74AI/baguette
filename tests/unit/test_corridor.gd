extends "res://addons/gut/test.gd"
## Unit tests for DungeonCorridor — verifies L-shaped path building between rooms.

const DungeonCorridor = preload("res://scripts/procedural/corridor.gd")
const DungeonRoom = preload("res://scripts/procedural/room.gd")

var _corridor: DungeonCorridor
var _room_a: DungeonRoom
var _room_b: DungeonRoom


func before_each() -> void:
	_corridor = DungeonCorridor.new()
	_room_a = DungeonRoom.new()
	_room_a.position = Vector2(0.0, 0.0)
	_room_a.size = Vector2(10.0, 10.0)
	_room_b = DungeonRoom.new()
	_room_b.position = Vector2(30.0, 20.0)
	_room_b.size = Vector2(8.0, 8.0)


func test_corridor_has_from_room() -> void:
	_corridor.from_room = _room_a
	assert_eq(_corridor.from_room, _room_a, "from_room should be settable")


func test_corridor_has_to_room() -> void:
	_corridor.to_room = _room_b
	assert_eq(_corridor.to_room, _room_b, "to_room should be settable")


func test_path_points_starts_empty() -> void:
	assert_eq(_corridor.path_points.size(), 0, "path_points should start empty")


func test_build_path_creates_l_shaped_path() -> void:
	_corridor.from_room = _room_a
	_corridor.to_room = _room_b
	_corridor.build_path()

	assert_eq(_corridor.path_points.size(), 3, "L-shaped path should have 3 points")
	# start point = center of room_a
	assert_eq(_corridor.path_points[0], _room_a.get_center(), "First point should be from_room center")
	# end point = center of room_b
	assert_eq(_corridor.path_points[2], _room_b.get_center(), "Last point should be to_room center")
	# corner = L-bend: horizontal from start, vertical to end
	var corner: Vector2 = _corridor.path_points[1]
	assert_eq(corner.x, _room_b.get_center().x, "Corner X should match end X (horizontal first)")
	assert_eq(corner.y, _room_a.get_center().y, "Corner Y should match start Y (vertical second)")


func test_build_path_null_rooms_does_nothing() -> void:
	_corridor.build_path()
	assert_eq(_corridor.path_points.size(), 0, "Should have empty path when rooms are null")

	_corridor.from_room = _room_a
	_corridor.to_room = null
	_corridor.build_path()
	assert_eq(_corridor.path_points.size(), 0, "Should have empty path when to_room is null")

	_corridor.from_room = null
	_corridor.to_room = _room_b
	_corridor.build_path()
	assert_eq(_corridor.path_points.size(), 0, "Should have empty path when from_room is null")


func test_build_path_idempotent() -> void:
	_corridor.from_room = _room_a
	_corridor.to_room = _room_b
	_corridor.build_path()
	var count := _corridor.path_points.size()
	_corridor.build_path()
	assert_eq(_corridor.path_points.size(), count, "Second build should have same point count")
	assert_eq(_corridor.path_points[0], _room_a.get_center(), "Points should be same after second build")


func test_build_path_different_positions() -> void:
	# Test with rooms at different positions
	_room_a.position = Vector2(5.0, 5.0)
	_room_a.size = Vector2(6.0, 6.0)
	_room_b.position = Vector2(50.0, 10.0)
	_room_b.size = Vector2(4.0, 4.0)

	_corridor.from_room = _room_a
	_corridor.to_room = _room_b
	_corridor.build_path()

	assert_eq(_corridor.path_points.size(), 3, "L-shaped path should have 3 points")
	assert_eq(_corridor.path_points[0], Vector2(8.0, 8.0), "Start should be room_a center")
	assert_eq(_corridor.path_points[2], Vector2(52.0, 12.0), "End should be room_b center")
	var corner: Vector2 = _corridor.path_points[1]
	assert_eq(corner.x, 52.0, "Corner X = end.x")
	assert_eq(corner.y, 8.0, "Corner Y = start.y")
