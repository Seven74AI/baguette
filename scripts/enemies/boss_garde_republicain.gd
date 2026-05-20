extends "res://scripts/enemies/base_enemy.gd"
## Garde Républicain Pâtissier — Zone 2.5 mini-boss. 2-phase mounted guard.
## Phase 1 (100-50% HP): Mounted on pain d'épices horse. Cavalry charges + matraque swings.
##   Weakness: Four Sacré scares horse (3s stun).
## Phase 2 (<50% HP): Horse destroyed. Dual-wield éclair akimbo + grenades.
##   Weakness: Éclairs can be shot mid-air.

enum BossPhase { PHASE_1 = 1, PHASE_2 = 2 }

## Emitted when the boss changes phases.
signal phase_changed(new_phase: int)

## Emitted when boss health changes (for UI health bar).
signal boss_health_changed(current: int, max_hp: int)

@export_category("Boss Stats")
@export var phase_1_speed: float = 6.0  ## Fast on horseback
@export var phase_2_speed: float = 3.5  ## Slower on foot
@export var charge_damage: int = 60  ## Massive cavalry charge damage
@export var matraque_damage: int = 25
@export var eclair_damage: int = 15
@export var grenade_damage: int = 30
@export var charge_telegraph_time: float = 1.0
@export var horse_scare_duration: float = 3.0

@export_category("Phase Thresholds")
@export var phase_2_threshold: float = 0.50  ## 50% HP

var current_phase: int = BossPhase.PHASE_1
var horse_alive: bool = true
var eclairs_interceptable: bool = true
var _is_stunned: bool = false
var _stun_timer: float = 0.0
var _charge_cooldown: float = 0.0
var _akimbo_timer: float = 0.0
var _grenade_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _charge_telegraph_timer: float = 0.0
var _is_telegraphing: bool = false
var _charge_direction: Vector3 = Vector3.ZERO
var arena: Node = null
var _initial_max_hp: int = 0


func _ready() -> void:
	super._ready()

	# Boss-specific stats
	move_speed = phase_1_speed
	attack_damage = 40
	attack_cooldown = 1.5
	detection_range = 45.0

	if health_component:
		health_component.max_health = 2000
		health_component.current_health = 2000
		_initial_max_hp = 2000
		if not health_component.health_changed.is_connected(_on_health_changed):
			health_component.health_changed.connect(_on_health_changed)


func _on_health_changed(current: int, max_hp: int) -> void:
	boss_health_changed.emit(current, max_hp)
	_check_phase_transition()


## Override take_damage to relay boss_health_changed via _on_health_changed callback.
func take_damage(amount: int, source: Node = null) -> void:
	if current_state == EnemyState.DEAD:
		return

	if health_component:
		var health_before := health_component.current_health
		health_component.take_damage(amount, source)
		if health_component.current_health < health_before:
			damaged.emit(amount, source)


## Check HP thresholds and transition phases if needed.
func _check_phase_transition() -> void:
	if not health_component or not is_alive():
		return

	var hp_ratio := float(health_component.current_health) / float(health_component.max_health)
	var new_phase := current_phase

	if hp_ratio <= phase_2_threshold:
		new_phase = BossPhase.PHASE_2
	else:
		new_phase = BossPhase.PHASE_1

	if new_phase != current_phase:
		_enter_phase(new_phase)


func _enter_phase(new_phase: int) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)

	match new_phase:
		BossPhase.PHASE_1:
			move_speed = phase_1_speed
			horse_alive = true
			eclairs_interceptable = false
		BossPhase.PHASE_2:
			move_speed = phase_2_speed
			horse_alive = false
			eclairs_interceptable = true


# ═══════════════════════════════════════════════════════════════
# Phase 1 Attacks — Cavalry charges + matraque swings
# ═══════════════════════════════════════════════════════════════

