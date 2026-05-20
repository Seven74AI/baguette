class_name FourSacre
extends Node3D
## Four Sacré — ultimate weapon. Channelled heat beam, cooldown-based (no ammo).
## Deals 100 damage/sec with a 0.5m beam over 20m range. 60s cooldown.
## Kills reduce remaining cooldown by 2 seconds. Dedicated ultimate slot (Q).

signal firing_started
signal firing_stopped
signal charge_changed(charge: float)

@export_category("Weapon Stats")
@export var damage_per_second: int = 100
@export var beam_width: float = 0.5
@export var max_range: float = 20.0
@export var cooldown_time: float = 60.0
@export var kill_cooldown_reduction: float = 2.0
@export var max_ammo: int = 0  ## No ammo — cooldown-based
@export var damage_types: Array = [3]  ## FIRE

@export_category("Effects")
@export var beam_damage_interval: float = 0.1  ## Damage tick every 100ms

@onready var _beam_raycast: RayCast3D = $BeamRayCast
@onready var _beam_timer: Timer = $BeamTimer

var _charge: float = 0.0  ## 0.0 = empty, 1.0 = fully charged
var _is_firing: bool = false
var _beam_elapsed: float = 0.0


func _ready() -> void:
	_charge = 0.0
	if _beam_timer:
		_beam_timer.wait_time = beam_damage_interval
		_beam_timer.one_shot = false


func _process(delta: float) -> void:
	if not _is_firing:
		# Charge fills passively
		if _charge < 1.0:
			_charge = min(1.0, _charge + delta / cooldown_time)
			charge_changed.emit(_charge)
	else:
		# Consume charge while firing
		if _charge > 0.0:
			_charge = max(0.0, _charge - delta / cooldown_time)
			charge_changed.emit(_charge)
		else:
			_is_firing = false
			firing_stopped.emit()
			if _beam_timer:
				_beam_timer.stop()


func fire() -> void:
	## Begin channelling the beam. Does nothing if not charged.
	if _charge < 1.0:
		return
	if _is_firing:
		return

	_is_firing = true
	if _beam_timer:
		_beam_timer.start()
	firing_started.emit()


func release() -> void:
	## Stop channelling the beam.
	_is_firing = false
	firing_stopped.emit()
	if _beam_timer:
		_beam_timer.stop()


func is_firing() -> bool:
	return _is_firing


func is_ready() -> bool:
	return _charge >= 1.0


func get_charge() -> float:
	return _charge


func record_kill() -> void:
	## Reduce remaining cooldown by kill_cooldown_reduction seconds.
	var charge_boost: float = kill_cooldown_reduction / cooldown_time
	_charge = min(1.0, _charge + charge_boost)
	charge_changed.emit(_charge)


func get_ammo_count() -> int:
	return 0  ## No ammo — cooldown-based


func get_max_ammo() -> int:
	return max_ammo


func is_reloading() -> bool:
	return false


# ─── Beam damage tick ──────────────────────────────────────────────────

func _on_beam_timer_timeout() -> void:
	if not _is_firing or _charge <= 0.0:
		return

	# Perform hitscan along the beam
	if _beam_raycast:
		_beam_raycast.target_position = Vector3(0, 0, -max_range)
		_beam_raycast.force_raycast_update()
		if _beam_raycast.is_colliding():
			var collider: Node = _beam_raycast.get_collider()
			var hit_point: Vector3 = _beam_raycast.get_collision_point()
			_apply_beam_damage(collider, hit_point)


func _apply_beam_damage(target: Node, hit_point: Vector3) -> void:
	# Damage per tick = damage_per_second * beam_damage_interval
	var tick_damage: int = int(damage_per_second * beam_damage_interval)
	if target.has_method("take_damage"):
		target.take_damage(tick_damage, get_parent(), damage_types[0])
	elif target.get_parent() and target.get_parent().has_method("take_damage"):
		target.get_parent().take_damage(tick_damage, get_parent(), damage_types[0])
