extends "res://tests/test_base.gd"
## Unit tests for test dummy enemy — verifies approach behavior toward player.

var _dummy: CharacterBody3D
var _player_target: Node3D


func before_each() -> void:
	# Create a NavigationRegion3D so the NavigationAgent3D can work
	var nav_region := NavigationRegion3D.new()
	var nav_mesh := NavigationMesh.new()
	nav_mesh.set_vertices(PackedVector3Array([
		Vector3(50, 0, 50),
		Vector3(-50, 0, 50),
		Vector3(-50, 0, -50),
		Vector3(50, 0, -50),
	]))
	nav_mesh.add_polygon(PackedInt32Array([0, 1, 2]))
	nav_mesh.add_polygon(PackedInt32Array([0, 2, 3]))
	nav_region.navigation_mesh = nav_mesh
	add_child(nav_region)

	# Create a player target at a known position
	_player_target = Node3D.new()
	_player_target.name = "PlayerTarget"
	_player_target.global_position = Vector3(10, 0, 0)
	_player_target.add_to_group("player")
	add_child(_player_target)

	# Load and instantiate the test dummy scene
	var dummy_scene: PackedScene = load("res://scenes/enemies/test_dummy.tscn") as PackedScene
	if dummy_scene:
		_dummy = dummy_scene.instantiate()
		_dummy.global_position = Vector3(0, 0, 0)
		add_child(_dummy)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame  # Extra frame for nav sync


func after_each() -> void:
	if _dummy:
		_dummy.queue_free()
		_dummy = null
	if _player_target:
		_player_target.queue_free()
		_player_target = null


func test_dummy_scene_loads() -> void:
	var scene: PackedScene = load("res://scenes/enemies/test_dummy.tscn") as PackedScene
	assert_not_null(scene, "test_dummy.tscn should exist and be loadable")


func test_dummy_has_navigation_agent() -> void:
	if not _dummy:
		return
	var nav_agent = _dummy.get_node_or_null("NavigationAgent3D")
	assert_not_null(nav_agent, "Test dummy should have a NavigationAgent3D child")


func test_dummy_detection_range_is_20m() -> void:
	if not _dummy:
		return
	assert_eq(_dummy.detection_range, 20.0,
		"Detection range should be 20 meters")


func test_dummy_moves_toward_player() -> void:
	if not _dummy:
		return

	# Place dummy far from player (within detection range)
	_dummy.global_position = Vector3(0, 0, 0)
	_player_target.global_position = Vector3(5, 0, 0)

	# Let physics process run
	for _i in range(5):
		await get_tree().process_frame

	# After moving, distance should decrease
	var distance := _dummy.global_position.distance_to(_player_target.global_position)
	assert_lt(distance, 5.0,
		"Dummy should move toward player, distance should be less than initial 5m")


func test_dummy_stops_when_out_of_range() -> void:
	if not _dummy:
		return

	# Place dummy far from player (beyond 20m detection range)
	_dummy.global_position = Vector3(0, 0, 0)
	_player_target.global_position = Vector3(25, 0, 0)

	# Let physics process run
	for _i in range(5):
		await get_tree().process_frame

	# Dummy should not move significantly when out of range
	var distance := _dummy.global_position.distance_to(Vector3(0, 0, 0))
	assert_lt(distance, 1.0,
		"Dummy should not move when player is out of detection range")


func test_dummy_is_in_enemy_group() -> void:
	if not _dummy:
		return
	assert_true(_dummy.is_in_group("enemy"),
		"Test dummy should be in the 'enemy' group")
