extends "res://addons/gut/test.gd"
## Tests for Grand Critique boss — phase transitions, word projectiles,
## plate return mechanic, melee dash, giant letters, DPS check, regen.

const GrandCritique = preload("res://scripts/enemies/boss_grand_critique.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _boss: GrandCritique
var _health: HealthComponent


func before_each() -> void:
	_boss = GrandCritique.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 3000
	_health.current_health = 3000
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
	assert_eq(_boss.get_max_health(), 3000, "Boss should have 3000 HP")

func test_boss_starts_in_idle_state() -> void:
	assert_eq(_boss.current_state, GrandCritique.EnemyState.IDLE)

func test_boss_has_boss_health_bar_signal() -> void:
	watch_signals(_boss)
	_boss.take_damage(100)
	assert_signal_emitted(_boss, "boss_health_changed")


# ═══════════════════════════════════════════════════════════════
# Phase transitions (70% HP → phase 2, 30% HP → phase 3)
# ═══════════════════════════════════════════════════════════════

func test_boss_starts_in_phase_1() -> void:
	assert_eq(_boss.current_phase, 1, "Boss should start in phase 1")

func test_boss_transitions_to_phase_2_at_70_percent_hp() -> void:
	watch_signals(_boss)
	# 3000 * 0.70 = 2100; need to go below 70% → damage 900+ (to 2100 or below)
	_boss.take_damage(910)
	assert_eq(_boss.current_phase, 2, "Should transition to phase 2 at <= 70% HP")
	assert_signal_emitted(_boss, "phase_changed")

func test_boss_transitions_to_phase_3_at_30_percent_hp() -> void:
	watch_signals(_boss)
	# 3000 * 0.30 = 900; need to go below 30%
	_boss.take_damage(2110)
	assert_eq(_boss.current_phase, 3, "Should transition to phase 3 at <= 30% HP")
	assert_signal_emitted(_boss, "phase_changed")

func test_boss_phase_does_not_change_when_dead() -> void:
	_boss.take_damage(3000)
	assert_eq(_boss.current_state, GrandCritique.EnemyState.DEAD)
	assert_eq(_boss.current_phase, 1, "Phase should not change on instant kill")

func test_boss_phase_stays_same_on_small_damage() -> void:
	_boss.take_damage(100)
	assert_eq(_boss.current_phase, 1, "Small damage should not change phase")


# ═══════════════════════════════════════════════════════════════
# Phase 1 — Word projectiles + plate mechanic
# ═══════════════════════════════════════════════════════════════

func test_phase_1_has_word_projectile_method() -> void:
	assert_true(_boss.has_method("_fire_word_projectile"), "Should have word projectile method")

func test_phase_1_has_three_word_types() -> void:
	# Boss should have defined word projectile data
	var words := _boss.get("word_projectiles")
	assert_not_null(words, "Should have word_projectiles data")
	assert_eq(words.size(), 3, "Should have 3 word types (FADE, TROP CUIT, SANS SAVEUR)")

func test_phase_1_has_plate_return_weakness() -> void:
	assert_true(_boss.get("plate_stun_duration") > 0.0, "Should have plate stun duration set")

func test_plate_stuns_boss() -> void:
	_boss._on_plate_hit()
	assert_eq(_boss.get("_is_stunned"), true, "Boss should be stunned after plate hit")


# ═══════════════════════════════════════════════════════════════
# Phase 2 — Melee dash + giant CRITIQUE letters
# ═══════════════════════════════════════════════════════════════

func test_phase_2_has_dash_attack() -> void:
	assert_true(_boss.has_method("_attack_dash"), "Phase 2 should have dash attack method")

func test_phase_2_has_giant_letter_attack() -> void:
	assert_true(_boss.has_method("_attack_giant_letters"), "Phase 2 should have giant letter attack method")

func test_phase_2_speed_increases() -> void:
	var phase1_speed := _boss.move_speed
	_boss.take_damage(910)
	assert_gt(_boss.move_speed, phase1_speed, "Phase 2 move_speed should be faster than phase 1")

func test_phase_2_projectile_rate_faster() -> void:
	var p1_rate := _boss.get("word_fire_rate")
	_boss.take_damage(910)
	assert_lt(_boss.get("word_fire_rate"), p1_rate, "Phase 2 should fire word projectiles faster")


# ═══════════════════════════════════════════════════════════════
# Phase 3 — DPS check, regen, visibility reduction
# ═══════════════════════════════════════════════════════════════

func test_phase_3_has_dps_check() -> void:
	assert_true(_boss.has_method("_dps_check"), "Phase 3 should have DPS check method")

func test_phase_3_has_regeneration() -> void:
	assert_true(_boss.get("regen_enabled") != null, "Phase 3 should have regen property")
	# 3000 * 0.30 = 900; need to go below 30% → damage 2110+ (to 890 or below)
	_boss.take_damage(2110)
	assert_eq(_boss.current_phase, 3)
	# At phase 3, regen should be enabled
	assert_true(_boss.regen_enabled, "Regen should be enabled in phase 3")

func test_boss_regens_in_phase_3() -> void:
	_boss.take_damage(2500)  # Down to 500 HP — phase 3
	assert_eq(_boss.current_phase, 3)
	# Force DPS check to fail (no recent damage) so regen applies
	_boss._damage_tracker = 0.0
	_boss._dps_timer = 1.0
	_boss.regen_enabled = true
	var hp_before := _boss.get_current_health()
	_boss._apply_regen(5.0)  # 5 seconds of regen at 25 HP/s = 125 HP
	assert_gt(_boss.get_current_health(), hp_before, "Regen should heal boss in phase 3")

func test_phase_3_visibility_reduced() -> void:
	_boss.take_damage(2110)
	assert_eq(_boss.current_phase, 3)
	assert_true(_boss.get("visibility_reduced"), "Visibility should be reduced in phase 3")


# ═══════════════════════════════════════════════════════════════
# Death / reward
# ═══════════════════════════════════════════════════════════════

func test_boss_death_emits_died_signal() -> void:
	watch_signals(_boss)
	_boss.take_damage(3000)
	assert_signal_emitted(_boss, "died")

func test_boss_has_loot_explosion() -> void:
	assert_true(_boss.has_method("_loot_explosion"), "Boss should have loot explosion method")
