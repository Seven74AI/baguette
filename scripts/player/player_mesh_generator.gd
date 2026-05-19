class_name PlayerMeshGenerator
extends MeshInstance3D
## Generates a procedural low-poly MITCH player character mesh.
## MITCH is the bakery mitron (apprentice baker) — stylized low-poly
## aesthetic matching existing enemy models.
##
## Features: torso with apron, head with toque, arms, legs, baguette holster.

@export var body_height: float = 1.8
@export var body_radius: float = 0.25
@export var head_radius: float = 0.18
@export var limb_radius: float = 0.09
@export var segments: int = 8  # Low-poly segments for cylinders


func _ready() -> void:
	generate_mitch_mesh()


## Generate the complete MITCH character mesh.
## All body parts are built with SurfaceTool and combined into one ArrayMesh.
func generate_mitch_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Colors from the bakery palette
	var skin_color := Color(1.0, 0.85, 0.73)  # Peachy skin
	var apron_color := Color(0.96, 0.94, 0.88)  # Cream-white apron (Palette.CREAM)
	var pants_color := Color(0.29, 0.29, 0.29)  # Dark grey pants (Palette.COBBLESTONE_GREY)
	var toque_color := Color(0.96, 0.94, 0.88)  # White toque
	var holster_color := Color(0.55, 0.37, 0.24)  # Brown leather (Palette.CRUST)
	var shoe_color := Color(0.55, 0.37, 0.24)  # Brown shoes

	# ── Proportions (total height ~1.8m) ──
	var ground_y: float = 0.0
	var leg_height: float = 0.55
	var torso_bottom_y: float = ground_y + leg_height  # 0.55
	var torso_height: float = 0.55
	var torso_top_y: float = torso_bottom_y + torso_height  # 1.1
	var head_center_y: float = torso_top_y + head_radius * 0.7  # ~1.23
	var toque_bottom_y: float = head_center_y + head_radius * 0.8  # ~1.37
	var toque_height: float = 0.22

	# ── Body part helpers ──
	_add_cylinder_surface(st, Vector3(0, torso_bottom_y + torso_height * 0.5, 0),
		torso_height, body_radius, skin_color)

	# Apron — flat panel on front of torso (slightly wider, thin)
	_add_apron(st, Vector3(0, torso_bottom_y + torso_height * 0.5, 0),
		torso_height, body_radius * 1.3, apron_color)

	# Legs
	var leg_offset_x: float = body_radius * 0.4
	_add_cylinder_surface(st, Vector3(-leg_offset_x, leg_height * 0.5, 0),
		leg_height, limb_radius, pants_color)
	_add_cylinder_surface(st, Vector3(leg_offset_x, leg_height * 0.5, 0),
		leg_height, limb_radius, pants_color)

	# Shoes
	var shoe_height: float = 0.08
	_add_box_surface(st, Vector3(-leg_offset_x, shoe_height * 0.5, limb_radius * 0.5),
		Vector3(limb_radius * 1.8, shoe_height, limb_radius * 2.5), shoe_color)
	_add_box_surface(st, Vector3(leg_offset_x, shoe_height * 0.5, limb_radius * 0.5),
		Vector3(limb_radius * 1.8, shoe_height, limb_radius * 2.5), shoe_color)

	# Arms
	var arm_length: float = 0.5
	var shoulder_y: float = torso_top_y - 0.05
	var arm_offset_x: float = body_radius + limb_radius
	_add_cylinder_surface(st, Vector3(-arm_offset_x, shoulder_y - arm_length * 0.5, 0),
		arm_length, limb_radius, skin_color)
	_add_cylinder_surface(st, Vector3(arm_offset_x, shoulder_y - arm_length * 0.5, 0),
		arm_length, limb_radius, skin_color)

	# Head
	_add_sphere_surface(st, Vector3(0, head_center_y, 0), head_radius, skin_color)

	# Toque (chef hat) — cylinder base + wider top
	var toque_radius: float = head_radius * 1.1
	var toque_top_radius: float = head_radius * 1.4
	var toque_band_height: float = toque_height * 0.35
	var toque_puff_height: float = toque_height * 0.65
	var toque_band_center_y: float = toque_bottom_y + toque_band_height * 0.5
	var toque_puff_center_y: float = toque_bottom_y + toque_band_height + toque_puff_height * 0.5

	_add_cylinder_surface(st, Vector3(0, toque_band_center_y, 0),
		toque_band_height, toque_radius, toque_color)
	_add_cylinder_surface(st, Vector3(0, toque_puff_center_y, 0),
		toque_puff_height, toque_top_radius, toque_color)

	# Baguette holster on back
	var holster_y: float = torso_bottom_y + torso_height * 0.55
	_add_box_surface(st, Vector3(0, holster_y, -body_radius - 0.03),
		Vector3(body_radius * 0.7, 0.1, 0.06), holster_color)

	# Baguette in holster (golden-brown)
	var baguette_y: float = holster_y + 0.05
	_add_cylinder_surface(st, Vector3(0, baguette_y, -body_radius - 0.08),
		0.45, 0.03, Color(0.83, 0.64, 0.33))  # Golden brown

	st.generate_normals()
	mesh = st.commit()


