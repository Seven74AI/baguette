extends "res://addons/gut/test.gd"
## TDD tests for Phase 5.1d: Lighting & Post-Processing
## Verifies lighting_setup.tscn with zone profiles, WorldEnvironment,
## bloom, vignette, FogVolume for kitchen/oven, and street lamps.

# ═══════════════════════════════════════════════════════════════════
# Scene preloads
# ═══════════════════════════════════════════════════════════════════

const LightingSetupScene = preload("res://scenes/levels/lighting_setup.tscn")
const LightingSetupScript = preload("res://scenes/levels/lighting_setup.gd")
const BakeryTestScene = preload("res://scenes/levels/proto/bakery_test.tscn")


# ═══════════════════════════════════════════════════════════════════
# Zone profile data — expected colors per zone
# ═══════════════════════════════════════════════════════════════════

const ZONE_1_DIRECTIONAL := Color("#FFE4B5")   # warm golden-hour
const ZONE_1_AMBIENT := Color.ORANGE             # orange ambient
const ZONE_2_DIRECTIONAL := Color("#B0C4DE")     # cool evening blue
const ZONE_2_AMBIENT := Color.VIOLET             # violet ambient
const ZONE_3_DIRECTIONAL := Color("#FF6347")     # industrial warm/red
const ZONE_3_AMBIENT := Color.RED                # warm ambient
const BAKERY_DIRECTIONAL := Color("#FFD700")     # very warm gold
const BAKERY_AMBIENT := Color.ORANGE             # fireplace glow


# ═══════════════════════════════════════════════════════════════════
# WorldEnvironment & Post-Processing
# ═══════════════════════════════════════════════════════════════════

func test_lighting_setup_scene_loads() -> void:
	var instance := LightingSetupScene.instantiate()
	assert_not_null(instance, "lighting_setup.tscn should instantiate")
	instance.queue_free()


func test_lighting_setup_has_world_environment() -> void:
	var instance := LightingSetupScene.instantiate()
	var world_env: WorldEnvironment = _find_node_of_type(instance, WorldEnvironment)
	assert_not_null(world_env, "lighting_setup should have a WorldEnvironment node")
	instance.queue_free()


func test_world_environment_has_bloom_enabled() -> void:
	var instance := LightingSetupScene.instantiate()
	var world_env: WorldEnvironment = _find_node_of_type(instance, WorldEnvironment)
	assert_not_null(world_env, "WorldEnvironment should exist")
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		assert_true(env.glow_enabled, "Bloom (glow) should be enabled")
		assert_gt(env.glow_intensity, 0.0, "Glow intensity should be > 0")
		assert_gt(env.glow_strength, 0.0, "Glow strength should be > 0")
	instance.queue_free()


func test_world_environment_has_vignette() -> void:
	var instance := LightingSetupScene.instantiate()
	var world_env: WorldEnvironment = _find_node_of_type(instance, WorldEnvironment)
	assert_not_null(world_env, "WorldEnvironment should exist")
	if world_env and world_env.environment:
		var env: Environment = world_env.environment
		assert_true(env.adjustment_enabled, "Color adjustment should be enabled for vignette")
		# Vignette is controlled via adjustment_brightness/contrast/saturation
		assert_ne(env.adjustment_contrast, 1.0, "Contrast should be adjusted for vignette effect")
	instance.queue_free()


# ═══════════════════════════════════════════════════════════════════
# Zone profiles
# ═══════════════════════════════════════════════════════════════════

func test_zone_profiles_exist() -> void:
	var profiles := LightingSetupScript.ZONE_PROFILES
	assert_not_null(profiles, "ZONE_PROFILES should exist on lighting_setup.gd")
	assert_eq(profiles.size(), 4, "Should have 4 zone profiles (Zone 1, Zone 2, Zone 3, Bakery Hub)")


func test_zone1_boulangerie_colors() -> void:
	var zone1 := LightingSetupScript.ZONE_PROFILES["zone_1"]
	assert_not_null(zone1, "Zone 1 profile should exist")
	assert_not_null(zone1.get("directional_color"), "Zone 1 should have directional_color")
	assert_not_null(zone1.get("ambient_color"), "Zone 1 should have ambient_color")


func test_zone2_marais_colors() -> void:
	var zone2 := LightingSetupScript.ZONE_PROFILES["zone_2"]
	assert_not_null(zone2, "Zone 2 profile should exist")
	assert_not_null(zone2.get("directional_color"), "Zone 2 should have directional_color")
	assert_not_null(zone2.get("ambient_color"), "Zone 2 should have ambient_color")


