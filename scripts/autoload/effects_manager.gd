extends Node
## PHASE 3: Global effects manager autoload.
## Spawns temporary particle effects (muzzle flash, impact flour, enemy death sparkles).
## Creates GPUParticles3D programmatically — no external scene files needed.

const MUZZLE_LIFETIME: float = 0.3
const IMPACT_LIFETIME: float = 0.6
const DEATH_LIFETIME: float = 0.8


func spawn_muzzle_flash(at_position: Vector3, direction: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(10, MUZZLE_LIFETIME, Color(1.0, 0.8, 0.1, 1.0), 3.0, 8.0, 15.0, 3.0, 0.02, 0.06)
	_add_to_world(particles, at_position, direction, MUZZLE_LIFETIME)


func spawn_impact_flour(at_position: Vector3, normal: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(20, IMPACT_LIFETIME, Color(0.95, 0.9, 0.8, 0.8), 1.0, 4.0, 45.0, 1.5, 0.03, 0.1, -2.0)
	_add_to_world(particles, at_position, normal, IMPACT_LIFETIME)


func spawn_pickup_burst(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(15, 0.4, Color(1.0, 0.9, 0.3, 0.8), 1.5, 5.0, 30.0, 2.0, 0.02, 0.06, -1.5)
	_add_to_world(particles, at_position, Vector3.UP, 0.4)


func spawn_death_spark(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(25, DEATH_LIFETIME, Color(1.0, 0.5, 0.1, 0.9), 2.0, 6.0, 60.0, 2.0, 0.02, 0.08, -1.0)
	_add_to_world(particles, at_position, Vector3.UP, DEATH_LIFETIME)


func _create_particles(
	amount: int,
	lifetime: float,
	color: Color,
	velocity_min: float,
	velocity_max: float,
	spread: float,
	damping: float,
	scale_min: float,
	scale_max: float,
	gravity: float = 0.0
) -> GPUParticles3D:
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = amount
	particles.lifetime = lifetime
	particles.draw_order = 1
	
	var proc_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	proc_mat.particle_flag_disable_z = true
	proc_mat.emission_shape = 1  # EMISSION_SHAPE_SPHERE
	proc_mat.emission_sphere_radius = 0.1
	proc_mat.direction = Vector3(0, 0, 1)
	proc_mat.spread = spread
	proc_mat.gravity = Vector3(0, gravity, 0)
	proc_mat.initial_velocity_min = velocity_min
	proc_mat.initial_velocity_max = velocity_max
	proc_mat.scale_min = scale_min
	proc_mat.scale_max = scale_max
	proc_mat.color = color
	proc_mat.damping_min = damping
	proc_mat.damping_max = damping * 1.5
	proc_mat.lifetime_randomness = 0.3
	particles.process_material = proc_mat
	
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.billboard_mode = 3  # BILLBOARD_PARTICLES
	mat.transparency = 1  # TRANSPARENCY_ALPHA
	particles.material_override = mat
	
	return particles


func _add_to_world(particles: GPUParticles3D, pos: Vector3, dir: Vector3, lifetime: float) -> void:
	var root: Node = _get_world_root()
	if not root:
		particles.queue_free()
		return
	
	particles.global_position = pos
	if dir.length() > 0.001:
		particles.look_at(pos + dir.normalized(), Vector3.UP)
	root.add_child(particles)
	
	get_tree().create_timer(lifetime + 0.5).timeout.connect(
		_remove_particles.bind(particles)
	)


func _remove_particles(p: GPUParticles3D) -> void:
	if is_instance_valid(p):
		p.queue_free()


func _get_world_root() -> Node:
	var tree: SceneTree = get_tree()
	if not tree:
		return null
	var root: Node = tree.current_scene
	if not root:
		root = tree.root
	return root
