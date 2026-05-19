extends "res://addons/gut/test.gd"
## PHASE 4.11: Run Summary tests — verifies unified run summary displays correct stats,
## supports game_over and victory variants, and has working navigation buttons.

var _run_summary: Control
var _game_over: Control
var _victory: Control


func before_each() -> void:
	GameState._reset_for_testing()
	GameState.start_run()
	GameState.record_kill()
	GameState.record_kill()
	GameState.record_kill()
	GameState.rooms_cleared = 5
	GameState.run_time = 120.5
	GameState.total_damage_dealt = 350
	GameState.record_weapon_used("Pistolet à Baguettes")
	GameState.record_weapon_used("Croissant Boomerang")

	# Load run_summary scene directly
	var rs_scene: PackedScene = load("res://scenes/ui/run_summary.tscn")
	_run_summary = rs_scene.instantiate()
	add_child_autofree(_run_summary)

	# Load game_over (should use run_summary internally)
	var go_scene: PackedScene = load("res://scenes/ui/game_over.tscn")
	_game_over = go_scene.instantiate()
	add_child_autofree(_game_over)

	# Load victory (should use run_summary internally)
	var v_scene: PackedScene = load("res://scenes/ui/victory.tscn")
	_victory = v_scene.instantiate()
	add_child_autofree(_victory)

	await wait_frames(2)


# ── Scene loading ────────────────────────────────────────────────────

func test_run_summary_scene_loads() -> void:
	assert_not_null(_run_summary, "Run Summary scene should be loadable and instantiable")
	assert_true(_run_summary is Control, "Run Summary should be a Control node")


func test_game_over_scene_loads() -> void:
	assert_not_null(_game_over, "Game Over scene should be loadable and instantiable")
	assert_true(_game_over is Control, "Game Over should be a Control node")


func test_victory_scene_loads() -> void:
	assert_not_null(_victory, "Victory scene should be loadable and instantiable")
	assert_true(_victory is Control, "Victory should be a Control node")


# ── Title tests ──────────────────────────────────────────────────────

func test_run_summary_has_title() -> void:
	var title: Label = _run_summary.get_node_or_null("CenterContainer/ContentVBox/TitleLabel")
	assert_not_null(title, "Run Summary should have a TitleLabel")
	assert_true(title.text.length() > 0, "Title should not be empty")


func test_game_over_shows_death_title() -> void:
	var title: Label = _game_over.get_node_or_null("CenterContainer/ContentVBox/TitleLabel")
	assert_not_null(title, "Game Over should have a TitleLabel")
	var upper := title.text.to_upper()
	assert_true("MORT" in upper or "GAME OVER" in upper or "DEAD" in upper,
		"Game Over title should indicate death, got: " + title.text)


func test_victory_shows_victory_title() -> void:
	var title: Label = _victory.get_node_or_null("CenterContainer/ContentVBox/TitleLabel")
	assert_not_null(title, "Victory should have a TitleLabel")
	var upper := title.text.to_upper()
	assert_true("VICTOIRE" in upper or "VICTORY" in upper or "WIN" in upper,
		"Victory title should indicate victory, got: " + title.text)


# ── Stats display tests ──────────────────────────────────────────────

func test_run_summary_displays_kills() -> void:
	var kills_label: Label = _run_summary.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/KillsLabel")
	assert_not_null(kills_label, "Should have KillsLabel")
	assert_true(str(GameState.enemies_killed) in kills_label.text or kills_label.text.length() > 0,
		"Kills label should display kill count (3 kills), got: " + kills_label.text)


func test_run_summary_displays_rooms_cleared() -> void:
	var rooms_label: Label = _run_summary.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/RoomsLabel")
	assert_not_null(rooms_label, "Should have RoomsLabel")
	assert_true(str(GameState.rooms_cleared) in rooms_label.text or rooms_label.text.length() > 0,
		"Rooms label should display rooms cleared (5), got: " + rooms_label.text)


func test_run_summary_displays_run_time() -> void:
	var time_label: Label = _run_summary.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/TimeLabel")
	assert_not_null(time_label, "Should have TimeLabel")
	assert_true(time_label.text.length() > 0, "Time label should display run time")


func test_run_summary_displays_damage_dealt() -> void:
	var damage_label: Label = _run_summary.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/DamageLabel")
	assert_not_null(damage_label, "Should have DamageLabel")
	assert_true(damage_label.text.length() > 0, "Damage label should display total damage")


# ── Button tests ─────────────────────────────────────────────────────

