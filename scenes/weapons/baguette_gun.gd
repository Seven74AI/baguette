class_name BaguetteGun
extends Node3D
## Baguette Gun — the player's starting weapon.
## Hitscan (RayCast3D) with visual tracer. 6 shots, manual reload.
## PHASE 3: Added Tween-based recoil animation.

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

@export_category("Recoil")
@export var recoil_strength: float = 0.08   ## How far the weapon kicks back (meters)
@export var recoil_recovery: float = 0.15    ## Seconds to return to original position

@onready var _raycast: RayCast3D = $RayCast3D
@onready var _fire_timer: Timer = $FireTimer
@onready var _reload_timer: Timer = $ReloadTimer
@onready var _muzzle_flash: MeshInstance3D = $MuzzleFlash
@onready var _weapon_model: MeshInstance3D = $WeaponModel

var _current_ammo: int = 0
var _can_fire: bool = true
var _is_reloading: bool = false
var _original_position: Vector3 = Vector3.ZERO
var _recoil_tween: Tween


func _ready() -> void:
	_current_ammo = max_ammo
	_original_position = position
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
	
	# PHASE 3 polish: spawn muzzle particles + play shoot sound
	if EffectsManager:
		EffectsManager.spawn_muzzle_flash(global_position, -global_transform.basis.z)
	if SoundManager:
		SoundManager.play_shoot_sound()
	
	# Apply recoil animation
	apply_recoil()
	
	fired.emit(_current_ammo)
	
	# Fire rate cooldown
	if _fire_timer:
		_fire_timer.start()
		await _fire_timer.timeout
	_can_fire = true


func apply_recoil() -> void:
	# Kill any existing recoil tween
	if _recoil_tween and _recoil_tween.is_valid():
		_recoil_tween.kill()
	
	_recoil_tween = create_tween()
	# Kick backward (negative Z in local space)
	var recoil_target := _original_position + Vector3(0, recoil_strength * 0.3, recoil_strength)
	_recoil_tween.tween_property(self, "position", recoil_target, 0.03)
	# Return to original
	_recoil_tween.tween_property(self, "position", _original_position, recoil_recovery).set_ease(Tween.EASE_OUT)


func reload() -> void:
	if _is_reloading or _current_ammo >= max_ammo:
		return
	
	_is_reloading = true
	_can_fire = false
	
	# PHASE 3 polish: reload sound
	if SoundManager:
		SoundManager.play_reload_sound()
	
	if _reload_timer:
		_reload_timer.wait_time = reload_time
		_reload_timer.start()
		await _reload_timer.timeout
	
	_current_ammo = max_ammo
	_is_reloading = false
	_can_fire = true
	reloaded.emit(_current_ammo)


func _apply_damage(target: Node, hit_point: Vector3) -> void:
	# PHASE 3 polish: spawn impact particles at hit point
	if EffectsManager:
		EffectsManager.spawn_impact_flour(hit_point, Vector3.UP)
	if SoundManager:
		SoundManager.play_hit_sound()
	
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
