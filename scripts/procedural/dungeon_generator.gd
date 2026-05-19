extends Node
## Procedural dungeon generator — random room placement with corridor connections.
## Generates floor layouts with themed rooms, spawn points, and CSG decoration.
##
## Architecture:
## - Random room placement: tries random positions within floor bounds,
##   rejects overlapping placements (with padding).
## - Room connection: Prim's minimum spanning tree over room centers,
##   producing a connected graph with no cycles.
## - Theme assignment: cycles through the 3 themes (cuisine, boulangerie, rue).
## - Spawn points: first generated room = player start, last = boss room.
## - CSG props: each room gets 3-5 themed CSG shapes as decoration.

const DungeonRoom = preload("res://scripts/procedural/room.gd")
const DungeonCorridor = preload("res://scripts/procedural/corridor.gd")

# ── Prop scene preloads ──────────────────────────────────────────
const BakeryRackScene = preload("res://scenes/props/bakery_rack.tscn")
const OvenPropScene = preload("res://scenes/props/oven_prop.tscn")
const CounterDisplayScene = preload("res://scenes/props/counter_display.tscn")
const FlourSackScene = preload("res://scenes/props/flour_sack.tscn")
const CroissantCrateScene = preload("res://scenes/props/croissant_crate.tscn")
const StreetLampScene = preload("res://scenes/props/street_lamp.tscn")
const BenchPropScene = preload("res://scenes/props/bench_prop.tscn")
const AbandonedCarScene = preload("res://scenes/props/abandoned_car.tscn")

const THEMES: Array = ["cuisine", "boulangerie", "rue"]
const MAX_PLACEMENT_ATTEMPTS: int = 100

var floor_size: Vector2 = Vector2(100.0, 100.0)
var room_count: int = 8
var min_room_size: float = 4.0
var max_room_size: float = 12.0
var corridor_width: float = 2.0
var seed: int = 0

var rooms: Array = []        # Array[DungeonRoom]
var corridors: Array = []    # Array[DungeonCorridor]
var start_room = null        # DungeonRoom
var boss_room = null         # DungeonRoom

var _rng: RandomNumberGenerator = null


func generate() -> void:
	# Idempotent: clear previous state
	_clear_scene()
	_clear()

	_rng = RandomNumberGenerator.new()
	_rng.seed = self.seed

	_place_rooms()
	_connect_rooms()
	_assign_themes()
	_assign_spawn_points()
	_spawn_csg_props()


func _clear() -> void:
	rooms.clear()
	corridors.clear()
	start_room = null
	boss_room = null


func _clear_scene() -> void:
	# Remove previously spawned CSG children
	for child in get_children():
		child.queue_free()


func _place_rooms() -> void:
	for _i in range(room_count):
		var room = _try_place_room()
		if room != null:
			rooms.append(room)
		else:
			break


func _try_place_room():
	for _attempt in range(MAX_PLACEMENT_ATTEMPTS):
		var w: float = _rng.randf_range(min_room_size, max_room_size)
		var h: float = _rng.randf_range(min_room_size, max_room_size)

		var max_x: float = floor_size.x - w
		var max_y: float = floor_size.y - h
		if max_x < 0.0 or max_y < 0.0:
			return null

		var x: float = _rng.randf_range(0.0, max_x)
		var y: float = _rng.randf_range(0.0, max_y)

		var candidate = DungeonRoom.new()
		candidate.position = Vector2(x, y)
		candidate.size = Vector2(w, h)

		if not _overlaps_existing(candidate):
			return candidate

	return null


func _overlaps_existing(room) -> bool:
	for existing in rooms:
		if existing.overlaps(room):
			return true
	return false


func _connect_rooms() -> void:
	if rooms.size() <= 1:
		return

	# Prim's minimum spanning tree
	var in_tree: Array = []
	in_tree.resize(rooms.size())
	in_tree.fill(false)
	in_tree[0] = true
	var edges_added: int = 0

	while edges_added < rooms.size() - 1:
		var best_from: int = -1
		var best_to: int = -1
		var best_dist: float = INF

		for i in range(rooms.size()):
			if not in_tree[i]:
				continue
			for j in range(rooms.size()):
				if in_tree[j]:
					continue
				var dist: float = rooms[i].get_center().distance_to(
					rooms[j].get_center())
				if dist < best_dist:
					best_dist = dist
					best_from = i
					best_to = j

		if best_to < 0:
			break

		in_tree[best_to] = true
		edges_added += 1

		var corr = DungeonCorridor.new()
		corr.from_room = rooms[best_from]
		corr.to_room = rooms[best_to]
		corr.build_path()
		corridors.append(corr)


func _assign_themes() -> void:
	for i in range(rooms.size()):
		rooms[i].theme = THEMES[i % THEMES.size()]


func _assign_spawn_points() -> void:
	if rooms.size() >= 1:
		start_room = rooms[0]
		start_room.is_start = true
	if rooms.size() >= 2:
		boss_room = rooms[rooms.size() - 1]
		boss_room.is_boss = true


# ── CSG Decoration ────────────────────────────────────────────────

func _spawn_csg_props() -> void:
	for room in rooms:
		var r = room
		match r.theme:
			"cuisine":
				_spawn_cuisine_props(r)
			"boulangerie":
				_spawn_boulangerie_props(r)
			"rue":
				_spawn_rue_props(r)


