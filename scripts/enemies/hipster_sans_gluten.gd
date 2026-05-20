extends "res://scripts/enemies/base_enemy.gd"
## Hipster Sans Gluten — Specialist/Debuffer enemy.
## Maintains distance, applies debuffs, dodges. Uses appareil photo (immobile 2s, regen).
## Attacks: Lanceur de Farine Sans Gluten (projectile, -30% reload speed + -20% move speed, 8s),
##   Aura Vegan (converts healing drops to 50% effective)
## Weakness: Pain au chocolat launcher cancels Aura Vegan. Shoot appareil photo -> explodes (AoE to nearby enemies)
## Elite: Influenceur Food — drone that films & attracts enemies, Aura Vegan makes drops toxic

enum HipsterState { POSITIONING = 100, DEBUFFING, PHOTOGRAPHING }

signal flour_fired(projectile: Node)
signal photo_exploded(position: Vector3, damage: int)
signal aura_vegan_toggled(active: bool)

@export_category("Hipster Sans Gluten")
@export var flour_damage: int = 12
@export var flour_speed: float = 6.0
@export var intolerance_reload_penalty: float = 0.30
@export var intolerance_speed_penalty: float = 0.20
@export var intolerance_duration: float = 8.0
@export var aura_vegan_radius: float = 8.0
@export var photo_regen_amount: int = 15
@export var photo_duration: float = 2.0
@export var photo_explosion_damage: int = 40
@export var photo_explosion_radius: float = 5.0
@export var photo_explodes_on_hit: bool = true
@export var preferred_distance: float = 10.0
@export var fire_interval: float = 2.0
@export var dodge_distance: float = 3.0
@export var dodge_cooldown: float = 2.5
@export var aura_vegan_active: bool = false
@export var is_elite: bool = false

var _hipster_state: int = HipsterState.POSITIONING
var _fire_timer: float = 0.0
var _photo_timer: float = 0.0
var _dodge_timer: float = 0.0
var _can_dodge: bool = true
var _is_dodging: bool = false
var _dodge_target: Vector3 = Vector3.ZERO
var _dodge_direction: int = 1
var _photo_cooldown: float = 0.0
var _is_photographing: bool = false
var _aura_area: Area3D = null
var _active_debuffs: Dictionary = {}


func _ready() -> void:
	super._ready()
	move_speed = 4.5
	attack_damage = flour_damage
	attack_range = 12.0
	detection_range = 20.0
	if health_component:
		health_component.max_health = 90
		health_component.current_health = 90
	_activate_aura_vegan()


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()
	_update_timers(delta)

	if _is_dodging:
		_perform_dodge_move(delta)
		move_and_slide()
		return

	if _is_photographing:
		_perform_photograph(delta)
		move_and_slide()
		return

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_position_and_fight(delta)
		EnemyState.ATTACK:
			_fire_flour_projectile()

	move_and_slide()


func _update_timers(delta: float) -> void:
	_dodge_timer += delta
	if _dodge_timer >= dodge_cooldown:
		_can_dodge = true

	if _is_photographing:
		_photo_timer += delta
		if _photo_timer >= photo_duration:
			_finish_photograph()

	_photo_cooldown += delta


func _position_and_fight(delta: float) -> void:
	if _player == null:
		return

	var distance := global_position.distance_to(_player.global_position)
	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	# Maintain preferred distance
	if distance > preferred_distance + 3.0:
		var target_velocity := direction * move_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	elif distance < preferred_distance - 2.0:
		var back_dir := -direction
		var target_velocity := back_dir * move_speed * 0.7
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	# Try to dodge
	if _can_dodge and distance < attack_range * 1.5 and randf() < 0.25:
		_start_dodge()

	# Fire flour projectile
	_fire_timer += delta
	if distance <= attack_range and _fire_timer >= fire_interval:
		current_state = EnemyState.ATTACK

	# Use appareil photo when low on health
	if _photo_cooldown >= 10.0 and get_current_health() < get_max_health() * 0.5:
		_use_appareil_photo()


