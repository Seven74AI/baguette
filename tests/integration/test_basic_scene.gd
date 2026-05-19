extends "res://tests/test_base.gd"
## Integration test — verifies the test room loads, player spawns, enemies approach.

var _level: Node3D
var _player: CharacterBody3D


func before_each() -> void:
	var level_scene: PackedScene = load("res://scenes/levels/test_room.tscn") as PackedScene
	if level_scene:
		_level = level_scene.instantiate()
		add_child(_level)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
	
	# Find player
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0] as CharacterBody3D


func after_each() -> void:
	if _level:
		_level.queue_free()
		_level = null
	_player = null


func test_level_loads_without_errors() -> void:
	var scene: PackedScene = load("res://scenes/levels/test_room.tscn") as PackedScene
	assert_not_null(scene, "test_room.tscn should be loadable")


func test_level_instance_exists() -> void:
	assert_not_null(_level, "Level should be instantiated successfully")


func test_player_spawns_in_level() -> void:
	assert_not_null(_player, "Player should spawn in the test room")
	if _player:
		assert_true(_player.is_in_group("player"),
			"Player should be in the 'player' group")


func test_enemies_spawn_in_level() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	assert_eq(enemies.size(), 3, "Exactly 3 test dummies should spawn")


func test_csg_room_exists() -> void:
	if not _level:
		return
	var room = _level.get_node_or_null("Room")
	assert_not_null(room, "CSG room should exist in the level")


func test_csg_room_has_collision() -> void:
	if not _level:
		return
	var room: CSGCombiner3D = _level.get_node_or_null("Room") as CSGCombiner3D
	if room:
		assert_true(room.use_collision, "CSG room should have collision enabled")


func test_navigation_region_exists() -> void:
	if not _level:
		return
	var nav_region = _level.get_node_or_null("NavigationRegion3D")
	assert_not_null(nav_region, "NavigationRegion3D should exist for navmesh")


func test_dummies_approach_player() -> void:
	if not _player:
		return
	
	var enemies := get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return
	
	# Record initial distances
	var initial_distances: Array[float] = []
	for enemy: Node3D in enemies:
		initial_distances.append(enemy.global_position.distance_to(_player.global_position))
	
	# Let physics run (need enough time for nav sync + movement)
	for _i in range(30):
		await get_tree().process_frame
	
	# Check that at least one enemy moved closer
	var any_closer := false
	for i in range(enemies.size()):
		var enemy: Node3D = enemies[i]
		var current_dist: float = enemy.global_position.distance_to(_player.global_position)
		if current_dist < initial_distances[i] - 0.1:
			any_closer = true
			break
	
	assert_true(any_closer, "At least one dummy should move closer to the player")
