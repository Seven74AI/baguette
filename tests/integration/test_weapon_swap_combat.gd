extends "res://addons/gut/test.gd"
## Integration test: WeaponManager swap mechanics in combat context.
## Verifies weapon swapping, visibility toggling, active weapon tracking,
## and interaction between multiple weapons and enemy systems.

const HealthComponent = preload("res://scripts/components/health_component.gd")
const BaguetteGunClass = preload("res://scenes/weapons/baguette_gun.gd")
const WeaponManager = preload("res://scripts/weapons/weapon_manager.gd")
const BaseEnemy = preload("res://scripts/enemies/base_enemy.gd")
const DamageTypes = preload("res://scripts/components/damage_types.gd")


var _manager: WeaponManager
var _gun1: BaguetteGunClass
var _gun2: BaguetteGunClass
var _enemy: BaseEnemy
var _health: HealthComponent


func _make_gun() -> BaguetteGunClass:
	var gun := BaguetteGunClass.new()
	var raycast := RayCast3D.new()
	raycast.name = "RayCast3D"
	raycast.target_position = Vector3(0, 0, -100)
	gun.add_child(raycast)
	var fire_timer := Timer.new()
	fire_timer.name = "FireTimer"
	fire_timer.one_shot = true
	gun.add_child(fire_timer)
	var reload_timer := Timer.new()
	reload_timer.name = "ReloadTimer"
	reload_timer.one_shot = true
	gun.add_child(reload_timer)
	var muzzle := MeshInstance3D.new()
	muzzle.name = "MuzzleFlash"
	muzzle.visible = false
	gun.add_child(muzzle)
	return gun


func before_each() -> void:
	# Setup WeaponManager with 2 weapons
	_manager = WeaponManager.new()
	add_child_autofree(_manager)
	
	_gun1 = _make_gun()
	_gun2 = _make_gun()
	_gun1.damage = 25
	_gun2.damage = 40  # gun2 is stronger
	_manager.add_child(_gun1)
	_manager.add_child(_gun2)
	
	# Add both weapons to manager slots
	_manager.add_weapon(_gun1, 0)
	_manager.add_weapon(_gun2, 1)
	
	# Setup enemy
	_enemy = BaseEnemy.new()
	_health = HealthComponent.new()
	_health.name = "HealthComponent"
	_health.max_health = 200
	_health.current_health = 200
	_health.invulnerability_duration = 0.0
	_enemy.add_child(_health)
	_enemy.health_component = _health
	
	add_child_autofree(_enemy)
	await wait_frames(2)


func test_active_weapon_is_gun1_by_default() -> void:
	assert_eq(_manager.get_active_weapon(), _gun1, "Slot 0 weapon should be active by default")


func test_swap_to_gun2_changes_active_weapon() -> void:
	_manager.swap_next()
	assert_eq(_manager.get_active_weapon(), _gun2, "Active weapon should be gun2 after swap")


func test_gun2_is_hidden_after_swap_back() -> void:
	_manager.swap_next()  # To gun2
	_manager.swap_next()  # Back to gun1
	assert_true(_gun1.visible, "Gun1 should be visible (active)")
	assert_false(_gun2.visible, "Gun2 should be hidden (inactive)")


func test_enemy_health_decreases_from_active_weapon_damage() -> void:
	# Active is gun1 (damage=25)
	var initial := _health.current_health
	_health.take_damage(_gun1.damage)
	assert_eq(_health.current_health, initial - 25, "Enemy should take 25 damage from gun1")


func test_swapped_weapon_damages_enemy_with_different_value() -> void:
	# Gun2 deals 40 damage
	_manager.swap_next()
	var active_weapon: BaguetteGunClass = _manager.get_active_weapon()
	assert_eq(active_weapon, _gun2)
	
	_health.take_damage(active_weapon.damage)
	assert_eq(_health.current_health, 160, "Enemy should take 40 damage from stronger gun2")


func test_swap_signal_emitted_during_combat_flow() -> void:
	# Set up combat context: damage enemy, then swap
	_health.take_damage(10)
	watch_signals(_manager)
	
	_manager.swap_next()
	assert_signal_emitted(_manager, "weapon_swapped")


func test_swap_does_not_work_with_one_weapon_alive() -> void:
	# Simulate one weapon destroyed or only one added initially
	var solo_manager := WeaponManager.new()
	add_child_autofree(solo_manager)
	
	var solo_gun := _make_gun()
	solo_manager.add_child(solo_gun)
	solo_manager.add_weapon(solo_gun, 0)
	
	solo_manager.swap_next()
	assert_eq(solo_manager.get_active_weapon(), solo_gun, "Should stay on same weapon")
	assert_eq(solo_manager.get_active_slot_index(), 0, "Slot should remain 0")


func test_swap_prev_cycles_to_last_slot() -> void:
	# Active is slot 0; swap_prev should go to slot 1
	_manager.swap_previous()
	assert_eq(_manager.get_active_weapon(), _gun2, "Swap prev should go to slot 1")


func test_multiple_swaps_track_correctly() -> void:
	_manager.swap_next()  # -> gun2
	_manager.swap_next()  # -> gun1
	_manager.swap_next()  # -> gun2
	_manager.swap_previous()  # -> gun1
	
	assert_eq(_manager.get_active_weapon(), _gun1, "After 3 next + 1 prev, should be back to gun1")
	assert_eq(_manager.get_active_slot_index(), 0, "Should be in slot 0")


func test_damage_types_preserved_through_swap() -> void:
	_gun1.damage_type = DamageTypes.SLASH
	_gun2.damage_type = DamageTypes.FIRE
	
	assert_eq(_gun1.damage_type, DamageTypes.SLASH)
	assert_eq(_gun2.damage_type, DamageTypes.FIRE)
	
	_manager.swap_next()
	var active: BaguetteGunClass = _manager.get_active_weapon()
	assert_eq(active.damage_type, DamageTypes.FIRE, "Active weapon should preserve its damage type")


func test_swap_does_not_affect_enemy() -> void:
	# Enemy should be unaffected by pure weapon swap
	var health_before := _health.current_health
	_manager.swap_next()
	_manager.swap_next()
	assert_eq(_health.current_health, health_before, "Swapping weapons should not affect enemy health")


func test_replacing_active_weapon_updates_reference() -> void:
	var replacement_gun := _make_gun()
	replacement_gun.damage = 99
	_manager.add_child(replacement_gun)
	_manager.add_weapon(replacement_gun, 0)
	
	var active: BaguetteGunClass = _manager.get_active_weapon()
	assert_eq(active, replacement_gun, "Replacement weapon should become active")
	assert_eq(active.damage, 99, "Replacement weapon properties should be accessible")


func test_swap_animation_player_exists() -> void:
	var anim_player: AnimationPlayer = _manager.get_node_or_null("SwapAnimPlayer")
	assert_not_null(anim_player, "WeaponManager should have SwapAnimPlayer for transitions")
	assert_true(anim_player.has_animation("swap"), "Should have swap animation")
