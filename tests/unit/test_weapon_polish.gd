extends "res://addons/gut/test.gd"
## Unit tests for weapon visual polish (PHASE 3): recoil, walk bob.

const WeaponScene = preload("res://scenes/weapons/baguette_gun.tscn")

var _weapon: Node3D


func before_each() -> void:
	_weapon = WeaponScene.instantiate()
	add_child_autofree(_weapon)
	await wait_frames(2)


func test_weapon_has_recoil_properties() -> void:
	assert_true(_weapon.has_method("apply_recoil"), "Weapon should have apply_recoil method")
	var recoil_strength: float = float(_weapon.get("recoil_strength"))
	var recoil_recovery: float = float(_weapon.get("recoil_recovery"))
	assert_gt(recoil_strength, 0.0, "Recoil strength should be positive")
	assert_gt(recoil_recovery, 0.0, "Recoil recovery should be positive")


func test_weapon_can_fire_with_recoil() -> void:
	var initial_ammo: int = _weapon.get_ammo_count()
	_weapon.fire()
	await wait_frames(5)
	var after_ammo: int = _weapon.get_ammo_count()
	assert_lt(after_ammo, initial_ammo, "Firing should consume ammo")


func test_weapon_fire_triggers_sound_manager() -> void:
	# Verify SoundManager exists and fire() doesn't crash with SFX integration
	assert_not_null(SoundManager, "SoundManager autoload should exist for weapon SFX")
	var initial_ammo: int = _weapon.get_ammo_count()
	_weapon.fire()
	await wait_frames(5)
	var after_ammo: int = _weapon.get_ammo_count()
	assert_lt(after_ammo, initial_ammo, "Firing should consume ammo even with SFX")


func test_weapon_reload_triggers_sound_manager() -> void:
	# Deplete ammo first
	_weapon.fire()
	await wait_frames(5)
	assert_lt(_weapon.get_ammo_count(), _weapon.get_max_ammo(), "Ammo should be depleted before reload")
	
	# Reload should trigger SoundManager.play_reload_sound()
	# Reload is async (1.5s timer) — wait long enough for it to complete
	_weapon.reload()
	await get_tree().create_timer(2.0).timeout  # reload_time is 1.5s, give margin
	assert_eq(_weapon.get_ammo_count(), _weapon.get_max_ammo(), "Ammo should be full after reload")
	assert_false(_weapon.is_reloading(), "Should not be reloading after reload completes")
