#!/usr/bin/env godot4 -s
## Tool script to generate .glb enemy model files procedurally.
## Run with: godot4 --headless --path . -s scripts/generate_enemy_models.gd
extends SceneTree

const OUTPUT_DIR = "res://assets/models/enemies"

func _init() -> void:
	print("=== Generating Enemy .glb Files ===")
	
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	
	_generate_baguette_vivante()
	_generate_croissant_ninja()
	_generate_sourdough_blob()
	_generate_touriste_zombie()
	_generate_gordon_bleu()
	
	print("=== All models generated ===")
	quit(0)


func _save_glb(name: String, root_node: Node3D) -> void:
	var path := OUTPUT_DIR + "/" + name + ".glb"
	
	var gltf_doc := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	
	var err := gltf_doc.append_from_scene(root_node, gltf_state)
	if err != OK:
		printerr("Failed to append scene for ", name, ": ", err)
		return
	
	err = gltf_doc.write_to_filesystem(gltf_state, path)
	if err != OK:
		printerr("Failed to write GLB for ", name, ": ", err)
	else:
		print("  Created: ", path)


func _make_material(color: Color, roughness := 0.6, metallic := 0.0, name := "") -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if name:
		mat.resource_name = name
	return mat


# ─── Baguette Vivante ───────────────────────────
func _generate_baguette_vivante() -> void:
	var root := Node3D.new()
	root.name = "BaguetteVivanteModel"
	
	# Main body: scaled baguette (elongated cylinder, tapered ends)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var baguette_mesh := CylinderMesh.new()
	baguette_mesh.top_radius = 0.12
	baguette_mesh.bottom_radius = 0.18
	baguette_mesh.height = 1.6
	body.mesh = baguette_mesh
	body.position = Vector3(0, 0.8, 0)
	body.scale = Vector3(1.0, 1.0, 1.0)
	body.material_override = _make_material(Color(0.82, 0.68, 0.45), 0.7, 0.0, "BaguetteCrust")
	root.add_child(body)
	
	# Left eye
	var left_eye := MeshInstance3D.new()
	left_eye.name = "LeftEye"
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.1
	eye_mesh.height = 0.2
	left_eye.mesh = eye_mesh
	left_eye.position = Vector3(-0.12, 1.5, -0.12)
	left_eye.material_override = _make_material(Color.WHITE, 0.1, 0.0, "EyeWhite")
	root.add_child(left_eye)
	
	# Left pupil
	var left_pupil := MeshInstance3D.new()
	left_pupil.name = "LeftPupil"
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = 0.05
	pupil_mesh.height = 0.1
	left_pupil.mesh = pupil_mesh
	left_pupil.position = Vector3(-0.12, 1.5, -0.2)
	left_pupil.material_override = _make_material(Color.BLACK, 0.0, 0.0, "Pupil")
	root.add_child(left_pupil)
	
	# Right eye
	var right_eye := MeshInstance3D.new()
	right_eye.name = "RightEye"
	right_eye.mesh = eye_mesh.duplicate()
	right_eye.position = Vector3(0.12, 1.5, -0.12)
	right_eye.material_override = _make_material(Color.WHITE, 0.1, 0.0, "EyeWhite")
	root.add_child(right_eye)
	
	# Right pupil
	var right_pupil := MeshInstance3D.new()
	right_pupil.name = "RightPupil"
	right_pupil.mesh = pupil_mesh.duplicate()
	right_pupil.position = Vector3(0.12, 1.5, -0.2)
	right_pupil.material_override = _make_material(Color.BLACK, 0.0, 0.0, "Pupil")
	root.add_child(right_pupil)
	
	_save_glb("baguette_vivante", root)


