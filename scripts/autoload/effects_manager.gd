extends Node
## PHASE 4.4: Global effects manager autoload — VFX fixes.
## Spawns temporary particle effects (muzzle flash, bullet tracers, impact flour, death sparkles).
## Creates GPUParticles3D and meshes programmatically — no external scene files needed.

const MUZZLE_LIFETIME: float = 0.3
const IMPACT_LIFETIME: float = 0.6
const DEATH_LIFETIME: float = 0.8
const TRACER_LIFETIME: float = 0.07
const FLASH_CORE_LIFETIME: float = 0.05


func spawn_muzzle_flash(at_position: Vector3, direction: Vector3) -> void:
	# PHASE 4.4: Scaled-up muzzle flash — 25 particles, scale 0.15-0.35, larger emission radius
	var particles: GPUParticles3D = _create_particles(
		25, MUZZLE_LIFETIME, Color(1.0, 0.8, 0.1, 1.0),
		3.0, 8.0, 15.0, 3.0,
		0.15, 0.35, -1.0,
		0.2  # emission_radius
	)
	# Color gradient: bright yellow → orange → dark red
	_apply_muzzle_flash_gradient(particles)
	_add_to_world(particles, at_position, direction, MUZZLE_LIFETIME)
	# Flash core sphere
	_spawn_flash_core(at_position)


func _apply_muzzle_flash_gradient(particles: GPUParticles3D) -> void:
	if not particles.process_material is ParticleProcessMaterial:
		return
	var pmat: ParticleProcessMaterial = particles.process_material
	var grad := Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 0.9, 0.1, 1.0),  # Bright yellow
		Color(1.0, 0.5, 0.0, 0.8),  # Orange
		Color(0.6, 0.1, 0.0, 0.2),  # Dark red (fading)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = grad
	grad_tex.width = 256
	pmat.color_initial_ramp = grad_tex
	pmat.color = Color.WHITE  # Let the gradient control color


func _spawn_flash_core(at_position: Vector3) -> void:
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_inst.mesh = sphere
	mesh_inst.global_position = at_position

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.3)
	mat.emission_energy_multiplier = 4.0
	mat.shading_mode = 1  # UNSHADED
	mesh_inst.material_override = mat

	_add_mesh_to_world(mesh_inst, FLASH_CORE_LIFETIME)


func spawn_impact_flour(at_position: Vector3, normal: Vector3) -> void:
	# PHASE 4.4: Bigger impact — 40 particles, larger scale, stronger gravity/damping
	var particles: GPUParticles3D = _create_particles(
		40, IMPACT_LIFETIME, Color(0.95, 0.9, 0.8, 0.9),
		3.0, 8.0, 45.0, 2.5,
		0.1, 0.5, -3.0
	)
	_add_to_world(particles, at_position, normal, IMPACT_LIFETIME)
	# Dust cloud decal
	_spawn_dust_cloud(at_position, normal)


func _spawn_dust_cloud(at_position: Vector3, normal: Vector3) -> void:
	var mesh_inst := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.2, 1.2)
	mesh_inst.mesh = quad
	mesh_inst.global_position = at_position + normal * 0.05
	# Face the normal direction
	if normal.length() > 0.001:
		mesh_inst.look_at(at_position + normal, Vector3.UP)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.9, 0.8, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.9, 0.8)
	mat.emission_energy_multiplier = 0.3
	mat.billboard_mode = 2  # BILLBOARD_FIXED_Y
	mat.transparency = 1  # TRANSPARENCY_ALPHA
	mat.cull_mode = 2  # CULL_DISABLED
	mesh_inst.material_override = mat

	_add_mesh_to_world(mesh_inst, 0.4)


func spawn_pickup_burst(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(15, 0.4, Color(1.0, 0.9, 0.3, 0.8), 1.5, 5.0, 30.0, 2.0, 0.02, 0.06, -1.5)
	_add_to_world(particles, at_position, Vector3.UP, 0.4)


func spawn_death_spark(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(25, DEATH_LIFETIME, Color(1.0, 0.5, 0.1, 0.9), 2.0, 6.0, 60.0, 2.0, 0.02, 0.08, -1.0)
	_add_to_world(particles, at_position, Vector3.UP, DEATH_LIFETIME)


## PHASE 4.4: NEW — Bullet tracer system
func spawn_tracer(from: Vector3, to: Vector3, color: Color = Color.YELLOW) -> void:
	var mesh_inst := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.03
	cylinder.bottom_radius = 0.03
	cylinder.height = from.distance_to(to)
	cylinder.radial_segments = 8
	mesh_inst.mesh = cylinder

	# Position at midpoint, oriented from->to
	var mid_point := from.lerp(to, 0.5)
	mesh_inst.global_position = mid_point
	var dir := (to - from).normalized()
	if dir.length() > 0.001:
		# Align the cylinder (which stands on Y axis) with the direction
		var up := Vector3.UP
		var axis := up.cross(dir).normalized()
		var angle := up.angle_to(dir)
		if axis.length() > 0.001:
			mesh_inst.global_rotate(axis, angle)
		elif angle > 0.001:
			# Parallel case
			mesh_inst.global_rotate(Vector3.RIGHT, angle)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.transparency = 1  # TRANSPARENCY_ALPHA
	mat.cull_mode = 2  # CULL_DISABLED
	mesh_inst.material_override = mat

	_add_mesh_to_world(mesh_inst, TRACER_LIFETIME)


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
	gravity: float = 0.0,
	emission_radius: float = 0.1
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
	proc_mat.emission_sphere_radius = emission_radius
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


func _add_mesh_to_world(mesh_inst: MeshInstance3D, lifetime: float) -> void:
	var root: Node = _get_world_root()
	if not root:
		mesh_inst.queue_free()
		return
	root.add_child(mesh_inst)
	get_tree().create_timer(lifetime + 0.5).timeout.connect(
		_remove_mesh.bind(mesh_inst)
	)


func _remove_particles(p: GPUParticles3D) -> void:
	if is_instance_valid(p):
		p.queue_free()


func _remove_mesh(m: MeshInstance3D) -> void:
	if is_instance_valid(m):
		m.queue_free()


func _get_world_root() -> Node:
	var tree: SceneTree = get_tree()
	if not tree:
		return null
	var root: Node = tree.current_scene
	if not root:
		root = tree.root
	return root