func test_zone3_halles_colors() -> void:
	var zone3 := LightingSetupScript.ZONE_PROFILES["zone_3"]
	assert_not_null(zone3, "Zone 3 profile should exist")
	assert_not_null(zone3.get("directional_color"), "Zone 3 should have directional_color")
	assert_not_null(zone3.get("ambient_color"), "Zone 3 should have ambient_color")


func test_zone_bakery_hub_colors() -> void:
	var bakery := LightingSetupScript.ZONE_PROFILES["bakery_hub"]
	assert_not_null(bakery, "Bakery Hub profile should exist")
	assert_not_null(bakery.get("directional_color"), "Bakery Hub should have directional_color")
	assert_not_null(bakery.get("ambient_color"), "Bakery Hub should have ambient_color")


# ═══════════════════════════════════════════════════════════════════
# FogVolume for kitchen/oven
# ═══════════════════════════════════════════════════════════════════

func test_lighting_setup_has_fog_volume() -> void:
	var instance := LightingSetupScene.instantiate()
	var fog: FogVolume = _find_node_of_type(instance, FogVolume)
	assert_not_null(fog, "lighting_setup should have a FogVolume for kitchen/oven areas")
	instance.queue_free()


func test_fog_volume_has_material() -> void:
	var instance := LightingSetupScene.instantiate()
	var fog: FogVolume = _find_node_of_type(instance, FogVolume)
	assert_not_null(fog, "FogVolume should exist")
	if fog:
		assert_not_null(fog.material, "FogVolume should have a FogMaterial assigned")
	instance.queue_free()


# ═══════════════════════════════════════════════════════════════════
# Street lamps
# ═══════════════════════════════════════════════════════════════════

func test_lighting_setup_has_street_lamp_lights() -> void:
	var instance := LightingSetupScene.instantiate()
	var lamps := _find_nodes_by_group(instance, "street_lamp")
	assert_gt(lamps.size(), 0, "lighting_setup should have street lamp nodes (group: street_lamp)")
	instance.queue_free()


func test_street_lamp_has_warm_light() -> void:
	var instance := LightingSetupScene.instantiate()
	var lamps := _find_nodes_by_group(instance, "street_lamp")
	assert_gt(lamps.size(), 0, "At least one street lamp should exist")
	if lamps.size() > 0:
		var lamp := lamps[0]
		var light: Light3D = _find_node_of_type(lamp, Light3D)
		assert_not_null(light, "Street lamp should have a Light3D child")
		if light:
			var col := light.light_color
			var warmth := col.r + col.g  # warm = red+green dominance over blue
			var coolness := col.b
			assert_gt(warmth, coolness, "Street lamp light should be warm (r+g > b)")
	instance.queue_free()


# ═══════════════════════════════════════════════════════════════════
# Bakery test scene integration
# ═══════════════════════════════════════════════════════════════════

func test_bakery_test_has_lighting_setup_node() -> void:
	var bakery := BakeryTestScene.instantiate()
	var lighting: Node = _find_node_by_name(bakery, "LightingSetup")
	assert_not_null(lighting, "bakery_test.tscn should have a LightingSetup child node")
	bakery.queue_free()


func test_bakery_test_has_directional_light() -> void:
	var bakery := BakeryTestScene.instantiate()
	var dir_light: DirectionalLight3D = _find_node_of_type(bakery, DirectionalLight3D)
	assert_not_null(dir_light, "bakery_test.tscn should have a DirectionalLight3D")
	bakery.queue_free()


# ═══════════════════════════════════════════════════════════════════
# DirectionalLight3D per zone
# ═══════════════════════════════════════════════════════════════════

func test_lighting_setup_has_directional_light() -> void:
	var instance := LightingSetupScene.instantiate()
	var dir_light: DirectionalLight3D = _find_node_of_type(instance, DirectionalLight3D)
	assert_not_null(dir_light, "lighting_setup should have a DirectionalLight3D")
	instance.queue_free()


# ═══════════════════════════════════════════════════════════════════
# Helpers
# ═══════════════════════════════════════════════════════════════════

func _find_node_of_type(root: Node, type) -> Node:
	if is_instance_of(root, type):
		return root
	for child in root.get_children():
		var result := _find_node_of_type(child, type)
		if result:
			return result
	return null


func _find_nodes_by_group(root: Node, group_name: String) -> Array[Node]:
	var result: Array[Node] = []
	if root.is_in_group(group_name):
		result.append(root)
	for child in root.get_children():
		result.append_array(_find_nodes_by_group(child, group_name))
	return result


func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var result := _find_node_by_name(child, node_name)
		if result:
			return result
	return null
