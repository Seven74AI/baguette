extends Control
## PHASE 5.1c: Main Menu scene — startup screen with title, start/quit buttons.
## Bakery-themed dark purple-sky background with warm cream/golden text.
## Supports oven door transition via MenuTransitions node.

@onready var _start_button: Button = $CenterContainer/ContentVBox/VBox/StartButton
@onready var _quit_button: Button = $CenterContainer/ContentVBox/VBox/QuitButton
@onready var _title_label: Label = $CenterContainer/ContentVBox/TitleLabel
@onready var _version_label: Label = $CenterContainer/ContentVBox/VersionLabel
@onready var _transitions: Node = _resolve_transitions()


func _resolve_transitions() -> Node:
	var menu_transitions := get_node_or_null("MenuTransitions")
	if menu_transitions:
		return menu_transitions
	# Create transitions node automatically
	var ts := load("res://scripts/ui/menu_transitions.gd")
	if ts:
		var mt: Node = ts.new()
		mt.name = "MenuTransitions"
		add_child(mt)
		return mt
	return Node.new()


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_apply_bakery_theme()


func _on_start_pressed() -> void:
	# Play oven door transition if available, then start game
	if _transitions and _transitions.has_method("play_oven_door_open"):
		_transitions.play_oven_door_open()
		await _transitions.transition_completed
	GameState.start_run()
	get_tree().change_scene_to_file("res://scenes/levels/proto/bakery_test.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _apply_bakery_theme() -> void:
	# Title styling — large golden text
	_title_label.add_theme_color_override("font_color", Palette.GOLDEN_BROWN)
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Version label — small cream text
	_version_label.add_theme_color_override("font_color", Color(Palette.CREAM.r, Palette.CREAM.g, Palette.CREAM.b, 0.5))
	_version_label.add_theme_font_size_override("font_size", 12)
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Button styling — rounded with golden border, dark brown background
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(Palette.CRUST.r, Palette.CRUST.g, Palette.CRUST.b, 0.9)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Palette.GOLDEN_BROWN

	_start_button.add_theme_stylebox_override("normal", btn_style)
	_quit_button.add_theme_stylebox_override("normal", btn_style)

	# Cream text on buttons
	_start_button.add_theme_color_override("font_color", Palette.CREAM)
	_quit_button.add_theme_color_override("font_color", Palette.CREAM)
	_start_button.add_theme_font_size_override("font_size", 24)
	_quit_button.add_theme_font_size_override("font_size", 24)