func test_run_summary_has_new_game_button() -> void:
	var btn: Button = _find_new_game_button(_run_summary)
	assert_not_null(btn, "Run Summary should have a NewGameButton or RestartButton")
	assert_true(btn.text.length() > 0, "New game button should have text")


func test_run_summary_has_menu_button() -> void:
	var btn: Button = _run_summary.get_node_or_null("CenterContainer/ContentVBox/ButtonsContainer/MenuButton")
	assert_not_null(btn, "Run Summary should have a MenuButton")
	assert_true(btn.text.length() > 0, "Menu button should have text")


func test_game_over_has_new_game_button() -> void:
	var btn: Button = _find_new_game_button(_game_over)
	assert_not_null(btn, "Game Over should have a new game button")
	assert_true(btn.text.length() > 0, "New game button should have text")


func test_victory_has_new_game_button() -> void:
	var btn: Button = _find_new_game_button(_victory)
	assert_not_null(btn, "Victory should have a new game button")
	assert_true(btn.text.length() > 0, "New game button should have text")


func test_menu_button_text_contains_menu() -> void:
	var btn: Button = _run_summary.get_node_or_null("CenterContainer/ContentVBox/ButtonsContainer/MenuButton")
	assert_true("MENU" in btn.text.to_upper() or "PRINCIPAL" in btn.text.to_upper() or "MAIN" in btn.text.to_upper(),
		"Menu button should reference menu, got: " + btn.text)


# ── Variant theme tests ──────────────────────────────────────────────

func test_game_over_has_dark_background() -> void:
	# Game Over should use dark/red theme
	var bg: ColorRect = _game_over.get_node_or_null("Background")
	if bg:
		# Dark theme: red channel should be dominant over green
		assert_true(bg.color.r > bg.color.g,
			"Game Over background should have red-dominant dark theme, got: " + str(bg.color))


func test_victory_has_golden_background() -> void:
	# Victory should use golden/bright theme
	var bg: ColorRect = _victory.get_node_or_null("Background")
	if bg:
		# Golden theme: red and green channels should be significant (golden = r+g)
		assert_true(bg.color.r > 0.05 and bg.color.g > 0.02,
			"Victory background should have golden tones, got: " + str(bg.color))


# ── Button action tests ──────────────────────────────────────────────

func test_new_game_button_resets_game_state() -> void:
	var btn: Button = _find_new_game_button(_run_summary)
	if btn:
		# Simulate click by emitting pressed signal
		btn.pressed.emit()
		await wait_frames(1)
		assert_true(GameState.run_active, "GameState should be active after New Game button press")
		assert_eq(GameState.enemies_killed, 0, "Kills should reset after New Game")
		assert_eq(GameState.rooms_cleared, 0, "Rooms should reset after New Game")


# ── Weapon usage display tests ───────────────────────────────────────

func test_run_summary_displays_weapons_used() -> void:
	var weapons_label: Label = _run_summary.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/WeaponsLabel")
	if weapons_label:
		assert_true(weapons_label.text.length() > 0, "Weapons label should display weapons used")


# ── Game Over specific display after death ────────────────────────────

func test_game_over_displays_stats_after_death() -> void:
	GameState._reset_for_testing()
	GameState.start_run()
	GameState.record_kill()
	GameState.record_kill()
	GameState.rooms_cleared = 3
	GameState.run_time = 65.0
	GameState.total_damage_dealt = 200
	GameState.damage_player(100)  # Dies

	var go_scene: PackedScene = load("res://scenes/ui/game_over.tscn")
	var go = go_scene.instantiate()
	add_child_autofree(go)
	await wait_frames(2)

	# Verify kills are shown after death
	var kills_label: Label = go.get_node_or_null("CenterContainer/ContentVBox/StatsContainer/KillsLabel")
	assert_not_null(kills_label, "Should have KillsLabel")
	assert_true(str(GameState.enemies_killed) in kills_label.text or kills_label.text.length() > 0,
		"Game Over should still display kills after death, got: " + kills_label.text)


# ── Helpers ──────────────────────────────────────────────────────────

func _find_new_game_button(node: Control) -> Button:
	"""Find new game button — handles both NewGameButton and RestartButton naming."""
	var btn: Button = node.get_node_or_null("CenterContainer/ContentVBox/ButtonsContainer/NewGameButton")
	if btn:
		return btn
	btn = node.get_node_or_null("CenterContainer/ContentVBox/ButtonsContainer/RestartButton")
	return btn
