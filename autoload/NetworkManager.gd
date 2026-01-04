extends Node
## Network Manager - HTTP ve WebSocket yönetimi
## Singleton autoload: Network

signal request_completed(endpoint: String, result: Dictionary)
signal request_failed(endpoint: String, error: String)
signal ws_connected()
signal ws_disconnected()
signal ws_message_received(channel: String, data: Dictionary)
signal rate_limit_exceeded(retry_after: int)

var BASE_URL: String = ProjectSettings.get_setting("game_settings/server/base_url", "https://znvsyzstmxhqvdkkmgdt.supabase.co")
var WS_URL: String = ProjectSettings.get_setting("game_settings/server/ws_url", "wss://znvsyzstmxhqvdkkmgdt.supabase.co/realtime/v1")

# Rate limiting
var _request_tokens: int = 60  # 60 req/min for free tier
var _token_refill_rate: float = 1.0  # 1 token/saniye
var _last_token_update: float = 0.0
var _rate_limit_reset_time: int = 0

# Retry logic
const MAX_RETRIES = 3
const RETRY_DELAY = 2.0  # saniye

var ws_client: WebSocketPeer
var ws_connected_flag: bool = false
var ws_subscriptions: Dictionary = {}  # channel -> callback
var _initialized: bool = false

func initialize() -> void:
	if _initialized:
		return
	_initialized = true
	print("[Network] Manual initialize called")
	_setup_http()
	_setup_websocket()

func _ready() -> void:
	print("[Network] Initializing...")
	_setup_http()
	_setup_websocket()
	_last_token_update = Time.get_ticks_msec() / 1000.0


func _process(delta: float) -> void:
	_update_rate_limit_tokens(delta)
	_poll_websocket()

## Rate Limiting
func _update_rate_limit_tokens(_delta: float) -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var time_passed = current_time - _last_token_update
	
	if time_passed >= 1.0:  # Her saniye
		_request_tokens = min(_request_tokens + int(_token_refill_rate), 60)
		_last_token_update = current_time

func _can_make_request() -> bool:
	return _request_tokens > 0

## Public helper to check online status
func is_online() -> bool:
	# Consider online if websocket is connected or we have request tokens
	return ws_connected_flag or _can_make_request()

# Backwards-compatible shim: some code may call `_is_online()`
func _is_online() -> bool:
	return is_online()

func _consume_token() -> void:
	_request_tokens = max(_request_tokens - 1, 0)

## HTTP İstek Gönderme
func get_request(endpoint: String, callback: Callable = Callable()) -> void:
	_send_request(endpoint, HTTPClient.METHOD_GET, {}, callback)

func post(endpoint: String, body: Dictionary, callback: Callable = Callable()) -> void:
	_send_request(endpoint, HTTPClient.METHOD_POST, body, callback)

# Convenience wrapper: await a POST response and return the result dictionary
func post_json(endpoint: String, body: Dictionary) -> Dictionary:
	return await http_post(endpoint, body)

# Awaitable GET request
func http_get(endpoint: String) -> Dictionary:
	var holder := {"result": {}, "done": false}
	get_request(endpoint, func(result: Dictionary):
		holder["result"] = result
		holder["done"] = true
	)
	while not holder["done"]:
		await get_tree().process_frame
	return holder["result"]

# Awaitable POST request
func http_post(endpoint: String, body: Dictionary) -> Dictionary:
	var holder := {"result": {}, "done": false}
	post(endpoint, body, func(result: Dictionary):
		holder["result"] = result
		holder["done"] = true
	)
	while not holder["done"]:
		await get_tree().process_frame
	return holder["result"]

# Awaitable PUT request
func http_put(endpoint: String, body: Dictionary) -> Dictionary:
	var holder := {"result": {}, "done": false}
	put(endpoint, body, func(result: Dictionary):
		holder["result"] = result
		holder["done"] = true
	)
	while not holder["done"]:
		await get_tree().process_frame
	return holder["result"]

# Awaitable PATCH request
func http_patch(endpoint: String, body: Dictionary) -> Dictionary:
	var holder := {"result": {}, "done": false}
	patch(endpoint, body, func(result: Dictionary):
		holder["result"] = result
		holder["done"] = true
	)
	while not holder["done"]:
		await get_tree().process_frame
	return holder["result"]

func patch(endpoint: String, body: Dictionary, callback: Callable = Callable()) -> void:
	_send_request(endpoint, HTTPClient.METHOD_PATCH, body, callback)

