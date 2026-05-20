extends "res://scripts/enemies/base_enemy.gd"
## Barista Possédé — Support/Spawner enemy.
## Static behind counter, spawns minions, buffs allies, attacks if approached.
## Attacks: Invoque un Stagiaire (spawns Touriste Zombie every 8s, max 3),
##   Machine à Expresso (steam cone, medium damage + push),
##   Latte Art Maudit (buffs 1 ally +30% speed +20% damage, 10s)
## Weakness: Counter is destructible (3 croissant rifle hits).
##   Latte Art can be interrupted by shooting the cup.
## Elite: Torréfacteur Maudit — spawns Pigeons AND Touristes, expresso has more range.

enum BaristaState { IDLE_AT_COUNTER = 100, SPAWNING, BUFFING, ATTACKING }

signal stagiaire_spawned(minion: Node)
signal expresso_fired()
signal latte_buff_applied(target: Node)
signal counter_destroyed()

const TouristeZombie = preload("res://scenes/enemies/touriste_zombie.gd")

@export_category("Barista Possédé")
@export var spawn_interval: float = 8.0
@export var max_active_minions: int = 3
@export var expresso_damage: int = 15
@export var expresso_push_force: float = 8.0
@export var expresso_cone_angle: float = 45.0
@export var expresso_range: float = 5.0
@export var expresso_is_cone: bool = true
@export var latte_speed_bonus: float = 0.30
@export var latte_damage_bonus: float = 0.20
@export var latte_duration: float = 10.0
@export var latte_art_interruptible: bool = true
@export var has_counter: bool = true
@export var counter_health: int = 3
@export var is_static: bool = true
@export var is_elite: bool = false

var _barista_state: int = BaristaState.IDLE_AT_COUNTER
var _spawn_timer: float = 0.0
var _active_minions: Array[Node] = []
var _counter_hits: int = 0
var _latte_target: Node = null
var _latte_timer: float = 0.0
var _is_buffing: bool = false
var _attack_cooldown_timer: float = 0.0
var _spawns_pigeons: bool = false


func _ready() -> void:
	super._ready()
	move_speed = 0.0
	attack_damage = expresso_damage
	attack_range = expresso_range
	detection_range = 15.0
	if health_component:
		health_component.max_health = 160
		health_component.current_health = 160


func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	_find_player()

	if _player == null:
		move_and_slide()
		return

	# Static — don't move
	velocity = Vector3.ZERO

	# Face the player
	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	# Decide what to do
	_cleanup_dead_minions()

	match _barista_state:
		BaristaState.IDLE_AT_COUNTER:
			_decide_action(delta)
		BaristaState.SPAWNING:
			_spawn_stagiaire()
		BaristaState.BUFFING:
			_perform_buffing(delta)
		BaristaState.ATTACKING:
			_machine_expresso()

	move_and_slide()


func _decide_action(delta: float) -> void:
	# Priority 1: Buff an ally if any nearby
	var ally := _find_nearby_ally()
	if ally and not _is_buffing:
		_latte_target = ally
		_barista_state = BaristaState.BUFFING
		return

	# Priority 2: Spawn minion if under max
	_cleanup_dead_minions()
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval and _active_minions.size() < max_active_minions:
		_barista_state = BaristaState.SPAWNING
		return

	# Priority 3: Attack if player is close (and counter destroyed or bypassed)
	var dist := global_position.distance_to(_player.global_position)
	if (not has_counter or _counter_hits >= counter_health) and dist <= expresso_range:
		_attack_cooldown_timer += delta
		if _attack_cooldown_timer >= 2.0:
			_attack_cooldown_timer = 0.0
			_barista_state = BaristaState.ATTACKING
			return


func _spawn_stagiaire() -> void:
	_spawn_timer = 0.0

	var minion := TouristeZombie.new()
	minion.name = "Stagiaire"

	# Set up health component
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 20
	hc.current_health = 20
	minion.add_child(hc)
	minion.health_component = hc

	# Set up collision
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.0
	cs.shape = shape
	minion.add_child(cs)

	# Position near the counter
	var offset := Vector3(randf_range(-2.0, 2.0), 0, randf_range(2.0, 4.0))
	minion.position = global_position + offset

	get_parent().add_child(minion)
	_active_minions.append(minion)
	stagiaire_spawned.emit(minion)

	_barista_state = BaristaState.IDLE_AT_COUNTER


