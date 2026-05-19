extends Control
## PHASE 5.1c: Stylized bakery-themed HUD — unified palette, weapon icons, kill streak.
## Crosshair, health bar, ammo counter, dash indicator, kill counter, weapon display, combo.
## Attached to the player's Camera3D so it renders in the viewport.

@onready var _ammo_label: Label = $AmmoPanel/AmmoLabel
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _kill_label: Label = $KillPanel/KillLabel
@onready var _combo_label: Label = _resolve_combo_label()
@onready var _dash_indicator: Label = $DashPanel/DashLabel
@onready var _crosshair_top: Label = $Crosshair/Top
@onready var _crosshair_bot: Label = $Crosshair/Bottom
@onready var _crosshair_left: Label = $Crosshair/Left
@onready var _crosshair_right: Label = $Crosshair/Right
@onready var _crosshair_center: Label = $Crosshair/Center
@onready var _weapon_display: Control = _resolve_weapon_display()
@onready var _weapon_name_label: Label = _resolve_weapon_label()

var _player: CharacterBody3D = null
var _weapon: Node = null


func _resolve_combo_label() -> Label:
	var lbl := get_node_or_null("KillPanel/ComboLabel") as Label
	if lbl:
		return lbl
	return Label.new()


func _resolve_weapon_display() -> Control:
	var wd := get_node_or_null("WeaponSlot") as Control
	if wd:
		return wd
	return Control.new()


func _resolve_weapon_label() -> Label:
	if _weapon_display and is_instance_valid(_weapon_display):
		var lbl := _weapon_display.get_node_or_null("WeaponLabel") as Label
		if lbl:
			return lbl
	return Label.new()


func _ready() -> void:
	var camera := get_parent()
	if camera and camera.get_parent() is CharacterBody3D:
		_player = camera.get_parent()

	_refresh_weapon_ref()
	_apply_bakery_theme()


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
					stylebox.bg_color = Palette.GOLDEN_BROWN           # Golden - healthy
				elif ratio > 0.25:
					stylebox.bg_color = Color(1.0, 0.55, 0.0, 1.0)     # Orange - warning
				else:
					stylebox.bg_color = Color(0.8, 0.2, 0.1, 1.0)      # Red - danger

	# Update ammo
	_refresh_weapon_ref()
	if _weapon and _weapon.has_method("get_ammo_count") and _weapon.has_method("get_max_ammo"):
		var current: int = _weapon.get_ammo_count()
		var maximum: int = _weapon.get_max_ammo()
		_ammo_label.text = str(current) + " / " + str(maximum)
		if current == 0:
			_ammo_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.1, 1.0))
		else:
			_ammo_label.add_theme_color_override("font_color", Palette.GOLDEN_BROWN)
	elif _weapon:
		_ammo_label.text = "-- / --"

	# Update kills
	_kill_label.text = "BAGUETTES: " + str(GameState.enemies_killed)

	# Update combo streak
	_update_combo()

	# Update weapon display
	_update_weapon_display()

	# Update dash cooldown indicator
	if _player and _player.has_method("is_dashing"):
		var is_dashing: bool = _player.is_dashing()
		if is_dashing:
			_dash_indicator.text = ">>> DASH >>>"
			_dash_indicator.add_theme_color_override("font_color", Palette.CREAM)
		else:
			var cooldown: float = float(_player.get("_dash_cooldown_timer"))
			if cooldown <= 0.0:
				_dash_indicator.text = "[CTRL] DASH"
				_dash_indicator.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2, 1.0))
			else:
				_dash_indicator.text = "DASH " + str(ceil(cooldown * 10) / 10.0) + "s"
				_dash_indicator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))


func _update_combo() -> void:
	if not _combo_label or not is_instance_valid(_combo_label):
		return
	var combo_tracker := _find_combo_tracker()
	if combo_tracker and combo_tracker.is_combo_active():
		var count: int = combo_tracker.get_combo_count()
		if count >= 2:
			_combo_label.text = "x" + str(count) + " COMBO"
			_combo_label.add_theme_color_override("font_color", Palette.GOLDEN_BROWN)
			_combo_label.visible = true
			var scale_pulse := 1.0 + (count * 0.05)
			_combo_label.scale = Vector2(scale_pulse, scale_pulse)
		else:
			_combo_label.visible = false
	else:
		_combo_label.visible = false


func _find_combo_tracker() -> Node:
	if _player and _player.has_node("ComboTracker"):
		return _player.get_node("ComboTracker")
	return null


