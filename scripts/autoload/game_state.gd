extends Node
## Global game state autoload — tracks player stats, run state, and settings.
## Persists across scene changes. Proto: lightweight in-memory only.

signal player_died
signal run_started
signal run_ended(won: bool)

var player_health: int = 100
var player_max_health: int = 100
var enemies_killed: int = 0
var current_weapon_name: String = "Pistolet à Baguettes"
var run_active: bool = false


func start_run() -> void:
	player_health = player_max_health
	enemies_killed = 0
	run_active = true
	run_started.emit()


func damage_player(amount: int) -> void:
	player_health = max(0, player_health - amount)
	if player_health <= 0:
		run_active = false
		player_died.emit()


func record_kill() -> void:
	enemies_killed += 1


func end_run(won: bool) -> void:
	run_active = false
	run_ended.emit(won)
