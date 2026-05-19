extends "res://scripts/enemies/base_enemy.gd"
## Pain au Chocolatine — charger enemy that explodes on contact.
## Rushes the player at very high speed, self-destructs on contact
## dealing 40 AoE splash damage in a radius and leaving a slowing chocolate puddle.
## HP 30, speed 9.0. Fragile but dangerous.

enum ChocolatineState { IDLE, CHARGING, DETONATING }

## Emitted when the chocolatine explodes.
signal detonated(position: Vector3, damage: int)

## Emitted when a chocolate puddle is spawned.
signal puddle_spawned(puddle: Node)

@export_category("Pain au Chocolatine")
@export var self_destructs_on_contact: bool = true
@export var explosion_damage: int = 40
@export var explosion_radius: float = 3.0
@export var charge_speed_multiplier: float = 1.3  ## Speed multiplier when charging
@export var chocolate_slow_factor: float = 0.4  ## 0.4 = 60% speed reduction from puddle
@export var chocolate_slow_duration: float = 3.0  ## How long slow persists after leaving puddle
@export var puddle_lifetime: float = 8.0  ## How long chocolate puddles persist
@export var puddle_interval: float = 0.5  ## Seconds between puddle spawns while chasing
@export var charge_cooldown: float = 0.5  ## Seconds between charge attempts
@export var death_puddle_radius: float = 2.0  ## Size of death puddle

var _chocolatine_state: int = ChocolatineState.IDLE
var _charge_timer: float = 0.0
var _puddle_timer: float = 0.0
var _is_charging: bool = false


func _ready() -> void:
	super._ready()
	move_speed = 9.0
	attack_damage = explosion_damage
	attack_range = 1.5  # Close range for contact explosion
	detection_range = 25.0

	if health_component:
		health_component.max_health = 30
		health_component.current_health = 30


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()

	if _player == null:
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		return

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_charge_player(delta)
		EnemyState.ATTACK:
			_detonate()

	move_and_slide()

	# Check for contact with player after movement
	if current_state != EnemyState.DEAD and self_destructs_on_contact:
		_check_player_contact()


## Charge toward the player at high speed, leaving chocolate puddles.
func _charge_player(delta: float) -> void:
	if _player == null:
		return

	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	var charge_speed := move_speed * charge_speed_multiplier
	var target_velocity := direction * charge_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * 2.0 * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * 2.0 * delta)

	# Leave chocolate puddles while charging
	_puddle_timer += delta
	if _puddle_timer >= puddle_interval:
		_puddle_timer = 0.0
		_spawn_chocolate_puddle(global_position)


## Check if the chocolatine has made contact with the player.
func _check_player_contact() -> void:
	if _player == null:
		return

	var distance := global_position.distance_to(_player.global_position)
	if distance <= attack_range:
		current_state = EnemyState.ATTACK


## Detonate — deal AoE damage and self-destruct.
func _detonate() -> void:
	if current_state == EnemyState.DEAD:
		return

	current_state = EnemyState.DEAD

	# Deal AoE damage to all enemies/player in range
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = explosion_radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 1 | 2  # Player + enemy layers

	var results := space_state.intersect_shape(query)
	for result in results:
		var collider := result.get("collider") as Node
		if collider and is_instance_valid(collider) and collider != self:
			# Only damage the player (explosion damages player, not other enemies)
			if collider.is_in_group("player"):
				if collider.has_method("take_damage"):
					collider.take_damage(explosion_damage, self)
				elif collider.get("health_component"):
					var hc = collider.health_component
					if hc and hc.has_method("take_damage"):
						hc.take_damage(explosion_damage, self)

	detonated.emit(global_position, explosion_damage)

	# Spawn a large chocolate puddle at detonation point
	_spawn_chocolate_puddle(global_position)

	# Disable collision
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true

	set_process(false)
	set_physics_process(false)

	# Queue free after brief delay
	var timer := get_tree().create_timer(0.1)
	timer.timeout.connect(queue_free)


## Spawn a chocolate puddle at the given position that slows the player.
func _spawn_chocolate_puddle(pos: Vector3) -> void:
	var puddle := Area3D.new()
	puddle.name = "ChocolatePuddle"
	puddle.collision_layer = 8
	puddle.collision_mask = 1
	puddle.position = Vector3(pos.x, 0.05, pos.z)

	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.8
	shape.height = 0.05
	cs.shape = shape
	puddle.add_child(cs)

	# Visual: dark brown disc
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.8
	cylinder.bottom_radius = 0.6
	cylinder.height = 0.05
	mesh.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.15, 0.05, 0.6)  # Dark chocolate brown
	mat.roughness = 0.9
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	puddle.add_child(mesh)

	# Connect body entered for slow effect
	puddle.body_entered.connect(_on_body_entered_puddle.bind(puddle))
	puddle.body_exited.connect(_on_body_exited_puddle.bind(puddle))

	get_tree().root.add_child(puddle)
	puddle_spawned.emit(puddle)

	# Remove after lifetime
	var timer := get_tree().create_timer(puddle_lifetime)
	timer.timeout.connect(
		func():
			if is_instance_valid(puddle):
				var fade := create_tween()
				fade.tween_property(mat, "albedo_color:a", 0.0, 1.0)
				fade.tween_callback(puddle.queue_free)
	)


func _on_body_entered_puddle(body: Node3D, puddle: Area3D) -> void:
	if not is_instance_valid(puddle):
		return
	if body.is_in_group("player"):
		if body.has_method("set_speed_multiplier"):
			body.set_speed_multiplier(chocolate_slow_factor)
		elif body is CharacterBody3D:
			var original_speed: float = 0.0
			if body.get("move_speed") != null:
				original_speed = body.move_speed
				body.move_speed = original_speed * chocolate_slow_factor
				puddle.set_meta("_original_speed", original_speed)
				puddle.set_meta("_target", body)


func _on_body_exited_puddle(body: Node3D, puddle: Area3D) -> void:
	if not is_instance_valid(puddle):
		return
	if body.is_in_group("player") and puddle.has_meta("_target"):
		var original_speed = puddle.get_meta("_original_speed", 0.0)
		if original_speed > 0 and body.get("move_speed") != null:
			body.move_speed = original_speed


## Override death to spawn a large chocolate puddle.
func _on_death() -> void:
	_spawn_chocolate_puddle(global_position)
	super._on_death()
