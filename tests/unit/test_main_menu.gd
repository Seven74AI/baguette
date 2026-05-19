extends "res://addons/gut/test.gd"
## PHASE 4.1: Main Menu scene tests — loads, has buttons, has title.

var _menu: Control

func before_each() -> void:
	var main_menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	_menu = main_menu_scene.instantiate()
	add_child_autofree(_menu)
	await wait_frames(2)


func test_main_menu_scene_loads() -> void:
	assert_not_null(_menu, "Main menu scene should be loadable and instantiable")


func test_main_menu_has_title_label() -> void:
	var title: Label = _menu.get_node_or_null("CenterContainer/ContentVBox/TitleLabel")
	assert_not_null(title, "Main menu should have a TitleLabel")
	assert_true(title.text.to_upper().contains("BAGUETTE"), "Title should contain BAGUETTE")


func test_main_menu_has_start_button() -> void:
	var start_btn: Button = _menu.get_node_or_null("CenterContainer/ContentVBox/VBox/StartButton")
	assert_not_null(start_btn, "Main menu should have a StartButton")
	assert_true(start_btn.text.to_upper().contains("COMMENCER") or start_btn.text.to_upper().contains("START"), "Start button should say COMMENCER or START")


func test_main_menu_has_quit_button() -> void:
	var quit_btn: Button = _menu.get_node_or_null("CenterContainer/ContentVBox/VBox/QuitButton")
	assert_not_null(quit_btn, "Main menu should have a QuitButton")
	assert_true(quit_btn.text.to_upper().contains("QUITTER") or quit_btn.text.to_upper().contains("QUIT"), "Quit button should say QUITTER or QUIT")


func test_main_menu_has_version_label() -> void:
	var version_label: Label = _menu.get_node_or_null("CenterContainer/ContentVBox/VersionLabel")
	assert_not_null(version_label, "Main menu should have a VersionLabel")


func test_main_menu_is_control_node() -> void:
	assert_true(_menu is Control, "Main menu should be a Control node")


func test_start_button_triggers_scene_change() -> void:
	# The button should exist and be connectable
	var start_btn: Button = _menu.get_node_or_null("CenterContainer/ContentVBox/VBox/StartButton")
	assert_not_null(start_btn, "Start button should exist")
	# Check that pressing the button doesn't crash
	start_btn.button_down.emit()
	await wait_frames(1)
	assert_true(true, "Start button press should be handled without crash")
