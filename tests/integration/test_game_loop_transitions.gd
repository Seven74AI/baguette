extends "res://addons/gut/test.gd"
## Integration tests for game loop transitions.
## Verifies: GameState signals wire to scene transitions,
## boss arena triggers victory, run_ended(won) behavior.

const BossArena = preload("res://scripts/procedural/boss_arena.gd")
const GordonBleu = preload("res://scenes/enemies/gordon_bleu.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")

var _level_scene: PackedScene
var _level: Node3D


# ═══════════════════════════════════════════════════════════════
# GameState signal behavior (unit-level, but integration-context)
# ═══════════════════════════════════════════════════════════════

func test_player_died_signal_fires_on_zero_health() -> void:
	GameState._reset_for_testing()
	GameState.player_health = 1
	watch_signals(GameState)

	GameState.damage_player(1)

	assert_eq(GameState.player_health, 0, "Player health should be 0 after fatal damage")
	assert_signal_emitted(GameState, "player_died")
	assert_false(GameState.run_active, "Run should be inactive after player death")


func test_run_ended_true_emits_won_true() -> void:
	GameState._reset_for_testing()
	GameState.start_run()
	watch_signals(GameState)

	GameState.end_run(true)

	assert_signal_emitted_with_parameters(GameState, "run_ended", [true])
	assert_false(GameState.run_active, "Run should be inactive after end_run")


func test_run_ended_false_emits_won_false() -> void:
	GameState._reset_for_testing()
	GameState.start_run()
	watch_signals(GameState)

	GameState.end_run(false)

	assert_signal_emitted_with_parameters(GameState, "run_ended", [false])
	assert_false(GameState.run_active, "Run should be inactive after end_run")


# ═══════════════════════════════════════════════════════════════
# Boss arena — Gap 3: boss death must trigger victory
# ═══════════════════════════════════════════════════════════════

func test_boss_death_calls_game_state_end_run_true() -> void:
	GameState._reset_for_testing()
	GameState.start_run()
	watch_signals(GameState)

	var arena := BossArena.new()
	arena.name = "TestArena"
	add_child_autofree(arena)

	# Spawn boss to get a GordonBleu instance
	var boss := arena.spawn_boss()
	assert_not_null(boss, "Boss should be spawned")

	# Simulate boss death by calling the callback directly
	arena._on_boss_died()

	# Gap 3 fix: _on_boss_died should call GameState.end_run(true)
	# This assertion should fail until the fix is applied
	assert_signal_emitted_with_parameters(GameState, "run_ended", [true],
		"_on_boss_died should call GameState.end_run(true) — Gap 3")


# ═══════════════════════════════════════════════════════════════
# Bakery level — Gap 1 & 2: signal connections
# ═══════════════════════════════════════════════════════════════

func test_bakery_level_instantiates_without_errors() -> void:
	_level_scene = load("res://scenes/levels/proto/bakery_test.tscn") as PackedScene
	assert_not_null(_level_scene, "Bakery test scene should load")

	if _level_scene:
		_level = _level_scene.instantiate()
		assert_not_null(_level, "Bakery level should instantiate")


func test_bakery_level_connects_player_died_signal() -> void:
	# Instantiate the level — its _ready() should connect GameState signals
	_level_scene = load("res://scenes/levels/proto/bakery_test.tscn") as PackedScene
	if not _level_scene:
		return
	_level = _level_scene.instantiate()
	add_child_autofree(_level)
	await wait_frames(5)

	# Verify player_died signal is connected to the level script
	var connections := GameState.player_died.get_connections()
	var connected := false
	for conn in connections:
		if conn.callable.get_object() == _level:
			connected = true
			break
	assert_true(connected,
		"GameState.player_died should be connected to bakery_main level script — Gap 1")


func test_bakery_level_connects_run_ended_signal() -> void:
	# Instantiate the level — its _ready() should connect GameState signals
	_level_scene = load("res://scenes/levels/proto/bakery_test.tscn") as PackedScene
	if not _level_scene:
		return
	_level = _level_scene.instantiate()
	add_child_autofree(_level)
	await wait_frames(5)

	# Verify run_ended signal is connected to the level script
	var connections := GameState.run_ended.get_connections()
	var connected := false
	for conn in connections:
		if conn.callable.get_object() == _level:
			connected = true
			break
	assert_true(connected,
		"GameState.run_ended should be connected to bakery_main level script — Gap 2")


# ═══════════════════════════════════════════════════════════════
# Scene handling safety
# ═══════════════════════════════════════════════════════════════

func test_game_over_scene_exists() -> void:
	var scene := load("res://scenes/ui/game_over.tscn") as PackedScene
	assert_not_null(scene, "game_over.tscn should exist on disk")


func test_victory_scene_exists() -> void:
	var scene := load("res://scenes/ui/victory.tscn") as PackedScene
	assert_not_null(scene, "victory.tscn should exist on disk")
