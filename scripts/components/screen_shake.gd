extends Node
## Screen shake component — trauma-based camera shake for combat feedback.
## Attach to a Camera3D node. Accumulates trauma from hits/kills.
##
## Inspired by Vlambeer's juicing talk: trauma decays, intensity = trauma^2.
## More trauma = more violent shake. Multiple sources stack.

## Reference to the camera to shake (typically $Camera3D on the Player)
@export var camera: Camera3D = null

## How fast trauma decays per second. Higher = faster recovery.
@export var decay: float = 0.8

## Multiplier applied to trauma to get positional shake magnitude.
@export var max_offset: float = 0.5

## Maximum rotation in radians for the shake.
@export var max_roll: float = 0.05

var _noise: RandomNumberGenerator = RandomNumberGenerator.new()
var _trauma: float = 0.0
var _active: bool = false
var _camera_original_transform: Transform3D


func _ready() -> void:
	_noise.randomize()
	if camera:
		_camera_original_transform = camera.transform


func trigger(intensity: float, duration: float) -> void:
	if intensity <= 0.0 or duration <= 0.0:
		return
	# Scale intensity to trauma: 10.0 intensity = 1.0 trauma (max)
	var trauma_amount := clampf(intensity / 10.0, 0.0, 1.0)
	add_trauma(trauma_amount)
	_active = true


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)
	_active = true


func get_trauma() -> float:
	return _trauma


func is_shaking() -> bool:
	return _active


func _process(delta: float) -> void:
	if not _active or not camera:
		return
	_apply_shake(delta)


func _apply_shake(delta: float) -> void:
	_trauma = maxf(0.0, _trauma - decay * delta)
	
	if _trauma <= 0.0:
		if camera:
			camera.transform = _camera_original_transform
		_active = false
		return
	
	# Shake intensity = trauma^2 (softer at low trauma, violent at high)
	var shake := _trauma * _trauma
	
	# Random offset
	var offset := Vector3(
		_noise.randf_range(-1.0, 1.0) * max_offset * shake,
		_noise.randf_range(-1.0, 1.0) * max_offset * shake,
		_noise.randf_range(-1.0, 1.0) * max_offset * shake * 0.5
	)
	
	# Random rotation (roll)
	var roll := _noise.randf_range(-1.0, 1.0) * max_roll * shake
	
	camera.transform = _camera_original_transform
	camera.transform.origin += offset
	camera.rotation.z += roll


## Test hook — advance simulation manually, applying the shake effect
func _manual_process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - decay * delta)
		if _trauma <= 0.0:
			if camera:
				camera.transform = _camera_original_transform
			_active = false
		else:
			# Apply simulated shake for testing
			var shake := _trauma * _trauma
			var offset := Vector3(
				_noise.randf_range(-1.0, 1.0) * max_offset * shake,
				_noise.randf_range(-1.0, 1.0) * max_offset * shake,
				0.0
			)
			camera.transform = _camera_original_transform
			camera.transform.origin += offset
	else:
		if camera:
			camera.transform = _camera_original_transform
		_active = false
