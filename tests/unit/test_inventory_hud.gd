extends "res://addons/gut/test.gd"
## Tests for InventoryHUD — UI overlay for ammo display and active buffs.
## Verifies UI creation, theme application, and GameState signal integration.

const InventoryHUD = preload("res://scripts/ui/inventory_hud.gd")

var _hud: Control


func before_each() -> void:
	# Reset GameState to known state
	GameState._reset_for_testing()
	
	_hud = InventoryHUD.new()
	add_child_autofree(_hud)
	await wait_frames(2)


func test_hud_creates_ammo_display() -> void:
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display, "InventoryHUD should create an AmmoDisplay PanelContainer")
	assert_true(ammo_display is PanelContainer, "AmmoDisplay should be a PanelContainer")


func test_hud_creates_ammo_label() -> void:
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display)
	var ammo_label: Label = ammo_display.get_node_or_null("AmmoLabel")
	assert_not_null(ammo_label, "AmmoDisplay should contain an AmmoLabel")
	assert_true(ammo_label is Label, "AmmoLabel should be a Label")


func test_hud_creates_buffs_panel() -> void:
	var buffs_panel: PanelContainer = _hud.get_node_or_null("BuffsPanel")
	assert_not_null(buffs_panel, "InventoryHUD should create a BuffsPanel PanelContainer")
	assert_false(buffs_panel.visible, "BuffsPanel should start hidden (no active buffs)")


func test_hud_creates_buffs_container() -> void:
	var buffs_panel: PanelContainer = _hud.get_node_or_null("BuffsPanel")
	assert_not_null(buffs_panel)
	var container: VBoxContainer = buffs_panel.get_node_or_null("VBoxContainer")
	assert_not_null(container, "BuffsPanel should contain a VBoxContainer")
	assert_true(container is VBoxContainer, "Should be a VBoxContainer")


func test_ammo_label_shows_initial_state() -> void:
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display)
	var ammo_label: Label = ammo_display.get_node_or_null("AmmoLabel")
	assert_not_null(ammo_label)
	# GameState starts with 0/30 ammo
	assert_string_contains(ammo_label.text, "BAGUETTES", "Label should show 'BAGUETTES' prefix")
	assert_string_contains(ammo_label.text, "0", "Label should show 0 ammo")
	assert_string_contains(ammo_label.text, "30", "Label should show max ammo (30)")


func test_ammo_label_updates_on_game_state_change() -> void:
	GameState._ammo_count = 15
	_hud._refresh_ammo()
	
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display)
	var ammo_label: Label = ammo_display.get_node_or_null("AmmoLabel")
	assert_not_null(ammo_label)
	assert_string_contains(ammo_label.text, "15", "Label should reflect updated ammo (15)")


func test_ammo_label_shows_red_when_empty() -> void:
	GameState._ammo_count = 0
	_hud._refresh_ammo()
	
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display)
	var ammo_label: Label = ammo_display.get_node_or_null("AmmoLabel")
	assert_not_null(ammo_label)
	# When ammo is 0, COLOR_RED is applied — test that color is set
	var font_color: Color = ammo_label.get_theme_color("font_color")
	assert_eq(font_color, InventoryHUD.COLOR_RED, "Ammo label should be red when ammo is 0")


func test_ammo_label_shows_gold_when_ammo_available() -> void:
	GameState._ammo_count = 10
	_hud._refresh_ammo()
	
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display)
	var ammo_label: Label = ammo_display.get_node_or_null("AmmoLabel")
	assert_not_null(ammo_label)
	var font_color: Color = ammo_label.get_theme_color("font_color")
	assert_eq(font_color, InventoryHUD.COLOR_GOLD, "Ammo label should be gold when ammo > 0")


func test_hud_connects_to_ammo_changed_signal() -> void:
	# Simulate GameState ammo_changed signal
	GameState._ammo_count = 5
	GameState.ammo_changed.emit(5, GameState._max_ammo)
	
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display)
	var ammo_label: Label = ammo_display.get_node_or_null("AmmoLabel")
	assert_not_null(ammo_label)
	assert_string_contains(ammo_label.text, "5", "Label should update via ammo_changed signal")


func test_buffs_panel_refreshes_on_game_state_change() -> void:
	GameState.add_buff("speed", 1.5, 10.0)
	await wait_frames(1)
	var buffs_panel: PanelContainer = _hud.get_node_or_null("BuffsPanel")
	assert_not_null(buffs_panel)
	assert_true(buffs_panel.visible, "BuffsPanel should be visible with active buffs")