func _machine_expresso() -> void:
	if _player == null:
		_barista_state = BaristaState.IDLE_AT_COUNTER
		return

	# Cone attack toward player
	var to_player := (_player.global_position - global_position).normalized()
	to_player.y = 0
	var dist := global_position.distance_to(_player.global_position)

	# Check if player is within cone
	var forward := -global_transform.basis.z  # Forward direction
	var angle := rad_to_deg(forward.angle_to(to_player))

	if angle <= expresso_cone_angle * 0.5 and dist <= expresso_range:
		# Hit! Damage + push
		if _player.has_method("take_damage"):
			_player.take_damage(expresso_damage, self)

		# Push the player away
		if _player is CharacterBody3D:
			var push := to_player * expresso_push_force
			push.y = 1.0
			_player.velocity += push

	expresso_fired.emit()
	_barista_state = BaristaState.IDLE_AT_COUNTER


func _perform_buffing(delta: float) -> void:
	if not is_instance_valid(_latte_target):
		_is_buffing = false
		_latte_target = null
		_barista_state = BaristaState.IDLE_AT_COUNTER
		return

	_is_buffing = true
	_latte_timer += delta

	# It takes time to apply the buff
	if _latte_timer >= 1.5:
		_apply_latte_buff()
		_is_buffing = false
		_latte_timer = 0.0
		_barista_state = BaristaState.IDLE_AT_COUNTER


func _apply_latte_buff() -> void:
	if not is_instance_valid(_latte_target):
		return

	var speed_bonus := latte_speed_bonus
	var dmg_bonus := latte_damage_bonus
	var dur := latte_duration

	if _latte_target.has_method("apply_move_speed_multiplier"):
		_latte_target.apply_move_speed_multiplier(1.0 + speed_bonus, dur)
	elif _latte_target.get("move_speed") != null:
		var original: float = _latte_target.move_speed
		_latte_target.move_speed = original * (1.0 + speed_bonus)
		_latte_target.set_meta("_latte_speed_original", original)
		_latte_target.set_meta("_latte_buff_remaining", dur)

	if _latte_target.has_method("apply_damage_multiplier"):
		_latte_target.apply_damage_multiplier(1.0 + dmg_bonus, dur)

	latte_buff_applied.emit(_latte_target)
	_latte_target = null


func _latte_art_maudit() -> void:
	# Public method, used by test
	var ally := _find_nearby_ally()
	if ally:
		_latte_target = ally
		_barista_state = BaristaState.BUFFING


func _find_nearby_ally() -> Node:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < 10.0:
			return enemy
	return null


func _cleanup_dead_minions() -> void:
	var valid: Array[Node] = []
	for minion in _active_minions:
		if is_instance_valid(minion):
			valid.append(minion)
	_active_minions = valid


## Called when counter is hit — from external damage
func hit_counter() -> void:
	if not has_counter:
		return

	_counter_hits += 1
	if _counter_hits >= counter_health:
		has_counter = false
		is_static = false
		counter_destroyed.emit()
		# Now mobile (though slow)
		move_speed = 1.5


## Interrupt the latte art buff
func interrupt_latte() -> void:
	if _is_buffing and latte_art_interruptible:
		_is_buffing = false
		_latte_target = null
		_latte_timer = 0.0
		_barista_state = BaristaState.IDLE_AT_COUNTER


func _on_death() -> void:
	# Kill all minions
	for minion in _active_minions:
		if is_instance_valid(minion):
			if minion.has_method("take_damage"):
				minion.take_damage(999, self)
	_active_minions.clear()
	super._on_death()


## Apply elite modifier: Torréfacteur Maudit
func _apply_elite_modifier() -> void:
	is_elite = true
	# Elite: spawns Pigeons AND Touristes, expresso has more range
	max_active_minions = 5
	expresso_range *= 1.5
	expresso_damage += 5
	expresso_push_force *= 1.3
	spawn_interval = 6.0
	latte_speed_bonus = 0.40
	latte_damage_bonus = 0.30
	if health_component:
		health_component.max_health = int(health_component.max_health * 1.5)
		health_component.current_health = health_component.max_health
	scale = Vector3(1.3, 1.3, 1.3)
