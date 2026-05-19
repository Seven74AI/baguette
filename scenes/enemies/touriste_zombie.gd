class_name TouristeZombie
extends CharacterBody3D
## Touriste Zombie — the most basic enemy. Slow-moving melee attacker.
## CharacterBody3D with simple chase AI and health component.

const HealthComponent = preload("res://scripts/components/health_component.gd")

enum EnemyState { IDLE, CHASE, ATTACK, DEAD }

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

@onready var _state: EnemyState = EnemyState.IDLE
@onready var _attack_timer: Timer = $AttackTimer
@onready var _player: Node3D = null
@onready var _anim_player: AnimationPlayer = $AnimationPlayer

var _can_attack: bool = true


func _ready() -> void:
	if not health_component:
		health_component = $HealthComponent
	
	if health_component:
		health_component.health_depleted.connect(_on_death)
	
	if _attack_timer:
		_attack_timer.wait_time = attack_cooldown


func _physics_process(delta: float) -> void:
	if _state == EnemyState.DEAD:
		return
	
	_find_player()
	
	match _state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_chase_player(delta)
		EnemyState.ATTACK:
			_attack_player()
	
	move_and_slide()


func take_damage(amount: int, source: Node = null) -> void:
	if health_component:
		health_component.take_damage(amount, source)


func _find_player() -> void:
	# Try to find player by group tag
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
	
	if _player == null:
		_state = EnemyState.IDLE
		return
	
	var distance := global_position.distance_to(_player.global_position)
	
	if _state == EnemyState.DEAD:
		return
	
	if distance <= attack_range and _can_attack:
		_state = EnemyState.ATTACK
	elif distance <= detection_range:
		_state = EnemyState.CHASE
	else:
		_state = EnemyState.IDLE


func _chase_player(delta: float) -> void:
	if _player == null:
		return
	
	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0
	var target_velocity := direction * move_speed
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	
	# Face the player
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)


func _attack_player() -> void:
	if _player == null or not _can_attack:
		return
	
	_can_attack = false
	
	# Apply damage to player
	if _player.has_method("take_damage"):
		_player.take_damage(attack_damage, self)
	elif _player.get("health_component"):
		var hc: HealthComponent = _player.health_component
		if hc:
			hc.take_damage(attack_damage, self)
	
	# Cooldown
	if _attack_timer:
		_attack_timer.start()
		await _attack_timer.timeout
	_can_attack = true
	
	# Return to chase after attack
	_state = EnemyState.CHASE


func _on_death() -> void:
	_state = EnemyState.DEAD
	if GameState:
		GameState.record_kill()
	
	# PHASE 3 polish: death particles + sound
	if EffectsManager:
		EffectsManager.spawn_death_spark(global_position)
	if SoundManager:
		SoundManager.play_enemy_death_sound()
	
	# Disable collision but keep body for a moment
	set_process(false)
	set_physics_process(false)
	if $CollisionShape3D:
		$CollisionShape3D.disabled = true
	
	# Death fade-out
	if _anim_player and _anim_player.has_animation("death"):
		_anim_player.play("death")
	
	# Remove after brief delay
	await get_tree().create_timer(1.0).timeout
	queue_free()
