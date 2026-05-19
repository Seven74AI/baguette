class_name Pickup
extends Area3D
## 3D pickup item — floats, rotates, auto-collects when player enters proximity.
## Instances are spawned by LootManager.

enum PickupType { HEALTH, AMMO, SPEED_BUFF, WEAPON_UPGRADE }

## Emitted when this pickup is collected by the player (before queue_free).
signal collected(pickup: Pickup)

@export var loot_type: PickupType = PickupType.HEALTH
## The value: HP restored for health, ammo added for ammo, speed multiplier for buff, token count for upgrade.
@export var pickup_value: float = 25.0
## Duration in seconds for buff-type pickups (ignored for instant pickups).
@export var buff_duration: float = 0.0
## Optional buff identifier string (e.g., "speed") for the inventory system.
@export var buff_id: String = ""

# Animation
@export var bob_height: float = 0.15
@export var bob_speed: float = 2.0
@export var rotate_speed: float = 90.0   # degrees per second

var _base_y: float = 0.0
var _bob_time: float = 0.0


func _ready() -> void:
	_base_y = position.y
	# Randomise bob phase so identical pickups don't synch
	_bob_time = randf() * TAU

	# Connect body_entered for auto-collect
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	# Bob animation
	_bob_time += delta * bob_speed
	position.y = _base_y + sin(_bob_time) * bob_height

	# Rotation
	rotation_degrees.y += rotate_speed * delta


func _on_body_entered(body: Node3D) -> void:
	# Only the player triggers collection
	if body.is_in_group("player"):
		collect()


## Trigger collection — applies effect to GameState and emits signal.
func collect() -> void:
	match loot_type:
		PickupType.HEALTH:
			GameState.heal_player(int(pickup_value))
		PickupType.AMMO:
			GameState.add_ammo(int(pickup_value))
		PickupType.SPEED_BUFF:
			GameState.add_buff(buff_id if buff_id != "" else "speed", pickup_value, buff_duration)
		PickupType.WEAPON_UPGRADE:
			GameState.add_upgrade_token(int(pickup_value))

	# Sound + particle burst
	SoundManager.play_pickup_sound()
	EffectsManager.spawn_pickup_burst(global_position)

	collected.emit(self)
	queue_free()
