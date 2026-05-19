extends "res://scripts/enemies/base_enemy.gd"
## Baguette Vivante — a slow, tanky melee enemy that wiggles toward the player.
## Attacks with a baguette slap. On death, splits into two broken baguette halves.
## Leaves breadcrumb particles while moving.

signal split  ## Emitted when the baguette splits into two halves on death.

@export_category("Baguette Vivante")
@export var wiggle_intensity: float = 0.15  ## How much the baguette wobbles while moving.
@export var wiggle_speed: float = 4.0  ## Speed of the wobble animation.
@export var breadcrumb_interval: float = 0.3  ## Seconds between breadcrumb particles.
@export var split_force: float = 1.5  ## Impulse applied to split halves.

var _breadcrumb_timer: float = 0.0
var _wiggle_angle: float = 0.0


func _ready() -> void:
	super._ready()
	move_speed = 2.0
	attack_damage = 25
	attack_range = 1.8
	detection_range = 12.0
	attack_cooldown = 1.5

	if health_component:
		health_component.max_health = 150
		health_component.current_health = 150


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_chase_player(delta)
			_spawn_breadcrumb(delta)
		EnemyState.ATTACK:
			_attack_player()

	move_and_slide()


func _chase_player(delta: float) -> void:
	super._chase_player(delta)
	# Add wiggle while moving
	if velocity.length() > 0.1:
		_wiggle_angle += wiggle_speed * delta
		rotation.z = sin(_wiggle_angle) * wiggle_intensity


func _attack_player() -> void:
	if _player == null:
		return

	# Melee slap
	if _player.has_method("take_damage"):
		_player.take_damage(attack_damage, self)
	elif _player.get("health_component"):
		var hc = _player.health_component
		if hc and hc.has_method("take_damage"):
			hc.take_damage(attack_damage, self)

	# Return to chase after attack
	current_state = EnemyState.CHASE


func _on_death() -> void:
	# Split into two halves before marking as dead
	_spawn_split_halves()
	split.emit()
	super._on_death()


## Spawns breadcrumb particles while moving.
func _spawn_breadcrumb(delta: float) -> void:
	_breadcrumb_timer += delta
	if _breadcrumb_timer >= breadcrumb_interval:
		_breadcrumb_timer = 0.0
		# Spawn a simple breadcrumb particle (CSG sphere at ground level)
		var crumb := CSGSphere3D.new()
		crumb.radius = 0.05
		crumb.position = global_position + Vector3(randf_range(-0.2, 0.2), -0.4, randf_range(-0.2, 0.2))
		crumb.material = StandardMaterial3D.new()
		crumb.material.albedo_color = Color(0.82, 0.71, 0.55)  # Golden brown
		get_tree().root.add_child(crumb)
		# Auto-remove after a few seconds
		var tween := create_tween()
		tween.tween_property(crumb, "scale", Vector3.ZERO, 3.0)
		tween.tween_callback(crumb.queue_free)


## Spawns two broken baguette halves on death.
func _spawn_split_halves() -> void:
	for i in range(2):
		var half := CSGCylinder3D.new()
		half.radius = 0.15
		half.height = 0.5
		half.position = global_position + Vector3((i - 0.5) * 0.5, 0.0, 0.0)
		half.material = StandardMaterial3D.new()
		half.material.albedo_color = Color(0.82, 0.71, 0.55)

		var body := RigidBody3D.new()
		body.add_child(half)
		var body_cs := CollisionShape3D.new()
		var body_shape := CylinderShape3D.new()
		body_shape.radius = 0.15
		body_shape.height = 0.5
		body_cs.shape = body_shape
		body.add_child(body_cs)
		get_tree().root.add_child(body)

		# Apply a small impulse
		body.apply_impulse(Vector3((i - 0.5) * split_force, split_force * 0.5, randf_range(-0.3, 0.3)))

		# Cleanup after a few seconds
		var timer := get_tree().create_timer(4.0)
		timer.timeout.connect(body.queue_free)
