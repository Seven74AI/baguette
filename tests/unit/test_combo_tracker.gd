extends "res://addons/gut/test.gd"
## Tests for the ComboTracker — combo chains, multi-kills, and combo breaks.

const ComboTracker = preload("res://scripts/components/combo_tracker.gd")

var _combo: ComboTracker


func before_each() -> void:
	_combo = ComboTracker.new()
	add_child_autofree(_combo)


func test_starts_at_zero_combo() -> void:
	assert_eq(_combo.get_combo_count(), 0, "Combo should start at 0")
	assert_false(_combo.is_combo_active(), "Combo should not be active initially")


func test_record_kill_starts_combo() -> void:
	watch_signals(_combo)
	_combo.record_kill()
	assert_eq(_combo.get_combo_count(), 1, "First kill should set combo to 1")
	assert_true(_combo.is_combo_active(), "Combo should be active after first kill")


func test_consecutive_kills_increment_combo() -> void:
	_combo.record_kill()
	_combo.record_kill()
	assert_eq(_combo.get_combo_count(), 2, "Two kills should increment combo to 2")


func test_kill_emits_combo_signal() -> void:
	watch_signals(_combo)
	_combo.record_kill()
	_combo.record_kill()
	assert_signal_emitted(_combo, "combo_advanced")


func test_multi_kill_emits_signal() -> void:
	watch_signals(_combo)
	_combo.record_multi_kill(3)
	assert_signal_emitted(_combo, "multi_kill")


func test_multi_kill_sets_count() -> void:
	_combo.record_multi_kill(5)
	assert_eq(_combo.get_combo_count(), 5, "Multi-kill should set combo count")


func test_combo_expires_after_timeout() -> void:
	_combo.record_kill()
	assert_true(_combo.is_combo_active())

	# Simulate time passing beyond combo window
	_combo._combo_timer(999.0)  # Force timeout
	assert_false(_combo.is_combo_active(), "Combo should expire after timeout")
	assert_eq(_combo.get_combo_count(), 0, "Combo count should reset on timeout")


func test_combo_renews_on_kill() -> void:
	_combo.record_kill()
	# Advance timer partially
	_combo._combo_timer(0.5)
	assert_true(_combo.is_combo_active(), "Combo should still be active mid-window")

	# Another kill resets timer
	_combo.record_kill()
	assert_eq(_combo.get_combo_count(), 2, "Kill should increment combo")
	assert_true(_combo.is_combo_active(), "Combo should remain active")


func test_highest_combo_tracked() -> void:
	_combo.record_kill()
	_combo.record_kill()
	_combo.record_kill()
	_combo._combo_timer(999.0)  # Break combo
	_combo.record_kill()
	assert_eq(_combo.get_highest_combo(), 3, "Highest combo should be 3")


func test_reset_clears_all() -> void:
	_combo.record_kill()
	_combo.record_kill()
	_combo.reset()
	assert_eq(_combo.get_combo_count(), 0, "Reset should clear combo count")
	assert_false(_combo.is_combo_active(), "Reset should deactivate combo")
	assert_eq(_combo.get_highest_combo(), 0, "Reset should clear highest combo")


func test_combo_window_default() -> void:
	assert_eq(_combo.combo_window, 2.0, "Default combo window should be 2.0 seconds")