func _update_weapon_display() -> void:
	if not _weapon_display or not is_instance_valid(_weapon_display):
		return
	if _weapon_name_label and is_instance_valid(_weapon_name_label) and _weapon:
		var weapon_name = _weapon.get("weapon_name") if _weapon.get("weapon_name") != null else ""
		if weapon_name != "":
			_weapon_name_label.text = weapon_name
		elif _weapon.has_method("get_class"):
			_weapon_name_label.text = _weapon.name
		_weapon_name_label.add_theme_color_override("font_color", Palette.GOLDEN_BROWN)
		_weapon_display.visible = true
	else:
		if _weapon_display:
			_weapon_display.visible = false


func _refresh_weapon_ref() -> void:
	if not _weapon and _player:
		var mount := _player.get_node_or_null("Camera3D/WeaponMount")
		if mount and mount.get_child_count() > 0:
			_weapon = mount.get_child(0)


func _apply_bakery_theme() -> void:
	# Health bar styling — baguette-shaped (highly rounded rod)
	_health_bar.add_theme_color_override("font_color", Palette.CREAM)
	_health_bar.add_theme_font_size_override("font_size", 12)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Palette.GOLDEN_BROWN
	var baguette_radius := 10
	fill_style.corner_radius_top_left = baguette_radius
	fill_style.corner_radius_top_right = baguette_radius
	fill_style.corner_radius_bottom_left = baguette_radius
	fill_style.corner_radius_bottom_right = baguette_radius
	_health_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Palette.CRUST
	bg_style.corner_radius_top_left = baguette_radius
	bg_style.corner_radius_top_right = baguette_radius
	bg_style.corner_radius_bottom_left = baguette_radius
	bg_style.corner_radius_bottom_right = baguette_radius
	bg_style.border_width_left = 1
	bg_style.border_width_right = 1
	bg_style.border_width_top = 1
	bg_style.border_width_bottom = 1
	bg_style.border_color = Palette.GOLDEN_BROWN
	_health_bar.add_theme_stylebox_override("background", bg_style)

	# Ammo panel styling
	var ammo_style := StyleBoxFlat.new()
	ammo_style.bg_color = Color(Palette.CRUST.r, Palette.CRUST.g, Palette.CRUST.b, 0.7)
	ammo_style.corner_radius_top_left = 6
	ammo_style.corner_radius_top_right = 6
	ammo_style.corner_radius_bottom_left = 6
	ammo_style.corner_radius_bottom_right = 6
	ammo_style.border_width_left = 1
	ammo_style.border_width_right = 1
	ammo_style.border_width_top = 1
	ammo_style.border_width_bottom = 1
	ammo_style.border_color = Palette.GOLDEN_BROWN
	_ammo_label.get_parent().add_theme_stylebox_override("panel", ammo_style)

	# Kill panel styling
	var kill_style := StyleBoxFlat.new()
	kill_style.bg_color = Color(Palette.CRUST.r, Palette.CRUST.g, Palette.CRUST.b, 0.6)
	kill_style.corner_radius_top_left = 4
	kill_style.corner_radius_top_right = 4
	kill_style.corner_radius_bottom_left = 4
	kill_style.corner_radius_bottom_right = 4
	kill_style.border_width_left = 1
	kill_style.border_width_right = 1
	kill_style.border_width_top = 1
	kill_style.border_width_bottom = 1
	kill_style.border_color = Palette.CRUST
	_kill_label.get_parent().add_theme_stylebox_override("panel", kill_style)

	# Combo label styling
	if _combo_label and is_instance_valid(_combo_label) and _combo_label.get_parent() == $KillPanel:
		_combo_label.add_theme_font_size_override("font_size", 20)
		_combo_label.add_theme_color_override("font_color", Palette.GOLDEN_BROWN)

	# Dash panel styling
	var dash_style := StyleBoxFlat.new()
	dash_style.bg_color = Color(Palette.CRUST.r, Palette.CRUST.g, Palette.CRUST.b, 0.6)
	dash_style.corner_radius_top_left = 4
	dash_style.corner_radius_top_right = 4
	dash_style.corner_radius_bottom_left = 4
	dash_style.corner_radius_bottom_right = 4
	_dash_indicator.get_parent().add_theme_stylebox_override("panel", dash_style)

	# Weapon display styling
	if _weapon_display and is_instance_valid(_weapon_display) and _weapon_display is Panel:
		var wpn_style := StyleBoxFlat.new()
		wpn_style.bg_color = Color(Palette.CRUST.r, Palette.CRUST.g, Palette.CRUST.b, 0.6)
		wpn_style.corner_radius_top_left = 4
		wpn_style.corner_radius_top_right = 4
		wpn_style.corner_radius_bottom_left = 4
		wpn_style.corner_radius_bottom_right = 4
		wpn_style.border_width_left = 1
		wpn_style.border_width_right = 1
		wpn_style.border_width_top = 1
		wpn_style.border_width_bottom = 1
		wpn_style.border_color = Palette.CRUST
		_weapon_display.add_theme_stylebox_override("panel", wpn_style)