func _spawn_cuisine_props(room) -> void:
	var props_root := Node3D.new()
	props_root.name = "CuisineProps"
	add_child(props_root)
	props_root.owner = self

	var cx: float = room.position.x + room.size.x * 0.5
	var cz: float = room.position.y + room.size.y * 0.5

	# 1. Oven (large box)
	_spawn_csg_box(props_root, "Oven", Vector3(cx - 2, 1.0, cz), Vector3(2, 2, 1.5), Color(0.4, 0.4, 0.45))

	# 2. Counter (wide flat box)
	_spawn_csg_box(props_root, "Counter", Vector3(cx + 1.5, 0.8, cz - 1), Vector3(3, 0.3, 1), Color(0.5, 0.4, 0.3))

	# 3. Hanging pot (cylinder + sphere)
	var pot := CSGCombiner3D.new()
	pot.name = "HangingPot"
	var cyl := CSGCylinder3D.new()
	cyl.height = 0.5
	cyl.radius = 0.3
	cyl.position = Vector3(cx + 1, 2.0, cz + 1.5)
	pot.add_child(cyl)
	var lid := CSGSphere3D.new()
	lid.radius = 0.35
	lid.position = Vector3(cx + 1, 2.3, cz + 1.5)
	pot.add_child(lid)
	props_root.add_child(pot)
	pot.owner = self

	# 4. Ingredient pile (cluster of small boxes)
	for _i in range(4):
		var ix: float = _rng.randf_range(-1.0, 1.0)
		var iz: float = _rng.randf_range(-1.0, 1.0)
		_spawn_csg_box(props_root, "Ingredient", Vector3(cx + ix + 2, 0.3, cz + iz), Vector3(0.5, 0.5, 0.5), Color(0.7, 0.5, 0.2), true)


func _spawn_boulangerie_props(room) -> void:
	var props_root := Node3D.new()
	props_root.name = "BoulangerieProps"
	add_child(props_root)
	props_root.owner = self

	var cx: float = room.position.x + room.size.x * 0.5
	var cz: float = room.position.y + room.size.y * 0.5

	# 1. Bakery rack with baguettes
	_spawn_prop_instance(BakeryRackScene, props_root, "BakeryRack", Vector3(cx - 1.5, 0, cz))

	# 2. Oven with glow
	_spawn_prop_instance(OvenPropScene, props_root, "Oven", Vector3(cx + 1.5, 0, cz - 1))

	# 3. Counter display case
	_spawn_prop_instance(CounterDisplayScene, props_root, "CounterDisplay", Vector3(cx + 1.5, 0, cz + 1))

	# 4. Flour sack
	_spawn_prop_instance(FlourSackScene, props_root, "FlourSack", Vector3(cx - 0.8, 0, cz + 1.5))

	# 5. Flour sack #2
	_spawn_prop_instance(FlourSackScene, props_root, "FlourSack2", Vector3(cx - 1.8, 0, cz + 1.8))

	# 6. Croissant crate
	_spawn_prop_instance(CroissantCrateScene, props_root, "CroissantCrate", Vector3(cx + 2.5, 0, cz + 2))


func _spawn_rue_props(room) -> void:
	var props_root := Node3D.new()
	props_root.name = "RueProps"
	add_child(props_root)
	props_root.owner = self

	var cx: float = room.position.x + room.size.x * 0.5
	var cz: float = room.position.y + room.size.y * 0.5

	# 1. Street lamp
	_spawn_prop_instance(StreetLampScene, props_root, "StreetLamp", Vector3(cx - 2, 0, cz - 2))

	# 2. Street lamp #2
	_spawn_prop_instance(StreetLampScene, props_root, "StreetLamp2", Vector3(cx + 2, 0, cz - 2))

	# 3. Bench
	_spawn_prop_instance(BenchPropScene, props_root, "Bench", Vector3(cx + 2, 0, cz + 1))

	# 4. Abandoned car
	var car_inst := AbandonedCarScene.instantiate()
	car_inst.name = "AbandonedCar"
	car_inst.position = Vector3(cx + 2, 0, cz + 3)
	car_inst.rotation_degrees = Vector3(0, _rng.randf_range(0, 360), 0)
	props_root.add_child(car_inst)
	car_inst.owner = self

	# 5. Bench #2
	_spawn_prop_instance(BenchPropScene, props_root, "Bench2", Vector3(cx - 3, 0, cz + 2))


# ── CSG Helpers (kept for cuisine props) ──────────────────────────

func _spawn_prop_instance(scene: PackedScene, parent: Node3D, name: String, pos: Vector3) -> void:
	var inst := scene.instantiate()
	inst.name = name
	inst.position = pos
	parent.add_child(inst)
	inst.owner = self

func _spawn_csg_box(parent: Node3D, name: String, pos: Vector3, size: Vector3, col: Color, use_rng_offset: bool = false) -> void:
	var box := CSGBox3D.new()
	box.name = name
	box.size = size
	if use_rng_offset:
		box.position = pos + Vector3(_rng.randf_range(-0.3, 0.3), 0, _rng.randf_range(-0.3, 0.3))
	else:
		box.position = pos
	_set_material_color(box, col)
	parent.add_child(box)
	box.owner = self


func _set_material_color(node: CSGShape3D, col: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.8
	node.material = mat
