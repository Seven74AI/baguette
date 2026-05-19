extends "res://scripts/enemies/base_enemy.gd"
## Michelin Etoile Perdu — ranged enemy that throws ink blobs.
## Stays at a distance and pelts the player with ink projectiles.
## Ink blobs slow + damage the player. Drops Michelin Star crit buff on death.
## HP 80, speed 3.5, ranged attack at 15m, ink damage 12.

const InkBlobClass = preload("res://scripts/projectiles/ink_blob.gd")
const MichelinStarClass = preload("res://scripts/pickups/michelin_star.gd")

enum MichelinState { POSITIONING = 100, FIRING }

## Emitted when ink blob is fired.
signal ink_fired(blob: Node)

## Emitted when Michelin Star is dropped on death.
signal star_dropped(star: Node)

@export_category("Michelin Etoile Perdu")
@export var ink_damage: int = 12
@export var ink_speed: float = 7.0
@export var ink_slow_factor: float = 0.5
@export var ink_slow_duration: float = 2.0
@export var fire_interval: float = 1.8  ## Seconds between ink blobs
@export var preferred_distance: float = 10.0  ## Ideal distance from player
@export var star_drop_chance: float = 1.0  ## 100% chance to drop Michelin Star

## Reference to the InkBlob class for instantiation.
var ink_blob_scene = null

var _michelin_state: int = MichelinState.POSITIONING
var _fire_timer: float = 0.0


func _ready() -> void:
	super._ready()
	move_speed = 3.5
	attack_damage = ink_damage
	attack_range = 15.0
	detection_range = 20.0

	if health_component:
		health_component.max_health = 80
		health_component.current_health = 80

	# ink_blob_scene is set as a non-null sentinel (InkBlob class available via preload)
	ink_blob_scene = self


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_position_and_fire(delta)
		EnemyState.ATTACK:
			_fire_ink_blob()

	move_and_slide()


## Position at preferred distance and fire ink blobs.
func _position_and_fire(delta: float) -> void:
	if _player == null:
		return

	var distance := global_position.distance_to(_player.global_position)

	# Face the player
	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	# Move toward preferred distance
	if distance > preferred_distance + 2.0:
		# Too far — move closer
		var target_velocity := direction * move_speed
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	elif distance < preferred_distance - 2.0:
		# Too close — back away
		var back_dir := -direction
		var target_velocity := back_dir * move_speed * 0.7
		velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	else:
		# At preferred distance — slow to a stop
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	# Fire when within range
	_fire_timer += delta
	if distance <= attack_range and _fire_timer >= fire_interval:
		current_state = EnemyState.ATTACK


## Fire an ink blob projectile toward the player.
func _fire_ink_blob() -> void:
	if _player == null:
		current_state = EnemyState.CHASE
		return

	_fire_timer = 0.0

	# Create ink blob projectile using preload
	var blob := _create_ink_blob()
	blob.direction = (_player.global_position - global_position).normalized()
	blob.position = global_position + blob.direction * 1.0 + Vector3.UP * 1.2

	get_tree().root.add_child(blob)
	ink_fired.emit(blob)

	current_state = EnemyState.CHASE


## Factory method for creating an ink blob — overridable in tests.
func _create_ink_blob() -> Node:
	var blob := InkBlobClass.new()
	blob.damage = ink_damage
	blob.speed = ink_speed
	blob.slow_factor = ink_slow_factor
	blob.slow_duration = ink_slow_duration
	return blob


## Override death to drop Michelin Star.
func _on_death() -> void:
	_drop_michelin_star()
	super._on_death()


## Drop a Michelin Star crit buff pickup at death position.
func _drop_michelin_star() -> void:
	if randf() > star_drop_chance:
		return

	var star := MichelinStarClass.new()
	star.global_position = global_position + Vector3(0, 0.5, 0)
	star.crit_chance_bonus = 0.30
	# Initialize buff properties (normally done in _ready when added to tree)
	star._init_buff_properties()

	var parent_node: Node = get_parent()
	if not parent_node:
		parent_node = get_tree().root
	parent_node.add_child(star)
	star_dropped.emit(star)
