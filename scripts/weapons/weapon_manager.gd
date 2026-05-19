class_name WeaponManager
extends Node
## WeaponManager — manages 2 weapon slots and swap mechanics.
## Signal emitted when weapon is swapped: (previous_slot: int, new_slot: int)

signal weapon_swapped(previous_slot: int, new_slot: int)

const MAX_SLOTS: int = 2

var _slots: Array  # Array[Node] of size MAX_SLOTS, initialized to [null, null]
var _active_slot: int = 0
## Property used by the swap AnimationPlayer for transition progress (0.0-1.0)
var swap_progress: float = 0.0


func _ready() -> void:
	_slots.resize(MAX_SLOTS)
	# Fill with null
	for i in range(MAX_SLOTS):
		_slots[i] = null
	
	# Create AnimationPlayer for swap transitions
	var anim_player := AnimationPlayer.new()
	anim_player.name = "SwapAnimPlayer"
	add_child(anim_player)
	_create_swap_animation(anim_player)


func _create_swap_animation(anim_player: AnimationPlayer) -> void:
	var anim := Animation.new()
	anim.length = 0.2  # 200ms swap transition
	anim.loop_mode = Animation.LOOP_NONE
	
	# The swap animation is a placeholder that the AnimationPlayer can play
	# during weapon swaps for a smooth transition feel.
	# In-game, we'll tween weapon visibility/scale via this animation.
	var track_idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, ".:swap_progress")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 0.2, 1.0)
	
	var lib := AnimationLibrary.new()
	lib.add_animation("swap", anim)
	anim_player.add_animation_library("", lib)


## Adds a weapon to the given slot (0 or 1). Out-of-range slots are ignored.
## If this is the first weapon added, it becomes active.
func add_weapon(weapon: Node, slot: int) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	
	var is_first_weapon := get_weapon_count() == 0
	
	# Hide the old weapon in this slot if any
	var old_weapon: Node = _slots[slot]
	if old_weapon:
		old_weapon.visible = false
	
	_slots[slot] = weapon
	
	if is_first_weapon:
		_active_slot = slot
		weapon.visible = true
	elif slot == _active_slot:
		weapon.visible = true


## Returns the currently active weapon node, or null if empty.
func get_active_weapon() -> Node:
	if _active_slot < 0 or _active_slot >= MAX_SLOTS:
		return null
	return _slots[_active_slot]


## Returns the number of weapons in slots (0, 1, or 2).
func get_weapon_count() -> int:
	var count := 0
	for i in range(MAX_SLOTS):
		if _slots[i] != null:
			count += 1
	return count


## Returns the active slot index (0 or 1), or -1 if empty.
func get_active_slot_index() -> int:
	if get_weapon_count() == 0:
		return -1
	return _active_slot


## Swaps to the next weapon slot (0 -> 1 -> 0).
func swap_next() -> void:
	_swap_to((_active_slot + 1) % MAX_SLOTS)


## Swaps to the previous weapon slot (0 -> 1 -> 0).
func swap_previous() -> void:
	_swap_to((_active_slot - 1 + MAX_SLOTS) % MAX_SLOTS)


## Internal: perform the swap to a new slot if different and occupied.
func _swap_to(new_slot: int) -> void:
	if new_slot == _active_slot:
		return
	if get_weapon_count() <= 1:
		return
	
	var old_slot := _active_slot
	
	# Play swap animation
	var anim_player: AnimationPlayer = $SwapAnimPlayer
	if anim_player and anim_player.has_animation("swap"):
		anim_player.play("swap")
	
	# Hide old weapon
	var old_weapon: Node = _slots[old_slot]
	if old_weapon:
		old_weapon.visible = false
	
	# Show new weapon
	var new_weapon: Node = _slots[new_slot]
	if new_weapon:
		new_weapon.visible = true
	
	_active_slot = new_slot
	weapon_swapped.emit(old_slot, new_slot)
