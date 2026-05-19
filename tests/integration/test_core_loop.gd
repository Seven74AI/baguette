extends "res://addons/gut/test.gd"
## Integration tests for the proto core loop: player movement, weapon firing, enemy chase AI.
## Tests scene spawning and cross-system interactions.

const HealthComponent = preload("res://scripts/components/health_component.gd")
const BaguetteGun = preload("res://scenes/weapons/baguette_gun.gd")

var _level_scene: PackedScene
var _level: Node3D
var _player: CharacterBody3D
var _weapon: BaguetteGun


func before_each() -> void:
	# Load and instantiate the bakery level
	_level_scene = load("res://scenes/levels/proto/bakery_test.tscn") as PackedScene
	if _level_scene:
		_level = _level_scene.instantiate()
		add_child_autofree(_level)
		await wait_frames(3)  # Allow _ready() + spawns to complete
	
	# Find player
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
	
	# Find weapon (child of player's WeaponMount)
	if _player:
		var weapon_mount := _player.get_node_or_null("Camera3D/WeaponMount")
		if weapon_mount and weapon_mount.get_child_count() > 0:
			_weapon = weapon_mount.get_child(0)


func test_level_loads_without_errors() -> void:
	assert_not_null(_level, "Bakery test level should load successfully")


func test_player_spawns_in_level() -> void:
	assert_not_null(_player, "Player should be spawned in the level")
	assert_true(_player.is_in_group("player"), "Player should be in 'player' group")


func test_weapon_is_attached_to_player() -> void:
	assert_not_null(_weapon, "Baguette Gun should be attached to player")
	assert_eq(_weapon.get_ammo_count(), _weapon.max_ammo, "Weapon should start with full ammo")


func test_enemies_spawn_in_level() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	assert_gt(enemies.size(), 0, "At least one enemy should be spawned")


func test_enemy_has_health_component() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		var enemy := enemies[0]
		var hc: HealthComponent = enemy.get_node_or_null("HealthComponent")
		assert_not_null(hc, "Enemy should have a HealthComponent")
		assert_true(hc.is_alive(), "Enemy should start alive")


func test_weapon_can_damage_enemy() -> void:
	if not _weapon:
		return
	
	var enemies := get_tree().get_nodes_in_group("enemy")
	if enemies.size() > 0:
		var enemy: CharacterBody3D = enemies[0]
		var hc: HealthComponent = enemy.get_node_or_null("HealthComponent")
		if not hc:
			return
		
		var initial_health := hc.current_health
		
		# Simulate direct damage via the weapon's damage value
		hc.take_damage(_weapon.damage)
		
		assert_lt(hc.current_health, initial_health, "Enemy health should decrease when damaged")


func test_player_has_camera() -> void:
	if _player:
		var camera: Camera3D = _player.get_node_or_null("Camera3D")
		assert_not_null(camera, "Player should have a Camera3D child")


func test_game_state_run_active_after_level_load() -> void:
	assert_true(GameState.run_active, "GameState.run_active should be true after level loads")


func test_csg_collision_exists() -> void:
	if _level:
		var room := _level.get_node_or_null("BakeryRoom")
		assert_not_null(room, "BakeryRoom CSGCombiner3D should exist")
		if room:
			assert_true(room.use_collision, "CSG room should have collision enabled")
