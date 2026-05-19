extends Node
## Hitstop component — brief freeze-frame on impactful hits for juice/feedback.
## Slows Engine.time_scale briefly to emphasize heavy hits and kills.
##
## Light hit:  0.03s
## Normal hit: 0.05s
## Heavy hit:  0.08s
## Kill shot:  0.12s

## Default durations for different impact levels
@export var small_duration: float = 0.03
@export var medium_duration: float = 0.05
@export var large_duration: float = 0.10

var _remaining: float = 0.0
var _active: bool = false


func trigger(duration: float) -> void:
	_remaining = maxf(_remaining, duration)
	_active = true


func trigger_small() -> void:
	trigger(small_duration)


func trigger_medium() -> void:
	trigger(medium_duration)


func trigger_large() -> void:
	trigger(large_duration)


## For kill shots, use a longer freeze + reset first (kill > all)
func trigger_kill() -> void:
	_remaining = 0.12
	_active = true


func is_active() -> bool:
	return _active


func get_remaining() -> float:
	return _remaining


func _process(delta: float) -> void:
	if not _active:
		return
	
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining = 0.0
		_active = false


## Test hook — manual time stepping
func _manual_process(delta: float) -> void:
	if not _active:
		return
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining = 0.0
		_active = false