func put(endpoint: String, body: Dictionary, callback: Callable = Callable()) -> void:
	_send_request(endpoint, HTTPClient.METHOD_PUT, body, callback)

func delete(endpoint: String, callback: Callable = Callable()) -> void:
	_send_request(endpoint, HTTPClient.METHOD_DELETE, {}, callback)

func _send_request(endpoint: String, method: int, body: Dictionary, callback: Callable, retry_count: int = 0) -> void:
	# Rate limit kontrolü
	if not _can_make_request():
		print("[Network] Rate limit exceeded")
		rate_limit_exceeded.emit(_rate_limit_reset_time)
		# Queue'ya ekle
		var method_str = "GET"
		match method:
			HTTPClient.METHOD_POST: method_str = "POST"
			HTTPClient.METHOD_PUT: method_str = "PUT"
			HTTPClient.METHOD_DELETE: method_str = "DELETE"
		
		if Queue.has_method("enqueue"):
			Queue.enqueue(method_str, endpoint, body)
		else:
			print("[Network] Error: Queue.enqueue not found")
		return
	
	_consume_token()
	
	var url = BASE_URL + endpoint
	var headers = _get_headers()
	
	var http = HTTPRequest.new()
	add_child(http)
	
	var json_body = JSON.stringify(body) if method != HTTPClient.METHOD_GET else ""
	
	http.request_completed.connect(func(result, response_code, response_headers, body_data):
		_on_request_completed(http, endpoint, method, body, result, response_code, response_headers, body_data, callback, retry_count)
	)
	
	var error = http.request(url, headers, method, json_body)
	if error != OK:
		print("[Network] Request failed to start: ", error)
		request_failed.emit(endpoint, "Failed to start request")
		http.queue_free()
		
		# Retry logic
		if retry_count < MAX_RETRIES:
			await get_tree().create_timer(RETRY_DELAY).timeout
			_send_request(endpoint, method, body, callback, retry_count + 1)

func _on_request_completed(
	http: HTTPRequest, 
	endpoint: String, 
	method: int,
	body: Dictionary,
	result: int, 
	response_code: int, 
	response_headers: PackedStringArray,
	body_data: PackedByteArray, 
	callback: Callable,
	retry_count: int
) -> void:
	http.queue_free()
	
	# Rate limit header kontrolü
	_parse_rate_limit_headers(response_headers)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("[Network] Request failed: ", endpoint)
		request_failed.emit(endpoint, "Network error")
		
		# Retry logic
		if retry_count < MAX_RETRIES:
			print("[Network] Retrying request (%d/%d)..." % [retry_count + 1, MAX_RETRIES])
			await get_tree().create_timer(RETRY_DELAY).timeout
			_send_request(endpoint, method, body, callback, retry_count + 1)
			return
		
		if callback.is_valid():
			callback.call({"success": false, "error": "Network error"})
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body_data.get_string_from_utf8())
	
	var response_data = null
	if parse_result == OK:
		response_data = json.data
	
	# 429 Rate Limit
	if response_code == 429:
		print("[Network] Rate limit exceeded by server")
		rate_limit_exceeded.emit(_rate_limit_reset_time)
		
		var method_str = "GET"
		match method:
			HTTPClient.METHOD_POST: method_str = "POST"
			HTTPClient.METHOD_PUT: method_str = "PUT"
			HTTPClient.METHOD_DELETE: method_str = "DELETE"
			
		if Queue.has_method("enqueue"):
			Queue.enqueue(method_str, endpoint, body)
		return
	
	# 401 Unauthorized - Token refresh gerekir
	if response_code == 401:
		print("[Network] Unauthorized - endpoint: %s" % endpoint)
		# Parse response body for additional info (if any)
		var _parsed_body = null
		var safe_body = ""
		if body_data and body_data.size() > 0:
			safe_body = body_data.get_string_from_utf8()
			var j = JSON.new()
			if j.parse(safe_body) == OK:
				_parsed_body = j.data
			print("[Network] 401 response body: %s" % safe_body)

		# If we have a refresh token, try to refresh and retry
		if Session and not Session.refresh_token.is_empty():
			print("[Network] Refresh token found, attempting token refresh")
			Session.refresh_access_token()
			await Session.token_refreshed
			_send_request(endpoint, method, body, callback, 0)
			return

		# No refresh token: do not force session expiration on arbitrary 401s
		# If this was an auth-related endpoint (login/register/refresh), just fail gracefully
		var auth_endpoints = [APIEndpoints.AUTH_LOGIN, APIEndpoints.AUTH_REGISTER, APIEndpoints.AUTH_REFRESH]
		if auth_endpoints.has(endpoint):
			print("[Network] 401 from auth endpoint, failing request")
			if callback.is_valid():
				callback.call({"success": false, "error": "Unauthorized"})
			return

		# Otherwise log and fail the request but do not emit session_expired here
		print("[Network] 401 without refresh token; not emitting session_expired")
		if callback.is_valid():
			callback.call({"success": false, "error": "Unauthorized"})
		return
	
	var success = response_code >= 200 and response_code < 300
	
	var err_field = null
	if not success and response_data and typeof(response_data) == TYPE_DICTIONARY and response_data.has("error"):
		err_field = response_data.get("error", null)

	var final_result = {
		"success": success,
		"code": response_code,
		"data": response_data,
		"error": err_field
	}
	
	if success:
		request_completed.emit(endpoint, final_result)
	else:
		request_failed.emit(endpoint, str(response_code))
	
	if callback.is_valid():
		callback.call(final_result)

