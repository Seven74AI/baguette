class_name CroissantProjectile
extends Node3D
## Croissant Projectile — the flying projectile for the CroissantBoomerang weapon.
## Moves forward, hits enemies via Area3D, returns after max_range.

signal projectile_returned
signal hit_something(target: Node)

@export var damage: int = 35
@export var throw_speed: float = 15.0
@export var max_range: float = 25.0
@export var return_speed: float = 20.0
@export var spin_speed: float = 10.0  ## Radians per second rotation

var _distance_traveled: float = 0.0
var _is_returning: bool = false
var _origin_position: Vector3 = Vector3.ZERO
var _throw_direction: Vector3 = Vector3.FORWARD
var _spin_axis: Vector3 = Vector3(0, 1, 0).normalized()


func _ready() -> void:
	_origin_position = global_position
	# Use the parent's forward direction (or default to -Z for Godot)
	if get_parent():
		_throw_direction = -get_parent().global_transform.basis.z
	else:
		_throw_direction = Vector3.FORWARD


func _physics_process(delta: float) -> void:
	if _is_returning:
		_return_to_origin(delta)
	else:
		_move_forward(delta)
	rotate(_spin_axis, spin_speed * delta)


func _move_forward(delta: float) -> void:
	var step: float = throw_speed * delta
	_distance_traveled += step
	
	if _distance_traveled >= max_range:
		# Start returning
		_is_returning = true
		# Clamp to max range
		var overshoot: float = _distance_traveled - max_range
		global_position -= _throw_direction * overshoot * 0.5
		return
	
	global_position += _throw_direction * step


func _return_to_origin(delta: float) -> void:
	var to_origin: Vector3 = _origin_position - global_position
	var step: float = return_speed * delta
	
	if to_origin.length() <= step:
		# Arrived back
		global_position = _origin_position
		projectile_returned.emit()
	else:
		global_position += to_origin.normalized() * step


## Called by the Area3D when something enters the hit area.
func _on_hit_area_entered(body: Node3D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, get_parent())
		hit_something.emit(body)