# ── Primitive builders ──

## Add a cylinder surface centered at position, oriented along Y axis.
func _add_cylinder_surface(st: SurfaceTool, center: Vector3, height: float,
		radius: float, color: Color) -> void:
	var half_h: float = height * 0.5
	var n: int = segments

	# Side faces
	for i in range(n):
		var angle0: float = TAU * float(i) / float(n)
		var angle1: float = TAU * float(i + 1) / float(n)

		var x0: float = cos(angle0) * radius
		var z0: float = sin(angle0) * radius
		var x1: float = cos(angle1) * radius
		var z1: float = sin(angle1) * radius

		var nx0: float = cos(angle0)
		var nz0: float = sin(angle0)
		var nx1: float = cos(angle1)
		var nz1: float = sin(angle1)

		# Triangle 1: bottom-left, bottom-right, top-right
		st.set_normal(Vector3(nx0, 0, nz0))
		st.set_color(color)
		st.add_vertex(center + Vector3(x0, -half_h, z0))
		st.set_normal(Vector3(nx1, 0, nz1))
		st.add_vertex(center + Vector3(x1, -half_h, z1))
		st.set_normal(Vector3(nx1, 0, nz1))
		st.add_vertex(center + Vector3(x1, half_h, z1))

		# Triangle 2: bottom-left, top-right, top-left
		st.set_normal(Vector3(nx0, 0, nz0))
		st.add_vertex(center + Vector3(x0, -half_h, z0))
		st.set_normal(Vector3(nx1, 0, nz1))
		st.add_vertex(center + Vector3(x1, half_h, z1))
		st.set_normal(Vector3(nx0, 0, nz0))
		st.add_vertex(center + Vector3(x0, half_h, z0))

	# Top cap
	for i in range(n):
		var angle0: float = TAU * float(i) / float(n)
		var angle1: float = TAU * float(i + 1) / float(n)
		var x0: float = cos(angle0) * radius
		var z0: float = sin(angle0) * radius
		var x1: float = cos(angle1) * radius
		var z1: float = sin(angle1) * radius

		st.set_normal(Vector3.UP)
		st.set_color(color)
		st.add_vertex(center + Vector3(x0, half_h, z0))
		st.add_vertex(center + Vector3(x1, half_h, z1))
		st.add_vertex(center + Vector3(0, half_h, 0))

	# Bottom cap
	for i in range(n):
		var angle0: float = TAU * float(i) / float(n)
		var angle1: float = TAU * float(i + 1) / float(n)
		var x0: float = cos(angle0) * radius
		var z0: float = sin(angle0) * radius
		var x1: float = cos(angle1) * radius
		var z1: float = sin(angle1) * radius

		st.set_normal(Vector3.DOWN)
		st.set_color(color)
		st.add_vertex(center + Vector3(x0, -half_h, z0))
		st.add_vertex(center + Vector3(0, -half_h, 0))
		st.add_vertex(center + Vector3(x1, -half_h, z1))


## Add an apron — flat panel on front of torso.
func _add_apron(st: SurfaceTool, center: Vector3, torso_height: float,
		width: float, color: Color) -> void:
	var half_h: float = torso_height * 0.5
	var half_w: float = width * 0.5
	var depth_offset: float = body_radius + 0.01  # Slightly in front of body
	var verts := [
		Vector3(-half_w, -half_h, depth_offset),
		Vector3(half_w, -half_h, depth_offset),
		Vector3(half_w, half_h, depth_offset),
		Vector3(-half_w, half_h, depth_offset),
	]
	# Shift by center
	for i in range(verts.size()):
		verts[i] += center
		# Keep Z at the apron offset from center
		verts[i].z = depth_offset

	st.set_normal(Vector3.FORWARD)
	st.set_color(color)
	st.add_vertex(verts[0])
	st.add_vertex(verts[1])
	st.add_vertex(verts[2])
	st.set_normal(Vector3.FORWARD)
	st.set_color(color)
	st.add_vertex(verts[0])
	st.add_vertex(verts[2])
	st.add_vertex(verts[3])

	# Add apron strings (thin back strip)
	st.set_normal(Vector3.BACK)
	st.set_color(color)
	st.add_vertex(Vector3(-half_w * 0.3, -half_h, -body_radius - 0.01) + center)
	st.add_vertex(Vector3(half_w * 0.3, -half_h, -body_radius - 0.01) + center)
	st.add_vertex(Vector3(half_w * 0.3, half_h, -body_radius - 0.01) + center)
	st.add_vertex(Vector3(-half_w * 0.3, -half_h, -body_radius - 0.01) + center)
	st.add_vertex(Vector3(half_w * 0.3, half_h, -body_radius - 0.01) + center)
	st.add_vertex(Vector3(-half_w * 0.3, half_h, -body_radius - 0.01) + center)


