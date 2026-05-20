extends Control
## PHASE 5.2c: Hub Upgrade Screen — Meta-progression upgrades between runs.
## 4 branches with 5 levels each: Santé, Munitions, Dégâts, Chance.
## Golden baguette icons fill as you level.

const UPGRADE_BRANCHES := [
	{ "id": "sante", "name": "SANTÉ", "description": "Max HP", "unit": "+10 HP" },
	{ "id": "munitions", "name": "MUNITIONS", "description": "Max Ammo", "unit": "+5 munitions" },
	{ "id": "degats", "name": "DÉGÂTS", "description": "Damage %", "unit": "+5%" },
	{ "id": "chance", "name": "CHANCE", "description": "Loot Quality", "unit": "+3%" },
]

@onready var _title_label: Label = $CenterContainer/ContentVBox/TitleLabel
@onready var _reputation_label: Label = $CenterContainer/ContentVBox/ReputationLabel
@onready var _upgrades_container: VBoxContainer = $CenterContainer/ContentVBox/ScrollContainer/UpgradesVBox
@onready var _back_button: Button = $CenterContainer/ContentVBox/BackButton


func _ready() -> void:
	_refresh_display()
	_back_button.pressed.connect(_on_back_pressed)


func _refresh_display() -> void:
	var rep: int = 0
	if GameState.reputation:
		rep = GameState.reputation.get_total_reputation()
	_reputation_label.text = "RÉPUTATION: " + str(rep)

	# Clear existing upgrade rows
	for child in _upgrades_container.get_children():
		child.queue_free()

	# Create upgrade rows
	for branch in UPGRADE_BRANCHES:
		var row := _create_upgrade_row(branch)
		_upgrades_container.add_child(row)


func _create_upgrade_row(branch_data: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Branch name label
	var name_label := Label.new()
	name_label.text = branch_data["name"]
	name_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.custom_minimum_size = Vector2(140, 0)
	row.add_child(name_label)

	# Level indicator — golden baguette icons
	var level_container := HBoxContainer.new()
	var current_level: int = 0
	if GameState.reputation:
		current_level = GameState.reputation.get_upgrade_level(branch_data["id"])
	for i in range(5):
		var icon := Label.new()
		if i < current_level:
			icon.text = "🥖"  # filled baguette
			icon.add_theme_color_override("font_color", Color(0.85, 0.65, 0.13, 1.0))
		else:
			icon.text = "🥖"  # empty baguette (grey)
			icon.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3, 1.0))
		icon.add_theme_font_size_override("font_size", 18)
		level_container.add_child(icon)
	row.add_child(level_container)

	# Cost / Max label
	var cost_label := Label.new()
	if current_level >= 5:
		cost_label.text = "MAX"
		cost_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.13, 1.0))
	else:
		var cost: int = 0
		if GameState.reputation:
			cost = GameState.reputation.get_upgrade_cost(branch_data["id"], current_level)
		cost_label.text = str(cost) + " RP  " + branch_data["unit"]
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 0.9))
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.custom_minimum_size = Vector2(180, 0)
	row.add_child(cost_label)

	# Purchase button
	var purchase_btn := Button.new()
	if current_level >= 5:
		purchase_btn.text = "MAX"
		purchase_btn.disabled = true
	else:
		purchase_btn.text = "ACHETER"
		purchase_btn.pressed.connect(_on_purchase_pressed.bind(branch_data["id"]))

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.55, 0.27, 0.07, 0.9)
	btn_style.corner_radius_top_left = 6
	btn_style.corner_radius_top_right = 6
	btn_style.corner_radius_bottom_left = 6
	btn_style.corner_radius_bottom_right = 6
	btn_style.border_width_left = 1
	btn_style.border_width_right = 1
	btn_style.border_width_top = 1
	btn_style.border_width_bottom = 1
	btn_style.border_color = Color(0.85, 0.65, 0.13, 1.0)
	purchase_btn.add_theme_stylebox_override("normal", btn_style)
	purchase_btn.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	purchase_btn.add_theme_font_size_override("font_size", 18)
	purchase_btn.custom_minimum_size = Vector2(120, 36)
	row.add_child(purchase_btn)

	return row


func _on_purchase_pressed(branch_id: String) -> void:
	if GameState.reputation:
		var success: bool = GameState.reputation.purchase_upgrade(branch_id)
		if success:
			GameState._save_meta_progression()
	_refresh_display()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _apply_bakery_theme() -> void:
	_title_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.13, 1.0))
	_title_label.add_theme_font_size_override("font_size", 42)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_reputation_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 0.9))
	_reputation_label.add_theme_font_size_override("font_size", 22)
	_reputation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Back button
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.55, 0.27, 0.07, 0.9)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.85, 0.65, 0.13, 1.0)
	_back_button.add_theme_stylebox_override("normal", btn_style)
	_back_button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	_back_button.add_theme_font_size_override("font_size", 22)
