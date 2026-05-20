extends Control
## Zone transition screen — shown between zones.
## Displays zone name, bakery tip, and a loading bar.

signal transition_finished

## Bakery tips shown during zone transitions.
const BAKERY_TIPS := [
	"Une baguette bien cuite est la meilleure arme.",
	"Le croissant parfait a 7 couches de beurre.",
	"MITCH ne recule jamais devant l'ennemi.",
	"La farine T65 est le secret des grands boulangers.",
	"Un pain bien levé fait un projectile mortel.",
	"Le pétrissage, c'est 80% du travail.",
	"Les critiques gastronomiques sont les pires ennemis.",
	"Le four à 250°C — parfait pour les baguettes et les boss.",
	"Un mitron armé vaut dix soldats.",
	"La Sainte Trinité: farine, eau, sel.",
]

@onready var _zone_label: Label = $CenterContainer/ContentVBox/ZoneNameLabel
@onready var _tip_label: Label = $CenterContainer/ContentVBox/TipLabel
@onready var _progress_bar: ProgressBar = $CenterContainer/ContentVBox/ProgressBar


## Start the transition for a given zone name.
## Displays the zone name, a random bakery tip, and auto-advances.
func start_transition(zone_name: String) -> void:
	_zone_label.text = zone_name
	_tip_label.text = _pick_random_tip()
	_progress_bar.value = 0.0

	# Simulate loading progress (0 → 100 in ~2 seconds)
	var tween := create_tween()
	tween.tween_property(_progress_bar, "value", 100.0, 2.0)
	tween.tween_callback(_on_transition_complete)


func _pick_random_tip() -> String:
	return BAKERY_TIPS[randi() % BAKERY_TIPS.size()]


func _on_transition_complete() -> void:
	transition_finished.emit()
