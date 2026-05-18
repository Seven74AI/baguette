extends CharacterBody3D
## FPS Player controller — CharacterBody3D with mouse look, WASD movement, jump.
## Attaches HealthComponent for damage. Camera3D child for first-person view.

const HealthComponent = preload("res://scripts/components/health_component.gd")

@export_category("Movement")
@export var walk_speed: float = 8.0
@export var sprint_speed: float = 12.0
@export var acceleration: float = 20.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 18.0

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


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if not health_component:
		health_component = $HealthComponent
	
	# Find the weapon child (attached by level script)
	if _weapon_mount and _weapon_mount.get_child_count() > 0:
		_weapon = _weapon_mount.get_child(0)


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
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Movement input (relative to player orientation)
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var target_speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	var target_velocity := direction * target_speed
	
	# Smooth acceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	
	move_and_slide()


func get_camera() -> Camera3D:
	return _camera


func get_weapon_mount() -> Node3D:
	return _weapon_mount


func take_damage(amount: int, source: Node = null) -> void:
	if health_component:
		health_component.take_damage(amount, source)


## Called by level script to link weapon after it's attached
func link_weapon(weapon: Node) -> void:
	_weapon = weapon
