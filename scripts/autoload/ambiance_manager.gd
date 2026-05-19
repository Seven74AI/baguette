extends Node
## AmbianceManager autoload — plays room-type ambient loops.
## Maps room themes (cuisine, boulangerie, rue) to ambient sound loops.
## Uses the Ambiance audio bus. Supports cross-fading between room types.

# Map room theme strings to ambient .ogg resource paths
const ROOM_AMBIANCE_MAP: Dictionary = {
	"cuisine": "res://assets/audio/ambiance/oven_hum.ogg",
	"boulangerie": "res://assets/audio/ambiance/dough_squish.ogg",
	"rue": "res://assets/audio/ambiance/paris_street.ogg",
	"bakery": "res://assets/audio/ambiance/bakery_bell.ogg",
	"dungeon": "res://assets/audio/ambiance/fire_crackle.ogg",
	"street": "res://assets/audio/ambiance/paris_street.ogg",
}

var _ambiance_player: AudioStreamPlayer = null
var _room_streams: Dictionary = {}
var _current_room_type: String = ""
var _crossfade_tween: Tween = null
var _crossfade_duration: float = 0.5


func _ready() -> void:
	_create_player()
	_load_streams()


func _create_player() -> void:
	_ambiance_player = AudioStreamPlayer.new()
	_ambiance_player.name = "AmbiancePlayer"
	_ambiance_player.bus = "Ambiance"
	add_child(_ambiance_player)


func _load_streams() -> void:
	for room_type in ROOM_AMBIANCE_MAP:
		var path: String = ROOM_AMBIANCE_MAP[room_type]
		if ResourceLoader.exists(path):
			var stream: AudioStream = load(path)
			if stream:
				_room_streams[room_type] = stream


func play_ambiance(room_type: String) -> void:
	var stream: AudioStream = _room_streams.get(room_type, null)
	if not stream:
		# Try to load on demand
		var path: String = ROOM_AMBIANCE_MAP.get(room_type, "")
		if path != "" and ResourceLoader.exists(path):
			stream = load(path)
			if stream:
				_room_streams[room_type] = stream

	if not stream or not _ambiance_player:
		return

	# Kill any existing crossfade
	if _crossfade_tween and is_instance_valid(_crossfade_tween):
		_crossfade_tween.kill()
		_crossfade_tween = null

	# If the same room type is already playing, do nothing
	if _current_room_type == room_type and _ambiance_player.playing:
		return

	_current_room_type = room_type

	# Crossfade: create tween, fade out current, switch stream, fade in
	_crossfade_tween = create_tween()

	# Fade out
	if _ambiance_player.playing:
		_crossfade_tween.tween_property(_ambiance_player, "volume_db", linear_to_db(0.01), _crossfade_duration)
		_crossfade_tween.tween_callback(_set_stream_and_play.bind(stream))
	else:
		_set_stream_and_play(stream)

	# Fade in after stream switch
	_crossfade_tween.tween_property(_ambiance_player, "volume_db", linear_to_db(0.5), _crossfade_duration)


func _set_stream_and_play(stream: AudioStream) -> void:
	if _ambiance_player:
		_ambiance_player.stream = stream
		_ambiance_player.volume_db = linear_to_db(0.01)
		_ambiance_player.play()


func stop_ambiance() -> void:
	if _crossfade_tween and is_instance_valid(_crossfade_tween):
		_crossfade_tween.kill()
		_crossfade_tween = null

	if _ambiance_player:
		_ambiance_player.stop()

	_current_room_type = ""


func set_room_type(room_type: String) -> void:
	_current_room_type = room_type
	play_ambiance(room_type)


func get_current_room_type() -> String:
	return _current_room_type
