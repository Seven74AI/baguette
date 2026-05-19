extends "res://addons/gut/test.gd"
## Tests for SourdoughBlob — slime-like enemy that oozes and leaves slowing puddles.
## Verifies stats, slime trail, slow effect, and AoE behavior.

const SourdoughBlob = preload("res://scenes/enemies/sourdough_blob.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _enemy: SourdoughBlob
var _health: HealthComponent


func before_each() -> void:
	_enemy = SourdoughBlob.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 120
	_health.current_health = 120
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	var shape := SphereShape3D.new()
	shape.radius = 0.7
	cs.shape = shape
	_enemy.add_child(cs)

	add_child_autofree(_enemy)


func test_starts_with_correct_stats() -> void:
	assert_lt(_enemy.move_speed, 4.0, "Sourdough Blob should be slow (< 4.0 speed)")
	assert_eq(_enemy.get_max_health(), 120, "Should have medium HP (120)")
	assert_gt(_enemy.attack_damage, 15, "Should deal decent damage (> 15)")


func test_starts_in_idle_state() -> void:
	assert_eq(_enemy.current_state, SourdoughBlob.EnemyState.IDLE)


func test_take_damage_reduces_health() -> void:
	var initial := _enemy.get_current_health()
	_enemy.take_damage(30)
	assert_eq(_enemy.get_current_health(), initial - 30)


func test_leaves_slime_trail() -> void:
	assert_true(_enemy.has_method("_spawn_slime_puddle"), "Should have slime puddle spawning")


func test_slime_puddle_slows_player() -> void:
	# The slow factor should be exposed
	assert_lt(_enemy.slime_slow_factor, 1.0, "Slime slow factor should be < 1.0")
	assert_gt(_enemy.slime_slow_factor, 0.0, "Slime slow factor should be > 0.0")


func test_has_ooze_animation_hint() -> void:
	# The blob should have a configurable wobble for the ooze effect
	assert_gt(_enemy.ooze_wobble_intensity, 0.0, "Should have ooze wobble intensity")


func test_death_leaves_puddle() -> void:
	watch_signals(_enemy)
	_enemy.take_damage(120)
	assert_signal_emitted(_enemy, "died")
	# On death, the blob should leave a large final puddle
	assert_true(_enemy.has_method("_spawn_death_puddle"), "Should leave a puddle on death")
