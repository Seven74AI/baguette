extends "res://scripts/enemies/base_enemy.gd"
## Crêpier Démoniaque — Area Denial enemy.
## Slow, covers floor with nappes, throws crêpes. Melee AoE if player approaches.
## Attacks: Nappe de Pâte Brûlante (ground AoE, DoT 5s), Crêpe Suzette (slow fire projectile,
##   leaves fire AoE), Retournement de Crêpe (melee circular AoE)
## Weakness: Nappes can be ignited by his own Crêpes Suzette. Four Sacré cleans all nappes.
## Elite: Maître Crêpier — nappes slow AND stick (immobilize 1s), homing Crêpes.

enum CrepierState { POSITIONING = 100, SPREADING_NAPPE, THROWING_CREPE, MELEE_AOE }

signal nappe_spawned(nappe: Node)
signal crepe_fired(crepe: Node)
signal crepe_retournement_triggered()

@export_category("Crêpier Démoniaque")
@export var nappe_damage: int = 8
@export var nappe_duration: float = 5.0
@export var nappe_radius: float = 2.0
@export var nappe_interval: float = 2.5
@export var max_nappes: int = 4
@export var crepe_damage: int = 25
@export var crepe_speed: float = 5.0
@export var crepe_fire_aoe_radius: float = 1.5
@export var crepe_interval: float = 3.0
@export var melee_aoe_damage: int = 20
@export var melee_aoe_radius: float = 3.0
@export var melee_aoe_range: float = 3.0
@export var nappes_ignitable: bool = true
@export var is_elite: bool = false

var _crepier_state: int = CrepierState.POSITIONING
var _nappe_timer: float = 0.0
var _crepe_timer: float = 0.0
var _active_nappes: Array[Node] = []
var _is_melee_attacking: bool = false


func _ready() -> void:
	super._ready()
	move_speed = 2.0
	attack_damage = crepe_damage
	attack_range = 10.0
	detection_range = 18.0
	if health_component:
		health_component.max_health = 120
		health_component.current_health = 120


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()

	if _is_melee_attacking:
		move_and_slide()
		return

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_crepier_fight(delta)
		EnemyState.ATTACK:
			_execute_attack()

	move_and_slide()


func _crepier_fight(delta: float) -> void:
	if _player == null:
		return

	var distance := global_position.distance_to(_player.global_position)
	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	# Slow advance toward player
	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)

	# Priority: melee AoE if player is close
	if distance <= melee_aoe_range:
		_crepier_state = CrepierState.MELEE_AOE
		current_state = EnemyState.ATTACK
		return

	# Spread nappes when close enough
	_nappe_timer += delta
	if distance <= attack_range * 0.8 and _nappe_timer >= nappe_interval and _get_active_nappe_count() < max_nappes:
		_crepier_state = CrepierState.SPREADING_NAPPE
		current_state = EnemyState.ATTACK
		return

	# Throw crêpe suzette
	_crepe_timer += delta
	if distance <= attack_range and _crepe_timer >= crepe_interval:
		_crepier_state = CrepierState.THROWING_CREPE
		current_state = EnemyState.ATTACK
		return


func _execute_attack() -> void:
	match _crepier_state:
		CrepierState.SPREADING_NAPPE:
			_spawn_nappe()
		CrepierState.THROWING_CREPE:
			_throw_crepe_suzette()
		CrepierState.MELEE_AOE:
			_retournement_crepe()

	current_state = EnemyState.CHASE


func _spawn_nappe() -> void:
	_nappe_timer = 0.0

	var nappe := Area3D.new()
	nappe.name = "NappeDePate"
	nappe.collision_layer = 8
	nappe.collision_mask = 1

	var cs := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = nappe_radius
	cylinder.height = 0.05
	cs.shape = cylinder
	nappe.add_child(cs)

	# Visual: flat disc
	var mesh := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.top_radius = nappe_radius
	cylinder_mesh.bottom_radius = nappe_radius * 0.8
	cylinder_mesh.height = 0.05
	mesh.mesh = cylinder_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.78, 0.55, 0.7)
	mat.roughness = 0.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	nappe.add_child(mesh)

	# Place at the crêpier's position
	nappe.position = Vector3(global_position.x, 0.05, global_position.z)
	nappe.set_meta("damage", nappe_damage)
	nappe.set_meta("duration", nappe_duration)
	nappe.set_meta("elapsed", 0.0)
	nappe.set_meta("ignitable", nappes_ignitable)
	nappe.set_meta("ignited", false)
	nappe.set_meta("slows", is_elite)
	nappe.set_meta("sticks", is_elite)
	nappe.set_meta("source", self)

	nappe.body_entered.connect(_on_body_entered_nappe.bind(nappe))
	nappe.body_exited.connect(_on_body_exited_nappe.bind(nappe))

	get_tree().root.add_child(nappe)
	_active_nappes.append(nappe)
	nappe_spawned.emit(nappe)

	# Auto-remove after duration
	var timer := get_tree().create_timer(nappe_duration)
	timer.timeout.connect(
		func():
			if is_instance_valid(nappe):
				_remove_nappe(nappe)
	)


func _remove_nappe(nappe: Node) -> void:
	var idx := _active_nappes.find(nappe)
	if idx >= 0:
		_active_nappes.remove_at(idx)
	if is_instance_valid(nappe):
		nappe.queue_free()


func _on_body_entered_nappe(body: Node3D, nappe: Area3D) -> void:
	if not is_instance_valid(nappe):
		return
	if body.is_in_group("player"):
		# Apply damage over time
		var dmg := nappe.get_meta("damage", 8) as int
		if body.has_method("take_damage"):
			body.take_damage(dmg, self)


