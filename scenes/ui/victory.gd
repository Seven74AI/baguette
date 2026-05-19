extends "res://scripts/ui/run_summary.gd"
## PHASE 4.11: Victory screen — thin wrapper around RunSummary with victory variant.
## Shared display logic lives in run_summary.gd.


func _ready() -> void:
	variant = "victory"
	super._ready()
