extends Control

@onready var main_buttons: VBoxContainer = $MainButtons
@onready var host_panel: VBoxContainer = $HostPanel
@onready var join_panel: VBoxContainer = $JoinPanel
@onready var ip_input: LineEdit = $JoinPanel/IPInput
@onready var host_ip_label: Label = $HostPanel/IPLabel
@onready var host_status_label: Label = $HostPanel/StatusLabel
@onready var join_status_label: Label = $JoinPanel/StatusLabel

func _ready():
	$Music.play()
	_show_main()
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	

func _show_main():
	main_buttons.visible = true
	host_panel.visible = false
	join_panel.visible = false

func _on_singleplayer_pressed():
	NetworkManager.is_multiplayer_mode = false
	_start_game()

func _on_host_pressed():
	main_buttons.visible = false
	host_panel.visible = true
	var error = NetworkManager.host_game()
	if error != OK:
		host_status_label.text = "Failed to create server!"
		return
	# Show local IPs so the host can share them
	var ips = _get_local_ips()
	host_ip_label.text = "Share this IP with Player 2:\n" + "\n".join(ips)
	host_status_label.text = "Waiting for Player 2..."

func _on_join_pressed():
	main_buttons.visible = false
	join_panel.visible = true
	join_status_label.text = "Enter the host's IP address"

func _on_connect_pressed():
	var address = ip_input.text.strip_edges()
	if address.is_empty():
		address = "localhost"
	join_status_label.text = "Connecting to %s..." % address
	var error = NetworkManager.join_game(address)
	if error != OK:
		join_status_label.text = "Failed to connect!"

func _on_back_pressed():
	NetworkManager.disconnect_game()
	_show_main()

func _on_player_connected(_id: int):
	# Host sees a client joined — start game for everyone
	if NetworkManager.is_host():
		_start_game.rpc()

func _on_connection_succeeded():
	join_status_label.text = "Connected! Starting game..."

func _on_connection_failed():
	join_status_label.text = "Connection failed. Try again."

@rpc("authority", "call_local", "reliable")
func _start_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _get_local_ips() -> Array[String]:
	var ips: Array[String] = []
	for ip in IP.get_local_addresses():
		# Filter to likely LAN addresses
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			ips.append(ip)
	if ips.is_empty():
		ips.append("localhost")
	return ips
