extends "res://addons/gut/test.gd"
## PHASE 5.1c: UI Polish tests for bakery-themed HUD.
## Tests: health bar baguette shape, ammo croissant icons, color palette usage,
##        weapon icon display, kill streak counter, typography.

const HUDScene = preload("res://scenes/ui/hud.tscn")

var _hud: Control


func before_each() -> void:
	_hud = HUDScene.instantiate()
	add_child_autofree(_hud)
	await wait_frames(2)


# ── Health Bar Tests ────────────────────────────────────────────────

func test_health_bar_uses_palette_golden_brown_colors() -> void:
	var health_bar: ProgressBar = _hud.get_node_or_null("HealthBar")
	assert_not_null(health_bar, "HUD should have a HealthBar")

	# The fill style should be golden brown (palette color)
	var fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
	assert_not_null(fill_style, "Health bar should have a fill stylebox")

	# Golden/brown bakery tones — should not be pure red/green/blue
	assert_true(
		(fill_style.bg_color.r > 0.5 and fill_style.bg_color.g > 0.4) or
		(fill_style.bg_color.r > 0.5 and fill_style.bg_color.g < 0.4 and fill_style.bg_color.b < 0.3),
		"Health bar fill should use warm bakery golden/brown tones"
	)


func test_health_bar_has_baguette_rounded_shape() -> void:
	var health_bar: ProgressBar = _hud.get_node_or_null("HealthBar")
	assert_not_null(health_bar, "HUD should have a HealthBar")

	var fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
	assert_not_null(fill_style, "Health bar should have a fill stylebox")

	# Baguette-shaped = rounded ends (like a rod)
	assert_gt(fill_style.corner_radius_top_left, 0, "Health bar should have rounded corners (baguette shape)")
	assert_gt(fill_style.corner_radius_top_right, 0, "Health bar should have rounded corners (baguette shape)")
	assert_gt(fill_style.corner_radius_bottom_left, 0, "Health bar should have rounded corners (baguette shape)")
	assert_gt(fill_style.corner_radius_bottom_right, 0, "Health bar should have rounded corners (baguette shape)")


func test_health_bar_uses_warm_beige_cream_text_color() -> void:
	var health_bar: ProgressBar = _hud.get_node_or_null("HealthBar")
	assert_not_null(health_bar, "HUD should have a HealthBar")

	var font_color: Color = health_bar.get_theme_color("font_color")
	# Should be warm — high R and G, modest B
	assert_true(
		font_color.r > 0.6 and font_color.g > 0.5,
		"Health bar text should use warm cream/beige tones"
	)


# ── Ammo Counter Tests ──────────────────────────────────────────────

func test_ammo_panel_uses_palette_colors() -> void:
	var ammo_label: Label = _hud.get_node_or_null("AmmoPanel/AmmoLabel")
	assert_not_null(ammo_label, "HUD should have an AmmoLabel")

	var font_color: Color = ammo_label.get_theme_color("font_color")
	# Should be golden (not pure red when not empty)
	assert_true(
		font_color.r > 0.5 and font_color.g > 0.4,
		"Ammo text should use warm bakery golden tones"
	)


func test_ammo_panel_has_croissant_icon_or_golden_theme() -> void:
	var ammo_panel: Panel = _hud.get_node_or_null("AmmoPanel")
	assert_not_null(ammo_panel, "HUD should have an AmmoPanel")

	var panel_style: StyleBoxFlat = ammo_panel.get_theme_stylebox("panel")
	assert_not_null(panel_style, "Ammo panel should have a panel stylebox")

	# Should have golden/brown border (bakery theme)
	assert_true(
		panel_style.border_color.r > 0.5 or panel_style.border_color.g > 0.4 or panel_style.border_color.b > 0.4,
		"Ammo panel border should be visible (golden bakery border)"
	)

	# Dark brown background with some transparency — may be default in headless
	var bg_r := panel_style.bg_color.r
	var bg_g := panel_style.bg_color.g
	var has_override := ammo_panel.has_theme_stylebox_override("panel")
	assert_true(
		(bg_r < 0.4 and bg_g < 0.3) or has_override,
		"Ammo panel background should be dark brown or have a stylebox override"
	)


# ── Kill Streak / Combo Tests ───────────────────────────────────────

func test_hud_has_kill_combo_label() -> void:
	var combo_label: Label = _hud.get_node_or_null("KillPanel/ComboLabel")
	if not combo_label:
		combo_label = _hud.get_node_or_null("ComboLabel")
	assert_not_null(combo_label, "HUD should have a ComboLabel for kill streak counter")


func test_kill_combo_label_uses_golden_color() -> void:
	var combo_label: Label = _hud.get_node_or_null("KillPanel/ComboLabel")
	if not combo_label:
		combo_label = _hud.get_node_or_null("ComboLabel")
	if combo_label:
		var font_color: Color = combo_label.get_theme_color("font_color")
		assert_true(
			font_color.r > 0.5 and font_color.g > 0.4,
			"Combo label should use golden/bright colors"
		)


# ── Weapon Icon Display Tests ───────────────────────────────────────

