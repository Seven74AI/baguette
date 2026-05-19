extends Area3D
## Crescent-shaped projectile thrown by Croissant Ninja.
## Flies in a straight line, damages the player on hit.

signal projectile_hit(target: Node)

var speed: float = 8.0
var damage: int = 10
var direction: Vector3 = Vector3.FORWARD
var lifetime: float = 5.0

@onready var _timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= lifetime:
		queue_free()
		return

	position += direction * speed * delta


func _on_body_entered(body: Node3D) -> void:
	# Don't hit enemies
	if body.is_in_group("enemy"):
		return

	if body.is_in_group("player") or body.has_method("take_damage"):
		if body.has_method("take_damage"):
			body.take_damage(damage, self)
		elif body.get("health_component"):
			var hc = body.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(damage, self)
		projectile_hit.emit(body)
		queue_free()
