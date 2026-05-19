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