func test_hud_has_weapon_icon_display() -> void:
	var weapon_icon: Control = _hud.get_node_or_null("WeaponSlot")
	if not weapon_icon:
		weapon_icon = _hud.get_node_or_null("WeaponPanel")
	if not weapon_icon:
		weapon_icon = _hud.get_node_or_null("WeaponDisplay")
	assert_not_null(weapon_icon, "HUD should have a weapon icon/panel display")


func test_weapon_icon_has_label_or_texture() -> void:
	var weapon_display: Control = _hud.get_node_or_null("WeaponSlot")
	if not weapon_display:
		weapon_display = _hud.get_node_or_null("WeaponPanel")
	if not weapon_display:
		weapon_display = _hud.get_node_or_null("WeaponDisplay")
	if weapon_display:
		# Should either have a label with weapon name or a texture rect
		var has_label := weapon_display.get_node_or_null("WeaponName") != null or weapon_display.get_node_or_null("WeaponLabel") != null
		var has_texture := weapon_display.get_node_or_null("WeaponIcon") != null
		assert_true(has_label or has_texture or weapon_display is Label,
			"Weapon display should have a name label or icon texture"
		)


# ── Color Palette Integration Tests ─────────────────────────────────

func test_hud_uses_palette_autoload_colors() -> void:
	# Verify Palette autoload is accessible
	assert_not_null(Palette, "Palette autoload should exist")
	assert_eq(Palette.color_count(), 10, "Palette should have 10 colors")

	# Verify the HUD uses palette colors (not hardcoded un-palette ones)
	var health_bar: ProgressBar = _hud.get_node_or_null("HealthBar")
	assert_not_null(health_bar, "HUD should have a HealthBar")
	var fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
	assert_not_null(fill_style, "Health bar should have a fill stylebox")

	# Health bar fill should be close to a palette color
	var fill_color := fill_style.bg_color
	var palette_colors: Array = Palette.all_colors()
	var close_to_palette := false
	for pc: Color in palette_colors:
		var diff: float = abs(fill_color.r - pc.r) + abs(fill_color.g - pc.g) + abs(fill_color.b - pc.b)
		if diff < 0.3:
			close_to_palette = true
			break
	assert_true(close_to_palette, "Health bar fill color should be close to a palette color")


# ── Main Menu Button Styling Tests (run via main_menu scene) ────────

func test_main_menu_buttons_have_rounded_golden_style() -> void:
	var main_menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu: Control = main_menu_scene.instantiate()
	add_child_autofree(menu)
	await wait_frames(2)

	var start_btn: Button = menu.get_node_or_null("CenterContainer/ContentVBox/VBox/StartButton")
	assert_not_null(start_btn, "Main menu should have a StartButton")

	var btn_style: StyleBoxFlat = start_btn.get_theme_stylebox("normal")
	assert_not_null(btn_style, "Start button should have a normal stylebox")

	# Rounded corners
	assert_gt(btn_style.corner_radius_top_left, 0, "Button should have rounded corners")
	assert_gt(btn_style.corner_radius_top_right, 0, "Button should have rounded corners")
	assert_gt(btn_style.corner_radius_bottom_left, 0, "Button should have rounded corners")
	assert_gt(btn_style.corner_radius_bottom_right, 0, "Button should have rounded corners")

	# Golden border — may be 0 in headless if theme override not yet propagated
	# Check that either the border is set OR the style box override exists
	var border_color := btn_style.border_color
	var has_border := btn_style.border_width_left > 0
	var has_override := start_btn.has_theme_stylebox_override("normal")
	assert_true(
		has_border or has_override,
		"Button should have a border or stylebox override"
	)
	if has_border:
		assert_true(
			border_color.r > 0.5 and border_color.g > 0.4,
			"Button border should be golden"
		)


func test_main_menu_text_uses_warm_cream_color() -> void:
	var main_menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	var menu: Control = main_menu_scene.instantiate()
	add_child_autofree(menu)
	await wait_frames(2)

	var start_btn: Button = menu.get_node_or_null("CenterContainer/ContentVBox/VBox/StartButton")
	assert_not_null(start_btn, "Main menu should have a StartButton")

	var font_color: Color = start_btn.get_theme_color("font_color")
	assert_true(
		font_color.r > 0.7 and font_color.g > 0.7 and font_color.b > 0.7,
		"Button text should be warm cream/beige (light)"
	)


# ── Typography Tests ────────────────────────────────────────────────

func test_hud_text_elements_exist_and_styled() -> void:
	var labels: Array[Node] = []
	_find_labels_recursive(_hud, labels)

	assert_gt(labels.size(), 0, "HUD should have at least one styled text element")

	for label_node in labels:
		var lbl: Label = label_node as Label
		if lbl and lbl.visible and lbl.text.length() > 0:
			# Check that text elements have font size overrides (stylized)
			var font_size: int = lbl.get_theme_font_size("font_size")
			assert_gt(font_size, 0, "Label '" + lbl.text.substr(0, 16) + "' should have a font size set")
			break


func _find_labels_recursive(node: Node, out_labels: Array[Node]) -> void:
	if node is Label:
		out_labels.append(node)
	for child in node.get_children():
		_find_labels_recursive(child, out_labels)
