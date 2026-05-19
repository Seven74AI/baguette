extends RefCounted
## Dungeon room data — position, size, theme, and overlap detection.
## Pure data class, no scene tree dependency.

var position: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2.ZERO
var theme: String = "cuisine"
var is_start: bool = false
var is_boss: bool = false


## Returns true if this room overlaps with `other` (AABB overlap on XZ plane).
## Uses padding to ensure rooms are separated by at least a gap.
func overlaps(other, padding: float = 1.0) -> bool:
	var a_min: Vector2 = position
	var a_max: Vector2 = position + size
	var b_min: Vector2 = other.position
	var b_max: Vector2 = other.position + other.size

	# Expand bounding boxes by half padding on each side
	var half_pad: Vector2 = Vector2(padding * 0.5, padding * 0.5)
	a_min -= half_pad
	a_max += half_pad
	b_min -= half_pad
	b_max += half_pad

	if a_max.x <= b_min.x or b_max.x <= a_min.x:
		return false
	if a_max.y <= b_min.y or b_max.y <= a_min.y:
		return false
	return true


## Returns the center point of the room (position + size/2).
func get_center() -> Vector2:
	return position + size * 0.5
