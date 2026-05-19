extends Control
## PHASE 4.1: Victory screen — displayed when player wins (Gordon Bleu defeated).
## Shows victory message, run stats, new game/menu buttons.

@onready var _title_label: Label = $CenterContainer/ContentVBox/TitleLabel
@onready var _kills_label: Label = $CenterContainer/ContentVBox/StatsContainer/KillsLabel
@onready var _rooms_label: Label = $CenterContainer/ContentVBox/StatsContainer/RoomsLabel
@onready var _time_label: Label = $CenterContainer/ContentVBox/StatsContainer/TimeLabel
@onready var _damage_label: Label = $CenterContainer/ContentVBox/StatsContainer/DamageLabel
@onready var _new_game_button: Button = $CenterContainer/ContentVBox/ButtonsContainer/NewGameButton
@onready var _menu_button: Button = $CenterContainer/ContentVBox/ButtonsContainer/MenuButton


func _ready() -> void:
	_display_stats()
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_apply_bakery_theme()


func _display_stats() -> void:
	_kills_label.text = "BAGUETTES: " + str(GameState.enemies_killed)
	_rooms_label.text = "SALLES: " + str(GameState.rooms_cleared)

	var time_total: int = int(GameState.run_time)
	var minutes: int = time_total / 60
	var seconds: int = time_total % 60
	_time_label.text = "TEMPS: " + str(minutes) + "m " + str(seconds) + "s"

	_damage_label.text = "DÉGÂTS: " + str(GameState.total_damage_dealt)


func _on_new_game_pressed() -> void:
	GameState.start_run()
	get_tree().change_scene_to_file("res://scenes/levels/proto/bakery_test.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _apply_bakery_theme() -> void:
	# Golden victory title
	_title_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.13, 1.0))
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Stats labels — cream color
	var stat_color := Color(1.0, 0.97, 0.88, 0.9)
	_kills_label.add_theme_color_override("font_color", stat_color)
	_kills_label.add_theme_font_size_override("font_size", 22)
	_rooms_label.add_theme_color_override("font_color", stat_color)
	_rooms_label.add_theme_font_size_override("font_size", 22)
	_time_label.add_theme_color_override("font_color", stat_color)
	_time_label.add_theme_font_size_override("font_size", 22)
	_damage_label.add_theme_color_override("font_color", stat_color)
	_damage_label.add_theme_font_size_override("font_size", 22)

	# Button styling
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.85, 0.65, 0.13, 0.3)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.85, 0.65, 0.13, 1.0)

	_new_game_button.add_theme_stylebox_override("normal", btn_style)
	_menu_button.add_theme_stylebox_override("normal", btn_style)
	_new_game_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	_menu_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	_new_game_button.add_theme_font_size_override("font_size", 20)
	_menu_button.add_theme_font_size_override("font_size", 20)