# ─── Croissant Ninja ───────────────────────────
func _generate_croissant_ninja() -> void:
	var root := Node3D.new()
	root.name = "CroissantNinjaModel"
	
	# Main body: curved croissant shape (approximated as curved cylinder stack)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var croissant_mesh := CylinderMesh.new()
	croissant_mesh.top_radius = 0.15
	croissant_mesh.bottom_radius = 0.22
	croissant_mesh.height = 1.0
	body.mesh = croissant_mesh
	body.position = Vector3(0, 0.7, 0)
	body.rotation_degrees = Vector3(0, 0, 15)  # Crescent tilt
	body.material_override = _make_material(Color(0.92, 0.72, 0.28), 0.2, 0.1, "CroissantGolden")
	root.add_child(body)
	
	# Headband (flat black ring around top)
	var headband := MeshInstance3D.new()
	headband.name = "Headband"
	var band_mesh := CylinderMesh.new()
	band_mesh.top_radius = 0.25
	band_mesh.bottom_radius = 0.25
	band_mesh.height = 0.08
	headband.mesh = band_mesh
	headband.position = Vector3(0, 1.15, 0)
	headband.material_override = _make_material(Color(0.15, 0.15, 0.15), 0.3, 0.1, "NinjaBlack")
	root.add_child(headband)
	
	# Left arm (cylinder)
	var left_arm := MeshInstance3D.new()
	left_arm.name = "LeftArm"
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.06
	arm_mesh.bottom_radius = 0.08
	arm_mesh.height = 0.6
	left_arm.mesh = arm_mesh
	left_arm.position = Vector3(-0.25, 0.6, 0)
	left_arm.rotation_degrees = Vector3(0, 0, 20)
	left_arm.material_override = _make_material(Color(0.92, 0.72, 0.28), 0.3, 0.05, "CroissantLimb")
	root.add_child(left_arm)
	
	# Right arm (cylinder)
	var right_arm := MeshInstance3D.new()
	right_arm.name = "RightArm"
	right_arm.mesh = arm_mesh.duplicate()
	right_arm.position = Vector3(0.25, 0.6, 0)
	right_arm.rotation_degrees = Vector3(0, 0, -20)
	right_arm.material_override = _make_material(Color(0.92, 0.72, 0.28), 0.3, 0.05, "CroissantLimb")
	root.add_child(right_arm)
	
	# Left leg
	var left_leg := MeshInstance3D.new()
	left_leg.name = "LeftLeg"
	var leg_mesh := CylinderMesh.new()
	leg_mesh.top_radius = 0.07
	leg_mesh.bottom_radius = 0.07
	leg_mesh.height = 0.5
	left_leg.mesh = leg_mesh
	left_leg.position = Vector3(-0.12, -0.15, 0)
	left_leg.material_override = _make_material(Color(0.82, 0.62, 0.22), 0.3, 0.05, "CroissantLimb")
	root.add_child(left_leg)
	
	# Right leg
	var right_leg := MeshInstance3D.new()
	right_leg.name = "RightLeg"
	right_leg.mesh = leg_mesh.duplicate()
	right_leg.position = Vector3(0.12, -0.15, 0)
	right_leg.material_override = _make_material(Color(0.82, 0.62, 0.22), 0.3, 0.05, "CroissantLimb")
	root.add_child(right_leg)
	
	_save_glb("croissant_ninja", root)


# ─── Sourdough Blob ────────────────────────────
func _generate_sourdough_blob() -> void:
	var root := Node3D.new()
	root.name = "SourdoughBlobModel"
	
	# Main body: squashed sphere
	var body := MeshInstance3D.new()
	body.name = "Body"
	var blob_mesh := SphereMesh.new()
	blob_mesh.radius = 0.7
	blob_mesh.height = 1.2
	body.mesh = blob_mesh
	body.position = Vector3(0, 0.7, 0)
	body.scale = Vector3(1.0, 0.7, 1.0)
	var blob_mat := _make_material(Color(0.88, 0.82, 0.65), 0.35, 0.0, "SourdoughBlob")
	blob_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blob_mat.albedo_color.a = 0.88
	body.material_override = blob_mat
	root.add_child(body)
	
	# Left eye (googly)
	var left_eye := MeshInstance3D.new()
	left_eye.name = "LeftEye"
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.12
	eye_mesh.height = 0.24
	left_eye.mesh = eye_mesh
	left_eye.position = Vector3(-0.2, 0.85, -0.5)
	left_eye.material_override = _make_material(Color.WHITE, 0.1, 0.0, "GooglyWhite")
	root.add_child(left_eye)
	
	# Left pupil
	var left_pupil := MeshInstance3D.new()
	left_pupil.name = "LeftPupil"
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = 0.06
	pupil_mesh.height = 0.12
	left_pupil.mesh = pupil_mesh
	left_pupil.position = Vector3(-0.2, 0.85, -0.6)
	left_pupil.material_override = _make_material(Color.BLACK, 0.0, 0.0, "Pupil")
	root.add_child(left_pupil)
	
	# Right eye
	var right_eye := MeshInstance3D.new()
	right_eye.name = "RightEye"
	right_eye.mesh = eye_mesh.duplicate()
	right_eye.position = Vector3(0.2, 0.85, -0.5)
	right_eye.material_override = _make_material(Color.WHITE, 0.1, 0.0, "GooglyWhite")
	root.add_child(right_eye)
	
	# Right pupil
	var right_pupil := MeshInstance3D.new()
	right_pupil.name = "RightPupil"
	right_pupil.mesh = pupil_mesh.duplicate()
	right_pupil.position = Vector3(0.2, 0.85, -0.6)
	right_pupil.material_override = _make_material(Color.BLACK, 0.0, 0.0, "Pupil")
	root.add_child(right_pupil)
	
	_save_glb("sourdough_blob", root)


