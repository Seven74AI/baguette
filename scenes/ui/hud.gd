extends Control
## PHASE 3: Stylized bakery-themed HUD.
## Crosshair, health bar, ammo counter, dash indicator, kill counter.
## Attached to the player's Camera3D so it renders in the viewport.

# Bakery color palette
const COLOR_CREAM := Color(1.0, 0.97, 0.88, 1.0)       # #FFF8DC
const COLOR_GOLD := Color(0.85, 0.65, 0.13, 1.0)         # #DAA520
const COLOR_BROWN := Color(0.55, 0.27, 0.07, 1.0)        # #8B4513
const COLOR_DARK := Color(0.17, 0.09, 0.05, 1.0)         # #2C1810
const COLOR_RED := Color(0.8, 0.2, 0.1, 1.0)
const COLOR_GREEN := Color(0.2, 0.7, 0.2, 1.0)

@onready var _ammo_label: Label = $AmmoPanel/AmmoLabel
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _kill_label: Label = $KillPanel/KillLabel
@onready var _dash_indicator: Label = $DashPanel/DashLabel
@onready var _crosshair_top: Label = $Crosshair/Top
@onready var _crosshair_bot: Label = $Crosshair/Bottom
@onready var _crosshair_left: Label = $Crosshair/Left
@onready var _crosshair_right: Label = $Crosshair/Right
@onready var _crosshair_center: Label = $Crosshair/Center
## Phase 5.2b: Mutator display
@onready var _mutator_panel: Panel = $MutatorPanel
@onready var _mutator_label: Label = $MutatorPanel/MutatorLabel

var _player: CharacterBody3D = null
var _weapon: Node = null


func _ready() -> void:
	var camera := get_parent()
	if camera and camera.get_parent() is CharacterBody3D:
		_player = camera.get_parent()
	
	_refresh_weapon_ref()
	_apply_bakery_theme()
	
	# Phase 5.2b: Listen for floor mutator changes
	if not GameState.floor_mutator_changed.is_connected(_on_floor_mutator_changed):
		GameState.floor_mutator_changed.connect(_on_floor_mutator_changed)


func _process(_delta: float) -> void:
	# Update health
	if _player and _player.get("health_component"):
		var hc = _player.health_component
		if hc:
			_health_bar.max_value = hc.max_health
			_health_bar.value = hc.current_health
			# Color health bar based on health ratio
			var ratio: float = float(hc.current_health) / float(hc.max_health)
			var stylebox: StyleBoxFlat = _health_bar.get_theme_stylebox("fill")
			if stylebox:
				if ratio > 0.5:
					stylebox.bg_color = Color(0.85, 0.65, 0.13, 1.0)  # Gold - healthy
				elif ratio > 0.25:
					stylebox.bg_color = Color(1.0, 0.55, 0.0, 1.0)     # Orange - warning
				else:
					stylebox.bg_color = COLOR_RED                         # Red - danger
	
	# Update ammo
	_refresh_weapon_ref()
	if _weapon and _weapon.has_method("get_ammo_count") and _weapon.has_method("get_max_ammo"):
		var current: int = _weapon.get_ammo_count()
		var maximum: int = _weapon.get_max_ammo()
		_ammo_label.text = str(current) + " / " + str(maximum)
		if current == 0:
			_ammo_label.add_theme_color_override("font_color", COLOR_RED)
		else:
			_ammo_label.add_theme_color_override("font_color", COLOR_GOLD)
	elif _weapon:
		_ammo_label.text = "-- / --"
	
	# Update kills
	_kill_label.text = "BAGUETTES: " + str(GameState.enemies_killed)
	
	# Update dash cooldown indicator
	if _player and _player.has_method("is_dashing"):
		var is_dashing: bool = _player.is_dashing()
		if is_dashing:
			_dash_indicator.text = ">>> DASH >>>"
			_dash_indicator.add_theme_color_override("font_color", COLOR_CREAM)
		else:
			var cooldown: float = float(_player.get("_dash_cooldown_timer"))
			if cooldown <= 0.0:
				_dash_indicator.text = "[CTRL] DASH"
				_dash_indicator.add_theme_color_override("font_color", COLOR_GREEN)
			else:
				_dash_indicator.text = "DASH " + str(ceil(cooldown * 10) / 10.0) + "s"
				_dash_indicator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))


func _refresh_weapon_ref() -> void:
	if not _weapon and _player:
		var mount := _player.get_node_or_null("Camera3D/WeaponMount")
		if mount and mount.get_child_count() > 0:
			_weapon = mount.get_child(0)


func _apply_bakery_theme() -> void:
	# Health bar styling
	_health_bar.add_theme_color_override("font_color", COLOR_CREAM)
	_health_bar.add_theme_font_size_override("font_size", 12)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = COLOR_GOLD
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	_health_bar.add_theme_stylebox_override("fill", fill_style)
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = COLOR_DARK
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = COLOR_GOLD
	_health_bar.add_theme_stylebox_override("background", bg_style)
	
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
	ammo_style.border_color = COLOR_BROWN
	_ammo_label.get_parent().add_theme_stylebox_override("panel", ammo_style)
	
	# Kill panel styling
	var kill_style := StyleBoxFlat.new()
	kill_style.bg_color = Color(COLOR_DARK.r, COLOR_DARK.g, COLOR_DARK.b, 0.6)
	kill_style.corner_radius_top_left = 4
	kill_style.corner_radius_top_right = 4
	kill_style.corner_radius_bottom_left = 4
	kill_style.corner_radius_bottom_right = 4
	kill_style.border_width_left = 1
	kill_style.border_width_right = 1
	kill_style.border_width_top = 1
	kill_style.border_width_bottom = 1
	kill_style.border_color = COLOR_BROWN
	_kill_label.get_parent().add_theme_stylebox_override("panel", kill_style)
	
	# Dash panel styling
	var dash_style := StyleBoxFlat.new()
	dash_style.bg_color = Color(COLOR_DARK.r, COLOR_DARK.g, COLOR_DARK.b, 0.6)
	dash_style.corner_radius_top_left = 4
	dash_style.corner_radius_top_right = 4
	dash_style.corner_radius_bottom_left = 4
	dash_style.corner_radius_bottom_right = 4
	_dash_indicator.get_parent().add_theme_stylebox_override("panel", dash_style)
# ── Floor Mutator Display (Phase 5.2b) ──────────────────────────

var _mutator_timer: float = 0.0
var _mutator_display_active: bool = false


func _on_floor_mutator_changed(mutator: Dictionary) -> void:
	# Show the mutator panel with name, icon, and description
	if _mutator_panel and _mutator_label:
		var icon: String = mutator.get("icon", "")
		var name: String = mutator.get("name", "???")
		var desc: String = mutator.get("description", "")
		_mutator_label.text = icon + " " + name + " — " + desc
		_mutator_panel.visible = true
		_mutator_panel.modulate.a = 1.0
		_mutator_timer = 3.0
		_mutator_display_active = true


## Called by the test harness to manually show mutator display.
func _show_mutator_display(p_text: String, p_duration: float = 3.0) -> void:
	if _mutator_panel and _mutator_label:
		_mutator_label.text = p_text
		_mutator_panel.visible = true
		_mutator_panel.modulate.a = 1.0
		_mutator_timer = p_duration
		_mutator_display_active = true
