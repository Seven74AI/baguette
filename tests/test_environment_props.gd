extends "res://addons/gut/test.gd"
## TDD tests for Phase 4.6: Environment Props — Bakery & Parisian Street props.
## Verifies that each prop scene loads, has MeshInstance3D visual geometry,
## props spawn correctly in dungeon rooms by type, and bakery color palette
## materials are applied.

const DungeonGenerator = preload("res://scripts/procedural/dungeon_generator.gd")

# ── Prop scene preloads ────────────────────────────────────────────
const BakeryRackScene = preload("res://scenes/props/bakery_rack.tscn")
const OvenPropScene = preload("res://scenes/props/oven_prop.tscn")
const CounterDisplayScene = preload("res://scenes/props/counter_display.tscn")
const FlourSackScene = preload("res://scenes/props/flour_sack.tscn")
const CroissantCrateScene = preload("res://scenes/props/croissant_crate.tscn")
const StreetLampScene = preload("res://scenes/props/street_lamp.tscn")
const BenchPropScene = preload("res://scenes/props/bench_prop.tscn")
const AbandonedCarScene = preload("res://scenes/props/abandoned_car.tscn")

# ── Bakery color palette (from Phase 4 spec) ───────────────────────
const BAKERY_COLORS := [
	Color(0.82, 0.68, 0.45),  # Baguette crust gold
	Color(0.55, 0.35, 0.15),  # Wood shelf brown
	Color(0.95, 0.90, 0.75),  # Cream / flour white
	Color(0.50, 0.30, 0.10),  # Dark wood
	Color(0.80, 0.60, 0.10),  # Warm gold
	Color(0.40, 0.40, 0.45),  # Oven metal grey
]

var _spawned: Array[Node] = []


func after_each() -> void:
	for node in _spawned:
		if is_instance_valid(node):
			node.queue_free()
	_spawned.clear()


func _spawn(scene: PackedScene) -> Node:
	var instance := scene.instantiate()
	if instance:
		add_child(instance)
		_spawned.append(instance)
	return instance


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result:
			return result
	return null


