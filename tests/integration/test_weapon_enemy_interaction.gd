extends "res://addons/gut/test.gd"
## Integration tests: weapon damage types vs enemy weaknesses.
## Verifies DamageTypes constants, weakness_component interactions,
## and weapon upgrades' effective damage type.

const DamageTypes = preload("res://scripts/components/damage_types.gd")
const HealthComponent = preload("res://scripts/components/health_component.gd")
const WeaknessComponent = preload("res://scripts/components/weakness_component.gd")
const WeaponUpgrade = preload("res://scripts/components/weapon_upgrade.gd")
const BaguetteGun = preload("res://scenes/weapons/baguette_gun.gd")
const BaseEnemy = preload("res://scripts/enemies/base_enemy.gd")

var _gun: BaguetteGun
var _enemy: BaseEnemy
var _health: HealthComponent
var _weakness: WeaknessComponent


func before_each() -> void:
	# Create weapon
	_gun = BaguetteGun.new()
	var raycast := RayCast3D.new()
	raycast.name = "RayCast3D"
	raycast.target_position = Vector3(0, 0, -100)
	_gun.add_child(raycast)
	var fire_timer := Timer.new()
	fire_timer.name = "FireTimer"
	fire_timer.one_shot = true
	_gun.add_child(fire_timer)
	var reload_timer := Timer.new()
	reload_timer.name = "ReloadTimer"
	reload_timer.one_shot = true
	_gun.add_child(reload_timer)
	var muzzle := MeshInstance3D.new()
	muzzle.name = "MuzzleFlash"
	muzzle.visible = false
	_gun.add_child(muzzle)
	add_child_autofree(_gun)

	# Create enemy with health and weakness
	_enemy = BaseEnemy.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 100
	_health.current_health = 100
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health

	_weakness = WeaknessComponent.new()
	_weakness.name = "WeaknessComponent"
	_enemy.add_child(_weakness)

	add_child_autofree(_enemy)
	await wait_frames(2)


# ── Damage Types ────────────────────────────────────────────────────

func test_damage_types_constants_exist() -> void:
	assert_eq(DamageTypes.NONE, 0)
	assert_eq(DamageTypes.SLASH, 1)
	assert_eq(DamageTypes.BLUNT, 2)
	assert_eq(DamageTypes.FIRE, 3)
	assert_eq(DamageTypes.OVEN, 4)


func test_damage_types_get_name() -> void:
	# Test the _NAME_MAP dictionary directly
	var dt_instance = DamageTypes.new()
	assert_eq(dt_instance._NAME_MAP[0], "None")
	assert_eq(dt_instance._NAME_MAP[1], "Tranchant")
	assert_eq(dt_instance._NAME_MAP[2], "Contondant")
	assert_eq(dt_instance._NAME_MAP[3], "Feu")
	assert_eq(dt_instance._NAME_MAP[4], "Four")
	dt_instance.free()


func test_weapon_default_damage_type_is_none() -> void:
	assert_eq(_gun.damage_type, DamageTypes.NONE, "Weapon default damage_type should be NONE")


func test_weapon_damage_type_settable() -> void:
	_gun.damage_type = DamageTypes.FIRE
	assert_eq(_gun.damage_type, DamageTypes.FIRE, "Weapon damage_type should be settable to FIRE")


# ── Weakness Component Integration ──────────────────────────────────

func test_weakness_default_multiplier_is_one() -> void:
	# Default: no weaknesses set => multiplier is 1.0 (neutral)
	var mult := _weakness.get_damage_multiplier(DamageTypes.SLASH)
	assert_eq(mult, 1.0, "Default multiplier should be 1.0 for any type")


func test_weakness_set_weakness_increases_multiplier() -> void:
	_weakness.set_weakness(DamageTypes.FIRE, 2.0)
	var mult := _weakness.get_damage_multiplier(DamageTypes.FIRE)
	assert_eq(mult, 2.0, "FIRE weakness should return 2.0 multiplier")


