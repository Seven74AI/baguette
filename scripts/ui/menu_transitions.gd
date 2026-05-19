extends Node
## PHASE 5.1c: Menu transition effects.
## Provides bakery-themed screen transitions using Tween animations.
##
## Transitions:
##   play_oven_door_open()  — Main Menu → Game: screen splits outward, warm light floods
##   play_crumble()         — Game → Game Over: screen crumbles ("pain rassis" effect)
##   play_sparkle_burst()   — Game → Victory: golden sparkle burst + baguette confetti

signal transition_completed

const PANEL_COUNT_CRUMBLE := 40
const SPARKLE_COUNT := 25


## Oven door open: screen splits from center to reveal the game.
## Creates two panels (left/right) that slide outward with warm golden/orange glow.
func play_oven_door_open() -> void:
	_cleanup()

	var viewport_size := _get_viewport_size()

	# Left door panel — anchored to left half
	var left_panel := ColorRect.new()
	left_panel.name = "OvenDoorLeft"
	left_panel.color = Palette.ORANGE_RED
	left_panel.size = Vector2(viewport_size.x / 2 + 10, viewport_size.y)
	left_panel.position = Vector2.ZERO
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_panel)

	# Right door panel — anchored to right half
	var right_panel := ColorRect.new()
	right_panel.name = "OvenDoorRight"
	right_panel.color = Palette.ORANGE_RED
	right_panel.size = Vector2(viewport_size.x / 2 + 10, viewport_size.y)
	right_panel.position = Vector2(viewport_size.x / 2, 0)
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(right_panel)

	# Warm light flash overlay
	var light_flash := ColorRect.new()
	light_flash.name = "OvenLightFlash"
	light_flash.color = Palette.BUTTER
	light_flash.modulate.a = 0.3
	light_flash.size = viewport_size
	light_flash.position = Vector2.ZERO
	light_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(light_flash)

	# Animate: doors slide outward, light pulse fades
	var tween := create_tween()
	tween.set_parallel(true)

	# Left door slides left
	tween.tween_property(left_panel, "position:x", -viewport_size.x / 2, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Right door slides right
	tween.tween_property(right_panel, "position:x", viewport_size.x, 0.8).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	# Light flash fades after peak
	tween.tween_property(light_flash, "modulate:a", 0.0, 0.5).set_delay(0.2)

	# Emit completed when animation finishes
	tween.tween_callback(_emit_completed).set_delay(0.9)


## Crumble: screen breaks into pieces that fall and fade ("pain rassis" effect).
## Creates grid of small panels that crumble and disappear.
func play_crumble() -> void:
	_cleanup()

	var viewport_size := _get_viewport_size()
	var columns := 16
	var rows := 10
	var piece_w := viewport_size.x / float(columns)
	var piece_h := viewport_size.y / float(rows)
	var tween := create_tween()
	tween.set_parallel(true)

	# Dark overlay for the stale bread effect
	for row in rows:
		for col in columns:
			var piece := ColorRect.new()
			piece.name = "CrumblePiece_%d_%d" % [col, row]
			piece.size = Vector2(piece_w + 2, piece_h + 2)
			piece.position = Vector2(col * piece_w, row * piece_h)

			# "Pain rassis" colors — dull browns, dark greys, muted tones
			var colors := [
				Palette.CRUST,
				Color(0.3, 0.2, 0.1, 1.0),
				Color(0.4, 0.3, 0.2, 1.0),
				Palette.COBBLESTONE_GREY,
				Color(0.25, 0.18, 0.1, 1.0),
			]
			piece.color = colors[randi() % colors.size()]
			piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(piece)

			# Random delay per piece for organic crumble
			var delay := randf_range(0.0, 0.5)

			# Animate: fall down + fade out + slight rotation
			tween.tween_property(piece, "position:y",
				viewport_size.y + randf_range(0, 100), 0.8
			).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

			tween.tween_property(piece, "modulate:a", 0.0, 0.5).set_delay(delay + 0.3)

			# Slight random horizontal drift
			tween.tween_property(piece, "position:x",
				piece.position.x + randf_range(-30, 30), 0.8
			).set_delay(delay).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	tween.tween_callback(_emit_completed).set_delay(1.4)


## Sparkle burst: golden particles burst outward and fade (victory effect).
func play_sparkle_burst() -> void:
	_cleanup()

	var viewport_size := _get_viewport_size()
	var center := viewport_size / 2
	var tween := create_tween()
	tween.set_parallel(true)

	for i in SPARKLE_COUNT:
		var sparkle := ColorRect.new()
		sparkle.name = "Sparkle_%d" % i
		var size := randf_range(4, 16)
		sparkle.size = Vector2(size, size)
		sparkle.position = center - Vector2(size / 2, size / 2)

		# Golden / butter colors
		var colors := [
			Palette.GOLDEN_BROWN,
			Palette.BUTTER,
			Palette.CREAM,
			Color(1.0, 0.85, 0.3, 1.0),
		]
		sparkle.color = colors[randi() % colors.size()]
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sparkle)

		# Random outward direction
		var angle := randf_range(0, TAU)
		var distance := randf_range(100, 400)
		var target := center + Vector2(cos(angle), sin(angle)) * distance

		var delay := randf_range(0.0, 0.3)
		var duration := randf_range(0.5, 1.0)

		tween.tween_property(sparkle, "position",
			target - Vector2(size / 2, size / 2), duration
		).set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

		tween.tween_property(sparkle, "modulate:a", 0.0, duration * 0.7).set_delay(delay + duration * 0.3)

		# Scale pop on sparkle
		tween.tween_property(sparkle, "scale", Vector2(0.0, 0.0), duration * 0.3).set_delay(delay + duration * 0.7)

	tween.tween_callback(_emit_completed).set_delay(1.5)


func _emit_completed() -> void:
	_cleanup()
	transition_completed.emit()


func _cleanup() -> void:
	for child in get_children():
		if child is ColorRect:
			child.queue_free()


func _get_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport:
		return viewport.get_visible_rect().size
	return Vector2(1280, 720)
