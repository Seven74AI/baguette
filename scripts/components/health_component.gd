extends Node
## Attachable health component for any damageable entity (player, enemies, props).
## Uses composition pattern — attach to any node that should have health.
##
## NOTE: class_name removed to avoid headless loading-order issues.
## Use `const HealthComponent = preload("res://scripts/components/health_component.gd")`
## in scripts that reference this as a type.

signal health_changed(current: int, max_hp: int)
signal health_depleted
signal damage_taken(amount: int, source: Node)

@export var max_health: int = 100
@export var current_health: int = 100:
	set(v):
		current_health = clampi(v, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health <= 0:
			health_depleted.emit()

@export var is_invulnerable: bool = false
@export var invulnerability_duration: float = 0.5

var _invulnerability_timer: float = 0.0


func _ready() -> void:
	current_health = max_health


func _process(delta: float) -> void:
	if _invulnerability_timer > 0:
		_invulnerability_timer -= delta
		if _invulnerability_timer <= 0:
			is_invulnerable = false


func take_damage(amount: int, source: Node = null) -> void:
	if is_invulnerable or current_health <= 0:
		return

	current_health -= amount
	damage_taken.emit(amount, source)

	if amount > 0 and invulnerability_duration > 0:
		is_invulnerable = true
		_invulnerability_timer = invulnerability_duration


func heal(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = mini(current_health + amount, max_health)


func is_alive() -> bool:
	return current_health > 0


func get_health_ratio() -> float:
	return float(current_health) / float(max_health)
