extends Node3D
## Enemy spawner — spawns enemies at spawn points in the level.
## Supports multiple enemy types with weighted random selection.

## Emitted when an enemy is spawned.
signal enemy_spawned(enemy: Node, spawner: Node)

@export_category("Enemy Types")
## Array of enemy scene paths to spawn.
@export var enemy_scenes: Array[String] = [
	"res://scenes/enemies/touriste_zombie.tscn",
	"res://scenes/enemies/baguette_vivante.tscn",
	"res://scenes/enemies/croissant_ninja.tscn",
	"res://scenes/enemies/sourdough_blob.tscn",
	"res://scenes/enemies/michelin_etoile_perdu.tscn",
	"res://scenes/enemies/pain_au_chocolatine.tscn",
]

@export_category("Spawning")
## If true, spawns enemies at startup. If false, call spawn_enemies() manually.
@export var spawn_on_ready: bool = true
## Max enemies to spawn (-1 = use all spawn points).
@export var max_spawns: int = -1
## If true, picks random enemies from the pool. If false, cycles through them.
@export var randomize_enemy_type: bool = true
## Delay between spawns in seconds (0 = all at once).
@export var spawn_delay: float = 0.0

## Cached loaded scenes.
var _loaded_scenes: Dictionary = {}

var _spawned_count: int = 0
var _enemy_index: int = 0


func _ready() -> void:
	if spawn_on_ready:
		spawn_enemies()


## Spawn enemies at all spawn markers.
func spawn_enemies() -> void:
	var markers := get_tree().get_nodes_in_group("enemy_spawn")
	if markers.is_empty():
		return

	for marker in markers:
		if max_spawns >= 0 and _spawned_count >= max_spawns:
			break

		var scene_path := _pick_enemy_scene()
		if scene_path == "":
			continue

		var enemy := _spawn_one(scene_path, marker.global_position)
		if enemy:
			_spawned_count += 1

			if spawn_delay > 0:
				await get_tree().create_timer(spawn_delay).timeout


## Spawn a single enemy at a specific position.
func spawn_enemy_at(scene_path: String, position: Vector3) -> Node:
	return _spawn_one(scene_path, position)


## Pick which enemy scene to use next.
func _pick_enemy_scene() -> String:
	if enemy_scenes.is_empty():
		return ""

	if randomize_enemy_type:
		return enemy_scenes[randi() % enemy_scenes.size()]
	else:
		var path := enemy_scenes[_enemy_index % enemy_scenes.size()]
		_enemy_index += 1
		return path


## Instantiate and place a single enemy.
func _spawn_one(scene_path: String, pos: Vector3) -> Node:
	if scene_path not in _loaded_scenes:
		var scn := load(scene_path) as PackedScene
		if not scn:
			push_error("Enemy spawner: failed to load scene: " + scene_path)
			return null
		_loaded_scenes[scene_path] = scn

	var enemy := (_loaded_scenes[scene_path] as PackedScene).instantiate()
	enemy.global_position = pos
	get_parent().add_child(enemy)
	enemy_spawned.emit(enemy, self)
	return enemy


# ── Phase 5.2a: Zone-based difficulty scaling ─────────────────────

## Returns the current zone's difficulty multiplier for enemy HP scaling.
func get_zone_difficulty_multiplier() -> float:
	return ZoneManager.get_difficulty_multiplier()


## Returns the current zone's enemy count bonus.
func get_zone_enemy_count_bonus() -> int:
	return ZoneManager.get_enemy_count_bonus()


## Returns the scaled enemy HP for the current zone by applying the
## difficulty multiplier to a base HP value.
func get_scaled_enemy_hp(base_hp: int) -> int:
	var mult := ZoneManager.get_difficulty_multiplier()
	return max(1, int(ceil(float(base_hp) * mult)))


## Returns the current zone's enemy pool from ZoneManager.
func get_zone_enemy_pool() -> Array:
	return ZoneManager.get_enemy_pool()
