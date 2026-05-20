extends "res://scripts/enemies/base_enemy.gd"
## Livreur à Vélo — Rusher/Flanker enemy.
## Circles player in wide arcs, charges straight line. Vulnerable after missed charge.
## Attacks: Charge à Vélo (straight line, knockback, medium damage),
##   Lancer de Pizza (fast projectile), Coup de Sonnette (short AoE stun)
## Weakness: Charge is telegraphed (sonnette + straight trajectory). Shoot during charge -> chute.
## Elite: Coursier Uber Eats — drops energy drinks that buff nearby enemies, 2 consecutive charges.

enum LivreurState { CIRCLING = 100, WINDING_UP, CHARGING, THROWING_PIZZA, STUNNED, RECOVERING }

signal charge_started(direction: Vector3)
signal charge_hit(target: Node)
signal charge_missed()
signal pizza_thrown(projectile: Node)
signal energy_drink_dropped(drink: Node)

@export_category("Livreur à Vélo")
@export var charge_speed_multiplier: float = 2.5
@export var charge_damage: int = 20
@export var charge_knockback: float = 5.0
@export var charge_windup_duration: float = 0.8
@export var charge_telegraphed: bool = true
@export var charge_max_distance: float = 20.0
@export var vulnerable_after_missed_charge: bool = true
@export var missed_charge_stun_duration: float = 1.5
@export var chute_on_charge_shot: bool = true
@export var chute_stun_duration: float = 3.0
@export var chute_bonus_damage_mult: float = 2.0
@export var pizza_damage: int = 8
@export var pizza_speed: float = 12.0
@export var pizza_interval: float = 1.5
@export var sonnette_stun_duration: float = 0.8
@export var sonnette_radius: float = 2.0
@export var circle_radius: float = 10.0
@export var circle_speed_multiplier: float = 0.8
@export var is_elite: bool = false

var _livreur_state: int = LivreurState.CIRCLING
var _charge_timer: float = 0.0
var _charge_direction: Vector3 = Vector3.ZERO
var _charge_distance_traveled: float = 0.0
var _is_winding_up: bool = false
var _windup_timer: float = 0.0
var _pizza_timer: float = 0.0
var _stun_timer: float = 0.0
var _circle_angle: float = 0.0
var _charge_start_pos: Vector3 = Vector3.ZERO
var _shot_during_charge: bool = false
var _consecutive_charges: int = 0
var _max_consecutive_charges: int = 1


func _ready() -> void:
	super._ready()
	move_speed = 8.0
	attack_damage = charge_damage
	attack_range = 15.0
	detection_range = 25.0
	if health_component:
		health_component.max_health = 50
		health_component.current_health = 50


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()

	match _livreur_state:
		LivreurState.STUNNED:
			_stun_timer -= delta
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * 2.0 * delta)
			if _stun_timer <= 0.0:
				_livreur_state = LivreurState.RECOVERING
			move_and_slide()
			return

		LivreurState.RECOVERING:
			_charge_timer += delta
			if _charge_timer >= 0.5:
				_charge_timer = 0.0
				_livreur_state = LivreurState.CIRCLING
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			move_and_slide()
			return

		LivreurState.WINDING_UP:
			_windup_timer += delta
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * 2.0 * delta)
			if _windup_timer >= charge_windup_duration:
				_start_charge()
			move_and_slide()
			return

		LivreurState.CHARGING:
			_perform_charge(delta)
			move_and_slide()
			return

		LivreurState.THROWING_PIZZA:
			_throw_pizza()

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_livreur_fight(delta)
		EnemyState.ATTACK:
			_livreur_state = LivreurState.THROWING_PIZZA

	move_and_slide()


func _livreur_fight(delta: float) -> void:
	if _player == null:
		return

	# Circle the player
	_circle_player(delta)

	# Throw pizza while circling
	_pizza_timer += delta
	if _pizza_timer >= pizza_interval:
		_pizza_timer = 0.0
		_livreur_state = LivreurState.THROWING_PIZZA
		current_state = EnemyState.ATTACK
		return

	# Decide to charge
	_charge_timer += delta
	if _charge_timer >= 3.0:
		_charge_timer = 0.0
		_begin_charge_windup()


func _circle_player(delta: float) -> void:
	if _player == null:
		return

	var dist := global_position.distance_to(_player.global_position)

	# Adjust circle angle
	_circle_angle += delta * 1.5

	# Calculate position on circle around player
	var circle_pos := Vector3(
		_player.global_position.x + cos(_circle_angle) * circle_radius,
		global_position.y,
		_player.global_position.z + sin(_circle_angle) * circle_radius
	)

	var direction := (circle_pos - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	# Move toward circle position if too far from ideal
	if dist > circle_radius + 3.0:
		direction = (_player.global_position - global_position).normalized()
		direction.y = 0

	var target_velocity := direction * move_speed * circle_speed_multiplier
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)


func _begin_charge_windup() -> void:
	if _player == null:
		return

	# Face the player
	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)
	_charge_direction = direction

	_livreur_state = LivreurState.WINDING_UP
	_windup_timer = 0.0
	_shot_during_charge = false
	charge_started.emit(direction)

	# Telegraph with sonnette
	_coup_de_sonnette()


func _start_charge() -> void:
	_livreur_state = LivreurState.CHARGING
	_charge_start_pos = global_position
	_charge_distance_traveled = 0.0


func _perform_charge(delta: float) -> void:
	var charge_speed := move_speed * charge_speed_multiplier
	var move_dist := charge_speed * delta
	_charge_distance_traveled += move_dist
	velocity = _charge_direction * charge_speed

	# Check if hit player
	if _player and is_instance_valid(_player):
		var dist := global_position.distance_to(_player.global_position)
		if dist < 1.5:
			_on_charge_hit_player()
			return

	# End charge if traveled too far
	if _charge_distance_traveled >= charge_max_distance:
		_on_charge_missed()


