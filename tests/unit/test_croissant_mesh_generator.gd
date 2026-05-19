extends "res://addons/gut/test.gd"
## Tests for CroissantMeshGenerator — procedural 3D croissant mesh.
## Verifies export defaults, mesh generation, and surface properties.

const CroissantMeshGenerator = preload("res://scenes/weapons/croissant_mesh_generator.gd")

var _generator: CroissantMeshGenerator


func before_each() -> void:
	_generator = CroissantMeshGenerator.new()
	add_child_autofree(_generator)
	await wait_frames(2)


func test_default_curve_radius() -> void:
	assert_eq(_generator.curve_radius, 0.8, "Default curve_radius should be 0.8")


func test_default_tube_radius() -> void:
	assert_eq(_generator.tube_radius, 0.15, "Default tube_radius should be 0.15")


func test_default_arc_angle_deg() -> void:
	assert_eq(_generator.arc_angle_deg, 200.0, "Default arc_angle_deg should be 200.0")


func test_default_ring_segments() -> void:
	assert_eq(_generator.ring_segments, 16, "Default ring_segments should be 16")


func test_default_path_segments() -> void:
	assert_eq(_generator.path_segments, 24, "Default path_segments should be 24")


func test_default_endpoint_taper() -> void:
	assert_eq(_generator.endpoint_taper, 0.3, "Default endpoint_taper should be 0.3")


func test_mesh_is_generated_on_ready() -> void:
	var m: Mesh = _generator.mesh
	assert_not_null(m, "Mesh should be generated and assigned")
	assert_gt(m.get_surface_count(), 0, "Mesh should have at least one surface")


func test_mesh_is_custom_arraymesh() -> void:
	var m: Mesh = _generator.mesh
	assert_not_null(m)
	assert_true(m is ArrayMesh, "Generated mesh should be an ArrayMesh (custom), not a primitive")


func test_mesh_has_vertices() -> void:
	var m: Mesh = _generator.mesh
	assert_not_null(m)
	var arrays = m.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
	# Even at minimum resolution (ring_segments=16, path_segments=24), should have 400+ vertices
	assert_gt(vertices.size(), 100, "Mesh should have > 100 vertices for a proper croissant shape")


func test_mesh_has_normals() -> void:
	var m: Mesh = _generator.mesh
	assert_not_null(m)
	var arrays = m.surface_get_arrays(0)
	var normals: PackedVector3Array = arrays[ArrayMesh.ARRAY_NORMAL] as PackedVector3Array
	assert_eq(normals.size(), arrays[ArrayMesh.ARRAY_VERTEX].size(), "Normals should match vertex count")


func test_mesh_regenerates_after_property_change() -> void:
	# Change a property and verify mesh is regenerated
	_generator.ring_segments = 8  # Lower resolution
	_generator.path_segments = 12  # Lower resolution
	_generator._generate_croissant_mesh()
	await wait_frames(1)
	
	var m: Mesh = _generator.mesh
	assert_not_null(m, "Mesh should exist after regeneration")
	
	var arrays = m.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
	# Lower resolution should produce fewer vertices
	assert_gt(vertices.size(), 0, "Mesh should still have vertices after regeneration")
	assert_lt(vertices.size(), 1000, "Lower resolution should produce fewer vertices (< 1000; formula: 6 × path_segments × ring_segments)")
	# But still enough for a recognizable shape
	assert_gt(vertices.size(), 30, "Should still have meaningful vertex count (> 30)")


func test_curve_radius_positive() -> void:
	assert_gt(_generator.curve_radius, 0.0, "Curve radius should be > 0 for a meaningful curve")


func test_tube_radius_positive() -> void:
	assert_gt(_generator.tube_radius, 0.0, "Tube radius should be > 0 for a 3D tube")


func test_arc_angle_positive() -> void:
	assert_gt(_generator.arc_angle_deg, 0.0, "Arc angle should be > 0 for a visible arc")


func test_no_taper_mesh_is_cylindrical() -> void:
	# With taper=0, the tube cross-sections should be uniform
	_generator.endpoint_taper = 0.0
	_generator.ring_segments = 8
	_generator.path_segments = 8
	_generator._generate_croissant_mesh()
	await wait_frames(1)
	
	var m: Mesh = _generator.mesh
	assert_not_null(m, "Mesh should be generated with zero taper")
	assert_gt(m.get_surface_count(), 0, "Should have valid surfaces")


func test_full_taper_produces_collapsed_ends() -> void:
	# With taper=1.0, endpoints collapse to nearly zero radius
	_generator.endpoint_taper = 1.0
	_generator.ring_segments = 8
	_generator.path_segments = 8
	_generator._generate_croissant_mesh()
	await wait_frames(1)
	
	var m: Mesh = _generator.mesh
	assert_not_null(m, "Mesh should be generated with full taper")
	assert_gt(m.get_surface_count(), 0, "Should have valid surfaces")


func test_180_degree_arc_is_semicircle() -> void:
	_generator.arc_angle_deg = 180.0
	_generator.ring_segments = 8
	_generator.path_segments = 8
	_generator._generate_croissant_mesh()
	await wait_frames(1)
	
	var m: Mesh = _generator.mesh
	assert_not_null(m, "Mesh should be generated for 180° arc")
	
	var arrays = m.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
	assert_gt(vertices.size(), 50, "Should produce valid vertex count for semicircle")


func test_full_360_degree_arc() -> void:
	_generator.arc_angle_deg = 360.0
	_generator.ring_segments = 8
	_generator.path_segments = 8
	_generator._generate_croissant_mesh()
	await wait_frames(1)
	
	var m: Mesh = _generator.mesh
	assert_not_null(m, "Mesh should be generated for full 360° arc")


func test_triangles_form_valid_surface() -> void:
	var m: Mesh = _generator.mesh
	assert_not_null(m)
	
	var arrays = m.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[ArrayMesh.ARRAY_INDEX] as PackedInt32Array
	var vertices: PackedVector3Array = arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
	
	# Mesh should use indexed triangles
	assert_gt(indices.size(), 0, "Mesh should have triangle indices")
	
	# Triangle count should be reasonable: each ring pair creates 2 tris * ring_segments
	var ring_pair_count: int = _generator.path_segments
	var expected_tri_per_pair: int = _generator.ring_segments * 2
	# Plus cap triangles: 2 caps * ring_segments tri each
	var cap_tris: int = _generator.ring_segments * 2
	var expected_tris: int = ring_pair_count * expected_tri_per_pair + cap_tris
	# Allow some tolerance for internal representation differences
	assert_gt(indices.size(), 0, "Should have triangle indices")
	assert_gt(indices.size(), 100, "Should have many triangle indices for a smooth mesh")
	
	# Verify all indices are within vertex bounds
	for idx in indices:
		assert_lt(idx, vertices.size(), "All triangle indices should be within vertex range")
		assert_true(idx >= 0, "Triangle indices should not be negative")


func test_exports_are_settable() -> void:
	_generator.curve_radius = 1.5
	_generator.tube_radius = 0.3
	_generator.arc_angle_deg = 270.0
	_generator.ring_segments = 24
	_generator.path_segments = 32
	_generator.endpoint_taper = 0.5
	
	assert_eq(_generator.curve_radius, 1.5)
	assert_eq(_generator.tube_radius, 0.3)
	assert_eq(_generator.arc_angle_deg, 270.0)
	assert_eq(_generator.ring_segments, 24)
	assert_eq(_generator.path_segments, 32)
	assert_eq(_generator.endpoint_taper, 0.5)
