extends Control
## Simple proto HUD — crosshair, ammo counter, health display.
## Attached to the player's Camera3D so it renders in the viewport.
## Updates every frame from GameState and the player's weapon.

@onready var _ammo_label: Label = $AmmoPanel/AmmoLabel
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _kill_label: Label = $KillPanel/KillLabel

var _player: CharacterBody3D = null
var _weapon: Node = null


func _ready() -> void:
	# Find the player (parent's parent — Camera3D → Player)
	var camera := get_parent()
	if camera and camera.get_parent() is CharacterBody3D:
		_player = camera.get_parent()
	
	_refresh_weapon_ref()


func _process(_delta: float) -> void:
	# Update health
	if _player and _player.get("health_component"):
		var hc = _player.health_component
		if hc:
			_health_bar.max_value = hc.max_health
			_health_bar.value = hc.current_health
	
	# Update ammo
	_refresh_weapon_ref()
	if _weapon and _weapon.has_method("get_ammo_count") and _weapon.has_method("get_max_ammo"):
		_ammo_label.text = str(_weapon.get_ammo_count()) + " / " + str(_weapon.get_max_ammo())
	elif _weapon:
		_ammo_label.text = "-- / --"
	
	# Update kills
	_kill_label.text = "Kills: " + str(GameState.enemies_killed)


func _refresh_weapon_ref() -> void:
	if not _weapon and _player:
		var mount := _player.get_node_or_null("Camera3D/WeaponMount")
		if mount and mount.get_child_count() > 0:
			_weapon = mount.get_child(0)
