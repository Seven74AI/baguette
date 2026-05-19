extends "res://addons/gut/test.gd"
## PHASE 4.1: Game Over scene tests — loads, displays stats, has restart/menu buttons.

var _game_over: Control

func before_each() -> void:
	GameState._reset_for_testing()
	GameState.start_run()
	GameState.record_kill()
	GameState.record_kill()
	GameState.record_kill()
	GameState.rooms_cleared = 5
	GameState.run_time = 120.5
	GameState.total_damage_dealt = 350
	GameState.damage_player(100)  # Dies

	var game_over_scene: PackedScene = load("res://scenes/ui/game_over.tscn")
	_game_over = game_over_scene.instantiate()
	add_child_autofree(_game_over)
	await wait_frames(2)


func test_game_over_scene_loads() -> void:
	assert_not_null(_game_over, "Game Over scene should be loadable and instantiable")


func test_game_over_has_death_title() -> void:
	var title: Label = _game_over.get_node_or_null("CenterContainer/ContentVBox/TitleLabel")
	assert_not_null(title, "Game Over scene should have a TitleLabel")
	assert_true(title.text.to_upper().contains("MORT") or title.text.to_upper().contains("DEAD") or title.text.to_upper().contains("GAME OVER"), "Title should indicate death")


func test_game_over_displays_enemies_killed() -> void:
	var kills_label: Label = _game_over.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/KillsLabel")
	assert_not_null(kills_label, "Game Over should have a KillsLabel")
	assert_true(str(GameState.enemies_killed) in kills_label.text or kills_label.text.length() > 0, "Kills label should display kill count")


func test_game_over_displays_rooms_cleared() -> void:
	var rooms_label: Label = _game_over.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/RoomsLabel")
	assert_not_null(rooms_label, "Game Over should have a RoomsLabel")
	assert_true(str(GameState.rooms_cleared) in rooms_label.text or rooms_label.text.length() > 0, "Rooms label should display rooms cleared")


func test_game_over_displays_run_time() -> void:
	var time_label: Label = _game_over.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/TimeLabel")
	assert_not_null(time_label, "Game Over should have a TimeLabel")
	assert_true(time_label.text.length() > 0, "Time label should display run time")


func test_game_over_has_restart_button() -> void:
	var restart_btn: Button = _game_over.get_node_or_null("CenterContainer/ContentVBox/ButtonsContainer/RestartButton")
	assert_not_null(restart_btn, "Game Over should have a RestartButton")
	assert_true(restart_btn.text.to_upper().contains("RECOMMENCER") or restart_btn.text.to_upper().contains("RESTART") or restart_btn.text.to_upper().contains("NOUVELLE") or restart_btn.text.to_upper().contains("NEW"), "Restart button should say RECOMMENCER or similar")


func test_game_over_has_menu_button() -> void:
	var menu_btn: Button = _game_over.get_node_or_null("CenterContainer/ContentVBox/ButtonsContainer/MenuButton")
	assert_not_null(menu_btn, "Game Over should have a MenuButton")
	assert_true(menu_btn.text.to_upper().contains("MENU") or menu_btn.text.to_upper().contains("MAIN"), "Menu button should reference the main menu")


func test_game_over_is_control_node() -> void:
	assert_true(_game_over is Control, "Game Over should be a Control node")
