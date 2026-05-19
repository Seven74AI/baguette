extends CharacterBody3D
## Base class for all BAGUETTE enemies.
## Provides shared health, damage, death, drop-table hooks, and state machine.
## Subclasses should override _on_death(), _chase_player(), _attack_player().

const HealthComponent = preload("res://scripts/components/health_component.gd")

enum EnemyState { IDLE, CHASE, ATTACK, DEAD }

const LootTable = preload("res://scripts/loot/loot_table.gd")
const Pickup = preload("res://scripts/loot/pickup.gd")

## Emitted when the enemy takes damage.
signal damaged(amount: int, source: Node)

## Emitted when the enemy dies (health reaches 0).
signal died

## Emitted when loot is spawned (passes the Pickup node).
signal loot_spawned(pickup: Node)

@export_category("Movement")
@export var move_speed: float = 3.0
@export var acceleration: float = 10.0

@export_category("Combat")
@export var attack_damage: int = 15
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.2
@export var detection_range: float = 15.0

@export_category("Components")
@export var health_component: HealthComponent

@export_category("Loot")
## LootTable resource reference for per-enemy drop configuration.
@export var drop_table_ref: Resource
## [DEPRECATED] Legacy dictionary drop table. Use drop_table_ref instead.
@export var drop_table: Dictionary = {}

var current_state: EnemyState = EnemyState.IDLE
var _player: Node3D = null


func _ready() -> void:
	if not health_component:
		health_component = $HealthComponent as HealthComponent

	if health_component:
		health_component.health_depleted.connect(_on_death)


func take_damage(amount: int, source: Node = null) -> void:
	if current_state == EnemyState.DEAD:
		return

	if health_component:
		var health_before := health_component.current_health
		health_component.take_damage(amount, source)
		if health_component.current_health < health_before:
			damaged.emit(amount, source)


func get_max_health() -> int:
	if health_component:
		return health_component.max_health
	return 0


func get_current_health() -> int:
	if health_component:
		return health_component.current_health
	return 0


func is_alive() -> bool:
	if health_component:
		return health_component.is_alive()
	return false


## Called when health reaches 0. Override in subclasses for custom death behavior.
func _on_death() -> void:
	current_state = EnemyState.DEAD
	died.emit()

	# Drop loot
	_drop_loot()

	# Disable collision
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true

	set_process(false)
	set_physics_process(false)


## Spawn loot based on the enemy's drop table. Emits loot_spawned for each pickup.
func _drop_loot() -> void:
	if not drop_table_ref:
		return

	var rolled: String = (drop_table_ref as LootTable).roll()
	if rolled == "":
		return

	var defn := LootTable.get_item_definition(rolled)
	if defn.is_empty():
		return

	var pickup := _create_pickup(defn, rolled)
	if pickup:
		var scatter := Vector3(
			randf_range(-1.5, 1.5),
			0.0,
			randf_range(-1.5, 1.5)
		)
		pickup.global_position = global_position + scatter
		# Add to parent or self (testing fallback)
		var parent_node: Node = get_parent()
		if not parent_node:
			parent_node = self
		parent_node.add_child(pickup)
		loot_spawned.emit(pickup)


## Factory method to create a Pickup from an item definition.
func _create_pickup(defn: Dictionary, _item_name: String) -> Node:
	var pk: Pickup = Pickup.new()
	pk.loot_type = defn.type as int
	pk.pickup_value = defn.value
	if defn.has("duration"):
		pk.buff_duration = defn.duration
	if defn.type == LootTable.LootType.SPEED_BUFF:
		pk.buff_id = "speed"
	return pk


## Find and cache the player reference.
func _find_player() -> void:
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]


## Default chase behavior — move toward the player. Override in subclasses.
func _chase_player(delta: float) -> void:
	if _player == null:
		return

	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0

	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)


## Default attack behavior. Override in subclasses.
func _attack_player() -> void:
	if _player == null:
		return

	# Basic melee damage
	if _player.has_method("take_damage"):
		_player.take_damage(attack_damage, self)
	elif _player.get("health_component"):
		var hc: HealthComponent = _player.health_component
		if hc:
			hc.take_damage(attack_damage, self)
