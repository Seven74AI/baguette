## Tool script to generate mitch.glb from PlayerMeshGenerator.
## Run with: godot4 --headless --path . -s scripts/player/generate_mitch_glb.gd
extends SceneTree

const PlayerMeshGenerator = preload("res://scripts/player/player_mesh_generator.gd")

func _init() -> void:
	_export_glb()
	quit(0)


func _export_glb() -> void:
	print("[generate_mitch_glb] Building MITCH model...")

	# Create the mesh generator
	var generator: PlayerMeshGenerator = PlayerMeshGenerator.new()
	generator.generate_mitch_mesh()

	# Verify mesh
	if not generator.mesh:
		printerr("[generate_mitch_glb] ERROR: Mesh generation failed")
		quit(1)
		return

	var vert_count := 0
	if generator.mesh.get_surface_count() > 0:
		vert_count = generator.mesh.surface_get_arrays(0)[ArrayMesh.ARRAY_VERTEX].size()

	print("[generate_mitch_glb] Mesh generated: %d surfaces, %d vertices" % [
		generator.mesh.get_surface_count(), vert_count
	])

	# Create a model Node3D to hold the mesh instance
	var model := Node3D.new()
	model.name = "MitchModel"

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "MitchMesh"
	mesh_instance.mesh = generator.mesh
	model.add_child(mesh_instance)
	mesh_instance.owner = model

	# Add to scene tree so GLTFDocument can process it
	var tree_root := root
	tree_root.add_child(model)
	model.owner = tree_root

	# Use GLTFDocument to export
	var gltf_doc := GLTFDocument.new()
	var gltf_state := GLTFState.new()

	var err := gltf_doc.append_from_scene(model, gltf_state)
	if err != OK:
		printerr("[generate_mitch_glb] ERROR: append_from_scene failed: %d" % err)
		quit(1)
		return

	var output_path := "res://assets/models/player/mitch.glb"
	err = gltf_doc.write_to_filesystem(gltf_state, output_path)
	if err != OK:
		printerr("[generate_mitch_glb] ERROR: write_to_filesystem failed: %d" % err)
		quit(1)
		return

	print("[generate_mitch_glb] SUCCESS: Written to %s" % output_path)
	model.queue_free()
	generator.free()
