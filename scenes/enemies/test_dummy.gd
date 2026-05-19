extends CharacterBody3D
## Test Dummy — minimal enemy for integration testing.
## Uses NavigationAgent3D for pathfinding toward the player.
## CharacterBody3D that chases player within detection range.

@export_category("Movement")
@export var move_speed: float = 4.0
@export var acceleration: float = 10.0
@export var detection_range: float = 20.0

@onready var _nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var _player: Node3D = null

var _nav_ready: bool = false


func _ready() -> void:
	# Wait for navigation map to be fully synchronized
	if _nav_agent:
		await get_tree().physics_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		_nav_ready = true


func _physics_process(delta: float) -> void:
	if not _nav_ready or not _nav_agent:
		return
	
	_find_player()
	
	if _player == null:
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
		move_and_slide()
		return
	
	var distance := global_position.distance_to(_player.global_position)
	
	if distance > detection_range:
		# Too far — idle
		velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
	else:
		# Chase player using navigation
		_nav_agent.target_position = _player.global_position
		
		if not _nav_agent.is_navigation_finished():
			var next_pos := _nav_agent.get_next_path_position()
			var direction := (next_pos - global_position).normalized()
			direction.y = 0
			
			if direction.length() > 0.01:
				look_at(global_position + direction, Vector3.UP)
			
			var target_velocity := direction * move_speed
			velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
			velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector3.ZERO, acceleration * delta)
	
	move_and_slide()


func _find_player() -> void:
	if _player == null or not is_instance_valid(_player):
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
