extends Node

signal connected_to_server
signal server_disconnected
signal peer_joined(id: int)
signal peer_left(id: int)
signal connection_failed

const DEFAULT_PORT := 9080
const MAX_PLAYERS := 4

var _peer: WebSocketMultiplayerPeer = null
var is_server_mode := false

func host_game(port: int = DEFAULT_PORT) -> Error:
	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_server(port)
	if err != OK:
		push_error("NetworkManager: Failed to create server on port %d: %s" % [port, error_string(err)])
		_peer = null
		return err
	multiplayer.multiplayer_peer = _peer
	is_server_mode = true
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("NetworkManager: Server started on port %d" % port)
	return OK

func join_game(url: String) -> Error:
	_peer = WebSocketMultiplayerPeer.new()
	var err := _peer.create_client(url)
	if err != OK:
		push_error("NetworkManager: Failed to connect to %s: %s" % [url, error_string(err)])
		_peer = null
		return err
	multiplayer.multiplayer_peer = _peer
	is_server_mode = false
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("NetworkManager: Connecting to %s" % url)
	return OK

func disconnect_all():
	if _peer != null:
		_peer.close()
		_peer = null
	if multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.disconnect(_on_peer_connected)
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	multiplayer.multiplayer_peer = null
	is_server_mode = false

func is_active() -> bool:
	return _peer != null

func get_peer_count() -> int:
	if _peer == null:
		return 0
	return multiplayer.get_peers().size()

func _on_peer_connected(id: int):
	peer_joined.emit(id)

func _on_peer_disconnected(id: int):
	peer_left.emit(id)

func _on_connected_to_server():
	connected_to_server.emit()

func _on_connection_failed():
	connection_failed.emit()

func _on_server_disconnected():
	server_disconnected.emit()
