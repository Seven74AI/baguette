extends "res://scripts/enemies/base_enemy.gd"
## Sourdough Blob — slime-like enemy that oozes toward the player.
## Leaves sticky sourdough starter puddles on the ground that slow the player.
## On death, explodes into a large puddle.

signal puddle_spawned(puddle: Node)

@export_category("Sourdough Blob")
@export var slime_slow_factor: float = 0.4  ## Multiplier applied to player speed in puddle (0.4 = 60% slow).
@export var slime_slow_duration: float = 2.0  ## How long the slow effect lasts after leaving puddle.
@export var puddle_interval: float = 0.8  ## Seconds between puddle spawns.
@export var puddle_lifetime: float = 6.0  ## How long puddles persist.
@export var ooze_wobble_intensity: float = 0.25  ## How much the blob wobbles.
@export var ooze_wobble_speed: float = 2.5  ## Wobble speed.
@export var death_puddle_radius: float = 1.5  ## Size of death puddle.

var _puddle_timer: float = 0.0
var _wobble_angle: float = 0.0


func _ready() -> void:
	super._ready()
	move_speed = 2.5
	attack_damage = 20
	attack_range = 1.8
	detection_range = 10.0
	attack_cooldown = 1.2

	if health_component:
		health_component.max_health = 120
		health_component.current_health = 120


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()

	# Always wobble (ooze aesthetic)
	_wobble_angle += ooze_wobble_speed * delta
	var wobble := sin(_wobble_angle) * ooze_wobble_intensity
	scale = Vector3(1.0 + wobble * 0.5, 1.0 - wobble * 0.3, 1.0 + wobble * 0.5)

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_chase_player(delta)
			_spawn_slime_puddle(delta)
		EnemyState.ATTACK:
			_attack_player()

	# Clamp scale to avoid visual distortion
	scale = scale.clamp(Vector3(0.6, 0.6, 0.6), Vector3(1.4, 1.4, 1.4))

	move_and_slide()


func _chase_player(delta: float) -> void:
	if _player == null:
		return

	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	# Ooze forward — slightly bouncy movement
	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * 0.5 * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * 0.5 * delta)


func _attack_player() -> void:
	if _player == null:
		return

	# Melee ooze attack — damage + apply slow
	if _player.has_method("take_damage"):
		_player.take_damage(attack_damage, self)
	elif _player.get("health_component"):
		var hc = _player.health_component
		if hc and hc.has_method("take_damage"):
			hc.take_damage(attack_damage, self)

	# Spawn a puddle at attack point
	_spawn_single_puddle(global_position)

	current_state = EnemyState.CHASE


## Spawns slime puddles periodically while chasing.
func _spawn_slime_puddle(delta: float) -> void:
	_puddle_timer += delta
	if _puddle_timer >= puddle_interval:
		_puddle_timer = 0.0
		_spawn_single_puddle(global_position)


## Spawns a single sourdough puddle at a position.
func _spawn_single_puddle(pos: Vector3) -> void:
	var puddle := Area3D.new()
	puddle.name = "SlimePuddle"
	puddle.collision_layer = 8  # Separate layer for puddles
	puddle.collision_mask = 1
	puddle.position = Vector3(pos.x, 0.05, pos.z)  # Flat on ground

	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.6
	shape.height = 0.05
	cs.shape = shape
	puddle.add_child(cs)

	# Visual: flattened disc
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.6
	cylinder.bottom_radius = 0.5
	cylinder.height = 0.05
	mesh.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.8, 0.65, 0.5)  # Sourdough color, translucent
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	puddle.add_child(mesh)

	# Connect body entered signal for slow effect
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
		# Apply slow effect
		if body.has_method("set_speed_multiplier"):
			body.set_speed_multiplier(slime_slow_factor)
		elif body is CharacterBody3D:
			# Store original speed and apply slow
			var original_speed := 0.0
			if body.get("move_speed") != null:
				original_speed = body.move_speed
				body.move_speed = original_speed * slime_slow_factor
				# Restore after leaving
				puddle.set_meta("_original_speed", original_speed)
				puddle.set_meta("_target", body)


func _on_body_exited_puddle(body: Node3D, puddle: Area3D) -> void:
	if not is_instance_valid(puddle):
		return
	if body.is_in_group("player") and puddle.has_meta("_target"):
		var original_speed = puddle.get_meta("_original_speed", 0.0)
		if original_speed > 0 and body.get("move_speed") != null:
			body.move_speed = original_speed


func _on_death() -> void:
	_spawn_death_puddle()
	super._on_death()


## Spawns a large final puddle on death (AoE).
func _spawn_death_puddle() -> void:
	var puddle := Area3D.new()
	puddle.name = "DeathPuddle"
	puddle.collision_layer = 8
	puddle.collision_mask = 1
	puddle.position = Vector3(global_position.x, 0.05, global_position.z)

	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = death_puddle_radius
	shape.height = 0.1
	cs.shape = shape
	puddle.add_child(cs)

	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = death_puddle_radius
	cylinder.bottom_radius = death_puddle_radius * 0.8
	cylinder.height = 0.05
	mesh.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.7, 0.55, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	puddle.add_child(mesh)

	# Death puddle slows for double the normal factor
	puddle.body_entered.connect(
		func(body: Node3D):
			if body.is_in_group("player") and body.get("move_speed") != null:
				var orig: float = body.move_speed
				body.move_speed = orig * (slime_slow_factor * 0.7)
				puddle.set_meta("_original_speed", orig)
				puddle.set_meta("_target", body)
	)
	puddle.body_exited.connect(
		func(body: Node3D):
			if puddle.has_meta("_target") and body == puddle.get_meta("_target"):
				var orig: float = float(puddle.get_meta("_original_speed", 0.0))
				if orig > 0 and body.get("move_speed") != null:
					body.move_speed = orig
	)

	get_tree().root.add_child(puddle)

	# Death puddle lasts longer
	var timer := get_tree().create_timer(puddle_lifetime * 1.5)
	timer.timeout.connect(
		func():
			if is_instance_valid(puddle):
				var fade := create_tween()
				fade.tween_property(mat, "albedo_color:a", 0.0, 1.5)
				fade.tween_callback(puddle.queue_free)
	)
