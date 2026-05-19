extends Node
## Combo and multi-kill tracker — monitors consecutive enemy kills.
## Attach to the player or GameState to track combat flow.
##
## Combo: consecutive kills within `combo_window` seconds.
## Multi-kill: multiple enemies killed in a single action/frame.

signal combo_advanced(new_count: int)
signal multi_kill(count: int)
signal combo_broken(final_count: int)

## Time window (seconds) between kills to maintain a combo chain
@export var combo_window: float = 2.0

var _combo_count: int = 0
var _highest_combo: int = 0
var _combo_timer_val: float = 0.0


func _process(delta: float) -> void:
	if _combo_timer_val > 0.0:
		_combo_timer_val -= delta
		if _combo_timer_val <= 0.0:
			_break_combo()


func record_kill() -> void:
	_combo_count += 1
	_combo_timer_val = combo_window
	if _combo_count > _highest_combo:
		_highest_combo = _combo_count
	if _combo_count >= 2:
		combo_advanced.emit(_combo_count)


func record_multi_kill(count: int) -> void:
	assert(count >= 2, "Multi-kill requires at least 2 kills")
	_combo_count = maxi(_combo_count, count)
	if _combo_count > _highest_combo:
		_highest_combo = _combo_count
	_combo_timer_val = combo_window
	multi_kill.emit(count)
	combo_advanced.emit(_combo_count)


func get_combo_count() -> int:
	return _combo_count


func get_highest_combo() -> int:
	return _highest_combo


func is_combo_active() -> bool:
	return _combo_timer_val > 0.0


func reset() -> void:
	_combo_count = 0
	_highest_combo = 0
	_combo_timer_val = 0.0


## Test hook — force timer advance for unit testing
func _combo_timer(delta: float) -> void:
	if _combo_timer_val > 0.0:
		_combo_timer_val -= delta
		if _combo_timer_val <= 0.0:
			_break_combo()


func _break_combo() -> void:
	if _combo_count >= 2:
		combo_broken.emit(_combo_count)
	_combo_count = 0
	_combo_timer_val = 0.0
