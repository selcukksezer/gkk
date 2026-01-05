extends Control
## Chat Panel
## Global chat, Guild chat, DM, Trade channels

@onready var channel_tabs = $ChannelTabs
@onready var global_chat = $ChannelTabs/Global/ScrollContainer/VBoxContainer
@onready var guild_chat = $ChannelTabs/Guild/ScrollContainer/VBoxContainer
@onready var dm_chat = $ChannelTabs/DM/ScrollContainer/VBoxContainer
@onready var trade_chat = $ChannelTabs/Trade/ScrollContainer/VBoxContainer

@onready var message_input = $MessagePanel/MessageInput
@onready var send_button = $MessagePanel/SendButton

var _current_channel: String = "global"
var _message_scene = preload("res://scenes/prefabs/ChatMessage.tscn")

# Rate limiting
var _last_message_time: int = 0
const MESSAGE_COOLDOWN = 2  # seconds

func _ready() -> void:
	# Connect signals
	send_button.pressed.connect(_on_send_pressed)
	message_input.text_submitted.connect(_on_message_submitted)
	channel_tabs.tab_changed.connect(_on_channel_changed)
	
	# Subscribe to WebSocket channels
	Network.ws_subscribe("chat:global", _on_chat_message)
	Network.ws_subscribe("chat:guild:" + State.guild_id, _on_chat_message)
	Network.ws_subscribe("chat:dm:" + Session.player_id, _on_chat_message)
	Network.ws_subscribe("chat:trade", _on_chat_message)

func _on_channel_changed(tab_index: int) -> void:
	var channels = ["global", "guild", "dm", "trade"]
	_current_channel = channels[tab_index]

func _on_send_pressed() -> void:
	_send_message()

func _on_message_submitted(_text: String) -> void:
	_send_message()

func _send_message() -> void:
	var message = message_input.text.strip_edges()
	
	if message.is_empty():
		return
	
	# Check rate limit
	var current_time = Time.get_unix_time_from_system()
	if current_time - _last_message_time < MESSAGE_COOLDOWN:
		print("[Chat] Message cooldown active")
		return
	
	# Check length
	if message.length() > 200:
		print("[Chat] Message too long")
		return
	
	# Check profanity (basic filter)
	if _contains_profanity(message):
		print("[Chat] Message contains profanity")
		return
	
	var body = {
		"channel": _current_channel,
		"message": message
	}
	
	var result = await Network.http_post("/chat/send", body)
	_on_message_sent(result)
	
	# Track message
	Telemetry.track_chat_message_sent(_current_channel, message.length())
	
	# Update rate limit
	_last_message_time = current_time
	
	# Clear input
	message_input.text = ""

func _on_message_sent(result: Dictionary) -> void:
	if result.success:
		print("[Chat] Message sent")
	else:
		print("[Chat] Failed to send message: ", result.get("error", ""))

func _on_chat_message(data: Dictionary) -> void:
	var channel = data.get("channel", "")
	var sender = data.get("sender", "")
	var message = data.get("message", "")
	var timestamp = data.get("timestamp", "")
	
	# Add message to appropriate chat
	var chat_container: VBoxContainer
	match channel:
		"global":
			chat_container = global_chat
		"guild":
			chat_container = guild_chat
		"dm":
			chat_container = dm_chat
		"trade":
			chat_container = trade_chat
		_:
			return
	
	var message_node = _message_scene.instantiate()
	chat_container.add_child(message_node)
	message_node.set_message(sender, message, timestamp)
	
	# Scroll to bottom
	await get_tree().process_frame
	var scroll = chat_container.get_parent().get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _contains_profanity(text: String) -> bool:
	# TODO: Implement profanity filter
	# For now, basic blacklist
	var blacklist = ["fuck", "shit", "damn"]
	var lower_text = text.to_lower()
	
	for word in blacklist:
		if lower_text.contains(word):
			return true
	
	return false
