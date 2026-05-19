extends "res://addons/gut/test.gd"
## Minimal test to verify GUT test discovery for weapon_manager.

func test_weapon_manager_trivial() -> void:
	assert_true(true, "This test should be discovered and pass")