func _fire_flour_projectile() -> void:
	if _player == null:
		current_state = EnemyState.CHASE
		return

	_fire_timer = 0.0

	var projectile := Area3D.new()
	projectile.name = "FlourProjectile"
	projectile.collision_layer = 4
	projectile.collision_mask = 1

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.25
	cs.shape = sphere
	projectile.add_child(cs)

	# Visual
	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.25
	sphere_mesh.height = 0.5
	mesh.mesh = sphere_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.9, 1.0)
	mesh.material_override = mat
	projectile.add_child(mesh)

	var direction := (_player.global_position - global_position).normalized()
	projectile.position = global_position + direction * 1.0 + Vector3.UP * 1.2
	projectile.set_meta("direction", direction)
	projectile.set_meta("speed", flour_speed)
	projectile.set_meta("damage", flour_damage)
	projectile.set_meta("reload_penalty", intolerance_reload_penalty)
	projectile.set_meta("speed_penalty", intolerance_speed_penalty)
	projectile.set_meta("debuff_duration", intolerance_duration)
	projectile.set_meta("lifetime", 3.0)
	projectile.set_meta("elapsed", 0.0)
	projectile.set_meta("source", self)

	projectile.body_entered.connect(_on_flour_hit.bind(projectile))

	get_tree().root.add_child(projectile)
	flour_fired.emit(projectile)

	current_state = EnemyState.CHASE


func _on_flour_hit(body: Node3D, projectile: Area3D) -> void:
	if not is_instance_valid(projectile):
		return
	if body == self:
		return
	if body.is_in_group("player"):
		var dmg := projectile.get_meta("damage", 12) as int
		if body.has_method("take_damage"):
			body.take_damage(dmg, self)
		_apply_intolerance_debuff(body)
	projectile.queue_free()


func _apply_intolerance_debuff(target: Node) -> void:
	if not is_instance_valid(target):
		return
	var relief := intolerance_reload_penalty
	var speed := intolerance_speed_penalty
	var dur := intolerance_duration

	# Apply via method if available
	if target.has_method("apply_reload_speed_multiplier"):
		target.apply_reload_speed_multiplier(1.0 - relief, dur)
	if target.has_method("apply_move_speed_multiplier"):
		target.apply_move_speed_multiplier(1.0 - speed, dur)

	# Store debuff metadata
	_active_debuffs[target] = {"reload": relief, "speed": speed, "remaining": dur}


func _activate_aura_vegan() -> void:
	if aura_vegan_active:
		return

	aura_vegan_active = true
	_aura_area = Area3D.new()
	_aura_area.name = "AuraVegan"
	_aura_area.collision_layer = 16
	_aura_area.collision_mask = 0

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = aura_vegan_radius
	cs.shape = sphere
	_aura_area.add_child(cs)

	# Visual ring
	var mesh := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = aura_vegan_radius - 0.1
	torus.outer_radius = aura_vegan_radius
	mesh.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.3, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	_aura_area.add_child(mesh)

	add_child(_aura_area)
	aura_vegan_toggled.emit(true)


func deactivate_aura_vegan() -> void:
	if not aura_vegan_active:
		return
	aura_vegan_active = false
	if _aura_area and is_instance_valid(_aura_area):
		_aura_area.queue_free()
		_aura_area = null
	aura_vegan_toggled.emit(false)


func _use_appareil_photo() -> void:
	if _is_photographing:
		return

	_is_photographing = true
	_photo_timer = 0.0
	_photo_cooldown = 0.0
	current_state = EnemyState.CHASE  # Can't attack while photographing


func _perform_photograph(delta: float) -> void:
	# During photograph, stand still and regen
	velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)


func _finish_photograph() -> void:
	_is_photographing = false
	_photo_timer = 0.0

	# Regen health
	if health_component:
		health_component.heal(photo_regen_amount)


func _start_dodge() -> void:
	if not _can_dodge:
		return

	_can_dodge = false
	_dodge_timer = 0.0
	_is_dodging = true
	_dodge_direction *= -1

	var right_dir := global_transform.basis.x * _dodge_direction
	_dodge_target = global_position + right_dir * dodge_distance


func _perform_dodge_move(delta: float) -> void:
	if global_position.distance_to(_dodge_target) < 0.3:
		_is_dodging = false
		return

	var direction := (_dodge_target - global_position).normalized()
	velocity = direction * 10.0


func _perform_dodge() -> void:
	# Public method for testing
	_start_dodge()


func _on_death() -> void:
	deactivate_aura_vegan()
	super._on_death()


## Apply elite modifier: Influenceur Food
func _apply_elite_modifier() -> void:
	is_elite = true
	# Elite: Aura Vegan makes drops toxic instead of just reducing healing
	aura_vegan_radius *= 1.3
	intolerance_reload_penalty = 0.40
	intolerance_speed_penalty = 0.30
	intolerance_duration = 10.0
	flour_damage += 5
	photo_regen_amount += 10
	if health_component:
		health_component.max_health = int(health_component.max_health * 1.5)
		health_component.current_health = health_component.max_health
	scale = Vector3(1.2, 1.2, 1.2)
