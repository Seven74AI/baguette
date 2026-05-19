class_name PainAuChocolatLauncher
extends Node3D
## Pain au Chocolat Launcher — explosive pastry weapon.
## Arc projectile with AoE splash. 3 ammo, 2.5s reload.
## FIRE + SLASH damage types. 60 direct + 30 splash damage.

signal fired(ammo_remaining: int)
signal reloaded(ammo_remaining: int)
signal ammo_depleted

@export var damage: int = 60
@export var splash_damage: int = 30
@export var splash_radius: float = 3.0
@export var damage_types: Array = [3, 1]  ## FIRE=3, SLASH=1
@export var max_ammo: int = 3
@export var reload_time: float = 2.5

var _current_ammo: int = 0
var _can_fire: bool = true
var _is_reloading: bool = false


func _ready() -> void:
	_current_ammo = max_ammo


func fire() -> void:
	if not _can_fire or _is_reloading:
		return
	if _current_ammo <= 0:
		ammo_depleted.emit()
		return
	_current_ammo -= 1
	fired.emit(_current_ammo)


func reload() -> void:
	if _is_reloading or _current_ammo >= max_ammo:
		return
	_current_ammo = max_ammo
	reloaded.emit(_current_ammo)


func get_ammo_count() -> int:
	return _current_ammo


func get_max_ammo() -> int:
	return max_ammo


func is_reloading() -> bool:
	return _is_reloading
