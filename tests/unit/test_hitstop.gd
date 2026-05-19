extends "res://addons/gut/test.gd"
## Tests for the Hitstop component — brief freeze-frame on impactful hits.

const Hitstop = preload("res://scripts/components/hitstop.gd")

var _hitstop: Hitstop


func before_each() -> void:
	_hitstop = Hitstop.new()
	add_child_autofree(_hitstop)


func test_hitstop_starts_inactive() -> void:
	assert_false(_hitstop.is_active(), "Hitstop should not be active initially")


func test_trigger_hitstop_activates() -> void:
	_hitstop.trigger(0.1)
	assert_true(_hitstop.is_active(), "Hitstop should be active after trigger")


func test_hitstop_ends_after_duration() -> void:
	_hitstop.trigger(0.05)
	while _hitstop.is_active():
		_hitstop._manual_process(0.1)
	assert_false(_hitstop.is_active(), "Hitstop should end after its duration")


func test_longer_hitstop_overrides_shorter() -> void:
	_hitstop.trigger(0.05)
	_hitstop.trigger(0.2)
	
	assert_true(_hitstop.is_active(), "Hitstop should be active")
	# Duration should be the longer one
	assert_gt(_hitstop.get_remaining(), 0.05, "Remaining time should be based on longer hitstop")


func test_shorter_hitstop_does_not_override_longer() -> void:
	_hitstop.trigger(0.3)
	var remaining_after_long := _hitstop.get_remaining()
	_hitstop.trigger(0.05)  # Shorter, should not override
	
	assert_gt(_hitstop.get_remaining(), 0.05, "Shorter hitstop should not reduce remaining time")


func test_get_remaining_returns_zero_when_inactive() -> void:
	assert_eq(_hitstop.get_remaining(), 0.0, "Inactive hitstop should return 0 remaining")


func test_small_hit_for_light_attack() -> void:
	# Light attack: 0.03s hitstop
	_hitstop.trigger_small()
	assert_true(_hitstop.is_active())
	# Should be around 0.03s
	assert_lt(_hitstop.get_remaining(), 0.1)


func test_medium_hit_for_normal_attack() -> void:
	_hitstop.trigger_medium()
	assert_true(_hitstop.is_active())


func test_large_hit_for_critical_kill() -> void:
	_hitstop.trigger_large()
	assert_true(_hitstop.is_active())
	assert_gt(_hitstop.get_remaining(), 0.05)  # Large should be noticeable
