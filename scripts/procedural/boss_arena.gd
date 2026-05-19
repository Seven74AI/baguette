extends Node3D
## Boss Arena room — builds when a dungeon room has is_boss=true.
## Creates a large circular arena with thematic elements:
## - Grand entrance doors that lock behind the player
## - Giant oven backdrop
## - Dough pits (hazard zones)
## - Flour dust atmospheric particles
##
## Integration: the dungeon generator instantiates this scene for
## the boss room instead of regular CSG props.

const HealthComponent = preload("res://scripts/components/health_component.gd")
const GordonBleu = preload("res://scenes/enemies/gordon_bleu.gd")

signal boss_defeated
signal doors_locked
signal doors_unlocked

@export_category("Arena Dimensions")
@export var arena_radius: float = 12.0
@export var wall_height: float = 6.0
@export var wall_thickness: float = 0.5
@export var wall_segments: int = 32  ## Circular arena wall segments

@export_category("Doors")
@export var door_width: float = 3.0
@export var door_height: float = 4.0

@export_category("Thematic Elements")
@export var oven_scale: float = 4.0
@export var dough_pit_count: int = 3
@export var dough_pit_radius: float = 1.5
@export var flour_particle_count: int = 30

## Reference to the dungeon room data (assigned by dungeon generator).
var room_data = null  ## DungeonRoom

var _doors: Array[CSGBox3D] = []
var _doors_locked: bool = false
var _boss: GordonBleu = null
var _boss_spawn_point: Marker3D = null


func _ready() -> void:
	_build_arena()


## Builds the entire arena geometry. Called once in _ready.
## Public so dungeon generators / tests can rebuild.
func _build_arena() -> void:
	# Clear any existing children (use remove_child for immediate removal)
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_doors.clear()

	_create_arena_floor()
	_create_arena_walls()
	_create_entrance_doors()
	_create_oven_backdrop()
	_create_dough_pits()
	_create_flour_particles()
	_create_boss_spawn_point()


# ═══════════════════════════════════════════════════════════════
# Arena Structure
# ═══════════════════════════════════════════════════════════════

## Create the arena floor (large flat CSG box).
func _create_arena_floor() -> void:
	var floor := CSGBox3D.new()
	floor.name = "ArenaFloor"
	floor.size = Vector3(arena_radius * 2.0, 0.2, arena_radius * 2.0)
	floor.position = Vector3(0, -0.1, 0)
	floor.material = _make_material(Color(0.35, 0.30, 0.28), 0.85)
	floor.use_collision = true
	add_child(floor)
	floor.owner = self


## Create circular arena walls from CSG box segments.
func _create_arena_walls() -> void:
	var walls_parent := Node3D.new()
	walls_parent.name = "ArenaWalls"
	add_child(walls_parent)
	walls_parent.owner = self

	var segment_angle := TAU / float(wall_segments)
	var segment_width := 2.0 * PI * arena_radius / float(wall_segments) + 0.1

	for i in range(wall_segments):
		var angle := float(i) * segment_angle
		var wall := CSGBox3D.new()
		wall.name = "WallSegment_" + str(i)
		wall.size = Vector3(segment_width, wall_height, wall_thickness)

		# Position on circle perimeter
		var x := cos(angle) * arena_radius
		var z := sin(angle) * arena_radius
		wall.position = Vector3(x, wall_height * 0.5, z)

		# Rotate to face center
		wall.rotation.y = angle + PI * 0.5

		wall.material = _make_material(Color(0.5, 0.35, 0.2), 0.9)
		wall.use_collision = true
		walls_parent.add_child(wall)
		wall.owner = self


## Create grand entrance doors (two large CSG boxes that slide open/closed).
func _create_entrance_doors() -> void:
	var door_half := door_width * 0.5

	var left_door := CSGBox3D.new()
	left_door.name = "LeftDoor"
	left_door.size = Vector3(door_half, door_height, wall_thickness * 2.0)
	left_door.position = Vector3(-door_half * 0.5, door_height * 0.5, -arena_radius)
	left_door.material = _make_material(Color(0.45, 0.25, 0.12), 0.7)
	left_door.use_collision = true
	add_child(left_door)
	left_door.owner = self
	_doors.append(left_door)

	var right_door := CSGBox3D.new()
	right_door.name = "RightDoor"
	right_door.size = Vector3(door_half, door_height, wall_thickness * 2.0)
	right_door.position = Vector3(door_half * 0.5, door_height * 0.5, -arena_radius)
	right_door.material = _make_material(Color(0.45, 0.25, 0.12), 0.7)
	right_door.use_collision = true
	add_child(right_door)
	right_door.owner = self
	_doors.append(right_door)


# ═══════════════════════════════════════════════════════════════
# Thematic Decoration
# ═══════════════════════════════════════════════════════════════