func _count_mesh_instances(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		count += 1
	for child in node.get_children():
		count += _count_mesh_instances(child)
	return count


func _find_material_color(node: MeshInstance3D) -> Color:
	# Check surface_override_material (used by .tscn surface_material_override/N)
	var surf_mat := node.get_surface_override_material(0)
	if surf_mat and surf_mat is StandardMaterial3D:
		return (surf_mat as StandardMaterial3D).albedo_color
	# Check material_override
	if node.material_override and node.material_override is StandardMaterial3D:
		return (node.material_override as StandardMaterial3D).albedo_color
	# Check mesh primitive material
	if node.mesh and node.mesh is PrimitiveMesh:
		var pm: PrimitiveMesh = node.mesh as PrimitiveMesh
		if pm.material and pm.material is StandardMaterial3D:
			return (pm.material as StandardMaterial3D).albedo_color
	return Color.BLACK


# ─────────────────────────────────────────────────────────────────
# Model existence — every prop must have a MeshInstance3D
# ─────────────────────────────────────────────────────────────────

func test_bakery_rack_loads() -> void:
	var prop := _spawn(BakeryRackScene)
	assert_not_null(prop, "BakeryRack scene should instantiate")
	var mesh := _find_mesh_instance(prop)
	assert_not_null(mesh, "BakeryRack should have MeshInstance3D")

func test_oven_prop_loads() -> void:
	var prop := _spawn(OvenPropScene)
	assert_not_null(prop, "OvenProp scene should instantiate")
	var mesh := _find_mesh_instance(prop)
	assert_not_null(mesh, "OvenProp should have MeshInstance3D")

func test_counter_display_loads() -> void:
	var prop := _spawn(CounterDisplayScene)
	assert_not_null(prop, "CounterDisplay scene should instantiate")
	var mesh := _find_mesh_instance(prop)
	assert_not_null(mesh, "CounterDisplay should have MeshInstance3D")

func test_flour_sack_loads() -> void:
	var prop := _spawn(FlourSackScene)
	assert_not_null(prop, "FlourSack scene should instantiate")
	var mesh := _find_mesh_instance(prop)
	assert_not_null(mesh, "FlourSack should have MeshInstance3D")

func test_croissant_crate_loads() -> void:
	var prop := _spawn(CroissantCrateScene)
	assert_not_null(prop, "CroissantCrate scene should instantiate")
	var mesh := _find_mesh_instance(prop)
	assert_not_null(mesh, "CroissantCrate should have MeshInstance3D")

func test_street_lamp_loads() -> void:
	var prop := _spawn(StreetLampScene)
	assert_not_null(prop, "StreetLamp scene should instantiate")
	var mesh := _find_mesh_instance(prop)
	assert_not_null(mesh, "StreetLamp should have MeshInstance3D")

func test_bench_prop_loads() -> void:
	var prop := _spawn(BenchPropScene)
	assert_not_null(prop, "BenchProp scene should instantiate")
	var mesh := _find_mesh_instance(prop)
	assert_not_null(mesh, "BenchProp should have MeshInstance3D")

func test_abandoned_car_loads() -> void:
	var prop := _spawn(AbandonedCarScene)
	assert_not_null(prop, "AbandonedCar scene should instantiate")
	var mesh := _find_mesh_instance(prop)
	assert_not_null(mesh, "AbandonedCar should have MeshInstance3D")


# ─────────────────────────────────────────────────────────────────
# Prop spawning — dungeon generator must spawn props in rooms
# ─────────────────────────────────────────────────────────────────

func test_dungeon_generator_spawns_props() -> void:
	var gen := DungeonGenerator.new()
	gen.floor_size = Vector2(100.0, 100.0)
	gen.room_count = 8
	gen.min_room_size = 4.0
	gen.max_room_size = 12.0
	gen.seed = 42
	add_child_autofree(gen)
	gen.generate()

	# After generation, there should be prop containers under the generator
	var prop_containers := 0
	for child in gen.get_children():
		if child is Node3D and ("Props" in child.name):
			prop_containers += 1
	assert_gt(prop_containers, 0, "Dungeon generator should spawn prop containers")


# ─────────────────────────────────────────────────────────────────
# Room-type prop assignment — bakery props in boulangerie, street in rue
# ─────────────────────────────────────────────────────────────────

func test_boulangerie_rooms_get_bakery_props() -> void:
	var gen := DungeonGenerator.new()
	gen.floor_size = Vector2(200.0, 200.0)
	gen.room_count = 15
	gen.min_room_size = 6.0
	gen.max_room_size = 12.0
	gen.seed = 7
	add_child_autofree(gen)
	gen.generate()

	var found_boulangerie_props := false
	for child in gen.get_children():
		if child is Node3D and "BoulangerieProps" in child.name:
			found_boulangerie_props = true
			break
	assert_true(found_boulangerie_props, "At least one room should have BoulangerieProps container")


func test_rue_rooms_get_street_props() -> void:
	var gen := DungeonGenerator.new()
	gen.floor_size = Vector2(200.0, 200.0)
	gen.room_count = 15
	gen.min_room_size = 6.0
	gen.max_room_size = 12.0
	gen.seed = 7
	add_child_autofree(gen)
	gen.generate()

	var found_rue_props := false
	for child in gen.get_children():
		if child is Node3D and "RueProps" in child.name:
			found_rue_props = true
			break
	assert_true(found_rue_props, "At least one room should have RueProps container")


# ─────────────────────────────────────────────────────────────────
# Bakery color palette — materials must use bakery theme colors
# ─────────────────────────────────────────────────────────────────

func test_bakery_rack_uses_palette_colors() -> void:
	var prop := _spawn(BakeryRackScene)
	assert_not_null(prop, "BakeryRack should instantiate")
	_assert_has_palette_color(prop, "BakeryRack")

func test_oven_prop_uses_palette_colors() -> void:
	var prop := _spawn(OvenPropScene)
	assert_not_null(prop, "OvenProp should instantiate")
	_assert_has_palette_color(prop, "OvenProp")

func test_street_lamp_uses_bakery_colors() -> void:
	var prop := _spawn(StreetLampScene)
	assert_not_null(prop, "StreetLamp should instantiate")
	# Pole should be dark (bakery dark), light should be warm gold
	var has_warm_color := false
	var mesh := _find_mesh_instance(prop)
	while mesh:
		var col := _find_material_color(mesh)
		if _color_in_palette(col):
			has_warm_color = true
			break
		mesh = _find_next_mesh_after(prop, mesh)
	assert_true(has_warm_color, "StreetLamp should use bakery palette (warm gold light or dark pole)")


# ─────────────────────────────────────────────────────────────────
# Prop geometry — verify props have reasonable mesh count
# ─────────────────────────────────────────────────────────────────

func test_bakery_rack_has_multiple_meshes() -> void:
	var prop := _spawn(BakeryRackScene)
	var count := _count_mesh_instances(prop)
	assert_gt(count, 1, "BakeryRack should have multiple mesh parts (shelf + baguettes)")

func test_oven_prop_has_multiple_meshes() -> void:
	var prop := _spawn(OvenPropScene)
	var count := _count_mesh_instances(prop)
	assert_gt(count, 1, "OvenProp should have multiple mesh parts (body + glow)")

func test_abandoned_car_has_multiple_meshes() -> void:
	var prop := _spawn(AbandonedCarScene)
	var count := _count_mesh_instances(prop)
	assert_gt(count, 2, "AbandonedCar should have multiple mesh parts (body + wheels + windows)")


# ── Helpers ────────────────────────────────────────────────────────

func _color_in_palette(col: Color) -> bool:
	for pal_col in BAKERY_COLORS:
		var dist: float = abs(col.r - pal_col.r) + abs(col.g - pal_col.g) + abs(col.b - pal_col.b)
		if dist < 0.4:
			return true
	return false


func _assert_has_palette_color(prop: Node, prop_name: String) -> void:
	var mesh := _find_mesh_instance(prop)
	var found := false
	while mesh:
		var col := _find_material_color(mesh)
		if _color_in_palette(col):
			found = true
			break
		mesh = _find_next_mesh_after(prop, mesh)
	assert_true(found, "%s should use bakery palette colors" % prop_name)


func _find_next_mesh_after(root: Node, current: MeshInstance3D) -> MeshInstance3D:
	var found_current := false
	return _find_next_mesh_recursive(root, current, found_current)


func _find_next_mesh_recursive(node: Node, current: MeshInstance3D, found_current: bool) -> MeshInstance3D:
	if node is MeshInstance3D:
		if found_current:
			return node
		if node == current:
			found_current = true
	for child in node.get_children():
		var result := _find_next_mesh_recursive(child, current, found_current)
		if result:
			return result
	return null
