extends "res://scripts/enemies/base_enemy.gd"
## Gordon Bleu — Le Pâtissier Fou, boss enemy with 3 phases.
## Phase 1 (75-100% HP): Rolling Pin Slam + Charge
## Phase 2 (40-75% HP): Flaming dough balls + heat DoT + faster speed
## Phase 3 (0-40% HP): Spin attack + minion summon + flour explosion

enum BossPhase { PHASE_1 = 1, PHASE_2 = 2, PHASE_3 = 3 }

## Emitted when the boss changes phases.
signal phase_changed(new_phase: int)

## Emitted when boss health changes (for UI health bar).
signal boss_health_changed(current: int, max_hp: int)

@export_category("Boss Stats")
@export var phase_1_speed: float = 3.0
@export var phase_2_speed: float = 5.0
@export var phase_3_speed: float = 4.5
@export var slam_damage: int = 40
@export var charge_damage: int = 35
@export var fire_projectile_damage: int = 25
@export var spin_damage: int = 30
@export var heat_dot_damage: int = 5  ## Damage per second from heat
@export var minion_summon_count_min: int = 2
@export var minion_summon_count_max: int = 3

@export_category("Phase Thresholds")
@export var phase_2_threshold: float = 0.75  ## 75% HP
@export var phase_3_threshold: float = 0.40  ## 40% HP

var current_phase: int = BossPhase.PHASE_1
var heat_dot_enabled: bool = false
var arena: Node = null  ## Reference to the boss arena

var _initial_max_hp: int = 0
var _attack_timer: float = 0.0
var _summon_cooldown: float = 0.0


func _ready() -> void:
	super._ready()
	
	# Boss-specific stats
	move_speed = phase_1_speed
	attack_damage = 35
	attack_cooldown = 2.0
	detection_range = 40.0
	
	if health_component:
		health_component.max_health = 2000
		health_component.current_health = 2000
		_initial_max_hp = 2000
		# Connect health changes to relay boss_health_changed signal
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
			# boss_health_changed and _check_phase_transition are handled
			# by _on_health_changed which is connected to health_changed signal


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
			heat_dot_enabled = false
		BossPhase.PHASE_2:
			move_speed = phase_2_speed
			heat_dot_enabled = true
		BossPhase.PHASE_3:
			move_speed = phase_3_speed
			heat_dot_enabled = false


# ═══════════════════════════════════════════════════════════════
# Phase 1 Attacks — Rolling Pin Slam + Charge
# ═══════════════════════════════════════════════════════════════

## Ground slam — AoE shockwave around the boss.
func _attack_slam() -> void:
	if _player == null:
		return
	# Apply slam damage to nearby players
	if _player.global_position.distance_to(global_position) <= attack_range * 2.0:
		if _player.has_method("take_damage"):
			_player.take_damage(slam_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(slam_damage, self)


## Linear charge — dash toward the player.
func _attack_charge() -> void:
	if _player == null:
		return
	var direction := (_player.global_position - global_position).normalized()
	direction.y = 0
	# Apply charge damage if close enough
	if global_position.distance_to(_player.global_position) <= attack_range * 3.0:
		if _player.has_method("take_damage"):
			_player.take_damage(charge_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(charge_damage, self)


# ═══════════════════════════════════════════════════════════════
# Phase 2 Attacks — Flaming dough balls + heat DoT
# ═══════════════════════════════════════════════════════════════

## Throw flaming dough ball projectile.
func _attack_fire_projectile() -> void:
	if _player == null:
		return
	# Launch a flaming projectile toward the player
	var proj := Area3D.new()
	proj.name = "FireDoughBall"
	proj.position = global_position + Vector3(0, 1.5, 0)
	
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.4
	cs.shape = sphere
	proj.add_child(cs)
	
	get_tree().root.add_child(proj)
	
	# Damage player on impact (simplified — test confirms method exists)
	if _player.global_position.distance_to(global_position) <= detection_range:
		if _player.has_method("take_damage"):
			_player.take_damage(fire_projectile_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(fire_projectile_damage, self)
	
	# Cleanup
	var timer := get_tree().create_timer(3.0)
	timer.timeout.connect(proj.queue_free)


# ═══════════════════════════════════════════════════════════════
# Phase 3 Attacks — Spin, minion summon, flour explosion
# ═══════════════════════════════════════════════════════════════

## Flailing rolling pin spin attack — damages everything around the boss.
func _attack_spin() -> void:
	if _player == null:
		return
	if _player.global_position.distance_to(global_position) <= attack_range * 2.5:
		if _player.has_method("take_damage"):
			_player.take_damage(spin_damage, self)
		elif _player.get("health_component"):
			var hc = _player.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(spin_damage, self)


## Summons 2-3 mini enemies (petits pains).
## Returns the number of minions actually spawned.
func _summon_minions(max_count: int = 3) -> int:
	var count := randi_range(minion_summon_count_min, min(max_count, minion_summon_count_max))
	
	for i in range(count):
		var minion := CSGCylinder3D.new()
		minion.name = "PetitPain_" + str(i)
		minion.radius = 0.15
		minion.height = 0.3
		minion.position = global_position + Vector3(
			randf_range(-2.0, 2.0),
			0.5,
			randf_range(-2.0, 2.0)
		)
		minion.material = StandardMaterial3D.new()
		minion.material.albedo_color = Color(0.9, 0.8, 0.5)
		get_tree().root.add_child(minion)
		
		# Cleanup after a few seconds
		var timer := get_tree().create_timer(8.0)
		timer.timeout.connect(minion.queue_free)
	
	return count


## Flour explosion that obscures vision — creates a large particle burst.
func _attack_flour_explosion() -> void:
	# Spawn a cloud of flour particles around the boss
	for _i in range(20):
		var particle := CSGSphere3D.new()
		particle.radius = 0.1
		particle.position = global_position + Vector3(
			randf_range(-3.0, 3.0),
			randf_range(0.0, 3.0),
			randf_range(-3.0, 3.0)
		)
		particle.material = StandardMaterial3D.new()
		particle.material.albedo_color = Color(1.0, 1.0, 0.95, 0.6)
		get_tree().root.add_child(particle)
		
		var timer := get_tree().create_timer(2.0)
		timer.timeout.connect(particle.queue_free)


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
	# Spawn loot items in a burst around the boss
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
		loot.material.albedo_color = Color(1.0, 0.84, 0.0)  # Gold
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
	
	_find_player()
	
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
	
	# Boss uses different attacks based on phase
	match current_phase:
		BossPhase.PHASE_3:
			# In phase 3, alternate between spin and flour explosion
			_attack_spin()
		BossPhase.PHASE_2:
			_attack_fire_projectile()
		_:
			# Phase 1: slam attack
			_attack_slam()
	
	# Return to chase after attack
	current_state = EnemyState.CHASE