## Giant oven backdrop against the arena wall.
func _create_oven_backdrop() -> void:
	var oven := CSGCombiner3D.new()
	oven.name = "GiantOven"
	add_child(oven)
	oven.owner = self

	# Oven body (large box at the far end)
	var body := CSGBox3D.new()
	body.name = "OvenBody"
	body.size = Vector3(oven_scale * 1.5, oven_scale * 1.2, oven_scale * 0.8)
	body.position = Vector3(0, oven_scale * 0.6, arena_radius - oven_scale * 0.4)
	body.material = _make_material(Color(0.25, 0.22, 0.2), 0.6)
	oven.add_child(body)

	# Oven door (darker rectangle inset)
	var door := CSGBox3D.new()
	door.name = "OvenDoor"
	door.size = Vector3(oven_scale * 1.0, oven_scale * 0.5, 0.1)
	door.position = Vector3(0, oven_scale * 0.5, arena_radius - oven_scale * 0.8 - 0.05)
	door.material = _make_material(Color(0.15, 0.12, 0.08), 0.5)
	oven.add_child(door)

	# Oven glow (emissive panel — red/orange glow)
	var glow := CSGBox3D.new()
	glow.name = "OvenGlow"
	glow.size = Vector3(oven_scale * 0.6, oven_scale * 0.3, 0.01)
	glow.position = Vector3(0, oven_scale * 0.4, arena_radius - oven_scale * 0.85)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1.0, 0.4, 0.1)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.3, 0.0)
	glow_mat.emission_energy_multiplier = 2.0
	glow.material = glow_mat
	oven.add_child(glow)


## Create dough pits (hazard zones on the arena floor).
func _create_dough_pits() -> void:
	for i in range(dough_pit_count):
		var angle := float(i) / float(dough_pit_count) * TAU + 0.3
		var dist := arena_radius * 0.5

		var pit := CSGCylinder3D.new()
		pit.name = "DoughPit_" + str(i)
		pit.radius = dough_pit_radius
		pit.height = 0.05
		pit.position = Vector3(
			cos(angle) * dist,
			0.02,  # Just above floor
			sin(angle) * dist
		)
		pit.material = _make_material(Color(0.82, 0.71, 0.55), 0.4)
		add_child(pit)
		pit.owner = self

		# Add small rim
		var rim := CSGCylinder3D.new()
		rim.name = "DoughPitRim_" + str(i)
		rim.radius = dough_pit_radius + 0.15
		rim.height = 0.1
		rim.position = pit.position + Vector3(0, 0.05, 0)
		rim.material = _make_material(Color(0.35, 0.30, 0.28), 0.9)
		add_child(rim)
		rim.owner = self


## Create floating flour dust particles (small CSG spheres).
func _create_flour_particles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Deterministic for reproducibility

	for i in range(flour_particle_count):
		var particle := CSGSphere3D.new()
		particle.name = "FlourParticle_" + str(i)
		particle.radius = rng.randf_range(0.05, 0.15)
		particle.position = Vector3(
			rng.randf_range(-arena_radius * 0.9, arena_radius * 0.9),
			rng.randf_range(0.5, wall_height * 0.7),
			rng.randf_range(-arena_radius * 0.9, arena_radius * 0.9)
		)
		var particle_mat := StandardMaterial3D.new()
		particle_mat.albedo_color = Color(1.0, 1.0, 0.95, 0.4)
		particle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		particle.material = particle_mat
		add_child(particle)
		particle.owner = self


# ═══════════════════════════════════════════════════════════════
# Boss Spawn
# ═══════════════════════════════════════════════════════════════

## Create a marker for where the boss should spawn.
func _create_boss_spawn_point() -> void:
	_boss_spawn_point = Marker3D.new()
	_boss_spawn_point.name = "BossSpawnPoint"
	_boss_spawn_point.position = Vector3(0, 0, arena_radius * 0.3)
	add_child(_boss_spawn_point)
	_boss_spawn_point.owner = self


## Return the world position where the boss should spawn.
func get_boss_spawn_position() -> Vector3:
	if _boss_spawn_point:
		return _boss_spawn_point.global_position
	return global_position + Vector3(0, 0, arena_radius * 0.3)


# ═══════════════════════════════════════════════════════════════
# Door Controls
# ═══════════════════════════════════════════════════════════════

## Lock the entrance doors (call when boss fight starts).
func lock_doors() -> void:
	_doors_locked = true
	doors_locked.emit()

	# Change door color to indicate locked state
	for door in _doors:
		door.material = _make_material(Color(0.6, 0.1, 0.1), 0.7)


## Unlock the entrance doors (call when boss is defeated).
func unlock_doors() -> void:
	_doors_locked = false
	doors_unlocked.emit()

	# Remove doors — they slide open
	for door in _doors:
		door.queue_free()
	_doors.clear()


## Returns whether the doors are currently locked.
func are_doors_locked() -> bool:
	return _doors_locked


# ═══════════════════════════════════════════════════════════════
# Boss Integration
# ═══════════════════════════════════════════════════════════════

## Spawn the boss in the arena.
## Returns the spawned GordonBleu instance.
func spawn_boss() -> GordonBleu:
	if _boss and is_instance_valid(_boss):
		return _boss

	_boss = GordonBleu.new()
	_boss.name = "GordonBleu"
	_boss.position = get_boss_spawn_position()

	# Create health component BEFORE adding to tree so _ready() finds it
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 2000
	hc.current_health = 2000
	_boss.add_child(hc)
	_boss.health_component = hc

	add_child(_boss)
	_boss.owner = self

	# Connect boss death to unlock doors
	if not _boss.died.is_connected(_on_boss_died):
		_boss.died.connect(_on_boss_died)

	return _boss


## Callback when the boss dies — unlock doors and emit boss_defeated.
func _on_boss_died() -> void:
	unlock_doors()
	boss_defeated.emit()


## Get the boss reference (null if not spawned yet).
func get_boss() -> GordonBleu:
	return _boss


# ═══════════════════════════════════════════════════════════════
# Utility
# ═══════════════════════════════════════════════════════════════

func _make_material(color: Color, roughness: float = 0.8) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
