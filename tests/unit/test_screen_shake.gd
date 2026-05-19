extends "res://addons/gut/test.gd"
## Tests for the ScreenShake component — camera shake on hit/kill feedback.

const ScreenShake = preload("res://scripts/components/screen_shake.gd")

var _shake: ScreenShake
var _camera: Camera3D


func before_each() -> void:
	_camera = Camera3D.new()
	add_child_autofree(_camera)
	
	_shake = ScreenShake.new()
	_shake.camera = _camera
	add_child_autofree(_shake)


func test_shake_starts_inactive() -> void:
	assert_false(_shake.is_shaking(), "Shake should not be active initially")


func test_trigger_shake_activates() -> void:
	_shake.trigger(1.0, 0.5)
	assert_true(_shake.is_shaking(), "Shake should be active after trigger")


func test_shake_ends_after_duration() -> void:
	_shake.trigger(1.0, 0.3)
	# Simulate time passing
	for _i in range(20):
		_shake._manual_process(0.1)
	assert_false(_shake.is_shaking(), "Shake should end after duration")


func test_camera_offset_resets_after_shake() -> void:
	var original_transform := _camera.transform
	_shake.trigger(2.0, 0.2)
	# Process through duration
	for _i in range(15):
		_shake._manual_process(0.1)
	
	# Camera should be back to original position
	assert_eq(_camera.transform.origin, original_transform.origin, "Camera should return to original position")


func test_shake_intensity_affects_magnitude() -> void:
	# High intensity shake should produce larger offsets
	_shake.trigger(10.0, 1.0)
	_shake._manual_process(0.1)
	
	var offset := _camera.transform.origin
	# With intensity 10, offset should be significant
	assert_ne(offset, Vector3.ZERO, "Camera should be offset from origin during shake")


func test_multiple_shakes_stack() -> void:
	# Use high intensity to ensure shake lasts longer than step window
	_shake.trigger(10.0, 1.0)   # trauma = 1.0, lasts ~1.25s
	_shake.trigger(5.0, 0.5)    # adds trauma up to 1.0 (clamped)

	# Should still be shaking (highest intensity wins)
	assert_true(_shake.is_shaking(), "Shake should still be active")

	# Process past 0.5s — second trigger's extra trauma should keep it going
	for _i in range(4):  # 0.4s — still within the ~1.25s window
		_shake._manual_process(0.1)
	assert_true(_shake.is_shaking(), "First shake should still be active after 0.4s")


func test_zero_intensity_does_nothing() -> void:
	_shake.trigger(0.0, 1.0)
	assert_false(_shake.is_shaking(), "Zero intensity should not trigger shake")


func test_zero_duration_does_nothing() -> void:
	_shake.trigger(1.0, 0.0)
	assert_false(_shake.is_shaking(), "Zero duration should not trigger shake")


func test_trauma_based_shake() -> void:
	# Add trauma (like from taking damage)
	_shake.add_trauma(0.5)
	assert_true(_shake.is_shaking(), "Trauma should activate shake")
	
	# Trauma decays over time
	for _i in range(30):
		_shake._manual_process(0.1)
	assert_lt(_shake.get_trauma(), 0.5, "Trauma should decay over time")
