extends Control
## PHASE 4.1: Main Menu scene — startup screen with title, start/quit buttons.
## Bakery-themed dark background with warm glow.

@onready var _start_button: Button = $CenterContainer/ContentVBox/VBox/StartButton
@onready var _quit_button: Button = $CenterContainer/ContentVBox/VBox/QuitButton
@onready var _title_label: Label = $CenterContainer/ContentVBox/TitleLabel
@onready var _version_label: Label = $CenterContainer/ContentVBox/VersionLabel


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_apply_bakery_theme()


func _on_start_pressed() -> void:
	GameState.start_run()
	get_tree().change_scene_to_file("res://scenes/levels/proto/bakery_test.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _apply_bakery_theme() -> void:
	# Title styling — large golden text
	_title_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.13, 1.0))  # Gold
	_title_label.add_theme_font_size_override("font_size", 64)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Version label — small cream text
	_version_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 0.5))  # Cream, dim
	_version_label.add_theme_font_size_override("font_size", 12)
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Button styling
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.55, 0.27, 0.07, 0.9)  # Brown
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.85, 0.65, 0.13, 1.0)  # Gold border

	_start_button.add_theme_stylebox_override("normal", btn_style)
	_quit_button.add_theme_stylebox_override("normal", btn_style)

	_start_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))  # Cream text
	_quit_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	_start_button.add_theme_font_size_override("font_size", 24)
	_quit_button.add_theme_font_size_override("font_size", 24)