func _on_body_exited_nappe(body: Node3D, nappe: Area3D) -> void:
	pass  # Damage is applied on enter only


func _throw_crepe_suzette() -> void:
	if _player == null:
		return

	_crepe_timer = 0.0

	var crepe := Area3D.new()
	crepe.name = "CrepeSuzette"
	crepe.collision_layer = 4
	crepe.collision_mask = 1

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.4
	cs.shape = sphere
	crepe.add_child(cs)

	# Visual: fiery flat disc
	var mesh := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.top_radius = 0.35
	cylinder_mesh.bottom_radius = 0.35
	cylinder_mesh.height = 0.08
	mesh.mesh = cylinder_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.5, 0.1, 1.0)
	mat.emission = Color(1.0, 0.3, 0.0)
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	crepe.add_child(mesh)

	var direction := (_player.global_position - global_position).normalized()
	crepe.position = global_position + direction * 1.0 + Vector3.UP * 1.0
	crepe.set_meta("direction", direction)
	crepe.set_meta("speed", crepe_speed)
	crepe.set_meta("damage", crepe_damage)
	crepe.set_meta("fire_aoe_radius", crepe_fire_aoe_radius)
	crepe.set_meta("lifetime", 4.0)
	crepe.set_meta("elapsed", 0.0)
	crepe.set_meta("source", self)

	crepe.body_entered.connect(_on_crepe_hit.bind(crepe))

	get_tree().root.add_child(crepe)
	crepe_fired.emit(crepe)


func _on_crepe_hit(body: Node3D, crepe: Area3D) -> void:
	if not is_instance_valid(crepe):
		return
	if body == self:
		# Ignite nappes under crêpier
		_ignite_nearby_nappes(crepe.global_position, crepe_fire_aoe_radius)
		return
	if body.is_in_group("player"):
		var dmg := crepe.get_meta("damage", 25) as int
		if body.has_method("take_damage"):
			body.take_damage(dmg, self)

	# Spawn fire AoE at impact point
	_spawn_fire_aoe(crepe.global_position, crepe_fire_aoe_radius)
	crepe.queue_free()


func _spawn_fire_aoe(pos: Vector3, radius: float) -> void:
	var fire := Area3D.new()
	fire.name = "FireAoE"
	fire.collision_layer = 8
	fire.collision_mask = 1

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	cs.shape = sphere
	fire.add_child(cs)

	# Visual
	var mesh := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	mesh.mesh = sphere_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.0, 0.4)
	mat.emission = Color(1.0, 0.2, 0.0)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material_override = mat
	fire.add_child(mesh)

	fire.position = Vector3(pos.x, 0.05, pos.z)
	fire.set_meta("damage", int(crepe_damage * 0.5))
	fire.set_meta("lifetime", 3.0)

	fire.body_entered.connect(func(body: Node3D):
		if body.is_in_group("player") and is_instance_valid(fire):
			var dmg := fire.get_meta("damage", 12) as int
			if body.has_method("take_damage"):
				body.take_damage(dmg, self)
	)

	get_tree().root.add_child(fire)

	# Auto-remove
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(func():
		if is_instance_valid(fire):
			fire.queue_free()
	)


func _ignite_nearby_nappes(pos: Vector3, radius: float) -> void:
	for nappe in _active_nappes:
		if not is_instance_valid(nappe):
			continue
		if nappe.global_position.distance_to(pos) <= radius:
			nappe.set_meta("ignited", true)
			nappe.set_meta("damage", nappe.get_meta("damage", 8) * 2)
			# Visual change
			for child in nappe.get_children():
				if child is MeshInstance3D:
					var m := child.material_override as StandardMaterial3D
					if m:
						m.albedo_color = Color(1.0, 0.4, 0.1, 0.8)
						m.emission = Color(1.0, 0.3, 0.0)
						m.emission_energy_multiplier = 2.0


func _retournement_crepe() -> void:
	_is_melee_attacking = true

	# Deal AoE damage around self
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = melee_aoe_radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 1

	var results := space_state.intersect_shape(query)
	for result in results:
		var collider := result.get("collider") as Node
		if collider and is_instance_valid(collider) and collider.is_in_group("player"):
			if collider.has_method("take_damage"):
				collider.take_damage(melee_aoe_damage, self)

	crepe_retournement_triggered.emit()

	# Brief cooldown before next action
	var timer := get_tree().create_timer(0.3)
	timer.timeout.connect(func(): _is_melee_attacking = false)


func _clean_all_nappes() -> void:
	for nappe in _active_nappes:
		if is_instance_valid(nappe):
			nappe.queue_free()
	_active_nappes.clear()


func _get_active_nappe_count() -> int:
	# Clean up invalid references
	var valid: Array[Node] = []
	for nappe in _active_nappes:
		if is_instance_valid(nappe):
			valid.append(nappe)
	_active_nappes = valid
	return _active_nappes.size()


func _on_death() -> void:
	_clean_all_nappes()
	super._on_death()


## Apply elite modifier: Maître Crêpier
func _apply_elite_modifier() -> void:
	is_elite = true
	# Elite: nappes slow AND stick (immobilize 1s), homing Crêpes
	nappe_damage += 4
	nappe_duration += 3.0
	crepe_damage += 10
	crepe_speed *= 0.8  # Slower but homing
	melee_aoe_radius *= 1.3
	if health_component:
		health_component.max_health = int(health_component.max_health * 1.5)
		health_component.current_health = health_component.max_health
	scale = Vector3(1.25, 1.25, 1.25)
