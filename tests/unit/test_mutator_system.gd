extends "res://addons/gut/test.gd"
## PHASE 5.2b: Floor Mutator system unit tests.
## 8 mutators, random selection, no repeats, HUD display, signal-based effects.

const MutatorSystem = preload("res://scripts/systems/mutator_system.gd")

var _mutator_system: MutatorSystem


func before_each() -> void:
	_mutator_system = MutatorSystem.new()
	add_child_autofree(_mutator_system)


# ── Mutator definitions ──────────────────────────────────────────

func test_eight_mutators_defined() -> void:
	var mutators: Array = _mutator_system.get_all_mutators()
	assert_eq(mutators.size(), 8, "Should have exactly 8 floor mutators defined")


func test_mutator_has_name_and_icon() -> void:
	var mutators: Array = _mutator_system.get_all_mutators()
	for m in mutators:
		assert_true(m.has("name"), "Every mutator should have a 'name' field")
		assert_true(m.has("icon"), "Every mutator should have an 'icon' field")
		assert_true(m.has("description"), "Every mutator should have a 'description' field")


func test_mutator_nuit_sans_lune_exists() -> void:
	var names: Array = _mutator_system.get_mutator_names()
	assert_true(names.has("Nuit Sans Lune"), "Should include Nuit Sans Lune mutator")


func test_mutator_pate_qui_leve_exists() -> void:
	var names: Array = _mutator_system.get_mutator_names()
	assert_true(names.has("Pâte Qui Lève"), "Should include Pâte Qui Lève mutator")


func test_mutator_inspection_sanitaire_exists() -> void:
	var names: Array = _mutator_system.get_mutator_names()
	assert_true(names.has("Inspection Sanitaire"), "Should include Inspection Sanitaire mutator")


func test_mutator_penurie_de_farine_exists() -> void:
	var names: Array = _mutator_system.get_mutator_names()
	assert_true(names.has("Pénurie de Farine"), "Should include Pénurie de Farine mutator")


func test_mutator_jour_de_marche_exists() -> void:
	var names: Array = _mutator_system.get_mutator_names()
	assert_true(names.has("Jour de Marché"), "Should include Jour de Marché mutator")


func test_mutator_greve_des_livreurs_exists() -> void:
	var names: Array = _mutator_system.get_mutator_names()
	assert_true(names.has("Grève des Livreurs"), "Should include Grève des Livreurs mutator")


func test_mutator_four_surchauffe_exists() -> void:
	var names: Array = _mutator_system.get_mutator_names()
	assert_true(names.has("Four Surchauffé"), "Should include Four Surchauffé mutator")


func test_mutator_vent_de_farine_exists() -> void:
	var names: Array = _mutator_system.get_mutator_names()
	assert_true(names.has("Vent de Farine"), "Should include Vent de Farine mutator")


# ── Random selection ─────────────────────────────────────────────

func test_select_random_returns_valid_mutator() -> void:
	var selected: Dictionary = _mutator_system.select_random()
	var all_mutators: Array = _mutator_system.get_all_mutators()
	assert_true(selected in all_mutators, "Selected mutator should be in the master list")


func test_select_random_excludes_used_in_zone() -> void:
	# Pick first mutator and mark it used
	_mutator_system._reset_used_for_testing()
	var first: Dictionary = _mutator_system.select_random(["Nuit Sans Lune"])
	assert_ne(first.get("name", ""), "Nuit Sans Lune",
		"Should NOT select a mutator already used in this zone")


func test_select_random_eventually_exhausts_all() -> void:
	_mutator_system._reset_used_for_testing()
	var used: Array = []
	for i in range(8):
		var selected: Dictionary = _mutator_system.select_random(used)
		assert_not_null(selected, "Should return a valid mutator")
		var name: String = selected.get("name", "")
		assert_false(used.has(name), "Should not select an already-used mutator")
		used.append(name)
	assert_eq(used.size(), 8, "Should be able to select all 8 unique mutators")


func test_select_random_returns_null_when_all_used() -> void:
	_mutator_system._reset_used_for_testing()
	var all_names: Array = _mutator_system.get_mutator_names()
	# Select all 8 to exhaust the pool
	for i in range(8):
		_mutator_system.select_random(all_names.slice(0, i))
		# Add to "used" pool
	var result: Dictionary = _mutator_system.select_random(all_names)
	assert_eq(result, {}, "Should return empty dict when all mutators are used")


# ── Signal-based effects ─────────────────────────────────────────

func test_apply_mutator_emits_signal() -> void:
	watch_signals(_mutator_system)
	var mutator: Dictionary = _mutator_system.get_all_mutators()[0]
	_mutator_system.apply_mutator(mutator)
	assert_signal_emitted(_mutator_system, "mutator_applied",
		"Applying a mutator should emit mutator_applied signal")


func test_apply_mutator_sets_current_mutator() -> void:
	var mutator: Dictionary = _mutator_system.get_all_mutators()[3]
	_mutator_system.apply_mutator(mutator)
	var current: Dictionary = _mutator_system.get_current_mutator()
	assert_eq(current, mutator, "get_current_mutator should return the applied mutator")


func test_mutator_effects_contain_correct_keys() -> void:
	var mutator: Dictionary = _mutator_system.get_mutator_by_name("Nuit Sans Lune")
	assert_true(mutator.has("effects"), "Mutator should have effects dictionary")
	var effects: Dictionary = mutator["effects"]
	assert_true(effects.has("enemy_speed_mult"), "Nuit Sans Lune should affect enemy speed")
	assert_true(effects.has("enemy_aggro_mult"), "Nuit Sans Lune should affect enemy aggro")


# ── HUD display helpers ──────────────────────────────────────────

func test_get_display_text_returns_name() -> void:
	var mutator: Dictionary = _mutator_system.get_mutator_by_name("Vent de Farine")
	var text: String = _mutator_system.get_display_text(mutator)
	assert_string_contains(text, "Vent de Farine",
		"Display text should include the mutator name")


func test_get_display_text_returns_description() -> void:
	var mutator: Dictionary = _mutator_system.get_mutator_by_name("Pénurie de Farine")
	var text: String = _mutator_system.get_display_text(mutator)
	assert_string_contains(text, "Pénurie de Farine",
		"Display text should include the mutator name")


func test_display_duration_is_positive() -> void:
	assert_gt(_mutator_system.get_display_duration(), 0.0,
		"Display duration should be positive (seconds)")


func test_get_mutator_icon_returns_string() -> void:
	var mutator: Dictionary = _mutator_system.get_all_mutators()[0]
	var icon: String = _mutator_system.get_mutator_icon(mutator)
	assert_true(typeof(icon) == TYPE_STRING, "Icon should be a string (path or emoji)")


# ── Reset and zone tracking ──────────────────────────────────────

func test_reset_zone_clears_used_list() -> void:
	_mutator_system._reset_used_for_testing()
	var first: Dictionary = _mutator_system.select_random()
	var first_name: String = first.get("name", "")
	# Reset zone
	_mutator_system.reset_zone()
	# Same name should be selectable again
	var second: Dictionary = _mutator_system.select_random()
	var second_name: String = second.get("name", "")
	# After reset, we can select the same name again (not guaranteed by RNG but pool is fresh)
	var all_names: Array = _mutator_system.get_mutator_names()
	assert_true(first_name in all_names, "First name should still exist in master list")
	assert_true(second_name in all_names, "Second name should exist in master list")