# ─── Touriste Zombie ───────────────────────────
func _generate_touriste_zombie() -> void:
	var root := Node3D.new()
	root.name = "TouristeZombieModel"
	
	# Body: block character torso
	var body := MeshInstance3D.new()
	body.name = "Body"
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(0.7, 1.0, 0.5)
	body.mesh = torso_mesh
	body.position = Vector3(0, 1.2, 0)
	# Hawaiian shirt: bright floral colors
	var shirt_mat := _make_material(Color(0.2, 0.7, 0.85), 0.4, 0.0, "HawaiianShirt")
	body.material_override = shirt_mat
	root.add_child(body)
	
	# Head: slightly smaller box on top
	var head := MeshInstance3D.new()
	head.name = "Head"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.5, 0.5, 0.45)
	head.mesh = head_mesh
	head.position = Vector3(0, 1.85, 0)
	head.material_override = _make_material(Color(0.65, 0.75, 0.55), 0.5, 0.0, "ZombieSkin")
	root.add_child(head)
	
	# Left arm
	var left_arm := MeshInstance3D.new()
	left_arm.name = "LeftArm"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.2, 0.7, 0.2)
	left_arm.mesh = arm_mesh
	left_arm.position = Vector3(-0.5, 1.15, 0)
	left_arm.rotation_degrees = Vector3(0, 0, 10)
	left_arm.material_override = _make_material(Color(0.65, 0.75, 0.55), 0.5, 0.0, "ZombieSkin")
	root.add_child(left_arm)
	
	# Right arm
	var right_arm := MeshInstance3D.new()
	right_arm.name = "RightArm"
	right_arm.mesh = arm_mesh.duplicate()
	right_arm.position = Vector3(0.5, 1.15, 0)
	right_arm.rotation_degrees = Vector3(0, 0, -10)
	right_arm.material_override = _make_material(Color(0.65, 0.75, 0.55), 0.5, 0.0, "ZombieSkin")
	root.add_child(right_arm)
	
	# Left leg
	var left_leg := MeshInstance3D.new()
	left_leg.name = "LeftLeg"
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.22, 0.6, 0.22)
	left_leg.mesh = leg_mesh
	left_leg.position = Vector3(-0.15, 0.3, 0)
	left_leg.material_override = _make_material(Color(0.35, 0.3, 0.25), 0.5, 0.0, "Shorts")
	root.add_child(left_leg)
	
	# Right leg
	var right_leg := MeshInstance3D.new()
	right_leg.name = "RightLeg"
	right_leg.mesh = leg_mesh.duplicate()
	right_leg.position = Vector3(0.15, 0.3, 0)
	right_leg.material_override = _make_material(Color(0.35, 0.3, 0.25), 0.5, 0.0, "Shorts")
	root.add_child(right_leg)
	
	# Camera prop (neck strap camera)
	var camera_body := MeshInstance3D.new()
	camera_body.name = "Camera"
	var cam_mesh := BoxMesh.new()
	cam_mesh.size = Vector3(0.3, 0.2, 0.25)
	camera_body.mesh = cam_mesh
	camera_body.position = Vector3(0, 1.5, -0.35)
	camera_body.material_override = _make_material(Color(0.15, 0.15, 0.15), 0.3, 0.3, "CameraBody")
	root.add_child(camera_body)
	
	# Camera lens
	var lens := MeshInstance3D.new()
	lens.name = "CameraLens"
	var lens_mesh := CylinderMesh.new()
	lens_mesh.top_radius = 0.1
	lens_mesh.bottom_radius = 0.1
	lens_mesh.height = 0.1
	lens.mesh = lens_mesh
	lens.position = Vector3(0, 1.5, -0.48)
	lens.rotation_degrees = Vector3(90, 0, 0)
	lens.material_override = _make_material(Color(0.1, 0.1, 0.15), 0.1, 0.5, "Lens")
	root.add_child(lens)
	
	# Fanny pack
	var fanny := MeshInstance3D.new()
	fanny.name = "FannyPack"
	var fanny_mesh := BoxMesh.new()
	fanny_mesh.size = Vector3(0.25, 0.18, 0.15)
	fanny.mesh = fanny_mesh
	fanny.position = Vector3(0.35, 0.85, -0.15)
	fanny.material_override = _make_material(Color(0.9, 0.15, 0.2), 0.2, 0.1, "FannyPack")
	root.add_child(fanny)
	
	_save_glb("touriste_zombie", root)


