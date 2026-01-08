class_name GameHTTPClient
extends RefCounted
## HTTP Client - REST API wrapper
## Handles all HTTP requests with authentication and error handling

signal request_completed(result: Dictionary)
signal request_failed(error: String)

var _http_client: HTTPRequest
var _base_url: String = ""

## Initialize HTTP client
func initialize(parent_node: Node, base_url: String) -> void:
	_base_url = base_url
	_http_client = HTTPRequest.new()
	parent_node.add_child(_http_client)
	_http_client.request_completed.connect(_on_request_completed)
	print("[HTTPClient] Initialized with base URL: %s" % base_url)

## Make GET request
func http_get(endpoint: String, headers: Dictionary = {}) -> Dictionary:
	var url = _base_url + endpoint
	var final_headers = _build_headers(headers)
	
	print("[HTTPClient] GET %s" % url)
	
	var error = _http_client.request(url, final_headers, HTTPClient.METHOD_GET)
	
	if error != OK:
		push_error("[HTTPClient] GET request failed: %s" % error)
		return {"success": false, "error": "Request failed", "code": error}
	
	# Wait for response
	var result = await request_completed
	return result

## Make POST request
func post(endpoint: String, body: Dictionary, headers: Dictionary = {}) -> Dictionary:
	var url = _base_url + endpoint
	var final_headers = _build_headers(headers)
	
	# Add content type if not present
	var has_content_type = false
	for header in final_headers:
		if header.begins_with("Content-Type:"):
			has_content_type = true
			break
	if not has_content_type:
		final_headers.append("Content-Type: application/json")
	
	var json_body = JSON.stringify(body)
	
	print("[HTTPClient] POST %s" % url)
	
	var error = _http_client.request(url, final_headers, HTTPClient.METHOD_POST, json_body)
	
	if error != OK:
		push_error("[HTTPClient] POST request failed: %s" % error)
		return {"success": false, "error": "Request failed", "code": error}
	
	var result = await request_completed
	return result

## Make PUT request
func put(endpoint: String, body: Dictionary, headers: Dictionary = {}) -> Dictionary:
	var url = _base_url + endpoint
	var final_headers = _build_headers(headers)
	
	# Add content type if not present
	var has_content_type = false
	for header in final_headers:
		if header.begins_with("Content-Type:"):
			has_content_type = true
			break
	if not has_content_type:
		final_headers.append("Content-Type: application/json")
	
	var json_body = JSON.stringify(body)
	
	print("[HTTPClient] PUT %s" % url)
	
	var error = _http_client.request(url, final_headers, HTTPClient.METHOD_PUT, json_body)
	
	if error != OK:
		push_error("[HTTPClient] PUT request failed: %s" % error)
		return {"success": false, "error": "Request failed", "code": error}
	
	var result = await request_completed
	return result

## Make DELETE request
func delete(endpoint: String, headers: Dictionary = {}) -> Dictionary:
	var url = _base_url + endpoint
	var final_headers = _build_headers(headers)
	
	print("[HTTPClient] DELETE %s" % url)
	
	var error = _http_client.request(url, final_headers, HTTPClient.METHOD_DELETE)
	
	if error != OK:
		push_error("[HTTPClient] DELETE request failed: %s" % error)
		return {"success": false, "error": "Request failed", "code": error}
	
	var result = await request_completed
	return result

## Build headers with authentication
func _build_headers(custom_headers: Dictionary = {}) -> PackedStringArray:
	var headers = PackedStringArray()
	
	# Add authentication token if available
	if Session and Session.access_token != "":
		headers.append("Authorization: Bearer %s" % Session.access_token)
	
	# Add API key header (useful for Supabase REST endpoints)
	var api_key = ProjectSettings.get_setting("game_settings/server/api_key", "")
	if api_key and not str(api_key).is_empty():
		headers.append("apikey: %s" % str(api_key))

	# Prefer representation for REST inserts (helpful to get inserted row back)
	headers.append("Prefer: return=representation")

	# Add device ID
	if Session and Session.device_id != "":
		headers.append("X-Device-ID: %s" % Session.device_id)
	
	# Add custom headers
	for key in custom_headers:
		headers.append("%s: %s" % [key, custom_headers[key]])
	
	return headers

## Handle request completion
func _on_request_completed(result_code: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	print("[HTTPClient] Request completed - Result: %d, Response: %d" % [result_code, response_code])
	
	var response_dict = {
		"success": false,
		"result_code": result_code,
		"response_code": response_code,
		"data": null,
		"error": null
	}
	
	# Parse body
	if body.size() > 0:
		var json_str = body.get_string_from_utf8()
		var json = JSON.new()
		var parse_result = json.parse(json_str)
		
		if parse_result == OK:
			response_dict["data"] = json.data
		else:
			print("[HTTPClient] Failed to parse JSON response")
			response_dict["error"] = "Failed to parse response"
	
	# Check response code
	if response_code >= 200 and response_code < 300:
		response_dict["success"] = true
	else:
		response_dict["success"] = false
		
		# Extract error message
		if response_dict["data"] and response_dict["data"] is Dictionary:
			response_dict["error"] = response_dict["data"].get("message", "Unknown error")
		else:
			response_dict["error"] = "HTTP %d" % response_code
		
		print("[HTTPClient] Request failed: %s" % response_dict["error"])
	
	# Handle specific error codes
	match response_code:
		401:  # Unauthorized
			print("[HTTPClient] Unauthorized - token may be expired")
			# Only emit session_expired if we actually have a refresh token to attempt renewing
			if Session and not Session.refresh_token.is_empty():
				Session.session_expired.emit()
		403:  # Forbidden
			print("[HTTPClient] Forbidden")
		404:  # Not Found
			print("[HTTPClient] Resource not found")
		429:  # Too Many Requests
			print("[HTTPClient] Rate limited")
		500, 502, 503, 504:  # Server errors
			print("[HTTPClient] Server error")
	
	request_completed.emit(response_dict)

## Cancel ongoing request
func cancel() -> void:
	if _http_client:
		_http_client.cancel_request()
		print("[HTTPClient] Request cancelled")
