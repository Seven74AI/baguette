class_name PlayerAnimator
extends Node
## Animates the MITCH player model based on player state.
## Controls AnimationPlayer with 6 states: idle, walk, sprint, shoot, dash, death.
## Attach as child of the Player CharacterBody3D.

## The AnimationPlayer node to control
@export var animation_player: AnimationPlayer

## The target Node3D (Model node) to animate transforms on
@export var target: Node3D

const IDLE_NAME := "idle"
const WALK_NAME := "walk"
const SPRINT_NAME := "sprint"
const SHOOT_NAME := "shoot"
const DASH_NAME := "dash"
const DEATH_NAME := "death"


func _ready() -> void:
	if not animation_player:
		animation_player = _find_animation_player()
	if not target:
		target = _find_target()
	_setup_animations()


func _find_animation_player() -> AnimationPlayer:
	var parent := get_parent()
	if parent:
		var ap := parent.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if ap:
			return ap
	return null


func _find_target() -> Node3D:
	var parent := get_parent()
	if parent:
		var model := parent.get_node_or_null("Model") as Node3D
		if model:
			return model
	return null


## Create all 6 animation tracks programmatically.
func _setup_animations() -> void:
	if not animation_player or not target:
		return

	# Clear any existing animations
	var lib := animation_player.get_animation_library("")
	if not lib:
		lib = AnimationLibrary.new()
		animation_player.add_animation_library("", lib)

	_create_idle_animation(lib)
	_create_walk_animation(lib)
	_create_sprint_animation(lib)
	_create_shoot_animation(lib)
	_create_dash_animation(lib)
	_create_death_animation(lib)


func _create_idle_animation(lib: AnimationLibrary) -> void:
	var anim := Animation.new()
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR

	# Gentle breathing — slight Y oscillation on target position
	var track_idx := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(track_idx, ".")

	var base_pos := target.position if target else Vector3.ZERO
	anim.position_track_insert_key(track_idx, 0.0, base_pos)
	anim.position_track_insert_key(track_idx, 0.5, base_pos + Vector3(0, 0.02, 0))
	anim.position_track_insert_key(track_idx, 1.0, base_pos)
	anim.position_track_insert_key(track_idx, 1.5, base_pos + Vector3(0, 0.02, 0))
	anim.position_track_insert_key(track_idx, 2.0, base_pos)

	# Slight scale oscillation for breathing
	var scale_track := anim.add_track(Animation.TYPE_SCALE_3D)
	anim.track_set_path(scale_track, ".")
	anim.scale_track_insert_key(scale_track, 0.0, Vector3.ONE)
	anim.scale_track_insert_key(scale_track, 0.5, Vector3(1.0, 1.03, 1.0))
	anim.scale_track_insert_key(scale_track, 1.0, Vector3.ONE)
	anim.scale_track_insert_key(scale_track, 1.5, Vector3(1.0, 1.03, 1.0))
	anim.scale_track_insert_key(scale_track, 2.0, Vector3.ONE)

	lib.add_animation(IDLE_NAME, anim)


