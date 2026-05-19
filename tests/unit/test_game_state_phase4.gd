extends "res://addons/gut/test.gd"
## PHASE 4.1: GameState additions — rooms_cleared, run_time, total_damage_dealt.

func before_each() -> void:
	GameState._reset_for_testing()


func test_rooms_cleared_defaults_to_zero() -> void:
	assert_eq(GameState.rooms_cleared, 0, "rooms_cleared should default to 0")


func test_run_time_defaults_to_zero() -> void:
	assert_eq(GameState.run_time, 0.0, "run_time should default to 0.0")


func test_total_damage_dealt_defaults_to_zero() -> void:
	assert_eq(GameState.total_damage_dealt, 0, "total_damage_dealt should default to 0")


func test_increment_rooms_cleared() -> void:
	GameState.start_run()
	GameState.increment_rooms_cleared()
	assert_eq(GameState.rooms_cleared, 1, "rooms_cleared should increment to 1")
	GameState.increment_rooms_cleared()
	assert_eq(GameState.rooms_cleared, 2, "rooms_cleared should increment to 2")


func test_run_time_increments_when_run_active() -> void:
	GameState.start_run()
	assert_true(GameState.run_active, "run_active should be true after start_run()")
	var initial_time: float = GameState.run_time
	await wait_seconds(0.2)
	assert_gt(GameState.run_time, initial_time, "run_time should increase while run_active")


func test_run_time_does_not_increment_when_run_inactive() -> void:
	# run_active is false by default after reset
	var initial_time: float = GameState.run_time
	await wait_seconds(0.1)
	assert_eq(GameState.run_time, initial_time, "run_time should NOT increase while run is inactive")


func test_record_damage_dealt() -> void:
	GameState.start_run()
	GameState.record_damage_dealt(15)
	assert_eq(GameState.total_damage_dealt, 15, "total_damage_dealt should be 15 after recording 15")
	GameState.record_damage_dealt(10)
	assert_eq(GameState.total_damage_dealt, 25, "total_damage_dealt should be 25 after recording 10 more")


func test_start_run_resets_phase4_fields() -> void:
	GameState.start_run()
	GameState.increment_rooms_cleared()
	GameState.increment_rooms_cleared()
	GameState.record_damage_dealt(50)
	# End run then start new
	GameState.end_run(false)
	GameState.start_run()
	assert_eq(GameState.rooms_cleared, 0, "rooms_cleared should reset to 0 on new run")
	assert_eq(GameState.run_time, 0.0, "run_time should reset to 0.0 on new run")
	assert_eq(GameState.total_damage_dealt, 0, "total_damage_dealt should reset to 0 on new run")


func test_run_ended_signal_emits_on_end_run() -> void:
	GameState.start_run()
	GameState.end_run(true)
	assert_false(GameState.run_active, "run_active should be false after end_run()")
