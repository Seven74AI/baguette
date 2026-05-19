class_name CroissantMeshGenerator
extends MeshInstance3D
## Generates a procedural croissant (crescent) shaped mesh using SurfaceTool.
## The shape: a tube that follows a curved (crescent) path with tapered ends.

@export var curve_radius: float = 0.8   ## Radius of the crescent curve
@export var tube_radius: float = 0.15    ## Thickness of the croissant tube
@export var arc_angle_deg: float = 200.0 ## How many degrees the crescent spans
@export var ring_segments: int = 16       ## Cross-section resolution
@export var path_segments: int = 24       ## Number of samples along the curve
@export var endpoint_taper: float = 0.3   ## How much the ends taper (0=no taper, 1=full taper)

func _ready() -> void:
	_generate_croissant_mesh()


func _generate_croissant_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var arc_rad: float = deg_to_rad(arc_angle_deg)
	var half_arc: float = arc_rad * 0.5
	
	# Generate vertices for each ring along the curved path
	var prev_ring: Array[Vector3] = []
	var first_ring: Array[Vector3] = []
	
	for pi in range(path_segments + 1):
		var t: float = float(pi) / float(path_segments)  # 0.0 to 1.0
		var angle: float = -half_arc + t * arc_rad  # From -half_arc to +half_arc
		
		# Point on the crescent curve (XY plane, curve goes in XZ horizontally)
		var center: Vector3 = Vector3(
			sin(angle) * curve_radius,  # X: left-right curve
			cos(angle) * curve_radius * 0.3,  # Y: slight vertical flattening
			0.0  # Z: depth
		)
		
		# Taper factor: 1.0 at center, smaller at endpoints
		var taper: float = 1.0
		if endpoint_taper > 0.0:
			var dist_from_center: float = abs(t - 0.5) * 2.0  # 0.0 at center, 1.0 at ends
			taper = 1.0 - dist_from_center * endpoint_taper
		
		var effective_radius: float = tube_radius * taper
		
		# Generate ring vertices around this path point
		var ring: Array[Vector3] = []
		for ri in range(ring_segments):
			var ring_angle: float = float(ri) / float(ring_segments) * TAU
			# Offset perpendicular to the curve direction (approximate)
			var tangent: Vector3 = Vector3(
				cos(angle) * curve_radius,
				-sin(angle) * curve_radius * 0.3,
				0.0
			).normalized()
			var up: Vector3 = Vector3(0, 0, 1)  # Z as up for the ring
			var right: Vector3 = tangent.cross(up).normalized()
			
			var offset: Vector3 = (up * cos(ring_angle) + right * sin(ring_angle)) * effective_radius
			var vert: Vector3 = center + offset
			ring.append(vert)
		
		if pi > 0:
			# Connect this ring to the previous ring with triangles
			for ri in range(ring_segments):
				var curr_a: int = ri
				var curr_b: int = (ri + 1) % ring_segments
				var prev_a: int = ri
				var prev_b: int = (ri + 1) % ring_segments
				
				# Triangle 1: prev_a -> curr_a -> curr_b
				st.add_vertex(prev_ring[prev_a])
				st.add_vertex(ring[curr_a])
				st.add_vertex(ring[curr_b])
				
				# Triangle 2: prev_a -> curr_b -> prev_b
				st.add_vertex(prev_ring[prev_a])
				st.add_vertex(ring[curr_b])
				st.add_vertex(prev_ring[prev_b])
		
		prev_ring = ring
		if pi == 0:
			first_ring = ring
	
	# Cap the ends
	if first_ring.size() > 0:
		var first_center: Vector3 = Vector3(
			sin(-half_arc) * curve_radius,
			cos(-half_arc) * curve_radius * 0.3,
			0.0
		)
		var last_center: Vector3 = Vector3(
			sin(half_arc) * curve_radius,
			cos(half_arc) * curve_radius * 0.3,
			0.0
		)
		
		# Cap first end
		for ri in range(ring_segments):
			var next_ri: int = (ri + 1) % ring_segments
			st.add_vertex(first_center)
			st.add_vertex(first_ring[next_ri])
			st.add_vertex(first_ring[ri])
		
		# Cap last end
		for ri in range(ring_segments):
			var next_ri: int = (ri + 1) % ring_segments
			st.add_vertex(last_center)
			st.add_vertex(prev_ring[ri])
			st.add_vertex(prev_ring[next_ri])
	
	st.generate_normals()
	mesh = st.commit()
