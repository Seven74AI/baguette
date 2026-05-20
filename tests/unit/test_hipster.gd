extends "res://addons/gut/test.gd"
## Tests for Hipster Sans Gluten — Specialist/Debuffer enemy.
## Verifies stats, debuff attacks, Aura Vegan, appareil photo weakness, elite variant.

const HipsterSansGluten = preload("res://scripts/enemies/hipster_sans_gluten.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: HipsterSansGluten
var _health: HealthComponent


func before_each() -> void:
	_enemy = HipsterSansGluten.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 90
	_health.current_health = 90
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.5
	cs.shape = shape
	_enemy.add_child(cs)

	add_child_autofree(_enemy)


func test_spawns_with_correct_stats() -> void:
	assert_eq(_enemy.get_max_health(), 90, "Should have 90 HP")
	assert_between(_enemy.move_speed, 3.0, 6.0, "Should have medium speed")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, HipsterSansGluten.EnemyState.IDLE)


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(20)
	assert_eq(_enemy.get_current_health(), initial - 20)


func test_has_debuff_attack() -> void:
	assert_true(_enemy.has_method("_fire_flour_projectile"), "Should have flour projectile method")
	assert_true(_enemy.has_method("_apply_intolerance_debuff"), "Should have debuff application method")


func test_intolerance_debuff_exists() -> void:
	# The debuff should affect reload speed and move speed
	assert_gt(_enemy.intolerance_reload_penalty, 0.0, "Should have reload speed penalty")
	assert_gt(_enemy.intolerance_speed_penalty, 0.0, "Should have move speed penalty")


func test_has_aura_vegan() -> void:
	assert_true(_enemy.has_method("_activate_aura_vegan"), "Should have Aura Vegan activation")
	assert_true(_enemy.get("aura_vegan_active") != null, "Should have aura_vegan_active property")


func test_has_appareil_photo() -> void:
	assert_true(_enemy.has_method("_use_appareil_photo"), "Should have appareil photo ability")
	assert_gt(_enemy.photo_regen_amount, 0, "Photo should regen HP")


func test_appareil_photo_explodes_when_shot() -> void:
	assert_true(_enemy.photo_explodes_on_hit, "Appareil photo should explode on hit")
	assert_gt(_enemy.photo_explosion_damage, 0, "Photo explosion should deal damage")


func test_is_ranged_enemy() -> void:
	assert_gt(_enemy.attack_range, 8.0, "Should be a ranged enemy (> 8m range)")


func test_has_dodge_ability() -> void:
	assert_true(_enemy.has_method("_perform_dodge"), "Should have dodge ability")


func test_has_elite_variant() -> void:
	assert_true(_enemy.has_method("_apply_elite_modifier"), "Should support elite variants")
	assert_true(_enemy.get("is_elite") != null, "Should have is_elite property")


func test_dies_correctly() -> void:
	_enemy.take_damage(90)
	assert_eq(_enemy.current_state, HipsterSansGluten.EnemyState.DEAD)
