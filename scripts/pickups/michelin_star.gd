extends "res://scripts/loot/pickup.gd"
## Michelin Star pickup — grants temporary critical hit chance bonus.
## Dropped by Michelin Etoile Perdu on death.
## Gold star with rotating animation and glow.

@export var crit_chance_bonus: float = 0.30  ## +30% crit chance


func _ready() -> void:
	super._ready()
	loot_type = PickupType.SPEED_BUFF  # Reuse buff infrastructure
	buff_id = "crit"
	pickup_value = crit_chance_bonus
	buff_duration = 15.0  # 15 second crit buff

	# Override the visual to be a gold star (procedural)
	_clear_default_visual()
	_create_star_visual()


## Remove any default children added by Pickup._ready() visuals.
func _clear_default_visual() -> void:
	for child in get_children():
		if child is MeshInstance3D or child is CollisionShape3D:
			child.queue_free()


## Create a star-shaped visual for the Michelin Star pickup.
func _create_star_visual() -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.25
	sphere.height = 0.5
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.0, 0.9)  # Gold
	mat.roughness = 0.1
	mat.metallic = 0.8
	mat.emission = Color(1.0, 0.7, 0.0)
	mat.emission_energy_multiplier = 2.0
	mesh.material_override = mat
	add_child(mesh)

	# Add collision shape for pickup
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.6
	cs.shape = shape
	add_child(cs)


## Override collect to apply crit buff to GameState.
func collect() -> void:
	# Apply crit buff via GameState buff system
	if GameState:
		GameState.add_buff("crit", crit_chance_bonus, buff_duration)

	# Sound + particle burst
	if SoundManager:
		SoundManager.play_pickup_sound()
	if EffectsManager:
		EffectsManager.spawn_pickup_burst(global_position)

	collected.emit(self)
	queue_free()
