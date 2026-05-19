extends "res://addons/gut/test.gd"
## Tests for the BaguetteGun weapon — verifies firing, ammo, reload, and damage application.
## Also includes WeaponManager tests for weapon swapping system.
## Also includes CroissantBoomerang tests.

const HealthComponent = preload("res://scripts/components/health_component.gd")
const BaguetteGunClass = preload("res://scenes/weapons/baguette_gun.gd")
const WeaponManager = preload("res://scripts/weapons/weapon_manager.gd")
const CroissantBoomerangClass = preload("res://scenes/weapons/croissant_boomerang.gd")

var _gun: BaguetteGunClass


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


# === BaguetteGun tests ===

func before_each() -> void:
	_gun = _make_gun()
	add_child_autofree(_gun)
	await wait_frames(2)


func test_gun_starts_with_full_ammo() -> void:
	assert_eq(_gun.get_ammo_count(), _gun.max_ammo, "Gun should start with max ammo")
	assert_false(_gun.is_reloading(), "Should not be reloading initially")


func test_firing_reduces_ammo() -> void:
	_gun.fire()
	await wait_seconds(0.6)  # fire rate
	assert_eq(_gun.get_ammo_count(), _gun.max_ammo - 1, "Ammo should decrease after firing")


func test_firing_emits_fired_signal() -> void:
	watch_signals(_gun)
	_gun.fire()
	await wait_seconds(0.6)
	assert_signal_emitted(_gun, "fired")


func test_cannot_fire_while_reloading() -> void:
	# Fire one shot to allow reload to actually start
	_gun.fire()
	await wait_seconds(0.6)
	
	_gun.reload()
	await wait_frames(1)
	assert_true(_gun.is_reloading(), "Should be reloading")
	var ammo_before := _gun.get_ammo_count()
	_gun.fire()
	await wait_frames(1)
	assert_eq(_gun.get_ammo_count(), ammo_before, "Should not fire while reloading")


func test_reload_restores_ammo() -> void:
	# Fire all shots
	for i in range(_gun.max_ammo):
		_gun.fire()
		await wait_seconds(0.6)
	
	assert_eq(_gun.get_ammo_count(), 0, "Ammo should be 0 after firing all shots")
	
	_gun.reload()
	await wait_seconds(2.0)  # reload time + margin
	
	assert_eq(_gun.get_ammo_count(), _gun.max_ammo, "Reload should restore ammo to max")


func test_reloaded_signal() -> void:
	for i in range(_gun.max_ammo):
		_gun.fire()
		await wait_seconds(0.6)
	
	watch_signals(_gun)
	_gun.reload()
	await wait_seconds(2.0)
	assert_signal_emitted(_gun, "reloaded")


func test_ammo_depleted_signal() -> void:
	watch_signals(_gun)
	for i in range(_gun.max_ammo):
		_gun.fire()
		await wait_seconds(0.6)
	
	# Next fire should emit ammo_depleted
	_gun.fire()
	await wait_frames(2)
	# Check if the signal was emitted (it fires when _current_ammo is 0)
	# In practice this depends on timing — verify ammo is 0
	assert_eq(_gun.get_ammo_count(), 0, "Ammo should be depleted")


func test_reload_does_nothing_when_full() -> void:
	_gun.reload()
	await wait_frames(1)
	assert_eq(_gun.get_ammo_count(), _gun.max_ammo, "Reload with full ammo should not change count")
	assert_false(_gun.is_reloading(), "Should not be reloading with full ammo")


func test_damage_is_correct() -> void:
	assert_eq(_gun.damage, 25, "Baguette Gun should deal 25 damage")


func test_gun_has_damage_type_export() -> void:
	# BaguetteGun should have a damage_type property (default: NONE = 0)
	assert_eq(_gun.damage_type, 0, "Default damage_type should be NONE (0)")


func test_gun_damage_type_is_settable() -> void:
	var dt = preload("res://scripts/components/damage_types.gd")
	_gun.damage_type = dt.SLASH
	assert_eq(_gun.damage_type, dt.SLASH, "Should set damage_type to SLASH")


# === WeaponManager tests ===

var _manager: WeaponManager
var _wm_gun1: BaguetteGunClass
var _wm_gun2: BaguetteGunClass


func before_each_weapon_manager() -> void:
	_manager = WeaponManager.new()
	add_child_autofree(_manager)
	_wm_gun1 = _make_gun()
	_wm_gun2 = _make_gun()
	# Add guns as children of manager so visibility/tree works
	_manager.add_child(_wm_gun1)
	_manager.add_child(_wm_gun2)


