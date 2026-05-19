extends "res://addons/gut/test.gd"
## Tests for GordonBleu boss — phase transitions, attack patterns, minion summons.
## Verifies HP thresholds trigger phase changes, attack availability per phase,
## and minion summon count.

const GordonBleu = preload("res://scenes/enemies/gordon_bleu.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _boss: GordonBleu
var _health: HealthComponent


func before_each() -> void:
	_boss = GordonBleu.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 2000
	_health.current_health = 2000
	_health.invulnerability_duration = 0.0
	_boss.add_child(_health)
	_boss.health_component = _health

	# Add collision shape (required for CharacterBody3D behavior)
	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 1.0
	shape.height = 3.0
	cs.shape = shape
	_boss.add_child(cs)

	add_child_autofree(_boss)


# ═══════════════════════════════════════════════════════════════
# Stats
# ═══════════════════════════════════════════════════════════════

func test_boss_starts_with_correct_max_health() -> void:
	assert_eq(_boss.get_max_health(), 2000, "Boss should have 2000 HP")

func test_boss_starts_with_correct_attack_damage() -> void:
	assert_gt(_boss.attack_damage, 30, "Boss should hit hard (30+ damage)")

func test_boss_starts_with_correct_detection_range() -> void:
	assert_gt(_boss.detection_range, 20.0, "Boss should have large detection range (20+)")

func test_boss_starts_in_idle_state() -> void:
	assert_eq(_boss.current_state, GordonBleu.EnemyState.IDLE)


# ═══════════════════════════════════════════════════════════════
# Phase transitions
# ═══════════════════════════════════════════════════════════════

func test_boss_starts_in_phase_1() -> void:
	assert_eq(_boss.current_phase, 1, "Boss should start in phase 1")

func test_boss_transitions_to_phase_2_at_75_percent_hp() -> void:
	watch_signals(_boss)
	# Damage boss down to 75% HP (1500 / 2000)
	_boss.take_damage(500)
	assert_eq(_boss.current_phase, 2, "Should transition to phase 2 at <= 75% HP")
	assert_signal_emitted(_boss, "phase_changed")

func test_boss_transitions_to_phase_3_at_40_percent_hp() -> void:
	watch_signals(_boss)
	# Damage boss down to 40% HP (800 / 2000)
	_boss.take_damage(1200)
	assert_eq(_boss.current_phase, 3, "Should transition to phase 3 at <= 40% HP")
	# phase_changed should have been emitted (at least once — may skip phase 2 on large hits)
	assert_signal_emitted(_boss, "phase_changed")

func test_boss_transition_skips_when_dead() -> void:
	# One-shot kill should trigger death, not phase transitions
	watch_signals(_boss)
	_boss.take_damage(2000)
	assert_signal_emitted(_boss, "died")


# ═══════════════════════════════════════════════════════════════
# Phase 1 attacks — Rolling Pin Slam + Charge
# ═══════════════════════════════════════════════════════════════

func test_phase_1_has_slam_attack() -> void:
	assert_true(_boss.has_method("_attack_slam"), "Phase 1 should have slam attack method")

func test_phase_1_has_charge_attack() -> void:
	assert_true(_boss.has_method("_attack_charge"), "Phase 1 should have charge attack method")


# ═══════════════════════════════════════════════════════════════
# Phase 2 attacks — Flaming dough balls, heat, speed boost
# ═══════════════════════════════════════════════════════════════

func test_phase_2_has_fire_projectile_attack() -> void:
	assert_true(_boss.has_method("_attack_fire_projectile"), "Phase 2 should have fire projectile method")

func test_phase_2_has_heat_dot_enabled() -> void:
	assert_true(_boss.get("heat_dot_enabled") != null, "Phase 2 should have heat DoT property")

func test_phase_2_speed_increases() -> void:
	var phase1_speed := _boss.move_speed
	# Force boss to phase 2
	_boss.take_damage(500)
	assert_gt(_boss.move_speed, phase1_speed, "Phase 2 move_speed should be faster than phase 1")


# ═══════════════════════════════════════════════════════════════
# Phase 3 attacks — Spin, minion summon, flour explosion
# ═══════════════════════════════════════════════════════════════

func test_phase_3_has_spin_attack() -> void:
	assert_true(_boss.has_method("_attack_spin"), "Phase 3 should have spin attack method")

func test_phase_3_has_flour_explosion() -> void:
	assert_true(_boss.has_method("_attack_flour_explosion"), "Phase 3 should have flour explosion method")

func test_phase_3_has_summon_method() -> void:
	assert_true(_boss.has_method("_summon_minions"), "Phase 3 should have minion summon method")

func test_phase_3_summons_2_to_3_minions() -> void:
	# Force to phase 3 then trigger summon
	_boss.take_damage(1200)
	assert_eq(_boss.current_phase, 3)
	# Summon should return the number of minions spawned
	var count := _boss._summon_minions(3)
	assert_between(count, 2, 3, "Summon should spawn 2-3 minions")


# ═══════════════════════════════════════════════════════════════
# Boss death / loot
# ═══════════════════════════════════════════════════════════════

func test_boss_death_emits_died_signal() -> void:
	watch_signals(_boss)
	_boss.take_damage(2000)
	assert_signal_emitted(_boss, "died")

func test_boss_death_has_loot_explosion() -> void:
	assert_true(_boss.has_method("_loot_explosion"), "Boss should have loot explosion method")

func test_boss_has_health_bar_signal() -> void:
	# Boss should expose a signal for health bar updates
	# Re-check that health_changed from the health_component is proxied
	watch_signals(_boss)
	_boss.take_damage(100)
	assert_signal_emitted(_boss, "boss_health_changed")


# ═══════════════════════════════════════════════════════════════
# Boss arena integration
# ═══════════════════════════════════════════════════════════════

func test_boss_has_arena_reference() -> void:
	# Boss should have a way to reference its arena
	assert_true(_boss.get("arena") != null or _boss.has_method("_set_arena"),
		"Boss should have arena integration")


# ═══════════════════════════════════════════════════════════════
# Edge cases
# ═══════════════════════════════════════════════════════════════

func test_boss_phase_does_not_change_when_dead() -> void:
	_boss.take_damage(2000)
	assert_eq(_boss.current_state, GordonBleu.EnemyState.DEAD)
	# Phase should be frozen at last phase (don't change after death)
	assert_eq(_boss.current_phase, 1, "Phase should not change when dead (single-hit kill)")

func test_boss_phase_persists_after_mid_phase_damage() -> void:
	# Damage that stays within the same phase shouldn't change phase
	_boss.take_damage(100)  # 1900 / 2000 = 95% — still phase 1
	assert_eq(_boss.current_phase, 1, "Small damage should not change phase")
