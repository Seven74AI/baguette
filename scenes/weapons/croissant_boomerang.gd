class_name CroissantBoomerang
extends Node3D
## Croissant Boomerang — throw a croissant projectile that flies in an arc, hits enemies, and returns.
## Only one projectile active at a time.

signal thrown
signal returned
signal hit_enemy(enemy: Node)

@export var damage: int = 35
@export var throw_speed: float = 15.0
@export var max_range: float = 25.0
@export var return_speed: float = 20.0

var _is_ready: bool = true
var _active_projectile: Node = null


func _ready() -> void:
	_is_ready = true


func fire() -> void:
	if not _is_ready:
		return
	if _active_projectile:
		return
	
	_is_ready = false
	
	# Throw recoil animation
	_play_throw_animation()
	
	# Create the projectile — use runtime load to avoid circular preload
	var ProjectileScene: PackedScene = load("res://scenes/weapons/croissant_projectile.tscn")
	var projectile: Node = ProjectileScene.instantiate()
	projectile.set("damage", damage)
	projectile.set("throw_speed", throw_speed)
	projectile.set("max_range", max_range)
	projectile.set("return_speed", return_speed)
	projectile.connect("projectile_returned", _on_projectile_returned)
	
	add_child(projectile)
	_active_projectile = projectile
	thrown.emit()


func _play_throw_animation() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.7, 0.7, 0.7), 0.1)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.15)


func get_is_ready() -> bool:
	return _is_ready


func _on_projectile_returned() -> void:
	if _active_projectile:
		_active_projectile.queue_free()
		_active_projectile = null
	_is_ready = true
	
	# Catch animation — quick scale pulse
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(1.1, 1.1, 1.1), 0.08)
	tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.12)
	
	returned.emit()
