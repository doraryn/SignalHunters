extends Node

signal connection_succeeded
signal connection_failed
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

const DEFAULT_PORT = 9876
const MAX_PLAYERS = 2

var is_multiplayer_mode := false

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_PLAYERS - 1)
	if error != OK:
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	is_multiplayer_mode = true
	print("Hosting on port %d" % port)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		connection_failed.emit()
		return error
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	is_multiplayer_mode = true
	return OK

func disconnect_game():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_multiplayer_mode = false

func is_host() -> bool:
	if not is_multiplayer_mode:
		return true
	return multiplayer.is_server()

func is_movement_player() -> bool:
	# Singleplayer: both abilities available
	if not is_multiplayer_mode:
		return true
	# Multiplayer: host (peer 1) controls movement + jump
	return multiplayer.is_server()

func is_grapple_player() -> bool:
	# Singleplayer: both abilities available
	if not is_multiplayer_mode:
		return true
	# Multiplayer: client (peer != 1) controls grapple
	return not multiplayer.is_server()

func _on_peer_connected(id: int):
	print("Player connected: %d" % id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int):
	print("Player disconnected: %d" % id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	print("Connected to server")
	connection_succeeded.emit()

func _on_connection_failed():
	print("Connection failed")
	is_multiplayer_mode = false
	connection_failed.emit()
