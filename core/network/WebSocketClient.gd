class_name WebSocketClient
extends RefCounted
## WebSocket Client - Real-time communication wrapper
## Handles WebSocket connections for live updates (PvP, market, guild chat)

signal connected()
signal disconnected()
signal connection_error(error: String)
signal message_received(data: Dictionary)

var _ws_client: WebSocketPeer
var _url: String = ""
var _is_connected: bool = false
var _reconnect_attempts: int = 0
var _max_reconnect_attempts: int = 5
var _reconnect_delay: float = 2.0

## Initialize WebSocket client
func initialize(url: String) -> void:
	_url = url
	_ws_client = WebSocketPeer.new()
	print("[WebSocketClient] Initialized with URL: %s" % url)

## Connect to WebSocket server
func connect_to_server() -> void:
	if _is_connected:
		print("[WebSocketClient] Already connected")
		return
	
	print("[WebSocketClient] Connecting to %s" % _url)
	
	var headers = PackedStringArray()
	if Session.access_token != "":
		headers.append("Authorization: Bearer %s" % Session.access_token)
	
	var error = _ws_client.connect_to_url(_url, headers)
	
	if error != OK:
		push_error("[WebSocketClient] Failed to connect: %s" % error)
		connection_error.emit("Failed to connect")
		_schedule_reconnect()
		return

## Disconnect from server
func disconnect_from_server() -> void:
	if not _is_connected:
		return
	
	print("[WebSocketClient] Disconnecting")
	_ws_client.close()
	_is_connected = false
	disconnected.emit()

## Poll for messages (call in _process)
func poll() -> void:
	if not _ws_client:
		return
	
	_ws_client.poll()
	
	var state = _ws_client.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_CONNECTING:
			pass  # Still connecting
		
		WebSocketPeer.STATE_OPEN:
			if not _is_connected:
				_is_connected = true
				_reconnect_attempts = 0
				print("[WebSocketClient] Connected successfully")
				connected.emit()
			
			# Receive messages
			while _ws_client.get_available_packet_count() > 0:
				var packet = _ws_client.get_packet()
				var message = packet.get_string_from_utf8()
				_handle_message(message)
		
		WebSocketPeer.STATE_CLOSING:
			pass  # Closing connection
		
		WebSocketPeer.STATE_CLOSED:
			if _is_connected:
				_is_connected = false
				var close_code = _ws_client.get_close_code()
				var close_reason = _ws_client.get_close_reason()
				print("[WebSocketClient] Connection closed: %d - %s" % [close_code, close_reason])
				disconnected.emit()
				
				# Attempt reconnect
				if _reconnect_attempts < _max_reconnect_attempts:
					_schedule_reconnect()

## Send message to server
func send_message(data: Dictionary) -> void:
	if not _is_connected:
		push_error("[WebSocketClient] Not connected, cannot send message")
		return
	
	var json_str = JSON.stringify(data)
	var error = _ws_client.send_text(json_str)
	
	if error != OK:
		push_error("[WebSocketClient] Failed to send message: %s" % error)

## Send ping
func send_ping() -> void:
	send_message({"type": "ping", "timestamp": Time.get_unix_time_from_system()})

## Handle incoming message
func _handle_message(message: String) -> void:
	var json = JSON.new()
	var parse_result = json.parse(message)
	
	if parse_result != OK:
		push_error("[WebSocketClient] Failed to parse message: %s" % message)
		return
	
	var data = json.data
	
	if not data is Dictionary:
		push_error("[WebSocketClient] Invalid message format")
		return
	
	var msg_type = data.get("type", "")
	
	match msg_type:
		"ping":
			# Respond with pong
			send_message({"type": "pong", "timestamp": Time.get_unix_time_from_system()})
		
		"pong":
			# Ping response
			pass
		
		"market_update":
			# Market price update
			message_received.emit(data)
		
		"pvp_attack":
			# PvP attack notification
			message_received.emit(data)
		
		"guild_message":
			# Guild chat message
			message_received.emit(data)
		
		"notification":
			# General notification
			message_received.emit(data)
		
		_:
			# Unknown message type
			print("[WebSocketClient] Unknown message type: %s" % msg_type)
			message_received.emit(data)

## Schedule reconnect attempt
func _schedule_reconnect() -> void:
	_reconnect_attempts += 1
	
	if _reconnect_attempts > _max_reconnect_attempts:
		push_error("[WebSocketClient] Max reconnect attempts reached")
		connection_error.emit("Max reconnect attempts reached")
		return
	
	print("[WebSocketClient] Scheduling reconnect attempt %d/%d in %.1fs" % [_reconnect_attempts, _max_reconnect_attempts, _reconnect_delay])
	
	# Schedule reconnect (would need a Timer in real implementation)
	await Engine.get_main_loop().create_timer(_reconnect_delay).timeout
	connect_to_server()

## Check if connected
func is_ws_connected() -> bool:
	return _is_connected

## Get connection state
func get_state() -> WebSocketPeer.State:
	if _ws_client:
		return _ws_client.get_ready_state()
	return WebSocketPeer.STATE_CLOSED
