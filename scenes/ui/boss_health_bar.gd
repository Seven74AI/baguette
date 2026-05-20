extends Control
## Boss health bar UI — displays boss name, HP bar, and phase indicator.
## Designed to be shown during boss encounters, hidden otherwise.
## Listens for boss_health_changed and phase_changed signals.

const COLOR_CREAM := Color(1.0, 0.97, 0.88, 1.0)
const COLOR_GOLD := Color(0.85, 0.65, 0.13, 1.0)
const COLOR_RED := Color(0.8, 0.2, 0.1, 1.0)
const COLOR_DARK := Color(0.17, 0.09, 0.05, 1.0)
const COLOR_PURPLE := Color(0.6, 0.2, 0.8, 1.0)

@onready var _name_label: Label = $BossName
@onready var _hp_bar: ProgressBar = $HPBar
@onready var _phase_label: Label = $PhaseIndicator
@onready var _hp_text: Label = $HPText

var _boss: Node = null
var _visible_timer: float = 0.0
var _auto_hide: bool = true


func _ready() -> void:
	visible = false
	_apply_theme()


func _apply_theme() -> void:
	# Name label style
	if _name_label:
		_name_label.add_theme_color_override("font_color", COLOR_GOLD)
		_name_label.add_theme_font_size_override("font_size", 28)

	# HP bar style
	if _hp_bar:
		var stylebox := StyleBoxFlat.new()
		stylebox.bg_color = COLOR_GOLD
		stylebox.border_width_left = 2
		stylebox.border_width_right = 2
		stylebox.border_width_top = 2
		stylebox.border_width_bottom = 2
		stylebox.border_color = COLOR_CREAM
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_right = 4
		stylebox.corner_radius_bottom_left = 4
		_hp_bar.add_theme_stylebox_override("fill", stylebox)

		var bg_style := StyleBoxFlat.new()
		bg_style.bg_color = COLOR_DARK
		_hp_bar.add_theme_stylebox_override("background", bg_style)

	# Phase label style
	if _phase_label:
		_phase_label.add_theme_color_override("font_color", COLOR_PURPLE)
		_phase_label.add_theme_font_size_override("font_size", 22)

	# HP text style
	if _hp_text:
		_hp_text.add_theme_color_override("font_color", COLOR_CREAM)
		_hp_text.add_theme_font_size_override("font_size", 18)


func _process(delta: float) -> void:
	# Auto-hide after inactivity
	if _auto_hide:
		_visible_timer += delta
		if _visible_timer > 10.0:
			visible = false


## Show the boss health bar for a specific boss.
## Connects to the boss's signals to track HP and phase changes.
func show_for_boss(boss: Node, boss_name: String) -> void:
	if _boss:
		_disconnect_boss()

	_boss = boss
	_name_label.text = boss_name

	# Connect to boss signals
	if _boss.has_signal("boss_health_changed"):
		if not _boss.boss_health_changed.is_connected(_on_boss_health):
			_boss.boss_health_changed.connect(_on_boss_health)

	if _boss.has_signal("phase_changed"):
		if not _boss.phase_changed.is_connected(_on_phase_changed):
			_boss.phase_changed.connect(_on_phase_changed)

	# Initialize with current values
	var max_hp := _boss.get_max_health()
	var current_hp := _boss.get_current_health()
	_on_boss_health(current_hp, max_hp)

	var phase := _boss.get("current_phase")
	if phase != null:
		_on_phase_changed(phase)

	visible = true
	_visible_timer = 0.0


func _on_boss_health(current: int, max_hp: int) -> void:
	if _hp_bar:
		_hp_bar.max_value = max_hp
		_hp_bar.value = current

	if _hp_text:
		_hp_text.text = str(current) + " / " + str(max_hp)

	# Color the bar based on health ratio
	var ratio := float(current) / float(max_hp)
	if _hp_bar:
		var stylebox: StyleBoxFlat = _hp_bar.get_theme_stylebox("fill")
		if stylebox:
			if ratio > 0.5:
				stylebox.bg_color = COLOR_GOLD
			elif ratio > 0.25:
				stylebox.bg_color = Color.ORANGE
			else:
				stylebox.bg_color = COLOR_RED

	_visible_timer = 0.0


func _on_phase_changed(new_phase: int) -> void:
	if _phase_label:
		_phase_label.text = "Phase " + str(new_phase)
	_visible_timer = 0.0


func _disconnect_boss() -> void:
	if _boss and is_instance_valid(_boss):
		if _boss.has_signal("boss_health_changed") and _boss.boss_health_changed.is_connected(_on_boss_health):
			_boss.boss_health_changed.disconnect(_on_boss_health)
		if _boss.has_signal("phase_changed") and _boss.phase_changed.is_connected(_on_phase_changed):
			_boss.phase_changed.disconnect(_on_phase_changed)
	_boss = null


func hide_bar() -> void:
	_disconnect_boss()
	visible = false