## Add an axis-aligned box surface.
func _add_box_surface(st: SurfaceTool, center: Vector3, size: Vector3,
		color: Color) -> void:
	var half := size * 0.5

	# Define 6 faces with normals
	var faces := [
		{"normal": Vector3.FORWARD,  "verts": _box_face(center, half, Vector3.FORWARD)},
		{"normal": Vector3.BACK,     "verts": _box_face(center, half, Vector3.BACK)},
		{"normal": Vector3.RIGHT,    "verts": _box_face(center, half, Vector3.RIGHT)},
		{"normal": Vector3.LEFT,     "verts": _box_face(center, half, Vector3.LEFT)},
		{"normal": Vector3.UP,       "verts": _box_face(center, half, Vector3.UP)},
		{"normal": Vector3.DOWN,     "verts": _box_face(center, half, Vector3.DOWN)},
	]

	for face in faces:
		var n: Vector3 = face["normal"]
		var v: Array = face["verts"]
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(v[0])
		st.add_vertex(v[1])
		st.add_vertex(v[2])
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(v[0])
		st.add_vertex(v[2])
		st.add_vertex(v[3])


func _box_face(center: Vector3, half: Vector3, normal: Vector3) -> Array:
	# Two tangents perpendicular to normal
	var abs_n := Vector3(abs(normal.x), abs(normal.y), abs(normal.z))
	var tangent1: Vector3
	var tangent2: Vector3

	if abs_n.x > 0.5:
		tangent1 = Vector3(0, normal.x, 0)
		tangent2 = Vector3(0, 0, normal.x)
	else:
		tangent1 = Vector3(0, 0, -normal.y)
		tangent2 = Vector3(-normal.y, 0, 0)

	var n_component := Vector3(
		half.x * normal.x,
		half.y * normal.y,
		half.z * normal.z
	)
	var t1_component := Vector3(
		half.x * tangent1.x,
		half.y * tangent1.y,
		half.z * tangent1.z
	)
	var t2_component := Vector3(
		half.x * tangent2.x,
		half.y * tangent2.y,
		half.z * tangent2.z
	)

	return [
		center + n_component - t1_component - t2_component,
		center + n_component - t1_component + t2_component,
		center + n_component + t1_component + t2_component,
		center + n_component + t1_component - t2_component,
	]


## Add a UV-sphere surface.
func _add_sphere_surface(st: SurfaceTool, center: Vector3, radius: float,
		color: Color) -> void:
	var rings: int = max(4, segments / 2)
	var segs: int = segments

	for r in range(rings):
		var phi0: float = PI * float(r) / float(rings) - PI * 0.5
		var phi1: float = PI * float(r + 1) / float(rings) - PI * 0.5

		for s in range(segs):
			var theta0: float = TAU * float(s) / float(segs)
			var theta1: float = TAU * float(s + 1) / float(segs)

			var p00 := _sphere_point(radius, phi0, theta0)
			var p10 := _sphere_point(radius, phi1, theta0)
			var p11 := _sphere_point(radius, phi1, theta1)
			var p01 := _sphere_point(radius, phi0, theta1)

			# Triangle 1
			st.set_normal(p00.normalized())
			st.set_color(color)
			st.add_vertex(center + p00)
			st.set_normal(p10.normalized())
			st.add_vertex(center + p10)
			st.set_normal(p11.normalized())
			st.add_vertex(center + p11)

			# Triangle 2
			st.set_normal(p00.normalized())
			st.add_vertex(center + p00)
			st.set_normal(p11.normalized())
			st.add_vertex(center + p11)
			st.set_normal(p01.normalized())
			st.add_vertex(center + p01)


func _sphere_point(radius: float, phi: float, theta: float) -> Vector3:
	return Vector3(
		radius * cos(phi) * cos(theta),
		radius * sin(phi),
		radius * cos(phi) * sin(theta)
	)
