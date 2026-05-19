extends Node
## PHASE 4.4+4.7: Global effects manager autoload.
## Spawns particle effects — muzzle flash (core+particles), bullet tracers, impact flour,
## per-enemy death bursts (Baguette/Croissant/Sourdough/Touriste/Gordon Bleu), pickups.
## Creates GPUParticles3D and meshes programmatically — no external scene files needed.

const MUZZLE_LIFETIME: float = 0.3
const IMPACT_LIFETIME: float = 0.6
const DEATH_LIFETIME: float = 0.8
const TRACER_LIFETIME: float = 0.07
const FLASH_CORE_LIFETIME: float = 0.05
const CROISSANT_TRAIL_LIFETIME: float = 1.5
const PAIN_CHOCO_BURST_LIFETIME: float = 0.7
const PIERCE_FLASH_LIFETIME: float = 0.12
const BOSS_AURA_LIFETIME: float = 2.0
const PHASE_BURST_LIFETIME: float = 1.5
const FLOUR_DUST_LIFETIME: float = 3.0
const OVEN_SHIMMER_LIFETIME: float = 2.0
const STREET_AMBIANCE_LIFETIME: float = 5.0

## Death burst type — one per enemy archetype.
enum DeathBurstType {
	BAGUETTE,
	CROISSANT_NINJA,
	SOURDOUGH_BLOB,
	TOURISTE_ZOMBIE,
	GORDON_BLEU,
}


# ═══════════════════════════════════════════════════════════════
# Public API — muzzle flash (refactored: core sphere + particles)
# ═══════════════════════════════════════════════════════════════

## Spawns a muzzle flash at position, with core sphere glow + particle burst.
func spawn_muzzle_flash(at_position: Vector3, direction: Vector3) -> void:
	spawn_muzzle_flash_core(at_position)
	spawn_muzzle_particles(at_position, direction)


## Spawns a bright core sphere (flash center) — short-lived emissive sphere.
func spawn_muzzle_flash_core(at_position: Vector3) -> void:
	var sphere := MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	sphere.mesh = sphere_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.1)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material_override = mat

	sphere.position = at_position
	add_child(sphere)

	# Fade out and remove after MUZZLE_LIFETIME
	# Using create_timer (proven in GUT headless) instead of create_tween
	get_tree().create_timer(MUZZLE_LIFETIME).timeout.connect(sphere.queue_free)


