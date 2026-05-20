extends "res://scripts/enemies/base_enemy.gd"
## Grand Critique — Zone 2 boss. Restaurant critic with 3 phases.
## Phase 1 (100-70% HP): Seated, word projectiles, plates from zombie waiters.
## Phase 2 (70-30% HP): Rises, melee dash, giant CRITIQUE letters.
## Phase 3 (<30% HP): DPS check, HP regen, reduced visibility, critique text overlay.
## Weakness: Shooting plates returns them — damages boss and stuns 1s.

enum BossPhase { PHASE_1 = 1, PHASE_2 = 2, PHASE_3 = 3 }

## Emitted when the boss changes phases.
signal phase_changed(new_phase: int)

## Emitted when boss health changes (for UI health bar).
signal boss_health_changed(current: int, max_hp: int)

@export_category("Boss Stats")
@export var phase_1_speed: float = 0.0  ## Seated, no movement
@export var phase_2_speed: float = 4.0  ## Rises, moderate speed
@export var phase_3_speed: float = 3.0  ## Slower, writing
@export var word_fire_rate: float = 2.0  ## Seconds between word projectiles (phase 1)
@export var word_fire_rate_phase2: float = 1.2
@export var word_fire_rate_phase3: float = 0.8
@export var dash_damage: int = 45
@export var giant_letter_damage: int = 50
@export var plate_stun_duration: float = 1.0
@export var regen_rate: float = 25.0  ## HP per second in phase 3
@export var dps_check_threshold: float = 35.0  ## Minimum DPS to prevent regen

@export_category("Phase Thresholds")
@export var phase_2_threshold: float = 0.70  ## 70% HP
@export var phase_3_threshold: float = 0.30  ## 30% HP

## Word projectile definitions: [name, speed, damage, debuff_id]
## FADE: slow, low dmg. TROP CUIT: medium, tracking. SANS SAVEUR: fast, debuff.
var word_projectiles: Array[Dictionary] = [
	{"name": "FADE", "speed": 3.0, "damage": 10, "tracking": 0.0},
	{"name": "TROP CUIT", "speed": 5.0, "damage": 20, "tracking": 0.3},
	{"name": "SANS SAVEUR", "speed": 8.0, "damage": 15, "tracking": 0.0, "debuff": "damage_down"}
]

var current_phase: int = BossPhase.PHASE_1
var _is_stunned: bool = false
var _stun_timer: float = 0.0
var _projectile_timer: float = 0.0
var _letter_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _damage_tracker: float = 0.0  ## Recent damage for DPS check
var _dps_timer: float = 0.0
var regen_enabled: bool = false
var visibility_reduced: bool = false
var arena: Node = null
var _initial_max_hp: int = 0


func _ready() -> void:
	super._ready()

	# Boss-specific stats
	move_speed = phase_1_speed
	attack_damage = 40
	attack_cooldown = 2.0
	detection_range = 50.0

	if health_component:
		health_component.max_health = 3000
		health_component.current_health = 3000
		_initial_max_hp = 3000
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
			# Track damage for DPS check
			_damage_tracker += amount


## Check HP thresholds and transition phases if needed.
func _check_phase_transition() -> void:
	if not health_component or not is_alive():
		return

	var hp_ratio := float(health_component.current_health) / float(health_component.max_health)
	var new_phase := current_phase

	if hp_ratio <= phase_3_threshold:
		new_phase = BossPhase.PHASE_3
	elif hp_ratio <= phase_2_threshold:
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
			word_fire_rate = 2.0
			regen_enabled = false
			visibility_reduced = false
		BossPhase.PHASE_2:
			move_speed = phase_2_speed
			word_fire_rate = word_fire_rate_phase2
			regen_enabled = false
			visibility_reduced = false
		BossPhase.PHASE_3:
			move_speed = phase_3_speed
			word_fire_rate = word_fire_rate_phase3
			regen_enabled = true
			visibility_reduced = true


# ═══════════════════════════════════════════════════════════════
# Phase 1 Attacks — Word projectiles
# ═══════════════════════════════════════════════════════════════