func test_weakness_set_resistance_decreases_multiplier() -> void:
	_weakness.set_resistance(DamageTypes.BLUNT, 0.5)
	var mult := _weakness.get_damage_multiplier(DamageTypes.BLUNT)
	assert_eq(mult, 0.5, "BLUNT resistance should return 0.5 multiplier")


func test_weakness_calculate_damage_applies_multiplier() -> void:
	_weakness.set_weakness(DamageTypes.SLASH, 2.0)
	var damage := _weakness.calculate_damage(25, DamageTypes.SLASH)
	assert_eq(damage, 50, "25 base * 2.0 weakness = 50")


func test_weakness_calculate_damage_uses_default() -> void:
	var damage := _weakness.calculate_damage(30, DamageTypes.NONE)
	assert_eq(damage, 30, "NONE type should apply default damage")


func test_weakness_prebuilt_profiles() -> void:
	# Tourist zombie profile
	var profile = WeaknessComponent.tourist_zombie_weaknesses()
	assert_not_null(profile, "Tourist zombie weakness profile should exist")
	var mult = profile.get_damage_multiplier(DamageTypes.SLASH)
	assert_eq(mult, 1.5, "Tourist zombie should be weak to SLASH (1.5x)")


# ── Weapon Upgrade — Damage Type Mods ───────────────────────────────

func test_upgrade_default_effective_type_is_base() -> void:
	var upgrade := WeaponUpgrade.new()
	assert_eq(upgrade.get_effective_damage_type(DamageTypes.SLASH), DamageTypes.SLASH,
		"Without mods, effective type should be base type")


func test_upgrade_fire_mod_changes_damage_type() -> void:
	var upgrade := WeaponUpgrade.new()
	upgrade._level = 3
	upgrade.install_mod(WeaponUpgrade.ModType.FIRE_ELEMENT)
	assert_eq(upgrade.get_effective_damage_type(DamageTypes.NONE), DamageTypes.FIRE,
		"Fire mod should convert damage to FIRE")


func test_upgrade_oven_mod_changes_damage_type() -> void:
	var upgrade := WeaponUpgrade.new()
	upgrade._level = 3
	upgrade.install_mod(WeaponUpgrade.ModType.OVEN_ELEMENT)
	assert_eq(upgrade.get_effective_damage_type(DamageTypes.NONE), DamageTypes.OVEN,
		"Oven mod should convert damage to OVEN")


func test_upgrade_stat_multipliers() -> void:
	var upgrade := WeaponUpgrade.new()
	upgrade._level = 2  # 1 mod slot
	upgrade.install_mod(WeaponUpgrade.ModType.DAMAGE_BONUS)
	var mults: Dictionary = upgrade.get_stat_multipliers()
	assert_gt(mults["damage"], 1.0, "Damage bonus mod should increase damage multiplier")


# ── Enemy <-> Weapon Interaction ────────────────────────────────────

func test_enemy_health_decreases_when_damaged_by_weapon() -> void:
	var initial := _health.current_health
	_health.take_damage(_gun.damage)
	assert_lt(_health.current_health, initial, "Enemy health should decrease from weapon damage")


func test_enemy_weakness_to_weapon_damage_type() -> void:
	# Set FIRE weakness on enemy, weapon deals FIRE
	_gun.damage_type = DamageTypes.FIRE
	_weakness.set_weakness(DamageTypes.FIRE, 2.0)

	# Calculate effective damage
	var effective := _weakness.calculate_damage(_gun.damage, _gun.damage_type)
	assert_eq(effective, 50, "25 base * 2.0 FIRE weakness = 50 effective damage")

	var initial := _health.current_health
	_health.take_damage(effective)
	assert_lt(_health.current_health, initial, "Health should decrease via weakness interaction")
	assert_eq(_health.current_health, initial - effective, "Damage should be weakness-multiplied")
