extends Node
## Telemetry Client - Analytics event tracking
## Singleton autoload: Telemetry

const TELEMETRY_ENDPOINT = "/api/v1/telemetry/events"
const BATCH_SIZE = 10
const BATCH_INTERVAL = 30.0  # seconds

var _event_queue: Array = []
var _batch_timer: Timer
var _session_id: String

func _ready() -> void:
	# Telemetry temporarily disabled to avoid noisy runtime errors
	return
	_session_id = _generate_session_id()
	
	# Create batch timer
	_batch_timer = Timer.new()
	_batch_timer.wait_time = BATCH_INTERVAL
	_batch_timer.timeout.connect(_flush_events)
	add_child(_batch_timer)
	_batch_timer.start()
	
	# Track session start
	track_event("session_start", {
		"platform": OS.get_name(),
		"device_model": OS.get_model_name(),
		"screen_size": "%dx%d" % [
			DisplayServer.screen_get_size().x,
			DisplayServer.screen_get_size().y
		]
	})

func _exit_tree() -> void:
	# Track session end and flush
	track_event("session_end", {
		"duration": Time.get_ticks_msec() / 1000.0
	})
	_flush_events()

## Track event (category.subcategory.action format)
func track_event(category: String, action_or_props: Variant, properties: Dictionary = {}) -> void:
	# Backwards-compatible: second argument may be action (String) or properties (Dictionary)
	var action: String = ""
	if typeof(action_or_props) == TYPE_DICTIONARY:
		properties = action_or_props
	else:
		action = str(action_or_props)

	var event_name = category if action == "" else category + "." + action

	var event = {
		"event": event_name,
		"timestamp": Time.get_datetime_string_from_system(),
		"session_id": _session_id,
		"user_id": Session.player_id if Session.is_authenticated else "",
		"properties": properties
	}
	
	_event_queue.append(event)
	
	# Flush if batch size reached
	if _event_queue.size() >= BATCH_SIZE:
		_flush_events()

## Quick track functions
func track_screen(screen_name: String) -> void:
	track_event("ui", "screen_view", {"screen": screen_name})

func track_button_click(button_name: String, screen: String = "") -> void:
	track_event("ui", "button_click", {"button": button_name, "screen": screen})

## Economy events
func track_gold_earned(amount: int, source: String) -> void:
	track_event("economy.gold", "earned", {
		"amount": amount,
		"source": source,
		"balance_after": State.gold
	})

func track_gold_spent(amount: int, sink: String) -> void:
	track_event("economy.gold", "spent", {
		"amount": amount,
		"sink": sink,
		"balance_after": State.gold
	})

func track_gem_spent(amount: int, category: String) -> void:
	track_event("economy.gem", "spent", {
		"amount": amount,
		"category": category,
		"balance_after": State.gems
	})

## Progression events
func track_level_up(old_level: int, new_level: int) -> void:
	track_event("progression", "level_up", {
		"old_level": old_level,
		"new_level": new_level,
		"total_playtime": Time.get_ticks_msec() / 1000.0
	})

func track_quest_completed(quest_id: String, difficulty: String, duration: int) -> void:
	track_event("progression.quest", "completed", {
		"quest_id": quest_id,
		"quest_difficulty": difficulty,
		"duration": duration
	})

## Combat events
func track_pvp_initiated(target_id: String, power_diff: int) -> void:
	track_event("combat.pvp", "initiated", {
		"target_id": target_id,
		"power_diff": power_diff,
		"attacker_energy": State.current_energy
	})

func track_pvp_completed(target_id: String, outcome: String, gold_change: int) -> void:
	track_event("combat.pvp", "completed", {
		"target_id": target_id,
		"outcome": outcome,
		"gold_change": gold_change,
		"hospital_time": State.hospital_release_time
	})

## Social events
func track_guild_joined(guild_id: String, guild_size: int) -> void:
	track_event("social.guild", "joined", {
		"guild_id": guild_id,
		"guild_size": guild_size
	})

func track_chat_message_sent(channel: String, message_length: int) -> void:
	track_event("social.chat", "message_sent", {
		"channel": channel,
		"message_length": message_length
	})

## Monetization events
func track_purchase_initiated(package_id: String, price_usd: float) -> void:
	track_event("monetization.purchase", "initiated", {
		"package_id": package_id,
		"price_usd": price_usd
	})

func track_purchase_completed(package_id: String, price_usd: float, first_purchase: bool) -> void:
	track_event("monetization.purchase", "completed", {
		"package_id": package_id,
		"price_usd": price_usd,
		"first_purchase": first_purchase
	})

## Technical events
func track_error(error_type: String, message: String, context: Dictionary = {}) -> void:
	track_event("technical", "error", {
		"error_type": error_type,
		"message": message,
		"context": context
	})
func track_purchase(item_id: String, currency: String, amount: float, quantity: int = 1) -> void:
	track_event("purchase", {
		"item_id": item_id,
		"currency": currency,
		"amount": amount,
		"quantity": quantity
	})

## Track quest
func track_quest(action: String, quest_id: String, details: Dictionary = {}) -> void:
	var properties = {
		"action": action,  # started, completed, failed, abandoned
		"quest_id": quest_id
	}
	properties.merge(details)
	track_event("quest", properties)

## Track PvP
func track_pvp(action: String, opponent_id: String, outcome: String = "", details: Dictionary = {}) -> void:
	var properties = {
		"action": action,  # attack, defend, outcome
		"opponent_id": opponent_id,
		"outcome": outcome
	}
	properties.merge(details)
	track_event("pvp", properties)

## Track potion usage
func track_potion_usage(potion_id: String, result: String, details: Dictionary = {}) -> void:
	var properties = {
		"potion_id": potion_id,
		"result": result,  # consumed, overdose, failed
		"current_tolerance": State.tolerance,
		"current_energy": State.current_energy
	}
	properties.merge(details)
	track_event("potion_usage", properties)

## Track market activity
func track_market(action: String, item_id: String, details: Dictionary = {}) -> void:
	var properties = {
		"action": action,  # buy, sell, list, cancel
		"item_id": item_id
	}
	properties.merge(details)
	track_event("market", properties)

## Track login/logout
func track_auth(action: String, method: String = "") -> void:
	track_event("auth", {
		"action": action,  # login, logout, register
		"method": method   # email, guest, social
	})

## Flush events to server
func _flush_events() -> void:
	# Telemetry flush disabled in development to avoid network calls
	return

## Generate session ID
func _generate_session_id() -> String:
	return "%d_%s" % [
		Time.get_unix_time_from_system(),
		str(randi()).md5_text().substr(0, 12)
	]

func _on_telemetry_post_completed(result: Dictionary) -> void:
	if result.get("success", false):
		print("[Telemetry] Flushed successfully")
		_event_queue.clear()
	else:
		print("[Telemetry] Flush failed, requeueing")
		for event in _event_queue:
			Queue.enqueue("POST", TELEMETRY_ENDPOINT, {"events": [event]}, -1)
		_event_queue.clear()
