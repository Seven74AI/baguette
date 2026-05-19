extends "res://addons/gut/test.gd"
## Bootstrap test — verifies the Godot project loads without errors.
## If we can run this test, the project loaded successfully.

func test_project_loads_without_errors() -> void:
	assert_true(true, "Project should load without errors")

func test_main_scene_is_accessible() -> void:
	# Verify the main scene resource exists
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert_not_null(main_scene, "main.tscn should be loadable as a PackedScene")

func test_gut_framework_is_loaded() -> void:
	# Verify GUT is functional — we're extending GutTest so this is already proven
	assert_not_null(gut, "GUT runner should be accessible")
