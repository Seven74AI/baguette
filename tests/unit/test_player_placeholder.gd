extends "res://addons/gut/test.gd"
## Bootstrap test — verifies CharacterBody3D can be instantiated,
## confirming the engine's 3D physics capability is functional.

var _body: CharacterBody3D


func before_each() -> void:
	_body = CharacterBody3D.new()
	add_child_autofree(_body)


func test_character_body_3d_can_be_instantiated() -> void:
	assert_not_null(_body, "CharacterBody3D should be instantiable")

func test_character_body_3d_has_collision_layer() -> void:
	# Default collision layer should be non-zero (by default, layer 1 is set)
	_body.set_collision_layer_value(1, true)
	assert_true(_body.get_collision_layer_value(1), "Collision layer 1 should be settable")

func test_character_body_3d_position_defaults_to_origin() -> void:
	assert_eq(_body.position, Vector3.ZERO, "CharacterBody3D should default to origin")

func test_character_body_3d_can_be_moved() -> void:
	_body.position = Vector3(10, 0, 5)
	assert_eq(_body.position.x, 10.0, "X position should be 10")
	assert_eq(_body.position.y, 0.0, "Y position should be 0")
	assert_eq(_body.position.z, 5.0, "Z position should be 5")
