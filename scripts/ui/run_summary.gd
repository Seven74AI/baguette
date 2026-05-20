extends Control
## PHASE 4.11: Unified Run Summary — shared by Game Over and Victory screens.
## Displays kills, rooms cleared, time survived, weapons used, total damage dealt.
## Supports two variants via the `variant` property: "game_over" (dark/red) or "victory" (golden).

## Variant: "game_over" or "victory" — determines title text and color theme.
@export var variant: String = "game_over":
	set(v):
		variant = v
		if is_node_ready():
			_configure()


@onready var _title_label: Label = $CenterContainer/ContentVBox/TitleLabel
@onready var _kills_label: Label = $CenterContainer/ContentVBox/StatsContainer/KillsLabel
@onready var _rooms_label: Label = $CenterContainer/ContentVBox/StatsContainer/RoomsLabel
@onready var _time_label: Label = $CenterContainer/ContentVBox/StatsContainer/TimeLabel
@onready var _damage_label: Label = $CenterContainer/ContentVBox/StatsContainer/DamageLabel
@onready var _weapons_label: Label = _resolve_optional_label("WeaponsLabel")
@onready var _new_game_button: Button = _resolve_new_game_button()
@onready var _menu_button: Button = $CenterContainer/ContentVBox/ButtonsContainer/MenuButton
@onready var _background: ColorRect = $Background


## Resolve the new game / restart button — supports both naming conventions.
func _resolve_new_game_button() -> Button:
	var btn := get_node_or_null("CenterContainer/ContentVBox/ButtonsContainer/NewGameButton") as Button
	if btn:
		return btn
	btn = get_node_or_null("CenterContainer/ContentVBox/ButtonsContainer/RestartButton") as Button
	if btn:
		return btn
	# Fallback: create one dynamically if scene is missing it
	push_warning("RunSummary: No NewGameButton or RestartButton found in ButtonsContainer")
	return Button.new()


## Resolve an optional stats label — returns null if not found in scene.
func _resolve_optional_label(label_name: String) -> Label:
	return get_node_or_null("CenterContainer/ContentVBox/StatsContainer/" + label_name) as Label


func _ready() -> void:
	_display_stats()
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_configure()


func _configure() -> void:
	match variant:
		"game_over":
			_apply_game_over_theme()
		"victory":
			_apply_victory_theme()
		_:
			_apply_game_over_theme()


func _display_stats() -> void:
	_kills_label.text = "BAGUETTES: " + str(GameState.enemies_killed)
	_rooms_label.text = "SALLES: " + str(GameState.rooms_cleared)

	var time_total: int = int(GameState.run_time)
	var minutes: int = time_total / 60
	var seconds: int = time_total % 60
	_time_label.text = "TEMPS: " + str(minutes) + "m " + str(seconds) + "s"

	_damage_label.text = "DÉGÂTS: " + str(GameState.total_damage_dealt)

	# PHASE 5.2c: Display reputation earned this run
	if _weapons_label and GameState.reputation:
		var run_rep: int = GameState.reputation.get_run_reputation()
		if run_rep > 0:
			_weapons_label.text = "RÉPUTATION: " + str(run_rep) + " RP"
			_weapons_label.visible = true
		else:
			_weapons_label.visible = false


func _apply_game_over_theme() -> void:
	# Dark red death theme — "VOUS ÊTES MORT"
	_background.color = Color(0.12, 0.03, 0.03, 1.0)

	_title_label.text = "VOUS ÊTES MORT"
	_title_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.1, 1.0))
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_apply_common_stats_style()
	_apply_button_style(Color(0.55, 0.27, 0.07, 0.9), Color(0.85, 0.65, 0.13, 1.0))

	_new_game_button.text = "NOUVELLE PARTIE"


func _apply_victory_theme() -> void:
	# Golden victory theme — "VICTOIRE !"
	_background.color = Color(0.1, 0.08, 0.03, 1.0)

	_title_label.text = "VICTOIRE !"
	_title_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.13, 1.0))
	_title_label.add_theme_font_size_override("font_size", 48)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_apply_common_stats_style()
	_apply_button_style(Color(0.85, 0.65, 0.13, 0.3), Color(0.85, 0.65, 0.13, 1.0))

	_new_game_button.text = "NOUVELLE PARTIE"


func _apply_common_stats_style() -> void:
	var stat_color := Color(1.0, 0.97, 0.88, 0.9)
	var stat_font_size := 22

	var all_labels: Array[Label] = [_kills_label, _rooms_label, _time_label, _damage_label]
	if _weapons_label:
		all_labels.append(_weapons_label)

	for label: Label in all_labels:
		label.add_theme_color_override("font_color", stat_color)
		label.add_theme_font_size_override("font_size", stat_font_size)


func _apply_button_style(bg_color: Color, border_color: Color) -> void:
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = bg_color
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = border_color

	_new_game_button.add_theme_stylebox_override("normal", btn_style)
	_menu_button.add_theme_stylebox_override("normal", btn_style)

	_new_game_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	_menu_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))

	_new_game_button.add_theme_font_size_override("font_size", 20)
	_menu_button.add_theme_font_size_override("font_size", 20)


func _on_new_game_pressed() -> void:
	GameState.start_run()
	get_tree().change_scene_to_file("res://scenes/levels/proto/bakery_test.tscn")


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