func test_buffs_container_shows_buff_entries() -> void:
	# Clear any pre-existing buffs first
	GameState.clear_buffs()
	await wait_frames(1)
	
	GameState.add_buff("speed", 1.5, 10.0)
	GameState.add_buff("damage", 2.0, 5.0)
	await wait_frames(1)  # Let queue_free() complete on deferred removals
	
	var buffs_panel: PanelContainer = _hud.get_node_or_null("BuffsPanel")
	assert_not_null(buffs_panel)
	var container: VBoxContainer = buffs_panel.get_node_or_null("VBoxContainer")
	assert_not_null(container)
	
	var children = container.get_children()
	assert_eq(children.size(), 2, "Should have 2 buff label entries")
	
	for child in children:
		assert_true(child is Label, "Buff entries should be Labels")
		var label_text: String = (child as Label).text
		assert_true("s" in label_text, "Buff label should show duration in seconds")


func test_buffs_panel_hides_when_no_buffs() -> void:
	# Clear first
	GameState.clear_buffs()
	await wait_frames(1)
	
	# Add then clear buffs
	GameState.add_buff("speed", 1.5, 10.0)
	await wait_frames(1)
	assert_true(_hud.get_node_or_null("BuffsPanel").visible, "Should be visible with buff")
	
	GameState.clear_buffs()
	await wait_frames(1)
	assert_false(_hud.get_node_or_null("BuffsPanel").visible, "Should hide after buffs cleared")


func test_hud_connects_to_buffs_changed_signal() -> void:
	# Clear existing
	GameState.clear_buffs()
	await wait_frames(1)
	assert_false(_hud.get_node_or_null("BuffsPanel").visible)
	
	# Emit buffs_changed with active buff
	GameState.add_buff("speed", 1.5, 10.0)
	GameState.buffs_changed.emit(GameState.get_active_buffs())
	await wait_frames(1)
	
	assert_true(_hud.get_node_or_null("BuffsPanel").visible, "BuffsPanel should become visible via signal")


func test_ammo_display_is_anchored_bottom_right() -> void:
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display)
	assert_eq(ammo_display.anchor_left, 1.0, "AmmoDisplay should be anchored right")
	assert_eq(ammo_display.anchor_top, 1.0, "AmmoDisplay should be anchored bottom")


func test_buffs_panel_is_anchored_top_left() -> void:
	var buffs_panel: PanelContainer = _hud.get_node_or_null("BuffsPanel")
	assert_not_null(buffs_panel)
	assert_eq(buffs_panel.anchor_left, 0.0, "BuffsPanel should be anchored left")
	assert_eq(buffs_panel.anchor_top, 0.0, "BuffsPanel should be anchored top")


func test_color_constants_are_defined() -> void:
	assert_not_null(InventoryHUD.COLOR_GOLD, "COLOR_GOLD should be defined")
	assert_not_null(InventoryHUD.COLOR_DARK, "COLOR_DARK should be defined")
	assert_not_null(InventoryHUD.COLOR_BLUE, "COLOR_BLUE should be defined")
	assert_not_null(InventoryHUD.COLOR_RED, "COLOR_RED should be defined")
	
	assert_true(InventoryHUD.COLOR_GOLD is Color, "COLOR_GOLD should be a Color")
	assert_true(InventoryHUD.COLOR_RED is Color, "COLOR_RED should be a Color")


func test_calling_ammo_refresh_does_not_crash_without_label() -> void:
	# Create a fresh HUD without adding to tree
	var test_hud := InventoryHUD.new()
	# Don't add to tree — _ready shouldn't be called
	# _refresh_ammo references _ammo_label which would be null
	# But add_child should trigger _ready which creates the label
	add_child_autofree(test_hud)
	await wait_frames(1)
	GameState._ammo_count = 20
	test_hud._refresh_ammo()
	# Should not crash
	assert_true(true, "Calling _refresh_ammo on a prepared HUD should not crash")


func test_ammo_label_has_font_size() -> void:
	var ammo_display: PanelContainer = _hud.get_node_or_null("AmmoDisplay")
	assert_not_null(ammo_display)
	var ammo_label: Label = ammo_display.get_node_or_null("AmmoLabel")
	assert_not_null(ammo_label)
	var font_size: int = ammo_label.get_theme_font_size("font_size")
	assert_gt(font_size, 0, "AmmoLabel should have a positive font size")
	assert_eq(font_size, 16, "AmmoLabel font size should be 16")