## Cavalry charge — telegraphed, massive damage, linear dash toward the player.
func _attack_cavalry_charge() -> void:
	if _player == null:
		return

	if not _is_telegraphing:
		# Start telegraph — freeze briefly, show charge direction
		_is_telegraphing = true
		_charge_telegraph_timer = charge_telegraph_time
		_charge_direction = (_player.global_position - global_position).normalized()
		_charge_direction.y = 0
		return

	# Execute charge
	velocity = _charge_direction * 20.0
	_is_telegraphing = false

	# Damage player if hit
	if global_position.distance_to(_player.global_position) <= attack_range * 2.0:
		if _player.has_method("take_damage"):
			_player.take_damage(charge_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(charge_damage, self)


## Matraque-miche de pain melee swing.
func _attack_matraque_swing() -> void:
	if _player == null:
		return

	if global_position.distance_to(_player.global_position) <= attack_range:
		if _player.has_method("take_damage"):
			_player.take_damage(matraque_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(matraque_damage, self)


## Four Sacré scares the horse — boss is stunned for 3 seconds.
func _scare_horse() -> void:
	_is_stunned = true
	_stun_timer = horse_scare_duration


# ═══════════════════════════════════════════════════════════════
# Phase 2 Attacks — Dual-wield akimbo + grenades
# ═══════════════════════════════════════════════════════════════

## Dual-wield éclairs au chocolat — rapid fire in pairs.
func _attack_akimbo() -> void:
	if _player == null:
		return

	# Fire two éclairs in quick succession (left + right)
	for i in range(2):
		var offset := Vector3(float(i - 0.5) * 0.8, 1.5, 0.0)
		var proj := Area3D.new()
		proj.name = "Eclair_" + str(i)
		proj.position = global_position + offset
		proj.set_meta("damage", eclair_damage)
		proj.set_meta("interceptable", eclairs_interceptable)

		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.2, 0.15, 1.0)  # Éclair shape: long and thin
		cs.shape = box
		proj.add_child(cs)

		get_tree().root.add_child(proj)

		# Apply damage if player is in range
		if _player.global_position.distance_to(global_position) <= detection_range:
			if _player.has_method("take_damage"):
				_player.take_damage(eclair_damage, self)
			elif _player.get("health_component"):
				var hc = _player.health_component
				if hc and hc.has_method("take_damage"):
					hc.take_damage(eclair_damage, self)

		var timer := get_tree().create_timer(4.0)
		timer.timeout.connect(proj.queue_free)


## Lateral dash — quick sideways repositioning.
func _attack_dash_lateral() -> void:
	if _player == null:
		return

	# Dash perpendicular to the player direction for evasion
	var to_player := (_player.global_position - global_position).normalized()
	var lateral := Vector3(-to_player.z, 0.0, to_player.x)  # Rotate 90°
	if randi() % 2 == 0:
		lateral = -lateral

	velocity = lateral * 12.0


## Crème pâtissière grenade — AoE sticky zone.
func _attack_grenade() -> void:
	if _player == null:
		return

	# Spawn a grenade that creates a sticky AoE zone
	var grenade_marker := CSGSphere3D.new()
	grenade_marker.name = "GrenadeZone"
	grenade_marker.radius = 1.5
	grenade_marker.position = _player.global_position + Vector3(
		randf_range(-3.0, 3.0),
		0.1,
		randf_range(-3.0, 3.0)
	)
	grenade_marker.material = StandardMaterial3D.new()
	grenade_marker.material.albedo_color = Color(1.0, 0.9, 0.7, 0.5)  # Cream color
	get_tree().root.add_child(grenade_marker)

	# Damage player if they're in the zone
	if grenade_marker.global_position.distance_to(_player.global_position) <= 1.5:
		if _player.has_method("take_damage"):
			_player.take_damage(grenade_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(grenade_damage, self)

	# Cleanup after 3 seconds
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(grenade_marker.queue_free)


# ═══════════════════════════════════════════════════════════════
# Arena integration
# ═══════════════════════════════════════════════════════════════

## Set the arena reference for this boss.
func _set_arena(arena_node: Node) -> void:
	arena = arena_node


# ═══════════════════════════════════════════════════════════════
# Death / Loot
# ═══════════════════════════════════════════════════════════════

## Dramatic loot explosion on boss death.
func _loot_explosion() -> void:
	var loot_count := 8
	for i in range(loot_count):
		var angle := float(i) / float(loot_count) * TAU
		var loot := CSGSphere3D.new()
		loot.name = "Loot_" + str(i)
		loot.radius = 0.15
		loot.position = global_position + Vector3(
			cos(angle) * 2.0,
			1.0,
			sin(angle) * 2.0
		)
		loot.material = StandardMaterial3D.new()
		loot.material.albedo_color = Color(0.8, 0.6, 0.2)  # Gold/brass
		get_tree().root.add_child(loot)

		var timer := get_tree().create_timer(10.0)
		timer.timeout.connect(loot.queue_free)


## Override death to add loot explosion.
func _on_death() -> void:
	_loot_explosion()
	super._on_death()


# ═══════════════════════════════════════════════════════════════
# Physics process override
# ═══════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	if current_state == EnemyState.DEAD:
		return

	# Handle stun
	if _is_stunned:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			_is_stunned = false
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		return

	# Handle telegraph timer
	if _is_telegraphing:
		_charge_telegraph_timer -= delta
		if _charge_telegraph_timer <= 0.0:
			_attack_cavalry_charge()  # Execute the charge
		else:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
			move_and_slide()
			return

	_find_player()

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_chase_player(delta)
			# Phase 2: use lateral dash periodically
			if current_phase == BossPhase.PHASE_2:
				_dash_cooldown -= delta
				if _dash_cooldown <= 0.0:
					_attack_dash_lateral()
					_dash_cooldown = 2.0
		EnemyState.ATTACK:
			_attack_player()

	move_and_slide()


func _attack_player() -> void:
	if _player == null:
		return

	match current_phase:
		BossPhase.PHASE_2:
			# Phase 2: akimbo rapid fire + grenade
			_akimbo_timer -= 0.1
			if _akimbo_timer <= 0.0:
				_attack_akimbo()
				_akimbo_timer = 0.4

			_grenade_cooldown -= 0.1
			if _grenade_cooldown <= 0.0:
				_attack_grenade()
				_grenade_cooldown = 3.0
		_:
			# Phase 1: cavalry charge or matraque swing
			_charge_cooldown -= 0.1
			if _charge_cooldown <= 0.0:
				if not _is_telegraphing:
					_attack_cavalry_charge()  # Start telegraph
				_charge_cooldown = 4.0
			else:
				_attack_matraque_swing()

	current_state = EnemyState.CHASE
