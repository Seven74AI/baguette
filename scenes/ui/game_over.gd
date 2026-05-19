extends "res://scripts/ui/run_summary.gd"
## PHASE 4.11: Game Over screen — thin wrapper around RunSummary with game_over variant.
## Shared display logic lives in run_summary.gd.


func _ready() -> void:
	variant = "game_over"
	super._ready()
