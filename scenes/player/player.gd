extends CharacterBody3D
## FPS Player controller — CharacterBody3D with mouse look, WASD movement, jump, dash.
## Attaches HealthComponent for damage. Camera3D child for first-person view.

const HealthComponent = preload("res://scripts/components/health_component.gd")

@export_category("Movement")
@export var walk_speed: float = 8.0
@export var sprint_speed: float = 12.0
@export var dash_speed: float = 24.0
@export var acceleration: float = 20.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 18.0

@export_category("Dash")
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

@export_category("Walk Bob")
@export var bob_frequency: float = 8.0
@export var bob_amplitude: float = 0.03
@export var bob_speed_factor: float = 0.5

@export_category("Look")
@export var mouse_sensitivity: float = 0.002
@export var look_up_limit: float = deg_to_rad(85.0)
@export var look_down_limit: float = deg_to_rad(-85.0)

@export_category("Components")
@export var health_component: HealthComponent

@onready var _camera: Camera3D = $Camera3D
@onready var _weapon_mount: Node3D = $Camera3D/WeaponMount
@onready var _head_collision: CollisionShape3D = $HeadCollision

var _weapon: Node = null
var _mouse_captured: bool = true
var _look_rotation: Vector2 = Vector2.ZERO

# Dash state
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _base_fov: float = 90.0

# Walk bob state
var _bob_time: float = 0.0
var _camera_original_y: float = 1.7


func _ready() -> void:
	# Try to capture mouse — may fail in headless mode (display server limitation)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Fallback: if headless server rejected capture, mark as not captured
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		_mouse_captured = false
	if not health_component:
		health_component = $HealthComponent
	
	# Find the weapon child (attached by level script)
	if _weapon_mount and _weapon_mount.get_child_count() > 0:
		_weapon = _weapon_mount.get_child(0)
	
	_base_fov = _camera.fov


func _input(event: InputEvent) -> void:
	# Toggle mouse capture with Escape
	if event.is_action_pressed("pause"):
		_mouse_captured = not _mouse_captured
		Input.set_mouse_mode(
			Input.MOUSE_MODE_CAPTURED if _mouse_captured else Input.MOUSE_MODE_VISIBLE
		)
	
	# Mouse look
	if event is InputEventMouseMotion and _mouse_captured:
		_look_rotation.x -= event.relative.x * mouse_sensitivity
		_look_rotation.y -= event.relative.y * mouse_sensitivity
		_look_rotation.y = clamp(_look_rotation.y, look_down_limit, look_up_limit)
		
		# Horizontal rotation: rotate the player body
		rotation.y = _look_rotation.x
		# Vertical rotation: rotate the camera only
		_camera.rotation.x = _look_rotation.y
	
	# Weapon fire
	if event.is_action_pressed("shoot") and _mouse_captured and _weapon:
		if _weapon.has_method("fire"):
			_weapon.fire()
	
	# Weapon reload
	if event.is_action_pressed("reload") and _weapon:
		if _weapon.has_method("reload"):
			_weapon.reload()


func _physics_process(delta: float) -> void:
	# Update dash state
	_update_dash(delta)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Movement input (relative to player orientation)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if _is_dashing:
		# During dash, maintain dash direction at dash speed
		velocity.x = _dash_direction.x * dash_speed
		velocity.z = _dash_direction.z * dash_speed
	else:
		var target_speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
		var target_velocity := direction * target_speed
		
		# Smooth acceleration
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	
	move_and_slide()
	
	# Walk bob — oscillate camera vertically when moving on floor
	_update_walk_bob(delta, direction.length())


func _update_walk_bob(delta: float, input_strength: float) -> void:
	if not is_on_floor() or input_strength < 0.05 or _is_dashing:
		# Return camera to original position smoothly
		if _camera:
			_camera.position.y = move_toward(_camera.position.y, _camera_original_y, delta * 4.0)
		_bob_time = 0.0
		return
	
	var current_speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	var bob_speed := current_speed * bob_speed_factor
	_bob_time += delta * bob_speed
	
	var bob_offset := sin(_bob_time * bob_frequency) * bob_amplitude * input_strength
	if _camera:
		_camera.position.y = _camera_original_y + bob_offset


func _update_dash(delta: float) -> void:
	# Cooldown timer
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta
	
	# Dash timer
	if _is_dashing:
		_dash_timer -= delta
		# FOV boost during dash
		if _camera:
			_camera.fov = lerp(_base_fov + 10.0, _base_fov, 1.0 - (_dash_timer / dash_duration))
		if _dash_timer <= 0.0:
			_is_dashing = false
			if _camera:
				_camera.fov = _base_fov
		return
	
	# Start dash
	if Input.is_action_just_pressed("dash") and _dash_cooldown_timer <= 0.0:
		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		# If no movement input, dash forward
		if direction.length() < 0.1:
			direction = -transform.basis.z.normalized()
		
		_dash_direction = direction
		_is_dashing = true
		_dash_timer = dash_duration
		_dash_cooldown_timer = dash_cooldown
		
		# PHASE 3 polish: dash sound
		if SoundManager:
			SoundManager.play_dash_sound()


func get_camera() -> Camera3D:
	return _camera


func get_weapon_mount() -> Node3D:
	return _weapon_mount


func take_damage(amount: int, source: Node = null) -> void:
	if health_component:
		health_component.take_damage(amount, source)


func is_dashing() -> bool:
	return _is_dashing


## Called by level script to link weapon after it's attached
func link_weapon(weapon: Node) -> void:
	_weapon = weapon
