extends Node
## Palette autoload — central bakery color palette definitions.
## Provides 10 color constants for visual consistency across all 3D assets.
## See /tmp/baguette-phase4-plan.md Task 12 for the palette spec.

# ── Warm bakery palette ──────────────────────────────────────────────

## Golden-brown bread crust — primary bakery warm tone
const GOLDEN_BROWN := Color(0.831, 0.639, 0.329)  # #D4A354

## Dark toasted brown — crust accent, charred edges
const CRUST := Color(0.545, 0.369, 0.235)  # #8B5E3C

## Off-white cream / flour — light bakery base
const CREAM := Color(0.961, 0.941, 0.882)  # #F5F0E1

## Pale yellow butter — highlight and accent
const BUTTER := Color(1.0, 0.957, 0.761)  # #FFF4C2

## Warm beige — counter / wall surfaces
const WARM_BEIGE := Color(0.910, 0.835, 0.718)  # #E8D5B7

# ── Mood / accent palette ────────────────────────────────────────────

## Smoky dark purple — apocalyptic sky
const PURPLE_SKY := Color(0.176, 0.106, 0.239)  # #2D1B3D

## Orange-red — fire / heat glow / muzzle flash
const ORANGE_RED := Color(0.910, 0.365, 0.247)  # #E85D3F

## Sickly green — mold / decay accent
const SICKLY_GREEN := Color(0.361, 0.478, 0.227)  # #5C7A3A

## Dark grey — Parisian cobblestone
const COBBLESTONE_GREY := Color(0.290, 0.290, 0.290)  # #4A4A4A

## Faded cyan — neon signage
const FADED_CYAN := Color(0.239, 0.839, 0.816)  # #3DD6D0


# ── Material factory helpers ─────────────────────────────────────────

## Create a StandardMaterial3D with the given palette color.
## Optionally enable emission for glow effects (neon, fire).
static func create_material(color: Color, roughness: float = 0.6,
		emission_color: Color = Color.BLACK, emission_energy: float = 0.0,
		metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metallic
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_energy
	return mat


## Create a StandardMaterial3D with emission from the given palette color.
static func create_emissive_material(color: Color, energy: float = 1.0,
		roughness: float = 0.4) -> StandardMaterial3D:
	return create_material(color, roughness, color, energy)


## Return the full palette as an array of all 10 colors (in spec order).
static func all_colors() -> Array[Color]:
	return [
		GOLDEN_BROWN,
		CRUST,
		CREAM,
		BUTTER,
		WARM_BEIGE,
		PURPLE_SKY,
		ORANGE_RED,
		SICKLY_GREEN,
		COBBLESTONE_GREY,
		FADED_CYAN,
	]


## Return a dictionary mapping color names (String) to Color values.
## Useful for tests that need to look up a color by name.
static func color_dict() -> Dictionary:
	return {
		"golden_brown": GOLDEN_BROWN,
		"crust": CRUST,
		"cream": CREAM,
		"butter": BUTTER,
		"warm_beige": WARM_BEIGE,
		"purple_sky": PURPLE_SKY,
		"orange_red": ORANGE_RED,
		"sickly_green": SICKLY_GREEN,
		"cobblestone_grey": COBBLESTONE_GREY,
		"faded_cyan": FADED_CYAN,
	}


## Return the number of palette colors (always 10).
static func color_count() -> int:
	return 10
