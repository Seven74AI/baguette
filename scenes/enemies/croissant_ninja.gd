extends "res://scripts/enemies/base_enemy.gd"
## Croissant Ninja — fast, evasive ranged enemy that throws crescent projectiles.
## Dodges player attacks with quick sidesteps. Low HP, high speed.
## Leaves a butter-slick trail while moving.

@export_category("Croissant Ninja")
@export var dodge_distance: float = 3.0  ## How far the ninja sidesteps.
@export var dodge_cooldown: float = 2.0  ## Seconds between dodges.
@export var dodge_speed: float = 12.0  ## How fast the dodge animation plays.
@export var projectile_speed: float = 8.0  ## Speed of thrown projectiles.
@export var projectile_damage: int = 10  ## Damage per projectile.
@export var throw_interval: float = 1.5  ## Seconds between throws.
@export var butter_trail_interval: float = 0.2  ## Seconds between butter drops.
@export var projectile_scene: PackedScene = preload("res://scenes/enemies/croissant_projectile.tscn")

var _can_dodge: bool = true
var _can_throw: bool = true
var _dodge_timer: float = 0.0
var _throw_timer: float = 0.0
var _butter_timer: float = 0.0
var _dodge_direction: int = 1  ## 1 = right, -1 = left
var _is_dodging: bool = false
var _dodge_target: Vector3 = Vector3.ZERO


func _ready() -> void:
	super._ready()
	move_speed = 7.0
	attack_damage = projectile_damage
	attack_range = 10.0
	detection_range = 18.0

	if health_component:
		health_component.max_health = 40
		health_component.current_health = 40


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()
	_update_timers(delta)

	if _is_dodging:
		_perform_dodge(delta)
		move_and_slide()
		return

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_chase_player(delta)
			_spawn_butter_trail(delta)
		EnemyState.ATTACK:
			_throw_projectile()
			_spawn_butter_trail(delta)

	move_and_slide()


func _update_timers(delta: float) -> void:
	_dodge_timer += delta
	if _dodge_timer >= dodge_cooldown:
		_can_dodge = true

	_throw_timer += delta
	if _throw_timer >= throw_interval:
		_can_throw = true


func _chase_player(delta: float) -> void:
	if _player == null:
		return

	# Check if within attack range — throw projectiles
	var distance := global_position.distance_to(_player.global_position)
	if distance <= attack_range and _can_throw:
		current_state = EnemyState.ATTACK
		return

	# Try to dodge if being aimed at (probabilistic dodge)
	if _can_dodge and distance < attack_range * 1.5 and randf() < 0.3:
		_start_dodge()

	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	# Serpentine movement — slight sideways drift
	var perpendicular := direction.rotated(Vector3.UP, deg_to_rad(30.0 * sin(Time.get_ticks_msec() * 0.003)))
	var target_velocity := perpendicular * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)


func _start_dodge() -> void:
	if not _can_dodge:
		return

	_can_dodge = false
	_dodge_timer = 0.0
	_is_dodging = true
	_dodge_direction *= -1  # Alternate left/right

	var right_dir := global_transform.basis.x * _dodge_direction
	_dodge_target = global_position + right_dir * dodge_distance


func _perform_dodge(delta: float) -> void:
	if global_position.distance_to(_dodge_target) < 0.2:
		_is_dodging = false
		return

	var direction := (_dodge_target - global_position).normalized()
	velocity = direction * dodge_speed
	move_and_slide()


func _throw_projectile() -> void:
	if _player == null or not _can_throw:
		return

	_can_throw = false
	_throw_timer = 0.0

	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.damage = projectile_damage
		proj.speed = projectile_speed
		proj.direction = (_player.global_position - global_position).normalized()
		proj.position = global_position + proj.direction * 1.5 + Vector3.UP * 0.5
		get_tree().root.add_child(proj)

	current_state = EnemyState.CHASE


## Spawns butter-slick trail particles.
func _spawn_butter_trail(delta: float) -> void:
	_butter_timer += delta
	if _butter_timer >= butter_trail_interval:
		_butter_timer = 0.0
		var butter := CSGSphere3D.new()
		butter.radius = 0.08
		butter.position = global_position + Vector3(randf_range(-0.3, 0.3), -0.6, randf_range(-0.3, 0.3))
		butter.material = StandardMaterial3D.new()
		butter.material.albedo_color = Color(1.0, 0.92, 0.4, 0.6)  # Yellow butter
		get_tree().root.add_child(butter)

		# Fade and remove
		var tween := create_tween()
		tween.tween_property(butter, "scale", Vector3.ZERO, 2.0)
		tween.tween_callback(butter.queue_free)


func _on_death() -> void:
	super._on_death()
	# Spawn a bigger butter splat on death
	var splat := CSGSphere3D.new()
	splat.radius = 0.4
	splat.position = global_position
	splat.material = StandardMaterial3D.new()
	splat.material.albedo_color = Color(1.0, 0.85, 0.2, 0.5)
	get_tree().root.add_child(splat)

	var tween := create_tween()
	tween.tween_property(splat, "scale", Vector3(1.5, 0.3, 1.5), 5.0)
	tween.parallel().tween_property(splat.material, "albedo_color:a", 0.0, 5.0)
	tween.tween_callback(splat.queue_free)
