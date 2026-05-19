class_name PainChocolatProjectile
extends Node3D
## Pain au Chocolat Projectile — arc-trajectory explosive pastry.
## Flies in a gravity-affected arc, explodes on impact with AoE splash.

signal exploded(position: Vector3)

@export var damage: int = 60
@export var splash_damage: int = 30
@export var splash_radius: float = 3.0
@export var gravity_scale: float = 1.0
@export var launch_speed: float = 20.0

var _velocity: Vector3 = Vector3.ZERO
var _has_exploded: bool = false


func _physics_process(delta: float) -> void:
	if _has_exploded:
		return
	# Gravity
	_velocity.y -= 9.8 * gravity_scale * delta
	position += _velocity * delta


func explode() -> void:
	if _has_exploded:
		return
	_has_exploded = true
	exploded.emit(global_position)