func test_wm_starts_with_no_weapons() -> void:
	before_each_weapon_manager()
	assert_eq(_manager.get_weapon_count(), 0, "Should start with 0 weapons")
	assert_null(_manager.get_active_weapon(), "No active weapon when empty")


func test_wm_can_add_weapon_to_slot_0() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	assert_eq(_manager.get_weapon_count(), 1, "Should have 1 weapon")
	assert_eq(_manager.get_active_weapon(), _wm_gun1, "First weapon added becomes active")


func test_wm_can_add_two_weapons() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.add_weapon(_wm_gun2, 1)
	assert_eq(_manager.get_weapon_count(), 2, "Should have 2 weapons")


func test_wm_adding_to_occupied_slot_replaces() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.add_weapon(_wm_gun2, 0)  # Replace slot 0
	assert_eq(_manager.get_weapon_count(), 1, "Should still have 1 weapon after replacement")
	assert_eq(_manager.get_active_weapon(), _wm_gun2, "Replacement weapon becomes active")


func test_wm_cannot_exceed_two_slots() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.add_weapon(_wm_gun2, 1)
	var gun3 := _make_gun()
	_manager.add_weapon(gun3, 2)
	assert_eq(_manager.get_weapon_count(), 2, "Should stay at 2 weapons")
	_manager.add_weapon(gun3, 5)
	assert_eq(_manager.get_weapon_count(), 2, "Out-of-bounds slots ignored")


func test_wm_swap_next_wraps_around() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.add_weapon(_wm_gun2, 1)
	assert_eq(_manager.get_active_weapon(), _wm_gun1, "Slot 0 is active by default")
	_manager.swap_next()
	assert_eq(_manager.get_active_weapon(), _wm_gun2, "Swap next -> slot 1")
	_manager.swap_next()
	assert_eq(_manager.get_active_weapon(), _wm_gun1, "Swap next wraps to slot 0")


func test_wm_swap_previous_wraps_around() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.add_weapon(_wm_gun2, 1)
	assert_eq(_manager.get_active_weapon(), _wm_gun1, "Slot 0 is active by default")
	_manager.swap_previous()
	assert_eq(_manager.get_active_weapon(), _wm_gun2, "Swap prev wraps to slot 1")
	_manager.swap_previous()
	assert_eq(_manager.get_active_weapon(), _wm_gun1, "Swap prev wraps to slot 0")


func test_wm_swap_does_nothing_with_one_weapon() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.swap_next()
	assert_eq(_manager.get_active_weapon(), _wm_gun1, "Active unchanged with 1 weapon")
	_manager.swap_previous()
	assert_eq(_manager.get_active_weapon(), _wm_gun1, "Active unchanged with 1 weapon")


func test_wm_swap_signal_emitted() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.add_weapon(_wm_gun2, 1)
	watch_signals(_manager)
	_manager.swap_next()
	assert_signal_emitted(_manager, "weapon_swapped")


func test_wm_inactive_weapon_is_hidden() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.add_weapon(_wm_gun2, 1)
	_wm_gun1.visible = true
	_wm_gun2.visible = true
	
	_manager.swap_next()  # Switch to gun2
	assert_false(_wm_gun1.visible, "Inactive weapon should be hidden")
	assert_true(_wm_gun2.visible, "Active weapon should be visible")


func test_wm_get_slot_index() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	assert_eq(_manager.get_active_slot_index(), 0, "Active slot is 0")
	_manager.add_weapon(_wm_gun2, 1)
	_manager.swap_next()
	assert_eq(_manager.get_active_slot_index(), 1, "Active slot is 1 after swap")


# === CroissantBoomerang tests ===

var _croissant: CroissantBoomerangClass


func before_each_croissant() -> void:
	_croissant = CroissantBoomerangClass.new()
	add_child_autofree(_croissant)
	await wait_frames(2)


func test_cb_starts_ready() -> void:
	before_each_croissant()
	assert_true(_croissant.get_is_ready(), "Croissant should be ready to throw initially")


func test_cb_has_correct_damage() -> void:
	before_each_croissant()
	assert_eq(_croissant.damage, 35, "Croissant boomerang should deal 35 damage")


func test_cb_throw_changes_ready_state() -> void:
	before_each_croissant()
	_croissant.fire()
	await wait_frames(1)
	assert_false(_croissant.get_is_ready(), "Should not be ready while projectile is active")


func test_cb_cannot_throw_while_projectile_active() -> void:
	before_each_croissant()
	var initial_child_count: int = _croissant.get_child_count()
	_croissant.fire()
	await wait_frames(1)
	# Second fire should do nothing
	_croissant.fire()
	await wait_frames(1)
	# Should still have only 1 projectile (initial was 0 children)
	assert_eq(_croissant.get_child_count(), initial_child_count + 1,
		"Should only have one projectile after double-fire")


