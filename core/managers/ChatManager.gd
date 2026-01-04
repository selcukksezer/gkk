extends Node
## Chat Manager
## Multi-channel chat system with profanity filter, rate limiting, and message history

signal message_received(channel: String, message: Dictionary)
signal message_sent(channel: String, message: String)
signal channel_history_loaded(channel: String, messages: Array)
signal player_muted(player_id: String, duration: int)
signal player_unmuted(player_id: String)

const MAX_MESSAGE_LENGTH = 200
const RATE_LIMIT_SECONDS = 2
const MESSAGE_HISTORY_SIZE = 100

# Chat channels
enum Channel {
	GLOBAL,
	GUILD,
	DM,
	TRADE,
	SYSTEM
}

# Channel names
const CHANNEL_NAMES = {
	Channel.GLOBAL: "global",
	Channel.GUILD: "guild",
	Channel.DM: "dm",
	Channel.TRADE: "trade",
	Channel.SYSTEM: "system"
}

# Profanity filter - Turkish and English bad words
const PROFANITY_LIST = [
	"fuck", "shit", "ass", "damn", "bitch", "cunt", "dick", "pussy",
	"amk", "aq", "orospu", "piç", "sik", "götüne", "ananı", "amına",
	"yarrak", "taşak", "göt", "mal", "salak", "aptal", "gerizekalı"
]

# Message history by channel
var message_history: Dictionary = {}
var last_message_time: float = 0.0
var muted_players: Dictionary = {}

func _ready() -> void:
	# Initialize message history for each channel
	for channel_id in CHANNEL_NAMES.values():
		message_history[channel_id] = []
	
	# Connect to WebSocket
	if Network.ws_client:
		Network.ws_client.message_received.connect(_on_websocket_message)
	
	# Connect to state updates
	State.connect("player_updated", _on_player_updated)