func _on_charge_hit_player() -> void:
	if _player and is_instance_valid(_player):
		if _player.has_method("take_damage"):
			_player.take_damage(charge_damage, self)

		# Knockback
		if _player is CharacterBody3D:
			var kb := _charge_direction * charge_knockback
			kb.y = 2.0
			_player.velocity += kb

	charge_hit.emit(_player)

	if is_elite and _consecutive_charges < _max_consecutive_charges:
		_consecutive_charges += 1
		_charge_distance_traveled = 0.0
		if _player:
			_charge_direction = (_player.global_position - global_position).normalized()
			_charge_direction.y = 0
		return

	_consecutive_charges = 0
	_livreur_state = LivreurState.CIRCLING
	_charge_timer = 0.0


func _on_charge_missed() -> void:
	charge_missed.emit()

	if is_elite and _consecutive_charges < _max_consecutive_charges:
		_consecutive_charges += 1
		_charge_distance_traveled = 0.0
		if _player and is_instance_valid(_player):
			_charge_direction = (_player.global_position - global_position).normalized()
			_charge_direction.y = 0
		return

	_consecutive_charges = 0

	if _shot_during_charge:
		# Chute! Long stun + bonus damage
		_stun_timer = chute_stun_duration
		_livreur_state = LivreurState.STUNNED
		# Bonus damage already applied via on_hit during charge
	else:
		# Normal recovery after missed charge
		_stun_timer = missed_charge_stun_duration
		_livreur_state = LivreurState.STUNNED


func take_damage(amount: int, source: Node = null) -> void:
	if current_state == EnemyState.DEAD:
		return

	# If hit during charge windup or charging, trigger chute
	if _livreur_state in [LivreurState.WINDING_UP, LivreurState.CHARGING]:
		_shot_during_charge = true
		amount = int(amount * chute_bonus_damage_mult)

	super.take_damage(amount, source)


func _throw_pizza() -> void:
	if _player == null:
		_livreur_state = LivreurState.CIRCLING
		current_state = EnemyState.CHASE
		return

	var pizza := Area3D.new()
	pizza.name = "PizzaProjectile"
	pizza.collision_layer = 4
	pizza.collision_mask = 1

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	cs.shape = sphere
	pizza.add_child(cs)

	# Visual
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.3
	cylinder.bottom_radius = 0.3
	cylinder.height = 0.06
	mesh.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.7, 0.4, 1.0)
	mat.metallic = 0.1
	mesh.material_override = mat
	pizza.add_child(mesh)

	var direction := (_player.global_position - global_position).normalized()
	pizza.position = global_position + direction * 1.0 + Vector3.UP * 1.0
	pizza.set_meta("direction", direction)
	pizza.set_meta("speed", pizza_speed)
	pizza.set_meta("damage", pizza_damage)
	pizza.set_meta("lifetime", 3.0)
	pizza.set_meta("source", self)

	pizza.body_entered.connect(func(body: Node3D):
		if body == self or not is_instance_valid(pizza):
			return
		if body.is_in_group("player"):
			var dmg := pizza.get_meta("damage", 8) as int
			if body.has_method("take_damage"):
				body.take_damage(dmg, self)
		pizza.queue_free()
	)

	get_tree().root.add_child(pizza)
	pizza_thrown.emit(pizza)

	_livreur_state = LivreurState.CIRCLING
	current_state = EnemyState.CHASE


func _coup_de_sonnette() -> void:
	# Short AoE stun around the livreur
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = sonnette_radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 1

	var results := space_state.intersect_shape(query)
	for result in results:
		var collider := result.get("collider") as Node
		if collider and is_instance_valid(collider) and collider.is_in_group("player"):
			if collider.has_method("apply_stun"):
				collider.apply_stun(sonnette_stun_duration)


func _charge_player() -> void:
	# Public method for testing
	_begin_charge_windup()


func _on_death() -> void:
	if is_elite:
		_drop_energy_drink()
	super._on_death()


func _drop_energy_drink() -> void:
	var drink := Area3D.new()
	drink.name = "EnergyDrink"
	drink.collision_layer = 8
	drink.collision_mask = 1

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	cs.shape = sphere
	drink.add_child(cs)

	# Visual
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.2
	cylinder.bottom_radius = 0.25
	cylinder.height = 0.5
	mesh.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 1.0, 0.3, 1.0)
	mat.emission = Color(0.1, 0.8, 0.2)
	mat.emission_energy_multiplier = 1.5
	mesh.material_override = mat
	drink.add_child(mesh)

	drink.position = global_position + Vector3(0, 0.3, 0)
	drink.set_meta("buff_radius", 8.0)
	drink.set_meta("buff_duration", 8.0)
	drink.set_meta("buff_speed", 0.3)
	drink.set_meta("buff_damage", 0.2)

	get_tree().root.add_child(drink)
	energy_drink_dropped.emit(drink)

	# Auto-remove
	var timer := get_tree().create_timer(10.0)
	timer.timeout.connect(func():
		if is_instance_valid(drink):
			drink.queue_free()
	)


## Apply elite modifier: Coursier Uber Eats
func _apply_elite_modifier() -> void:
	is_elite = true
	_max_consecutive_charges = 2
	charge_damage += 8
	charge_speed_multiplier += 0.3
	pizza_damage += 4
	if health_component:
		health_component.max_health = int(health_component.max_health * 1.5)
		health_component.current_health = health_component.max_health
	scale = Vector3(1.2, 1.2, 1.2)