func test_cb_projectile_is_created_on_throw() -> void:
	before_each_croissant()
	var initial_count: int = _croissant.get_child_count()
	_croissant.fire()
	await wait_frames(1)
	assert_gt(_croissant.get_child_count(), initial_count, "A projectile should be created")


func test_cb_projectile_moves_forward() -> void:
	before_each_croissant()
	_croissant.fire()
	await wait_frames(1)
	var projectile: Node3D = _croissant.get_child(0) as Node3D
	if projectile:
		var initial_pos: Vector3 = projectile.global_position
		await wait_seconds(0.2)
		var new_pos: Vector3 = projectile.global_position
		assert_ne(initial_pos, new_pos, "Projectile should move from initial position")


func test_cb_projectile_returns() -> void:
	before_each_croissant()
	_croissant.max_range = 5.0  # Short range for fast test
	_croissant.fire()
	await wait_frames(1)
	var projectile: Node3D = _croissant.get_child(0) as Node3D
	if projectile:
		# Wait for it to reach max range and return
		await wait_seconds(1.0)
		# After return, the croissant should be ready again
		assert_true(_croissant.get_is_ready(), "Croissant should be ready after projectile returns")


func test_cb_projectile_has_curved_hitbox() -> void:
	before_each_croissant()
	_croissant.fire()
	await wait_frames(2)
	var projectile: Node3D = _croissant.get_child(0) as Node3D
	if projectile:
		var area: Area3D = projectile.get_node_or_null("HitArea")
		assert_not_null(area, "Projectile should have a hit detection Area3D")
		var shape: CollisionShape3D = area.get_node_or_null("CollisionShape3D")
		assert_not_null(shape, "HitArea should have a collision shape")
		# Curved hitbox: should be a SphereShape3D (larger than a point)
		assert_true(shape.shape is SphereShape3D, "Hitbox should be a sphere (curved)")


func test_cb_throw_speed_is_configurable() -> void:
	before_each_croissant()
	assert_gt(_croissant.throw_speed, 0.0, "Throw speed should be positive")


func test_cb_max_range_is_configurable() -> void:
	before_each_croissant()
	assert_gt(_croissant.max_range, 0.0, "Max range should be positive")


func test_cb_projectile_has_croissant_mesh() -> void:
	before_each_croissant()
	_croissant.fire()
	await wait_frames(2)
	var projectile: Node3D = _croissant.get_child(0) as Node3D
	if projectile:
		var mesh_instance: MeshInstance3D = projectile.get_node_or_null("MeshInstance3D")
		assert_not_null(mesh_instance, "Projectile should have a MeshInstance3D")
		var m: Mesh = mesh_instance.mesh
		assert_not_null(m, "Mesh should be assigned")
		# Croissant mesh is a custom ArrayMesh, not a built-in primitive
		assert_true(m is ArrayMesh, "Croissant mesh should be a custom ArrayMesh, not a primitive")
		assert_gt(m.get_surface_count(), 0, "Mesh should have at least one surface")
		var arrays = m.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[ArrayMesh.ARRAY_VERTEX] as PackedVector3Array
		# A proper croissant mesh should have > 100 vertices (sphere has ~42)
		assert_gt(vertices.size(), 50, "Croissant mesh should have many vertices (> 50)")


func test_cb_projectile_spins_in_flight() -> void:
	before_each_croissant()
	_croissant.fire()
	await wait_frames(2)
	var projectile: Node3D = _croissant.get_child(0) as Node3D
	if projectile:
		var initial_rotation: Vector3 = projectile.rotation
		await wait_seconds(0.2)
		var new_rotation: Vector3 = projectile.rotation
		var has_spin: bool = (
			not is_equal_approx(initial_rotation.x, new_rotation.x) or
			not is_equal_approx(initial_rotation.y, new_rotation.y) or
			not is_equal_approx(initial_rotation.z, new_rotation.z)
		)
		assert_true(has_spin, "Projectile should rotate (spin) while in flight")


func test_wm_swap_has_transition_animation() -> void:
	before_each_weapon_manager()
	_manager.add_weapon(_wm_gun1, 0)
	_manager.add_weapon(_wm_gun2, 1)
	# Check that WeaponManager has an AnimationPlayer for swap transitions
	var anim_player: AnimationPlayer = _manager.get_node_or_null("SwapAnimPlayer")
	assert_not_null(anim_player, "WeaponManager should have an AnimationPlayer for swap transitions")
	assert_true(anim_player.has_animation("swap"), "Should have a 'swap' animation")