## Spawns the muzzle flash particles — 25 particles, larger scale for 20m visibility.
func spawn_muzzle_particles(at_position: Vector3, direction: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(
		25, MUZZLE_LIFETIME, Color(1.0, 0.8, 0.1, 1.0),
		3.0, 8.0, 15.0, 3.0, 0.15, 0.35, -1.0, 0.2
	)
	_apply_muzzle_flash_gradient(particles)
	_add_to_world(particles, at_position, direction, MUZZLE_LIFETIME)


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


# ═══════════════════════════════════════════════════════════════
# Public API — impact flour, pickup burst, generic death spark
# ═══════════════════════════════════════════════════════════════

## Spawns impact flour — 40 particles, larger scale, gravity, visible at 20m.
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


## Spawns pickup burst — sparkles for loot.
func spawn_pickup_burst(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(
		15, 0.4, Color(1.0, 0.9, 0.3, 0.8),
		1.5, 5.0, 30.0, 2.0, 0.02, 0.06, -1.5
	)
	_add_to_world(particles, at_position, Vector3.UP, 0.4)


## Spawns generic death spark particles (legacy backward compat).
func spawn_death_spark(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(
		25, DEATH_LIFETIME, Color(1.0, 0.5, 0.1, 0.9),
		2.0, 6.0, 60.0, 2.0, 0.02, 0.08, -1.0
	)
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


# ═══════════════════════════════════════════════════════════════
# Public API — per-enemy death bursts (PHASE 4.7)
# ═══════════════════════════════════════════════════════════════

## Spawns a type-specific death burst effect at the given position.
## All effects are designed to be visible at 20m distance.
func spawn_death_burst(at_position: Vector3, type: DeathBurstType) -> void:
	match type:
		DeathBurstType.BAGUETTE:
			_spawn_death_baguette(at_position)
		DeathBurstType.CROISSANT_NINJA:
			_spawn_death_croissant(at_position)
		DeathBurstType.SOURDOUGH_BLOB:
			_spawn_death_sourdough(at_position)
		DeathBurstType.TOURISTE_ZOMBIE:
			_spawn_death_touriste(at_position)
		DeathBurstType.GORDON_BLEU:
			_spawn_death_gordon(at_position)


## Baguette Vivante: breadcrumb burst — 30 particles, brown/golden, scale 0.08-0.3.
func _spawn_death_baguette(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(
		30, 1.0, Color(0.82, 0.55, 0.2, 0.9),
		2.0, 5.0, 40.0, 1.5, 0.08, 0.3, -1.0
	)
	_add_to_world(particles, at_position, Vector3.UP, 1.0)


## Croissant Ninja: butter splat + crescent particle burst — 20 particles, yellow/butter.
func _spawn_death_croissant(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(
		20, 0.8, Color(1.0, 0.85, 0.2, 0.9),
		2.0, 6.0, 50.0, 2.0, 0.06, 0.2, -0.5
	)
	_add_to_world(particles, at_position, Vector3.UP, 0.8)


## Sourdough Blob: gooey splatter — 40 sticky droplets, beige/grey, scale 0.1-0.4, low velocity.
func _spawn_death_sourdough(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(
		40, 1.2, Color(0.75, 0.7, 0.55, 0.85),
		1.0, 3.0, 30.0, 1.0, 0.1, 0.4, -1.5
	)
	_add_to_world(particles, at_position, Vector3.UP, 1.2)


## Touriste Zombie: camera flash + large sparks — 35 particles, bright white/yellow.
func _spawn_death_touriste(at_position: Vector3) -> void:
	# Camera flash (no-op in headless, visual only in game)
	_trigger_camera_flash()
	# Large white/yellow sparks for visibility
	var particles: GPUParticles3D = _create_particles(
		35, 0.9, Color(1.0, 1.0, 0.8, 0.9),
		3.0, 7.0, 50.0, 2.0, 0.1, 0.35, -0.5
	)
	_add_to_world(particles, at_position, Vector3.UP, 0.9)


## Gordon Bleu: dramatic flour explosion — 60 particles, scale 0.2-0.8, velocity 5-15, screen shake.
func _spawn_death_gordon(at_position: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(
		60, 1.5, Color(0.95, 0.9, 0.8, 0.9),
		5.0, 15.0, 60.0, 3.0, 0.2, 0.8, -2.0
	)
	_add_to_world(particles, at_position, Vector3.UP, 1.5)
	# Dramatic screen shake
	_trigger_screen_shake(10.0)


# ═══════════════════════════════════════════════════════════════
# Public API — weapon-specific VFX (PHASE 5.1b)
# ═══════════════════════════════════════════════════════════════

## Spawns a golden trail ribbon for the croissant boomerang projectile.
## Continuous particles (one_shot=false) — follows the projectile trajectory.
func spawn_croissant_trail(at_position: Vector3, direction: Vector3) -> void:
	var particles: GPUParticles3D = _create_particles(
		15, CROISSANT_TRAIL_LIFETIME, Color(0.9, 0.7, 0.15, 0.8),
		0.3, 1.0, 5.0, 0.5, 0.04, 0.12, -0.1, 0.05
	)
	# Continuous ribbon — not one_shot
	particles.one_shot = false
	particles.lifetime = CROISSANT_TRAIL_LIFETIME
	_add_to_world(particles, at_position, direction, CROISSANT_TRAIL_LIFETIME)


## Spawns a fire/explosion burst for pain au chocolat launcher impact.
## Sphere burst + large fire particles with orange/red palette.
func spawn_pain_au_chocolat_burst(at_position: Vector3, normal: Vector3) -> void:
	# Fire burst particles — 35 particles, orange-red
	var particles: GPUParticles3D = _create_particles(
		35, PAIN_CHOCO_BURST_LIFETIME, Color(1.0, 0.45, 0.05, 0.95),
		4.0, 10.0, 50.0, 2.5, 0.08, 0.25, -0.8, 0.3
	)
	_add_to_world(particles, at_position, normal, PAIN_CHOCO_BURST_LIFETIME)

	# Smoke puff mesh at impact
	var mesh_inst := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.5, 1.5)
	mesh_inst.mesh = quad
	mesh_inst.global_position = at_position + normal * 0.1
	if normal.length() > 0.001:
		mesh_inst.look_at(at_position + normal, Vector3.UP)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.2, 0.15, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.25, 0.05)
	mat.emission_energy_multiplier = 1.0
	mat.billboard_mode = 2  # BILLBOARD_FIXED_Y
	mat.transparency = 1  # TRANSPARENCY_ALPHA
	mat.cull_mode = 2  # CULL_DISABLED
	mesh_inst.material_override = mat

	_add_mesh_to_world(mesh_inst, 0.5)


## Spawns an enhanced pierce flash for the baguette gun.
## Creates a linear streak (golden-brown cylinder) + impact spark particles.
func spawn_baguette_pierce_flash(from: Vector3, to: Vector3) -> void:
	# Linear streak mesh
	var mesh_inst := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.06
	cylinder.bottom_radius = 0.06
	cylinder.height = from.distance_to(to)
	cylinder.radial_segments = 8
	mesh_inst.mesh = cylinder

	var mid_point := from.lerp(to, 0.5)
	mesh_inst.global_position = mid_point
	var dir := (to - from).normalized()
	if dir.length() > 0.001:
		var up := Vector3.UP
		var axis := up.cross(dir).normalized()
		var angle := up.angle_to(dir)
		if axis.length() > 0.001:
			mesh_inst.global_rotate(axis, angle)
		elif angle > 0.001:
			mesh_inst.global_rotate(Vector3.RIGHT, angle)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.7, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = 1  # TRANSPARENCY_ALPHA
	mat.cull_mode = 2  # CULL_DISABLED
	mesh_inst.material_override = mat

	_add_mesh_to_world(mesh_inst, PIERCE_FLASH_LIFETIME)

	# Impact spark particles at the target point
	var spark: GPUParticles3D = _create_particles(
		12, 0.25, Color(1.0, 0.85, 0.2, 0.9),
		1.5, 4.0, 25.0, 1.5, 0.03, 0.08, -0.3, 0.1
	)
	_add_to_world(spark, to, Vector3.UP, 0.25)


# ═══════════════════════════════════════════════════════════════
# Public API — boss VFX placeholders (PHASE 5.1b)
# ═══════════════════════════════════════════════════════════════

## Spawns an energy aura (glow outline) around a boss at the given position.
## Creates a translucent sphere mesh with emission glow.
func spawn_boss_aura(at_position: Vector3, radius: float) -> void:
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	mesh_inst.mesh = sphere
	mesh_inst.global_position = at_position

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.2, 0.8, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.1, 1.0)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = 1  # TRANSPARENCY_ALPHA
	mat.cull_mode = 2  # CULL_DISABLED
	mat.shading_mode = 1  # UNSHADED
	mesh_inst.material_override = mat

	_add_mesh_to_world(mesh_inst, BOSS_AURA_LIFETIME)


## Spawns a phase transition burst — expanding ring + particle shockwave.
## Used when a boss transitions between phases.
func spawn_phase_transition_burst(at_position: Vector3, radius: float) -> void:
	# Expanding ring mesh (torus approximation via cylinder ring visual)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.8
	torus.outer_radius = radius * 1.0
	ring.mesh = torus
	ring.global_position = at_position

	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.5, 0.9, 0.6)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.8, 0.3, 1.0)
	ring_mat.emission_energy_multiplier = 3.0
	ring_mat.transparency = 1  # TRANSPARENCY_ALPHA
	ring_mat.cull_mode = 2  # CULL_DISABLED
	ring_mat.shading_mode = 1  # UNSHADED
	ring.material_override = ring_mat

	_add_mesh_to_world(ring, PHASE_BURST_LIFETIME)

	# Shockwave particles
	var particles: GPUParticles3D = _create_particles(
		40, PHASE_BURST_LIFETIME, Color(0.8, 0.4, 1.0, 0.85),
		4.0, 12.0, 60.0, 2.0, 0.06, 0.2, -0.5, 0.5
	)
	_add_to_world(particles, at_position, Vector3.UP, PHASE_BURST_LIFETIME)


# ═══════════════════════════════════════════════════════════════
# Public API — environmental particles (PHASE 5.1b)
# ═══════════════════════════════════════════════════════════════

## Spawns floating flour dust motes for bakery interior ambiance.
## Continuous warm white particles with very low velocity (drifting).
func spawn_flour_dust(at_position: Vector3, radius: float) -> void:
	var particles: GPUParticles3D = _create_particles(
		20, FLOUR_DUST_LIFETIME, Color(0.95, 0.92, 0.82, 0.6),
		0.1, 0.5, 360.0, 0.2, 0.02, 0.08, 0.05, radius
	)
	particles.one_shot = false
	particles.lifetime = FLOUR_DUST_LIFETIME
	particles.amount = 20
	_add_to_world(particles, at_position, Vector3.UP, FLOUR_DUST_LIFETIME)


## Spawns oven heat shimmer — warm glow + heat distortion particles.
## Used near oven props in bakery interiors.
func spawn_oven_heat_shimmer(at_position: Vector3, radius: float) -> void:
	# Warm glow sphere
	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius * 0.5
	sphere.height = radius
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_inst.mesh = sphere
	mesh_inst.global_position = at_position

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.1, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.05)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = 1  # TRANSPARENCY_ALPHA
	mat.cull_mode = 2  # CULL_DISABLED
	mat.shading_mode = 1  # UNSHADED
	mesh_inst.material_override = mat

	_add_mesh_to_world(mesh_inst, OVEN_SHIMMER_LIFETIME)

	# Rising heat particles
	var particles: GPUParticles3D = _create_particles(
		10, OVEN_SHIMMER_LIFETIME, Color(1.0, 0.7, 0.3, 0.4),
		0.2, 0.8, 15.0, 0.3, 0.03, 0.1, 0.3, radius
	)
	particles.one_shot = false
	particles.lifetime = OVEN_SHIMMER_LIFETIME
	_add_to_world(particles, at_position, Vector3.UP, OVEN_SHIMMER_LIFETIME)


## Spawns Parisian street ambiance — dust motes, paper scraps, distant effects.
## Large radius ambient particle system for street environments.
func spawn_street_ambiance(at_position: Vector3, radius: float) -> void:
	# Main dust/ambient particles — spread across large radius
	var particles: GPUParticles3D = _create_particles(
		25, STREET_AMBIANCE_LIFETIME, Color(0.75, 0.72, 0.68, 0.5),
		0.05, 0.4, 360.0, 0.1, 0.01, 0.06, 0.02, radius
	)
	particles.one_shot = false
	particles.lifetime = STREET_AMBIANCE_LIFETIME
	_add_to_world(particles, at_position, Vector3.UP, STREET_AMBIANCE_LIFETIME)


# ═══════════════════════════════════════════════════════════════
# Internal helpers — camera flash & screen shake
# ═══════════════════════════════════════════════════════════════

## Triggers a brief white camera flash (visual only — no-op in headless).
func _trigger_camera_flash() -> void:
	# In headless tests this is a no-op — no crash, no errors.
	# In-game, a Camera3D flash overlay would be triggered.
	# The particles alone provide the visible death effect.
	pass


## Triggers screen shake by finding a ScreenShake node in the scene tree.
func _trigger_screen_shake(intensity: float) -> void:
	var tree := get_tree()
	if not tree:
		return
	# Search via group (preferred)
	var shake_nodes := tree.get_nodes_in_group("screen_shake")
	if shake_nodes.size() > 0:
		for node in shake_nodes:
			if node.has_method("trigger"):
				node.trigger(intensity, 0.5)
				return
	# Fallback: recursive name search
	if tree.root:
		var shake := tree.root.find_child("ScreenShake", true, false)
		if shake and shake.has_method("trigger"):
			shake.trigger(intensity, 0.5)


# ═══════════════════════════════════════════════════════════════
# Internal — particle creation & lifecycle
# ═══════════════════════════════════════════════════════════════

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
