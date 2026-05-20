class_name PistoletEncre
extends Node3D
## Pistolet à Encre — semi-auto hitscan that applies a stacking DoT debuff.
## "Mauvaise critique" debuff: 2 damage/sec for 5s, stacks up to 3x (6/sec).
## 15 direct damage, 8 ammo, 2s reload. INK damage type.

signal fired(ammo_remaining: int)
signal reloaded(ammo_remaining: int)
signal ammo_depleted

@export_category("Weapon Stats")
@export var damage: int = 15
@export var dot_total_damage: int = 10       ## Total DoT damage over the duration
@export var dot_duration: float = 5.0        ## Duration of the debuff in seconds
@export var dot_damage_per_second: float = 2.0  ## Damage per second per stack
@export var max_debuff_stacks: int = 3       ## Max stacks of the debuff
@export var max_ammo: int = 8
@export var reload_time: float = 2.0
@export var fire_rate: float = 0.4           ## Seconds between shots
@export var max_range: float = 100.0
@export var damage_types: Array = [5]        ## INK
@export var debuff_name: String = "Mauvaise critique"

@onready var _raycast: RayCast3D = $RayCast3D
@onready var _fire_timer: Timer = $FireTimer
@onready var _reload_timer: Timer = $ReloadTimer

var _current_ammo: int = 0
var _can_fire: bool = true
var _is_reloading: bool = false


func _ready() -> void:
	_current_ammo = max_ammo
	if _fire_timer:
		_fire_timer.wait_time = fire_rate
		_fire_timer.one_shot = true


func fire() -> void:
	if not _can_fire or _is_reloading:
		return
	if _current_ammo <= 0:
		ammo_depleted.emit()
		return

	_can_fire = false
	_current_ammo -= 1

	# Perform hitscan
	if _raycast:
		_raycast.force_raycast_update()
		if _raycast.is_colliding():
			var collider: Node = _raycast.get_collider()
			var hit_point: Vector3 = _raycast.get_collision_point()
			_apply_damage(collider, hit_point)

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


func _apply_damage(target: Node, hit_point: Vector3) -> void:
	# Apply direct damage
	var applied := false
	if target.has_method("take_damage"):
		target.take_damage(damage, get_parent(), damage_types[0])
		applied = true
	elif target.get_parent() and target.get_parent().has_method("take_damage"):
		target.get_parent().take_damage(damage, get_parent(), damage_types[0])
		applied = true

	# Apply DoT debuff if target has a debuff method
	if applied:
		_apply_debuff(target)


func _apply_debuff(target: Node) -> void:
	# Apply the "Mauvaise critique" debuff
	var dot_data := get_debuff_data()
	var actual_target: Node = target
	if not target.has_method("apply_debuff") and target.get_parent() and target.get_parent().has_method("apply_debuff"):
		actual_target = target.get_parent()

	if actual_target.has_method("apply_debuff"):
		actual_target.apply_debuff(dot_data)


func get_debuff_data() -> Dictionary:
	return {
		"name": debuff_name,
		"damage_per_second": dot_damage_per_second,
		"duration": dot_duration,
		"max_stacks": max_debuff_stacks,
	}


func get_ammo_count() -> int:
	return _current_ammo


func get_max_ammo() -> int:
	return max_ammo


func is_reloading() -> bool:
	return _is_reloading
