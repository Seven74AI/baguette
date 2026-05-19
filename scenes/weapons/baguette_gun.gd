class_name BaguetteGun
extends Node3D
## Baguette Gun — the player's starting weapon.
## Hitscan (RayCast3D) with visual tracer. 6 shots, manual reload.

signal fired(ammo_remaining: int)
signal reloaded(ammo_remaining: int)
signal ammo_depleted

@export_category("Weapon Stats")
@export var damage: int = 25
@export var damage_type: int = 0   ## DamageTypes.NONE by default; set to SLASH/BLUNT/FIRE/OVEN
@export var max_ammo: int = 6
@export var fire_rate: float = 0.5   ## seconds between shots
@export var reload_time: float = 1.5  ## seconds to reload
@export var max_range: float = 100.0

@export_category("Effects")
@export var tracer_length: float = 50.0
@export var tracer_duration: float = 0.05

@onready var _raycast: RayCast3D = $RayCast3D
@onready var _fire_timer: Timer = $FireTimer
@onready var _reload_timer: Timer = $ReloadTimer
@onready var _muzzle_flash: MeshInstance3D = $MuzzleFlash

var _current_ammo: int = 0
var _can_fire: bool = true
var _is_reloading: bool = false


func _ready() -> void:
	_current_ammo = max_ammo
	if _fire_timer:
		_fire_timer.wait_time = fire_rate


func fire() -> void:
	if not _can_fire or _is_reloading:
		return
	if _current_ammo <= 0:
		ammo_depleted.emit()
		return
	
	_can_fire = false
	_current_ammo -= 1
	
	# Perform hitscan
	_raycast.force_raycast_update()
	if _raycast.is_colliding():
		var collider: Node = _raycast.get_collider()
		var hit_point: Vector3 = _raycast.get_collision_point()
		_apply_damage(collider, hit_point)
	else:
		pass  # Miss — tracer to max range
	
	# Show muzzle flash
	if _muzzle_flash:
		_muzzle_flash.visible = true
		await get_tree().create_timer(tracer_duration).timeout
		if _muzzle_flash:
			_muzzle_flash.visible = false
	
	fired.emit(_current_ammo)
	
	# Fire rate cooldown
	if _fire_timer:
		_fire_timer.start()
		await _fire_timer.timeout
	_can_fire = true


func reload() -> void:
	if _is_reloading or _current_ammo >= max_ammo:
		return
	
	_is_reloading = true
	_can_fire = false
	
	if _reload_timer:
		_reload_timer.wait_time = reload_time
		_reload_timer.start()
		await _reload_timer.timeout
	
	_current_ammo = max_ammo
	_is_reloading = false
	_can_fire = true
	reloaded.emit(_current_ammo)


func _apply_damage(target: Node, _hit_point: Vector3) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, get_parent(), damage_type)
	elif target.get_parent() and target.get_parent().has_method("take_damage"):
		target.get_parent().take_damage(damage, get_parent(), damage_type)


func get_ammo_count() -> int:
	return _current_ammo


func get_max_ammo() -> int:
	return max_ammo


func is_reloading() -> bool:
	return _is_reloading
