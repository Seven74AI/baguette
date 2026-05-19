extends Node3D
## Main game scene script — wires player weapon, handles enemy spawning, manages run lifecycle.
## Attached to the bakery_test level root.

const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const WEAPON_SCENE_PATH := "res://scenes/weapons/baguette_gun.tscn"
const ENEMY_SCENE_PATH := "res://scenes/enemies/touriste_zombie.tscn"

var _player: CharacterBody3D = null


func _ready() -> void:
	_spawn_player()
	_spawn_enemies()
	GameState.start_run()
	GameState.player_died.connect(_on_player_died)
	GameState.run_ended.connect(_on_run_ended)


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

	# Attach weapon BEFORE player enters tree so it's found in _ready()
	var weapon_scene := load(WEAPON_SCENE_PATH) as PackedScene
	if weapon_scene:
		var weapon_mount := _player.get_node_or_null("Camera3D/WeaponMount")
		if weapon_mount:
			var weapon := weapon_scene.instantiate()
			weapon_mount.add_child(weapon)

	add_child(_player)


func _spawn_enemies() -> void:
	var enemy_scene := load(ENEMY_SCENE_PATH) as PackedScene
	if not enemy_scene:
		push_error("Failed to load enemy scene: " + ENEMY_SCENE_PATH)
		return
	
	var markers := get_tree().get_nodes_in_group("enemy_spawn")
	for marker in markers:
		var enemy := enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = marker.global_position


func _on_player_died() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/game_over.tscn")


func _on_run_ended(won: bool) -> void:
	if won:
		get_tree().change_scene_to_file("res://scenes/ui/victory.tscn")