# ─── Gordon Bleu ───────────────────────────────
func _generate_gordon_bleu() -> void:
	var root := Node3D.new()
	root.name = "GordonBleuModel"
	
	# Body: chef body (large cylinder — 2x scale chef)
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 1.0
	body_mesh.bottom_radius = 1.2
	body_mesh.height = 3.0
	body.mesh = body_mesh
	body.position = Vector3(0, 1.5, 0)
	body.material_override = _make_material(Color(0.97, 0.97, 0.95), 0.4, 0.0, "ChefApron")
	root.add_child(body)
	
	# Toque (chef hat)
	var toque := MeshInstance3D.new()
	toque.name = "Toque"
	var toque_top := CylinderMesh.new()
	toque_top.top_radius = 1.1
	toque_top.bottom_radius = 0.9
	toque_top.height = 1.2
	toque.mesh = toque_top
	toque.position = Vector3(0, 3.2, 0)
	toque.material_override = _make_material(Color.WHITE, 0.25, 0.0, "ToqueWhite")
	root.add_child(toque)
	
	# Rolling pin (right hand weapon)
	var pin := MeshInstance3D.new()
	pin.name = "RollingPin"
	var pin_mesh := CylinderMesh.new()
	pin_mesh.top_radius = 0.15
	pin_mesh.bottom_radius = 0.15
	pin_mesh.height = 2.0
	pin.mesh = pin_mesh
	pin.position = Vector3(1.2, 1.2, 0.3)
	pin.rotation_degrees = Vector3(0, 0, 90)
	pin.material_override = _make_material(Color(0.75, 0.55, 0.35), 0.5, 0.0, "Wood")
	root.add_child(pin)
	
	# Left arm
	var left_arm := MeshInstance3D.new()
	left_arm.name = "LeftArm"
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.2
	arm_mesh.bottom_radius = 0.25
	arm_mesh.height = 1.0
	left_arm.mesh = arm_mesh
	left_arm.position = Vector3(-1.1, 1.5, 0)
	left_arm.rotation_degrees = Vector3(0, 0, 15)
	left_arm.material_override = _make_material(Color(0.97, 0.97, 0.95), 0.4, 0.0, "ChefSleeve")
	root.add_child(left_arm)
	
	# Right arm
	var right_arm := MeshInstance3D.new()
	right_arm.name = "RightArm"
	right_arm.mesh = arm_mesh.duplicate()
	right_arm.position = Vector3(1.1, 1.5, 0)
	right_arm.rotation_degrees = Vector3(0, 0, -15)
	right_arm.material_override = _make_material(Color(0.97, 0.97, 0.95), 0.4, 0.0, "ChefSleeve")
	root.add_child(right_arm)
	
	# Buttons on apron
	for i in range(3):
		var button := MeshInstance3D.new()
		button.name = "Button_" + str(i)
		var btn_mesh := SphereMesh.new()
		btn_mesh.radius = 0.06
		btn_mesh.height = 0.12
		button.mesh = btn_mesh
		button.position = Vector3(0, 0.8 + float(i) * 0.5, -0.6)
		button.material_override = _make_material(Color(0.15, 0.15, 0.15), 0.2, 0.5, "Button")
		root.add_child(button)
	
	_save_glb("gordon_bleu", root)