func send_message(channel: String, content: String, recipient_id: String = "") -> Dictionary:
	"""Send a message to a channel"""
	# Validate rate limit
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_message_time < RATE_LIMIT_SECONDS:
		return {
			"success": false,
			"error": "Please wait before sending another message"
		}
	
	# Check if muted
	if is_player_muted(State.player_data.get("id", "")):
		return {
			"success": false,
			"error": "You are muted"
		}
	
	# Validate content
	content = content.strip_edges()
	if content.is_empty():
		return {"success": false, "error": "Message cannot be empty"}
	
	if content.length() > MAX_MESSAGE_LENGTH:
		return {"success": false, "error": "Message too long"}
	
	# Filter profanity
	var filtered_content = filter_profanity(content)
	
	# Prepare message data
	var message_data = {
		"channel": channel,
		"content": filtered_content,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Add recipient for DM
	if channel == "dm" and not recipient_id.is_empty():
		message_data["recipient_id"] = recipient_id
	
	# Send to backend via WebSocket
	var response = await Network.ws_client.send_message("chat_message", message_data)
	
	if response.success:
		last_message_time = current_time
		message_sent.emit(channel, filtered_content)
		
		# Add to local history
		_add_to_history(channel, {
			"sender_id": State.player_data.get("id"),
			"sender_name": State.player_data.get("username"),
			"content": filtered_content,
			"timestamp": message_data.timestamp
		})
	
	return response

func load_channel_history(channel: String, _limit: int = 50) -> void:
	"""Load message history for a channel"""
	var response = await Network.http_get("/chat/history")
	
	if response.success:
		var messages = response.data.get("messages", [])
		message_history[channel] = messages
		channel_history_loaded.emit(channel, messages)

func filter_profanity(text: String) -> String:
	"""Filter profanity from text"""
	var filtered = text
	var lower_text = text.to_lower()
	
	for bad_word in PROFANITY_LIST:
		if bad_word in lower_text:
			var replacement = "*" * bad_word.length()
			# Case-insensitive replace
			var regex = RegEx.new()
			regex.compile("(?i)" + bad_word)
			filtered = regex.sub(filtered, replacement, true)
	
	return filtered

func is_profanity(text: String) -> bool:
	"""Check if text contains profanity"""
	var lower_text = text.to_lower()
	for bad_word in PROFANITY_LIST:
		if bad_word in lower_text:
			return true
	return false

func mute_player(player_id: String, duration_seconds: int = 300) -> Dictionary:
	"""Mute a player (admin/moderator only)"""
	var response = await Network.http_post("/chat/mute", {
		"player_id": player_id,
		"duration": duration_seconds
	})
	
	if response.success:
		muted_players[player_id] = Time.get_unix_time_from_system() + duration_seconds
		player_muted.emit(player_id, duration_seconds)
	
	return response

func unmute_player(player_id: String) -> Dictionary:
	"""Unmute a player"""
	var response = await Network.http_post("/chat/unmute", {
		"player_id": player_id
	})
	
	if response.success:
		muted_players.erase(player_id)
		player_unmuted.emit(player_id)
	
	return response

func is_player_muted(player_id: String) -> bool:
	"""Check if a player is muted"""
	if not muted_players.has(player_id):
		return false
	
	var unmute_time = muted_players[player_id]
	var current_time = Time.get_unix_time_from_system()
	
	if current_time >= unmute_time:
		muted_players.erase(player_id)
		return false
	
	return true

func get_mute_remaining(player_id: String) -> int:
	"""Get remaining mute time in seconds"""
	if not is_player_muted(player_id):
		return 0
	
	var unmute_time = muted_players[player_id]
	var current_time = Time.get_unix_time_from_system()
	return max(0, int(unmute_time - current_time))

func get_channel_messages(channel: String, limit: int = 50) -> Array:
	"""Get local message history for a channel"""
	var messages = message_history.get(channel, [])
	
	if messages.size() > limit:
		return messages.slice(messages.size() - limit, messages.size())
	
	return messages

func clear_channel_history(channel: String) -> void:
	"""Clear local message history for a channel"""
	message_history[channel] = []

func block_player(player_id: String) -> Dictionary:
	"""Block a player from sending DMs"""
	var response = await Network.http_post("/chat/block", {
		"player_id": player_id
	})
	
	if response.success:
		# Update local blocked list
		if not State.player_data.has("blocked_players"):
			State.player_data["blocked_players"] = []
		
		if player_id not in State.player_data.blocked_players:
			State.player_data.blocked_players.append(player_id)
	
	return response

func unblock_player(player_id: String) -> Dictionary:
	"""Unblock a player"""
	var response = await Network.http_post("/chat/unblock", {
		"player_id": player_id
	})
	
	if response.success:
		# Update local blocked list
		if State.player_data.has("blocked_players"):
			State.player_data.blocked_players.erase(player_id)
	
	return response

func is_player_blocked(player_id: String) -> bool:
	"""Check if a player is blocked"""
	if not State.player_data.has("blocked_players"):
		return false
	
	return player_id in State.player_data.blocked_players

func report_message(message_id: String, reason: String) -> Dictionary:
	"""Report an inappropriate message"""
	var response = await Network.http_post("/chat/report", {
		"message_id": message_id,
		"reason": reason
	})
	return response if response else {}

func get_dm_conversations() -> Array:
	"""Get list of DM conversations"""
	var response = await Network.http_get("/chat/conversations")
	
	if response.success:
		return response.data.get("conversations", [])
	return []

func _add_to_history(channel: String, message: Dictionary) -> void:
	"""Add message to local history"""
	if not message_history.has(channel):
		message_history[channel] = []
	
	message_history[channel].append(message)
	
	# Limit history size
	if message_history[channel].size() > MESSAGE_HISTORY_SIZE:
		message_history[channel].pop_front()

func _on_websocket_message(event_type: String, data: Dictionary) -> void:
	"""Handle incoming WebSocket messages"""
	if event_type == "chat_message":
		var channel = data.get("channel", "")
		var sender_id = data.get("sender_id", "")
		
		# Check if sender is blocked
		if is_player_blocked(sender_id):
			return
		
		# Add to history
		_add_to_history(channel, data)
		
		# Emit signal
		message_received.emit(channel, data)
	
	elif event_type == "player_muted":
		var player_id = data.get("player_id", "")
		var duration = data.get("duration", 0)
		muted_players[player_id] = Time.get_unix_time_from_system() + duration
		player_muted.emit(player_id, duration)
	
	elif event_type == "player_unmuted":
		var player_id = data.get("player_id", "")
		muted_players.erase(player_id)
		player_unmuted.emit(player_id)

func _on_player_updated() -> void:
	"""Handle player data updates"""
	# Update muted status if needed
	if State.player_data.has("muted_until"):
		var muted_until = State.player_data.muted_until
		if muted_until > Time.get_unix_time_from_system():
			var player_id = State.player_data.get("id", "")
			muted_players[player_id] = muted_until
