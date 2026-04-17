extends Node

const AudioLibrary = preload("res://scripts/audio/audio_library.gd")

const MASTER_BUS := "Master"
const CUSTOM_BUSES: Array[String] = ["Music", "Ambience", "SFX", "UI"]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _missing_paths_warned: Dictionary = {}
var _missing_events_warned: Dictionary = {}
var _stream_cache: Dictionary = {}
var _loop_players: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_buses()

func play_ui(event_id: String) -> void:
	_play_event(event_id, Vector3.ZERO, false)

func play_sfx(event_id: String, world_position: Vector3 = Vector3.ZERO, is_3d: bool = false) -> void:
	_play_event(event_id, world_position, is_3d)

func play_loop(slot_id: String, event_id: String) -> void:
	var event: Dictionary = AudioLibrary.get_event(event_id)
	if event.is_empty():
		_warn_missing_event(event_id)
		stop_loop(slot_id)
		return

	var stream: AudioStream = _resolve_stream(event_id, event)
	if stream == null:
		stop_loop(slot_id)
		return

	var existing_entry: Dictionary = _loop_players.get(slot_id, {})
	var existing_player: AudioStreamPlayer = existing_entry.get("player", null) as AudioStreamPlayer
	if existing_player != null and is_instance_valid(existing_player):
		if String(existing_entry.get("event_id", "")) == event_id and existing_player.playing:
			return
		existing_player.stop()
		existing_player.queue_free()

	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = String(event.get("bus", "SFX"))
	player.volume_db = float(event.get("volume_db", 0.0))
	player.pitch_scale = _resolve_pitch(event)
	player.stream = _prepare_loop_stream(stream, event)
	add_child(player)
	player.play()
	_loop_players[slot_id] = {"event_id": event_id, "player": player}

func stop_loop(slot_id: String) -> void:
	if not _loop_players.has(slot_id):
		return
	var entry: Dictionary = _loop_players[slot_id]
	var player: AudioStreamPlayer = entry.get("player", null) as AudioStreamPlayer
	if player != null and is_instance_valid(player):
		player.stop()
		player.queue_free()
	_loop_players.erase(slot_id)

func play_music(event_id: String) -> void:
	var event: Dictionary = AudioLibrary.get_event(event_id)
	if event.is_empty():
		_warn_missing_event(event_id)
		return
	if bool(event.get("loop", false)):
		play_loop("music_main", event_id)
		return
	_play_event(event_id, Vector3.ZERO, false)

func _play_event(event_id: String, world_position: Vector3, is_3d: bool) -> void:
	var event: Dictionary = AudioLibrary.get_event(event_id)
	if event.is_empty():
		_warn_missing_event(event_id)
		return

	var stream: AudioStream = _resolve_stream(event_id, event)
	if stream == null:
		return

	var resolved_is_3d: bool = is_3d or bool(event.get("default_3d", false))
	if resolved_is_3d:
		_play_3d(stream, event, world_position)
	else:
		_play_2d(stream, event)

func _play_2d(stream: AudioStream, event: Dictionary) -> void:
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = String(event.get("bus", "SFX"))
	player.volume_db = float(event.get("volume_db", 0.0))
	player.pitch_scale = _resolve_pitch(event)
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _play_3d(stream: AudioStream, event: Dictionary, world_position: Vector3) -> void:
	var player := AudioStreamPlayer3D.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.bus = String(event.get("bus", "SFX"))
	player.volume_db = float(event.get("volume_db", 0.0))
	player.pitch_scale = _resolve_pitch(event)
	player.max_distance = float(event.get("max_distance", 24.0))
	player.unit_size = 1.0
	player.stream = stream
	player.global_position = world_position
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _resolve_stream(event_id: String, event: Dictionary) -> AudioStream:
	var available_paths: Array[String] = []
	for raw_path in event.get("paths", []):
		var path: String = String(raw_path)
		if path.is_empty():
			continue
		if not ResourceLoader.exists(path):
			_warn_missing_path(path)
			continue
		available_paths.append(path)

	if available_paths.is_empty():
		_warn_missing_event(event_id)
		return null

	var selected_path: String = available_paths[_rng.randi_range(0, available_paths.size() - 1)]
	if _stream_cache.has(selected_path):
		return _stream_cache[selected_path] as AudioStream

	var stream := load(selected_path) as AudioStream
	if stream == null:
		_warn_missing_path(selected_path)
		return null
	_stream_cache[selected_path] = stream
	return stream

func _resolve_pitch(event: Dictionary) -> float:
	var pitch_range: Vector2 = event.get("pitch_range", Vector2.ONE)
	if is_equal_approx(pitch_range.x, pitch_range.y):
		return pitch_range.x
	return _rng.randf_range(pitch_range.x, pitch_range.y)

func _prepare_loop_stream(stream: AudioStream, event: Dictionary) -> AudioStream:
	if not bool(event.get("loop", false)):
		return stream
	var duplicated_stream := stream.duplicate() as AudioStream
	if duplicated_stream == null:
		return stream
	if duplicated_stream is AudioStreamOggVorbis:
		(duplicated_stream as AudioStreamOggVorbis).loop = true
	elif duplicated_stream is AudioStreamMP3:
		(duplicated_stream as AudioStreamMP3).loop = true
	elif duplicated_stream is AudioStreamWAV:
		(duplicated_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	return duplicated_stream

func _ensure_buses() -> void:
	for bus_name in CUSTOM_BUSES:
		var bus_index: int = AudioServer.get_bus_index(bus_name)
		if bus_index == -1:
			AudioServer.add_bus(AudioServer.get_bus_count())
			bus_index = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, MASTER_BUS)

func _warn_missing_event(event_id: String) -> void:
	if _missing_events_warned.has(event_id):
		return
	_missing_events_warned[event_id] = true
	push_warning("AudioManager: no playable files found for event '%s'." % event_id)

func _warn_missing_path(path: String) -> void:
	if _missing_paths_warned.has(path):
		return
	_missing_paths_warned[path] = true
	push_warning("AudioManager: missing audio file '%s'." % path)
