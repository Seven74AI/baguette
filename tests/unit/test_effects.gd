extends "res://addons/gut/test.gd"
## Unit tests for EffectsManager autoload (PHASE 3 polish).
## Verifies particle spawn methods exist and don't crash.

func before_all() -> void:
	# EffectsManager is an autoload — accessible globally
	pass


func test_effects_manager_exists() -> void:
	assert_not_null(EffectsManager, "EffectsManager autoload should exist")
	assert_true(EffectsManager.has_method("spawn_muzzle_flash"), "Should have spawn_muzzle_flash method")
	assert_true(EffectsManager.has_method("spawn_impact_flour"), "Should have spawn_impact_flour method")
	assert_true(EffectsManager.has_method("spawn_death_spark"), "Should have spawn_death_spark method")


func test_spawn_muzzle_flash_does_not_crash() -> void:
	# Run in a test context — should not crash even without a proper world root
	EffectsManager.spawn_muzzle_flash(Vector3.ZERO, Vector3.FORWARD)
	await wait_frames(2)
	# If we got here without errors, it's fine
	pass_test("spawn_muzzle_flash completed without errors")


func test_spawn_impact_flour_does_not_crash() -> void:
	EffectsManager.spawn_impact_flour(Vector3.ZERO, Vector3.UP)
	await wait_frames(2)
	pass_test("spawn_impact_flour completed without errors")


func test_spawn_death_spark_does_not_crash() -> void:
	EffectsManager.spawn_death_spark(Vector3(5, 2, 5))
	await wait_frames(2)
	pass_test("spawn_death_spark completed without errors")


func test_sound_manager_exists() -> void:
	assert_not_null(SoundManager, "SoundManager autoload should exist")
	assert_true(SoundManager.has_method("play_shoot_sound"), "Should have play_shoot_sound")
	assert_true(SoundManager.has_method("play_hit_sound"), "Should have play_hit_sound")
	assert_true(SoundManager.has_method("play_enemy_death_sound"), "Should have play_enemy_death_sound")
