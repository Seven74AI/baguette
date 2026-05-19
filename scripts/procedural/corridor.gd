extends RefCounted
## Corridor connecting two rooms with L-shaped path points.
## Pure data class, no scene tree dependency.

var from_room = null  # DungeonRoom
var to_room = null    # DungeonRoom
var path_points: Array = []  # Array[Vector2] — path from center of from_room to to_room


## Build an L-shaped path between two room centers.
func build_path() -> void:
	path_points.clear()
	if from_room == null or to_room == null:
		return

	var start: Vector2 = from_room.get_center()
	var end: Vector2 = to_room.get_center()
	path_points.append(start)

	# L-shaped: go horizontal then vertical
	var corner: Vector2 = Vector2(end.x, start.y)
	path_points.append(corner)
	path_points.append(end)
