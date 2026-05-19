extends Node3D
## Test room level script — spawns player and test dummies for integration testing.

const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const DUMMY_SCENE_PATH := "res://scenes/enemies/test_dummy.tscn"

var _player: CharacterBody3D = null


func _ready() -> void:
	_bake_navigation()
	_spawn_player()
	_spawn_dummies()


func _bake_navigation() -> void:
	var nav_region: NavigationRegion3D = $NavigationRegion3D
	if not nav_region:
		return
	
	var nav_mesh := NavigationMesh.new()
	nav_mesh.set_vertices(PackedVector3Array([
		Vector3(9.5, 0, 9.5),
		Vector3(-9.5, 0, 9.5),
		Vector3(-9.5, 0, -9.5),
		Vector3(9.5, 0, -9.5),
	]))
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2]))
	nav_mesh.add_polygon(PackedInt32Array([0, 2, 3]))
	nav_region.navigation_mesh = nav_mesh


func _spawn_player() -> void:
	var player_scene := load(PLAYER_SCENE_PATH) as PackedScene
	if not player_scene:
		push_error("Failed to load player scene: " + PLAYER_SCENE_PATH)
		return

	var spawn_pos := Vector3.ZERO
	var spawn_marker := get_node_or_null("SpawnPoints/PlayerSpawn")
	if spawn_marker:
		spawn_pos = spawn_marker.global_position

	_player = player_scene.instantiate()
	_player.global_position = spawn_pos
	_player.add_to_group("player")
	add_child(_player)


func _spawn_dummies() -> void:
	var dummy_scene := load(DUMMY_SCENE_PATH) as PackedScene
	if not dummy_scene:
		push_error("Failed to load dummy scene: " + DUMMY_SCENE_PATH)
		return

	# Spawn at specific positions
	var spawn_positions := [
		Vector3(5, 0, 5),
		Vector3(-5, 0, 5),
		Vector3(0, 0, 8),
	]

	# Override with spawn markers if they exist
	var markers := get_tree().get_nodes_in_group("enemy_spawn")
	if markers.size() > 0:
		spawn_positions.clear()
		for marker in markers:
			spawn_positions.append(marker.global_position)

	for pos in spawn_positions:
		var dummy := dummy_scene.instantiate()
		dummy.global_position = pos
		add_child(dummy)