## Fire a floating word projectile toward the player.
## Picks a random word from word_projectiles.
func _fire_word_projectile() -> void:
	if _player == null or word_projectiles.is_empty():
		return

	var word_data: Dictionary = word_projectiles[randi() % word_projectiles.size()]
	var proj := Area3D.new()
	proj.name = "Word_" + word_data.name
	proj.position = global_position + Vector3(0, 2.0, 0)
	proj.set_meta("damage", word_data.damage)
	proj.set_meta("speed", word_data.speed)
	proj.set_meta("word_name", word_data.name)

	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	cs.shape = sphere
	proj.add_child(cs)

	get_tree().root.add_child(proj)

	# Apply damage if player is in range
	if _player.global_position.distance_to(global_position) <= detection_range:
		if _player.has_method("take_damage"):
			_player.take_damage(word_data.damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(word_data.damage, self)

	# Cleanup after lifetime
	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(proj.queue_free)


# ═══════════════════════════════════════════════════════════════
# Plate return weakness — zombie waiters carry plates, player shoots them
# ═══════════════════════════════════════════════════════════════

## Called when a plate is returned to the boss (player shoots a plate projectile).
## Damages the boss and stuns for plate_stun_duration seconds.
func _on_plate_hit() -> void:
	take_damage(100, null)
	_is_stunned = true
	_stun_timer = plate_stun_duration


# ═══════════════════════════════════════════════════════════════
# Phase 2 Attacks — Melee dash + giant CRITIQUE letters
# ═══════════════════════════════════════════════════════════════

## Melee dash attack — boss dashes toward the player dealing damage.
func _attack_dash() -> void:
	if _player == null:
		return

	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0
	velocity = direction * 15.0  # Burst speed for dash

	if global_position.distance_to(_player.global_position) <= attack_range:
		if _player.has_method("take_damage"):
			_player.take_damage(dash_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(dash_damage, self)


## Invokes giant CRITIQUE letters that crush a zone (shadow telegraph on ground).
func _attack_giant_letters() -> void:
	if _player == null:
		return

	# Spawn a giant letter at the player's position with a shadow telegraph
	var letter_marker := CSGBox3D.new()
	letter_marker.name = "GiantLetter"
	letter_marker.size = Vector3(2.5, 0.1, 2.5)
	letter_marker.position = _player.global_position + Vector3(
		randf_range(-2.0, 2.0),
		0.05,
		randf_range(-2.0, 2.0)
	)
	# Telegraph color: dark shadow
	letter_marker.material = StandardMaterial3D.new()
	letter_marker.material.albedo_color = Color(0.1, 0.1, 0.1, 0.6)
	get_tree().root.add_child(letter_marker)

	# Damage player if they're in the zone after telegraph
	if letter_marker.global_position.distance_to(_player.global_position) <= 2.0:
		if _player.has_method("take_damage"):
			_player.take_damage(giant_letter_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(giant_letter_damage, self)

	# Cleanup
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(letter_marker.queue_free)


# ═══════════════════════════════════════════════════════════════
# Phase 3 — DPS check, regen, visibility
# ═══════════════════════════════════════════════════════════════

## DPS check: if player DPS is too low, warn or apply debuff.
## Returns true if DPS is sufficient.
func _dps_check() -> bool:
	var dps := _damage_tracker / maxf(_dps_timer, 0.1)
	return dps >= dps_check_threshold


## Apply HP regeneration in phase 3.
## Called periodically from _process.
func _apply_regen(delta: float) -> void:
	if not regen_enabled or not health_component:
		return

	# Only regen if DPS check fails
	if not _dps_check():
		health_component.heal(int(regen_rate * delta))
	else:
		# Player is doing enough DPS — reset tracker periodically
		pass


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
	var loot_count := 10
	for i in range(loot_count):
		var angle := float(i) / float(loot_count) * TAU
		var loot := CSGSphere3D.new()
		loot.name = "Loot_" + str(i)
		loot.radius = 0.15
		loot.position = global_position + Vector3(
			cos(angle) * 2.5,
			1.0,
			sin(angle) * 2.5
		)
		loot.material = StandardMaterial3D.new()
		loot.material.albedo_color = Color(0.2, 0.2, 0.9)  # Ink blue
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
		return  # Don't move while stunned

	# DPS tracker tick
	_dps_timer += delta
	if _dps_timer > 1.0:
		# Reset tracker every second
		_damage_tracker = 0.0
		_dps_timer = 0.0

	# Phase 3 regen
	if current_phase == BossPhase.PHASE_3:
		_apply_regen(delta)

	_find_player()

	# Projectile timer
	_projectile_timer += delta
	if _projectile_timer >= word_fire_rate and current_phase != BossPhase.PHASE_1:
		_projectile_timer = 0.0
		_fire_word_projectile()

	# Phase 2: letter attack on timer
	if current_phase == BossPhase.PHASE_2:
		_letter_timer += delta
		if _letter_timer >= 3.0:
			_letter_timer = 0.0
			_attack_giant_letters()

	match current_state:
		EnemyState.IDLE:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		EnemyState.CHASE:
			_chase_player(delta)
		EnemyState.ATTACK:
			_attack_player()

	move_and_slide()


func _attack_player() -> void:
	if _player == null:
		return

	match current_phase:
		BossPhase.PHASE_3:
			# Phase 3: fire word projectiles + regen is passive
			_fire_word_projectile()
		BossPhase.PHASE_2:
			# Phase 2: dash on cooldown
			_dash_cooldown -= 0.1
			if _dash_cooldown <= 0.0:
				_attack_dash()
				_dash_cooldown = 1.5
		_:
			# Phase 1: word projectile volley
			_fire_word_projectile()

	current_state = EnemyState.CHASE
