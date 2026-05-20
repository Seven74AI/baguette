extends "res://addons/gut/test.gd"
## Tests for Garde Républicain Pâtissier mini-boss — cavalry charges,
## horse destruction, dual-wield akimbo, grenades, projectile interception.

const GardeRepublicain = preload("res://scripts/enemies/boss_garde_republicain.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _boss: GardeRepublicain
var _health: HealthComponent


func before_each() -> void:
	_boss = GardeRepublicain.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 2000
	_health.current_health = 2000
	_health.invulnerability_duration = 0.0
	_boss.add_child(_health)
	_boss.health_component = _health

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
	assert_eq(_boss.get_max_health(), 2000, "Mini-boss should have 2000 HP")

func test_boss_starts_in_idle_state() -> void:
	assert_eq(_boss.current_state, GardeRepublicain.EnemyState.IDLE)

func test_boss_has_boss_health_bar_signal() -> void:
	watch_signals(_boss)
	_boss.take_damage(100)
	assert_signal_emitted(_boss, "boss_health_changed")


# ═══════════════════════════════════════════════════════════════
# Phase transitions (50% HP → phase 2)
# ═══════════════════════════════════════════════════════════════

func test_boss_starts_in_phase_1() -> void:
	assert_eq(_boss.current_phase, 1, "Boss should start in phase 1")

func test_boss_transitions_to_phase_2_at_50_percent_hp() -> void:
	watch_signals(_boss)
	# 2000 * 0.50 = 1000; need to go below 50%
	_boss.take_damage(1001)
	assert_eq(_boss.current_phase, 2, "Should transition to phase 2 at <= 50% HP")
	assert_signal_emitted(_boss, "phase_changed")

func test_boss_phase_does_not_change_when_dead() -> void:
	_boss.take_damage(2000)
	assert_eq(_boss.current_state, GardeRepublicain.EnemyState.DEAD)
	assert_eq(_boss.current_phase, 1, "Phase should not change on instant kill")


# ═══════════════════════════════════════════════════════════════
# Phase 1 — Mounted cavalry charges
# ═══════════════════════════════════════════════════════════════

func test_phase_1_has_horse() -> void:
	assert_true(_boss.get("horse_alive") != null, "Boss should track horse status")
	assert_true(_boss.horse_alive, "Horse should be alive in phase 1")

func test_phase_1_has_charge_attack() -> void:
	assert_true(_boss.has_method("_attack_cavalry_charge"), "Phase 1 should have cavalry charge method")

func test_charge_is_telegraphed() -> void:
	# Charge should have a telegraph duration before executing
	assert_gt(_boss.charge_telegraph_time, 0.0, "Charge should have telegraph time > 0")

func test_phase_1_has_melee_swing() -> void:
	assert_true(_boss.has_method("_attack_matraque_swing"), "Phase 1 should have matraque swing method")

func test_phase_1_has_four_sacre_weakness() -> void:
	# Four Sacré should scare the horse (3s stun)
	assert_true(_boss.has_method("_scare_horse"), "Should have horse scare method")

func test_horse_scare_stuns_boss() -> void:
	_boss._scare_horse()
	assert_true(_boss._is_stunned, "Boss should be stunned after horse scare")
	assert_eq(_boss.horse_scare_duration, 3.0, "Horse scare should last 3 seconds")


# ═══════════════════════════════════════════════════════════════
# Phase 2 — Horse destroyed, dual-wield akimbo
# ═══════════════════════════════════════════════════════════════

func test_phase_2_horse_destroyed() -> void:
	_boss.take_damage(1001)
	assert_false(_boss.horse_alive, "Horse should be destroyed in phase 2")

func test_phase_2_has_akimbo_attack() -> void:
	assert_true(_boss.has_method("_attack_akimbo"), "Phase 2 should have akimbo dual-wield method")

func test_phase_2_has_dash() -> void:
	assert_true(_boss.has_method("_attack_dash_lateral"), "Phase 2 should have lateral dash method")

func test_phase_2_has_grenade_attack() -> void:
	assert_true(_boss.has_method("_attack_grenade"), "Phase 2 should have crème pâtissière grenade method")

func test_phase_2_eclairs_are_shootable() -> void:
	# Boss should expose property indicating éclairs can be intercepted
	assert_true(_boss.get("eclairs_interceptable") != null, "Should track whether éclairs are interceptable")
	assert_true(_boss.eclairs_interceptable, "Éclairs should be interceptable in phase 2")


# ═══════════════════════════════════════════════════════════════
# Death / reward
# ═══════════════════════════════════════════════════════════════

func test_boss_death_emits_died_signal() -> void:
	watch_signals(_boss)
	_boss.take_damage(2000)
	assert_signal_emitted(_boss, "died")

func test_boss_has_loot_explosion() -> void:
	assert_true(_boss.has_method("_loot_explosion"), "Mini-boss should have loot explosion method")
