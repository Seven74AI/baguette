extends "res://addons/gut/test.gd"
## Unit tests for bakery-themed HUD (PHASE 3 polish).

const HUDScene = preload("res://scenes/ui/hud.tscn")

var _hud: Control


func before_each() -> void:
	_hud = HUDScene.instantiate()
	add_child_autofree(_hud)
	await wait_frames(2)


func test_hud_has_crosshair_elements() -> void:
	var top: Label = _hud.get_node_or_null("Crosshair/Top")
	var bottom: Label = _hud.get_node_or_null("Crosshair/Bottom")
	var left: Label = _hud.get_node_or_null("Crosshair/Left")
	var right: Label = _hud.get_node_or_null("Crosshair/Right")
	assert_not_null(top, "Crosshair should have Top label")
	assert_not_null(bottom, "Crosshair should have Bottom label")
	assert_not_null(left, "Crosshair should have Left label")
	assert_not_null(right, "Crosshair should have Right label")


func test_hud_has_health_bar() -> void:
	var health_bar: ProgressBar = _hud.get_node_or_null("HealthBar")
	assert_not_null(health_bar, "HUD should have a HealthBar")
	assert_eq(health_bar.max_value, 100.0, "Health bar max should be 100")


func test_hud_has_ammo_panel() -> void:
	var ammo_label: Label = _hud.get_node_or_null("AmmoPanel/AmmoLabel")
	assert_not_null(ammo_label, "HUD should have an AmmoLabel")


func test_hud_has_dash_indicator() -> void:
	var dash_label: Label = _hud.get_node_or_null("DashPanel/DashLabel")
	assert_not_null(dash_label, "HUD should have a DashLabel")


func test_hud_has_kill_counter() -> void:
	var kill_label: Label = _hud.get_node_or_null("KillPanel/KillLabel")
	assert_not_null(kill_label, "HUD should have a KillLabel")
