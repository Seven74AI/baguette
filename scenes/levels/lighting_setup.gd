extends Node3D
class_name LightingSetup
## Lighting manager with zone-specific profiles for atmosphere.
## Contains WorldEnvironment (bloom, vignette), FogVolume for kitchen/oven,
## and street lamp configurations.

# ═══════════════════════════════════════════════════════════════════
# Zone profiles — fixed per-zone lighting. No dynamic time-of-day.
# ═══════════════════════════════════════════════════════════════════

const ZONE_PROFILES := {
	"zone_1": {
		"name": "Rue de la Boulangerie",
		"directional_color": Color("#FFE4B5"),
		"ambient_color": Color.ORANGE,
		"bloom_threshold": 0.8,
		"shadow_enabled": true,
	},
	"zone_2": {
		"name": "Le Marais",
		"directional_color": Color("#B0C4DE"),
		"ambient_color": Color.VIOLET,
		"bloom_threshold": 0.8,
		"shadow_enabled": true,
	},
	"zone_3": {
		"name": "Les Halles",
		"directional_color": Color("#FF6347"),
		"ambient_color": Color.RED,
		"bloom_threshold": 0.7,
		"shadow_enabled": true,
	},
	"bakery_hub": {
		"name": "Bakery Hub",
		"directional_color": Color("#FFD700"),
		"ambient_color": Color.ORANGE,
		"bloom_threshold": 0.8,
		"shadow_enabled": false,
	},
}
