extends GutTest
## Bootstrap test — verifies the Godot project loads and basic systems are accessible.

func test_project_loads_without_errors() -> void:
	# If we're running, the project loaded successfully.
	assert_true(true, "Project should load without errors")


func test_game_state_autoload_exists() -> void:
	assert_not_null(GameState, "GameState autoload should be accessible")
	assert_eq(GameState.player_max_health, 100, "Player max health should be 100")


func test_game_state_run_lifecycle() -> void:
	GameState.start_run()
	assert_true(GameState.run_active, "Run should be active after start_run()")
	assert_eq(GameState.player_health, 100, "Player health should be 100 at run start")
	assert_eq(GameState.enemies_killed, 0, "Kill count should start at 0")


func test_game_state_damage() -> void:
	GameState.start_run()
	GameState.damage_player(30)
	assert_eq(GameState.player_health, 70, "Health should decrease after damage")


func test_game_state_death() -> void:
	GameState.start_run()
	GameState.damage_player(100)
	assert_eq(GameState.player_health, 0, "Health should not go below 0")
	assert_false(GameState.run_active, "Run should end when health reaches 0")


func test_game_state_kills() -> void:
	GameState.start_run()
	GameState.record_kill()
	GameState.record_kill()
	assert_eq(GameState.enemies_killed, 2, "Kill count should increment")