func _parse_rate_limit_headers(headers: PackedStringArray) -> void:
	for header in headers:
		var lower_header = header.to_lower()
		if lower_header.begins_with("x-ratelimit-remaining:"):
			var remaining = header.split(":")[1].strip_edges().to_int()
			_request_tokens = remaining
		elif lower_header.begins_with("x-ratelimit-reset:"):
			var reset_time = header.split(":")[1].strip_edges().to_int()
			_rate_limit_reset_time = reset_time

func _get_headers() -> PackedStringArray:
	var headers = PackedStringArray([
		"Content-Type: application/json",
		"apikey: " + ProjectSettings.get_setting("game_settings/server/api_key", "")
	])
	
	# Authorization: prefer session access token; if not present, use configured api_key as Bearer
	var api_key = ProjectSettings.get_setting("game_settings/server/api_key", "")
	if Session and Session.access_token and not Session.access_token.is_empty():
		headers.append("Authorization: Bearer " + Session.access_token)
	elif api_key and not str(api_key).is_empty():
		# Some server endpoints (edge functions) expect an Authorization header carrying the api key
		headers.append("Authorization: Bearer " + str(api_key))
	
	return headers

## WebSocket
func connect_websocket() -> void:
	if ws_connected_flag:
		return
	
	ws_client = WebSocketPeer.new()
	var error = ws_client.connect_to_url(WS_URL)
	
	if error != OK:
		print("[Network] WS connection failed: ", error)
	else:
		print("[Network] WS connecting...")

func disconnect_websocket() -> void:
	if ws_client:
		ws_client.close()
		ws_connected_flag = false
		ws_disconnected.emit()

func ws_subscribe(channel: String, callback: Callable) -> void:
	ws_subscriptions[channel] = callback
	print("[Network] Subscribed to: ", channel)

func ws_unsubscribe(channel: String) -> void:
	ws_subscriptions.erase(channel)

func _poll_websocket() -> void:
	if not ws_client:
		return
	
	ws_client.poll()
	var state = ws_client.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_OPEN:
			if not ws_connected_flag:
				ws_connected_flag = true
				ws_connected.emit()
				print("[Network] WS connected")
			
			while ws_client.get_available_packet_count() > 0:
				var packet = ws_client.get_packet()
				var message = packet.get_string_from_utf8()
				_handle_ws_message(message)
		
		WebSocketPeer.STATE_CLOSED:
			if ws_connected_flag:
				ws_connected_flag = false
				ws_disconnected.emit()
				print("[Network] WS disconnected")

func _handle_ws_message(message: String) -> void:
	var json = JSON.new()
	var parse_result = json.parse(message)
	
	if parse_result != OK:
		print("[Network] Invalid WS message")
		return
	
	var data = json.data
	if data is Dictionary and data.has("type"):
		var channel = data.get("channel", "")
		
		if ws_subscriptions.has(channel):
			var callback = ws_subscriptions[channel]
			if callback.is_valid():
				callback.call(data.get("payload", {}))
		
		ws_message_received.emit(channel, data.get("payload", {}))

func _setup_http() -> void:
	pass  # HTTP client her request için dinamik oluşturuluyor

func _setup_websocket() -> void:
	pass  # WS isteğe göre bağlanacak

## Cleanup
func cancel_pending_requests() -> void:
	for child in get_children():
		if child is HTTPRequest:
			child.cancel_request()
			child.queue_free()
