extends Node

signal lobby_updated(lobby_data: Dictionary)
signal all_players_ready
signal game_starting

const MAX_PLAYERS := 4
const MIN_PLAYERS_TO_START := 2
const ROOM_CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var players: Dictionary = {}  # peer_id -> {name, ready}
var room_code: String = ""
var local_player_name: String = "Player"

func generate_room_code() -> String:
	var code := ""
	for i in 6:
		code += ROOM_CODE_CHARS[randi() % ROOM_CODE_CHARS.length()]
	room_code = code
	return code

@rpc("any_peer", "call_local", "reliable")
func register_player(peer_id: int, player_name: String):
	if not multiplayer.is_server():
		return
	players[peer_id] = {"name": player_name, "ready": false}
	print("LobbyManager: Player %d (%s) joined" % [peer_id, player_name])
	_broadcast_lobby_state()

@rpc("any_peer", "call_local", "reliable")
func set_player_ready(peer_id: int, is_ready: bool):
	if not multiplayer.is_server():
		return
	if peer_id in players:
		players[peer_id]["ready"] = is_ready
		_broadcast_lobby_state()
		_check_all_ready()

@rpc("authority", "call_local", "reliable")
func receive_lobby_state(state: Dictionary):
	players = state
	lobby_updated.emit(players)

@rpc("authority", "call_local", "reliable")
func notify_game_starting():
	game_starting.emit()

func remove_player(peer_id: int):
	players.erase(peer_id)
	_broadcast_lobby_state()

func host_lobby(player_name: String):
	local_player_name = player_name
	var host_id := 1
	players[host_id] = {"name": player_name, "ready": false}
	lobby_updated.emit(players)

func join_lobby(player_name: String):
	local_player_name = player_name

func on_connected_to_server():
	var my_id := multiplayer.get_unique_id()
	rpc_id(1, "register_player", my_id, local_player_name)

func send_ready(is_ready: bool):
	if not NetworkManager.is_active():
		return
	var my_id := multiplayer.get_unique_id()
	if multiplayer.is_server():
		set_player_ready(my_id, is_ready)
	else:
		if multiplayer.multiplayer_peer != null:
			rpc_id(1, "set_player_ready", my_id, is_ready)

func start_game():
	if not multiplayer.is_server():
		return
	if players.size() < 1:
		return
	notify_game_starting.rpc()

func get_player_count() -> int:
	return players.size()

func can_start() -> bool:
	return multiplayer.is_server() and players.size() >= 1

func _broadcast_lobby_state():
	receive_lobby_state.rpc(players)

func _check_all_ready():
	if players.size() < MIN_PLAYERS_TO_START:
		return
	for p in players.values():
		if not p["ready"]:
			return
	all_players_ready.emit()