func _create_walk_animation(lib: AnimationLibrary) -> void:
	var anim := Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR

	var base_pos := target.position if target else Vector3.ZERO

	# Walk bob — vertical oscillation
	var track_idx := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(track_idx, ".")
	anim.position_track_insert_key(track_idx, 0.0, base_pos)
	anim.position_track_insert_key(track_idx, 0.25, base_pos + Vector3(0, 0.04, 0))
	anim.position_track_insert_key(track_idx, 0.5, base_pos)
	anim.position_track_insert_key(track_idx, 0.75, base_pos - Vector3(0, 0.04, 0))
	anim.position_track_insert_key(track_idx, 1.0, base_pos)

	# Slight side-to-side sway for walking
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, ".")
	anim.rotation_track_insert_key(rot_track, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(rot_track, 0.25, Quaternion(Vector3.UP, deg_to_rad(3.0)))
	anim.rotation_track_insert_key(rot_track, 0.5, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(rot_track, 0.75, Quaternion(Vector3.UP, deg_to_rad(-3.0)))
	anim.rotation_track_insert_key(rot_track, 1.0, Quaternion.IDENTITY)

	lib.add_animation(WALK_NAME, anim)


func _create_sprint_animation(lib: AnimationLibrary) -> void:
	var anim := Animation.new()
	anim.length = 0.6
	anim.loop_mode = Animation.LOOP_LINEAR

	var base_pos := target.position if target else Vector3.ZERO

	# Faster, bigger bob
	var track_idx := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(track_idx, ".")
	anim.position_track_insert_key(track_idx, 0.0, base_pos)
	anim.position_track_insert_key(track_idx, 0.15, base_pos + Vector3(0, 0.06, 0))
	anim.position_track_insert_key(track_idx, 0.3, base_pos)
	anim.position_track_insert_key(track_idx, 0.45, base_pos - Vector3(0, 0.06, 0))
	anim.position_track_insert_key(track_idx, 0.6, base_pos)

	# Forward lean for sprint
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, ".")
	anim.rotation_track_insert_key(rot_track, 0.0, Quaternion(Vector3.RIGHT, deg_to_rad(10.0)))
	anim.rotation_track_insert_key(rot_track, 0.3, Quaternion(Vector3.RIGHT, deg_to_rad(12.0)))
	anim.rotation_track_insert_key(rot_track, 0.6, Quaternion(Vector3.RIGHT, deg_to_rad(10.0)))

	lib.add_animation(SPRINT_NAME, anim)


func _create_shoot_animation(lib: AnimationLibrary) -> void:
	var anim := Animation.new()
	anim.length = 0.3
	anim.loop_mode = Animation.LOOP_NONE

	var base_pos := target.position if target else Vector3.ZERO

	# Quick recoil — push back slightly then return
	var track_idx := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(track_idx, ".")
	anim.position_track_insert_key(track_idx, 0.0, base_pos)
	anim.position_track_insert_key(track_idx, 0.05, base_pos + Vector3(0, 0.02, -0.08))
	anim.position_track_insert_key(track_idx, 0.2, base_pos + Vector3(0, 0.0, -0.02))
	anim.position_track_insert_key(track_idx, 0.3, base_pos)

	# Tilt up slightly
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, ".")
	anim.rotation_track_insert_key(rot_track, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(rot_track, 0.05, Quaternion(Vector3.RIGHT, deg_to_rad(-5.0)))
	anim.rotation_track_insert_key(rot_track, 0.3, Quaternion.IDENTITY)

	lib.add_animation(SHOOT_NAME, anim)


func _create_dash_animation(lib: AnimationLibrary) -> void:
	var anim := Animation.new()
	anim.length = 0.2
	anim.loop_mode = Animation.LOOP_NONE

	var base_pos := target.position if target else Vector3.ZERO

	# Lean forward during dash
	var track_idx := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(track_idx, ".")
	anim.position_track_insert_key(track_idx, 0.0, base_pos)
	anim.position_track_insert_key(track_idx, 0.1, base_pos + Vector3(0, -0.05, 0.15))
	anim.position_track_insert_key(track_idx, 0.2, base_pos)

	# Forward rotation (lean into dash)
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, ".")
	anim.rotation_track_insert_key(rot_track, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(rot_track, 0.05, Quaternion(Vector3.RIGHT, deg_to_rad(20.0)))
	anim.rotation_track_insert_key(rot_track, 0.2, Quaternion.IDENTITY)

	# Scale stretch effect
	var scale_track := anim.add_track(Animation.TYPE_SCALE_3D)
	anim.track_set_path(scale_track, ".")
	anim.scale_track_insert_key(scale_track, 0.0, Vector3.ONE)
	anim.scale_track_insert_key(scale_track, 0.05, Vector3(0.85, 1.1, 1.15))
	anim.scale_track_insert_key(scale_track, 0.2, Vector3.ONE)

	lib.add_animation(DASH_NAME, anim)


func _create_death_animation(lib: AnimationLibrary) -> void:
	var anim := Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_NONE

	var base_pos := target.position if target else Vector3.ZERO

	# Collapse — fall down and backward
	var track_idx := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(track_idx, ".")
	anim.position_track_insert_key(track_idx, 0.0, base_pos)
	anim.position_track_insert_key(track_idx, 0.3, base_pos + Vector3(0, -0.3, -0.1))
	anim.position_track_insert_key(track_idx, 0.7, base_pos + Vector3(0, -0.9, -0.2))
	anim.position_track_insert_key(track_idx, 1.0, base_pos + Vector3(0, -0.9, -0.2))

	# Rotation — fall backward
	var rot_track := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(rot_track, ".")
	anim.rotation_track_insert_key(rot_track, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(rot_track, 0.3, Quaternion(Vector3.RIGHT, deg_to_rad(30.0)))
	anim.rotation_track_insert_key(rot_track, 0.7, Quaternion(Vector3.RIGHT, deg_to_rad(85.0)))
	anim.rotation_track_insert_key(rot_track, 1.0, Quaternion(Vector3.RIGHT, deg_to_rad(85.0)))

	lib.add_animation(DEATH_NAME, anim)


# ── Playback API ──

## Play the idle animation (gentle breathing sway).
func play_idle() -> void:
	if animation_player and animation_player.has_animation(IDLE_NAME):
		animation_player.play(IDLE_NAME)


## Play the walk animation.
func play_walk() -> void:
	if animation_player and animation_player.has_animation(WALK_NAME):
		animation_player.play(WALK_NAME)


## Play the sprint animation.
func play_sprint() -> void:
	if animation_player and animation_player.has_animation(SPRINT_NAME):
		animation_player.play(SPRINT_NAME)


## Play the shoot animation (recoil).
func play_shoot() -> void:
	if animation_player and animation_player.has_animation(SHOOT_NAME):
		animation_player.play(SHOOT_NAME)


## Play the dash animation (lean + trail).
func play_dash() -> void:
	if animation_player and animation_player.has_animation(DASH_NAME):
		animation_player.play(DASH_NAME)


## Play the death animation (collapse).
func play_death() -> void:
	if animation_player and animation_player.has_animation(DEATH_NAME):
		animation_player.play(DEATH_NAME)
