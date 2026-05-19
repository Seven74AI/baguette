extends Area3D
## Ink blob projectile — thrown by Michelin Etoile Perdu.
## Flies toward the player, dealing damage and applying a slow effect on hit.
## Dark ink-colored sphere with trailing particles.

signal projectile_hit(target: Node)

@export var speed: float = 7.0
@export var damage: int = 12
@export var direction: Vector3 = Vector3.FORWARD
@export var lifetime: float = 4.0
@export var slow_factor: float = 0.5  ## 0.5 = 50% speed reduction
@export var slow_duration: float = 2.0  ## How long the slow lasts

@onready var _timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Visual: dark ink sphere
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.15, 0.9)  # Dark ink blue
	mat.roughness = 0.3
	mat.metallic = 0.1
	mesh.material_override = mat
	add_child(mesh)

	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	cs.shape = shape
	add_child(cs)


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
		# Apply damage
		if body.has_method("take_damage"):
			body.take_damage(damage, self)
		elif body.get("health_component"):
			var hc = body.health_component
			if hc and hc.has_method("take_damage"):
				hc.take_damage(damage, self)

		# Apply slow effect
		if body.is_in_group("player"):
			_apply_slow(body)

		projectile_hit.emit(body)
		queue_free()


## Apply slow effect to the player body.
func _apply_slow(body: Node3D) -> void:
	if body.has_method("set_speed_multiplier"):
		body.set_speed_multiplier(slow_factor)
	elif body is CharacterBody3D:
		var original_speed: float = 0.0
		if body.get("move_speed") != null:
			original_speed = body.move_speed
			body.move_speed = original_speed * slow_factor
			# Restore after slow_duration
			var timer := get_tree().create_timer(slow_duration)
			timer.timeout.connect(
				func():
					if is_instance_valid(body) and body.get("move_speed") != null:
						body.move_speed = original_speed
			)
