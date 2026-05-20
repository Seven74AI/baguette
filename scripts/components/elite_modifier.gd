extends Node
## Elite Spawn System — 15% chance any enemy spawns as Elite.
## Composition pattern: attach this component to enemy scenes.
## Elite buffs: +50% HP, +30% damage, unique ability per type.
## Visual: orange name, glow aura, larger scale (×1.2).
## Guaranteed drop: 1 rare resource + 2× money.

# ── Elite spawn chance ────────────────────────────────────────────

var _elite_chance: float = 0.15
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


# ── Public API ────────────────────────────────────────────────────

func get_elite_chance() -> float:
	return _elite_chance


func set_elite_chance(p_chance: float) -> void:
	_elite_chance = clampf(p_chance, 0.0, 1.0)


func should_spawn_as_elite() -> bool:
	return _rng.randf() < _elite_chance


# ── Elite stat multipliers ─────────────────────────────────────────

func get_hp_multiplier() -> float:
	return 1.5


func get_damage_multiplier() -> float:
	return 1.3


func get_scale_multiplier() -> float:
	return 1.2


# ── Elite name prefix ─────────────────────────────────────────────

func get_elite_name(p_base_name: String, p_elite_variant: String) -> String:
	if p_elite_variant.is_empty():
		return p_base_name
	return p_elite_variant


# ── Guaranteed drops ──────────────────────────────────────────────

func get_elite_drops() -> Dictionary:
	return {
		"rare_resource": true,
		"money_multiplier": 2,
	}


# ── Visual properties ─────────────────────────────────────────────

func get_glow_color() -> Color:
	return Color.ORANGE


func get_aura_color() -> Color:
	return Color(1.0, 0.5, 0.0, 1.0)  # Orange-toned


# ── Unique abilities per enemy type ───────────────────────────────

const ELITE_ABILITIES: Dictionary = {
	"Touriste": "Organized Group — follows guide, +20% speed, sync attack",
	"Pigeon": "Mini-baguette beak — +50% HP, charges player",
	"Vendeur": "Golden Eiffel Towers — tracers, +50% damage",
	"Hipster": "Food Influencer — drone attracts enemies, aura converts drops to toxic",
	"Crêpier": "Master Crêpier — sticky dough, homing Suzette crêpes",
	"Livreur": "Uber Eats — energy drink buffs allies, 2 consecutive charges",
	"Barista": "Master Roaster — spawns Pigeons+Touristes, longer steam range",
	"Critique": "Guide Michelin — 3 floating star shield, rage at 0 stars",
	"Brigade": "Pastry Chef — apron armor, combo charge+shockwave, double eating speed",
	"Chef": "Triple-Star Chef — 8 knives, global Sauce Mère, summons Crêpiers",
	"Essaim": "Hornet Swarm — ×2 damage, only Four Sacré disperses",
}


func get_elite_ability(p_enemy_type: String) -> String:
	if ELITE_ABILITIES.has(p_enemy_type):
		return ELITE_ABILITIES[p_enemy_type]
	return ""


# ── Elite modifier application ────────────────────────────────────

func apply_elite_modifier(p_base_stats: Dictionary, p_elite_variant: String = "") -> Dictionary:
	var result: Dictionary = p_base_stats.duplicate()

	# Apply stat multipliers
	if result.has("hp"):
		result["hp"] = int(round(float(result["hp"]) * get_hp_multiplier()))
	if result.has("damage"):
		result["damage"] = int(round(float(result["damage"]) * get_damage_multiplier()))
	if result.has("scale"):
		result["scale"] = float(result["scale"]) * get_scale_multiplier()
	else:
		result["scale"] = get_scale_multiplier()

	# Set display name
	var base_name: String = result.get("name", "")
	result["display_name"] = get_elite_name(base_name, p_elite_variant)

	# Add elite drops
	result["elite_drops"] = get_elite_drops()

	return result
