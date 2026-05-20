extends "res://addons/gut/test.gd"
## PHASE 5.2b: Elite Spawn System unit tests.
## 15% chance, +50% HP, +30% damage, orange name, glow, scale, guaranteed drops.

const EliteModifier = preload("res://scripts/components/elite_modifier.gd")

var _elite_modifier: EliteModifier


func before_each() -> void:
	_elite_modifier = EliteModifier.new()
	add_child_autofree(_elite_modifier)


# ── Elite chance ─────────────────────────────────────────────────

func test_is_elite_chance_configured() -> void:
	var chance: float = _elite_modifier.get_elite_chance()
	assert_eq(chance, 0.15, "Default elite chance should be 15%")


func test_should_spawn_as_elite_returns_boolean() -> void:
	var result: bool = _elite_modifier.should_spawn_as_elite()
	assert_true(typeof(result) == TYPE_BOOL, "should_spawn_as_elite should return a boolean")


func test_elite_chance_can_be_configured() -> void:
	_elite_modifier.set_elite_chance(0.5)
	assert_eq(_elite_modifier.get_elite_chance(), 0.5, "Elite chance should be configurable")


func test_should_spawn_as_elite_returns_true_with_chance_1() -> void:
	_elite_modifier.set_elite_chance(1.0)
	assert_true(_elite_modifier.should_spawn_as_elite(),
		"With 100% chance, should_spawn_as_elite should return true")


func test_should_spawn_as_elite_returns_false_with_chance_0() -> void:
	_elite_modifier.set_elite_chance(0.0)
	assert_false(_elite_modifier.should_spawn_as_elite(),
		"With 0% chance, should_spawn_as_elite should return false")


# ── Elite stats ──────────────────────────────────────────────────

func test_get_hp_multiplier_returns_1_5() -> void:
	var mult: float = _elite_modifier.get_hp_multiplier()
	assert_eq(mult, 1.5, "Elite HP multiplier should be 1.5 (+50%)")


func test_get_damage_multiplier_returns_1_3() -> void:
	var mult: float = _elite_modifier.get_damage_multiplier()
	assert_eq(mult, 1.3, "Elite damage multiplier should be 1.3 (+30%)")


func test_get_scale_multiplier_returns_1_2() -> void:
	var mult: float = _elite_modifier.get_scale_multiplier()
	assert_eq(mult, 1.2, "Elite scale multiplier should be 1.2 (×1.2)")


# ── Name prefix ──────────────────────────────────────────────────

func test_get_elite_name_returns_orange_prefixed_name() -> void:
	var elite_name: String = _elite_modifier.get_elite_name("Pigeon", "Pigeon Blindé")
	assert_string_contains(elite_name, "Pigeon Blindé",
		"Elite name should contain the elite variant name")


func test_get_elite_name_prefix_default() -> void:
	var elite_name: String = _elite_modifier.get_elite_name("Touriste Zombie", "")
	assert_string_contains(elite_name, "Touriste Zombie",
		"Elite name should contain the base name when no elite variant specified")


# ── Guaranteed drops ─────────────────────────────────────────────

func test_get_elite_drops_contains_rare_resource() -> void:
	var drops: Dictionary = _elite_modifier.get_elite_drops()
	assert_true(drops.has("rare_resource"), "Elite drops should include a rare_resource")


func test_get_elite_drops_contains_double_money() -> void:
	var drops: Dictionary = _elite_modifier.get_elite_drops()
	assert_true(drops.has("money_multiplier"), "Elite drops should include money_multiplier")


func test_money_multiplier_is_two() -> void:
	var drops: Dictionary = _elite_modifier.get_elite_drops()
	assert_eq(drops.get("money_multiplier", 1), 2,
		"Elite money multiplier should be 2 (2x money)")


# ── Visual properties ────────────────────────────────────────────

func test_get_glow_color_is_orange() -> void:
	var glow: Color = _elite_modifier.get_glow_color()
	assert_eq(glow, Color.ORANGE, "Elite glow should be orange")


func test_get_aura_color_is_orange() -> void:
	var aura: Color = _elite_modifier.get_aura_color()
	assert_true(aura.r > 0.7 and aura.g > 0.3 and aura.b < 0.2,
		"Elite aura should be orange-toned")


# ── Unique ability per type ──────────────────────────────────────

func test_get_elite_ability_returns_string_for_known_type() -> void:
	var ability: String = _elite_modifier.get_elite_ability("Pigeon")
	assert_true(typeof(ability) == TYPE_STRING,
		"get_elite_ability should return a string for a known type")


func test_get_elite_ability_returns_empty_for_unknown_type() -> void:
	var ability: String = _elite_modifier.get_elite_ability("UnknownEnemyType")
	assert_eq(ability, "", "Unknown enemy types should get empty ability string")


# ── Elite application ────────────────────────────────────────────

func test_apply_elite_modifier_returns_modified_stats() -> void:
	var base_stats: Dictionary = {"hp": 100, "damage": 20, "name": "Pigeon", "scale": 1.0}
	var elite_stats: Dictionary = _elite_modifier.apply_elite_modifier(base_stats, "Pigeon Blindé")
	assert_eq(elite_stats["hp"], 150, "Elite HP should be 150 (100 * 1.5)")
	assert_eq(elite_stats["damage"], 26, "Elite damage should be 26 (20 * 1.3)")
	assert_eq(elite_stats["scale"], 1.2, "Elite scale should be 1.2")
	assert_string_contains(elite_stats["display_name"], "Pigeon Blindé",
		"Elite display_name should contain the elite variant name")


func test_apply_elite_modifier_preserves_other_fields() -> void:
	var base_stats: Dictionary = {"hp": 80, "damage": 15, "name": "Touriste", "speed": 2.5}
	var elite_stats: Dictionary = _elite_modifier.apply_elite_modifier(base_stats, "Touriste Zombie")
	assert_eq(elite_stats["speed"], 2.5, "Non-modified fields like speed should be preserved")
