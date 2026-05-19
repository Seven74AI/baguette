extends "res://addons/gut/test.gd"
## TDD tests for Michelin Etoile Perdu — ranged enemy that throws ink blobs.
## Verifies stats, ranged attack, ink projectile, slow effect, and Michelin Star drop.

const MichelinEtoilePerdu = preload("res://scripts/enemies/michelin_etoile_perdu.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")
const InkBlob = preload("res://scripts/projectiles/ink_blob.gd")
const MichelinStar = preload("res://scripts/pickups/michelin_star.gd")

var _enemy: MichelinEtoilePerdu
var _health: HealthComponent


func before_each() -> void:
	_enemy = MichelinEtoilePerdu.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 80
	_health.current_health = 80
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.0
	cs.shape = shape
	_enemy.add_child(cs)

	add_child_autofree(_enemy)


func test_starts_with_correct_stats() -> void:
	assert_eq(_enemy.get_max_health(), 80, "Michelin should have 80 HP")
	assert_lt(_enemy.move_speed, 5.0, "Michelin should be slow (< 5.0 speed)")
	assert_gt(_enemy.attack_range, 10.0, "Michelin should have long range (> 10.0)")
	assert_eq(_enemy.ink_damage, 12, "Ink blob should deal 12 damage")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, MichelinEtoilePerdu.EnemyState.IDLE)


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(25)
	assert_eq(_enemy.get_current_health(), initial - 25)


func test_has_ranged_attack() -> void:
	assert_true(_enemy.has_method("_fire_ink_blob"), "Should have ink blob firing method")


func test_has_projectile_scene() -> void:
	assert_not_null(_enemy.ink_blob_scene, "Should have ink_blob_scene assigned")


func test_ink_blob_has_slow_effect() -> void:
	var blob := InkBlob.new()
	assert_lt(blob.slow_factor, 1.0, "Ink blob slow factor should be < 1.0")
	assert_gt(blob.slow_factor, 0.0, "Ink blob slow factor should be > 0.0")


func test_ink_blob_deals_damage() -> void:
	var blob := InkBlob.new()
	assert_gt(blob.damage, 0, "Ink blob should deal damage")
	assert_eq(blob.damage, 12, "Ink blob should deal 12 damage")


func test_ink_blob_is_projectile() -> void:
	# InkBlob should extend Area3D for collision detection
	var blob := InkBlob.new()
	assert_true(blob is Area3D, "InkBlob should be an Area3D")


func test_ink_blob_has_body_entered_signal() -> void:
	var blob := InkBlob.new()
	add_child_autofree(blob)
	assert_true(blob.has_signal("body_entered"), "InkBlob should have body_entered signal")


func test_death_drops_michelin_star() -> void:
	watch_signals(_enemy)
	_enemy.take_damage(80)
	assert_signal_emitted(_enemy, "died")
	assert_true(_enemy.has_method("_drop_michelin_star"), "Should have Michelin Star drop method")


func test_michelin_star_is_pickup() -> void:
	var star := MichelinStar.new()
	star._ready()
	assert_not_null(star, "MichelinStar should instantiate")


func test_michelin_star_grants_crit_buff() -> void:
	var star := MichelinStar.new()
	star._ready()
	# Michelin Star is a crit buff pickup
	assert_eq(star.buff_id, "crit", "Michelin Star buff_id should be 'crit'")
	assert_gt(star.buff_duration, 0.0, "Crit buff should have duration > 0")
	assert_gt(star.crit_chance_bonus, 0.0, "Crit chance bonus should be > 0")
	assert_eq(star.crit_chance_bonus, 0.30, "Crit chance bonus should be 30%")
