extends Control
## Inventory HUD overlay — displays shared ammo pool (bottom-right) and active buffs (top-left).
## Designed to be added as a child of the existing HUD scene or Camera3D.
## Listens to GameState signals for real-time updates.

const COLOR_GOLD := Color(0.85, 0.65, 0.13, 1.0)
const COLOR_DARK := Color(0.17, 0.09, 0.05, 1.0)
const COLOR_BLUE := Color(0.3, 0.5, 0.9, 1.0)
const COLOR_RED := Color(0.8, 0.2, 0.1, 1.0)

var _ammo_display: PanelContainer
var _ammo_label: Label
var _buffs_panel: PanelContainer
var _buffs_container: VBoxContainer

var _buff_icon_chars: Dictionary = {
	"speed": "\u26A1",
	"damage": "\U0001F4A5",
}


func _ready() -> void:
	_create_ui()
	_apply_theme()
	_refresh_ammo()
	_refresh_buffs()
	# Connect to GameState signals
	if not GameState.ammo_changed.is_connected(_on_ammo_changed):
		GameState.ammo_changed.connect(_on_ammo_changed)
	if not GameState.buffs_changed.is_connected(_on_buffs_changed):
		GameState.buffs_changed.connect(_on_buffs_changed)


func _create_ui() -> void:
	# --- Ammo display (bottom-right) ---
	_ammo_display = PanelContainer.new()
	_ammo_display.name = "AmmoDisplay"
	_ammo_display.anchor_left = 1.0
	_ammo_display.anchor_right = 1.0
	_ammo_display.anchor_top = 1.0
	_ammo_display.anchor_bottom = 1.0
	_ammo_display.offset_left = -220
	_ammo_display.offset_top = -50
	_ammo_display.offset_right = -20
	_ammo_display.offset_bottom = -10
	add_child(_ammo_display)

	_ammo_label = Label.new()
	_ammo_label.name = "AmmoLabel"
	_ammo_label.text = "BAGUETTES: 0 / 30"
	_ammo_label.add_theme_font_size_override("font_size", 16)
	_ammo_display.add_child(_ammo_label)

	# --- Buffs panel (top-left) ---
	_buffs_panel = PanelContainer.new()
	_buffs_panel.name = "BuffsPanel"
	_buffs_panel.anchor_left = 0.0
	_buffs_panel.anchor_right = 0.0
	_buffs_panel.anchor_top = 0.0
	_buffs_panel.anchor_bottom = 0.0
	_buffs_panel.offset_left = 10
	_buffs_panel.offset_top = 10
	_buffs_panel.offset_right = 200
	_buffs_panel.offset_bottom = 120
	_buffs_panel.visible = false
	add_child(_buffs_panel)

	_buffs_container = VBoxContainer.new()
	_buffs_container.name = "VBoxContainer"
	_buffs_panel.add_child(_buffs_container)


func _apply_theme() -> void:
	# Ammo panel styling
	var ammo_style := StyleBoxFlat.new()
	ammo_style.bg_color = Color(COLOR_DARK.r, COLOR_DARK.g, COLOR_DARK.b, 0.7)
	ammo_style.corner_radius_top_left = 6
	ammo_style.corner_radius_top_right = 6
	ammo_style.corner_radius_bottom_left = 6
	ammo_style.corner_radius_bottom_right = 6
	ammo_style.border_width_left = 1
	ammo_style.border_width_right = 1
	ammo_style.border_width_top = 1
	ammo_style.border_width_bottom = 1
	ammo_style.border_color = COLOR_GOLD
	_ammo_display.add_theme_stylebox_override("panel", ammo_style)

	# Buffs panel styling
	var buff_style := StyleBoxFlat.new()
	buff_style.bg_color = Color(COLOR_DARK.r, COLOR_DARK.g, COLOR_DARK.b, 0.5)
	buff_style.corner_radius_top_left = 4
	buff_style.corner_radius_top_right = 4
	buff_style.corner_radius_bottom_left = 4
	buff_style.corner_radius_bottom_right = 4
	buff_style.border_width_left = 1
	buff_style.border_width_right = 1
	buff_style.border_width_top = 1
	buff_style.border_width_bottom = 1
	buff_style.border_color = COLOR_BLUE
	_buffs_panel.add_theme_stylebox_override("panel", buff_style)


func _on_ammo_changed(_current: int, _maximum: int) -> void:
	_refresh_ammo()


func _on_buffs_changed(_buffs: Array) -> void:
	_refresh_buffs()


func _refresh_ammo() -> void:
	var current: int = GameState.get_ammo()
	var maximum: int = GameState.get_max_ammo()
	_ammo_label.text = "BAGUETTES: " + str(current) + " / " + str(maximum)
	if current == 0:
		_ammo_label.add_theme_color_override("font_color", COLOR_RED)
	else:
		_ammo_label.add_theme_color_override("font_color", COLOR_GOLD)


func _refresh_buffs() -> void:
	var buffs: Array = GameState.get_active_buffs()
	# Clear existing labels
	for child in _buffs_container.get_children():
		child.queue_free()

	for bd in buffs:
		var label := Label.new()
		var icon: String = _buff_icon_chars.get(bd.buff_id, "\u25C6")
		label.text = icon + " " + bd.buff_id.capitalize() + " " + str(ceil(bd.duration * 10) / 10.0) + "s"
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", COLOR_BLUE)
		_buffs_container.add_child(label)

	_buffs_panel.visible = buffs.size() > 0
