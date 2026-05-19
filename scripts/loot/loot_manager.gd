class_name LootManager
extends Node
## Manages per-enemy-type loot tables and spawns Pickup nodes in the world.
## Register tables per enemy class name, then call spawn_loot() on enemy death.

const LootTableLocal = preload("res://scripts/loot/loot_table.gd")
const PickupLocal = preload("res://scripts/loot/pickup.gd")

## Scatter radius for loot spawn position.
@export var scatter_radius: float = 1.5

## Per-enemy-class loot tables. Key = enemy class name String, Value = LootTable.
var _enemy_tables: Dictionary = {}

## Default fallback table (used when no specific table is registered).
var _default_table: Resource


func _ready() -> void:
	_setup_default_table()


func _setup_default_table() -> void:
	_default_table = LootTableLocal.new()
	# Default: 60% ammo, 30% health, 10% nothing
	_default_table.drop_table = {
		"ammo": 0.6,
		"health": 0.3,
	}


## Register a LootTable for a given enemy class name String.
func register_enemy_table(enemy_type: String, table: Resource) -> void:
	_enemy_tables[enemy_type] = table


## Get the loot table for an enemy type, falling back to default.
func get_table_for(enemy_type: String) -> Resource:
	if _enemy_tables.has(enemy_type):
		return _enemy_tables[enemy_type]
	return _default_table


## Roll on an enemy's table, spawn pickup(s) at position.
## Returns the spawned Pickup node, or null if nothing dropped.
func roll_and_spawn(enemy_type: String, world_position: Vector3) -> Node:
	var table: Resource = get_table_for(enemy_type)
	var item_name: String = table.roll()
	if item_name == "":
		return null
	return spawn_pickup(item_name, world_position)


## Spawn a pickup of the given item_name at position (with scatter).
func spawn_pickup(item_name: String, world_position: Vector3) -> Node:
	var defn: Dictionary = LootTableLocal.get_item_definition(item_name)
	if defn.is_empty():
		push_warning("LootManager.spawn_pickup: unknown item '" + item_name + "'")
		return null

	var pickup: Node = PickupLocal.new()
	pickup.loot_type = defn.type as int
	pickup.pickup_value = defn.value

	if defn.has("duration"):
		pickup.buff_duration = defn.duration

	if defn.type == LootTableLocal.LootType.SPEED_BUFF:
		pickup.buff_id = "speed"

	# Apply scatter
	var scatter := Vector3(
		randf_range(-scatter_radius, scatter_radius),
		0.0,
		randf_range(-scatter_radius, scatter_radius)
	)
	pickup.global_position = world_position + scatter

	# Add to scene — fall back to self if no current_scene (for testing)
	var parent: Node = get_tree().current_scene
	if not parent:
		parent = self
	parent.add_child(pickup)
	return pickup
