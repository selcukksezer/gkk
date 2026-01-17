extends Node
## Session Manager - Kimlik doğrulama ve oturum yönetimi
## Singleton autoload: Session

signal logged_in(player_data: Dictionary)
signal logged_out()
signal token_refreshed()
signal session_expired()
signal login_failed(error_message: String)
signal register_completed(success: bool, message: String)
signal session_status_checked(is_authenticated: bool)
# Emitted when auth token is valid but no game.users row exists for the auth user
signal profile_missing(auth_id: String)

var access_token: String = ""
var refresh_token: String = ""
var device_id: String = ""
var player_id: String = ""
var username: String = ""
var is_authenticated: bool = false

var _last_register_credentials: Dictionary = {}
var _username_email_map: Dictionary = {}
const USER_MAP_FILE = "user://user_map.json"

const AUTO_REFRESH_TOKENS: bool = false  # disable automatic token refresh on startup

func _ready() -> void:
	print("[Session] Initializing...")
	device_id = _generate_device_id()
	_load_username_email_map()

	# Only setup automatic refresh if enabled
	if AUTO_REFRESH_TOKENS:
		_setup_refresh_timer()

	# Initial session load with timeout protection
	if _load_tokens():
		print("[Session] Tokens present on disk, attempting to validate session with server.")
		is_authenticated = true
		
		# Attempt to fetch player profile from server to validate tokens
		var profile_result = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
		
		if profile_result and profile_result.get("success", false):
			# Profile fetch succeeded
			var data = profile_result.get("data", {})
			if data and data.has("id"):
				player_id = data.id
				username = data.get("username", username)
				is_authenticated = true
				State.load_player_data(data)
				print("[Session] Restored session and loaded player profile from server")
				logged_in.emit(data)
				session_status_checked.emit(true)
			else:
				print("[Session] PROFILE fetched but missing required fields. Falling back to auth user lookup. profile_result:", profile_result)
				# fall through to fallback
				is_authenticated = false
				logout()
				session_status_checked.emit(false)
		else:
			print("[Session] Profile fetch failed or returned error: %s" % profile_result)
			print("[Session] Attempting fallback: /auth/v1/user to validate token and find user record")
			# Fallback: try Supabase auth user endpoint to get auth id
			var auth_user = await Network.http_get("/auth/v1/user")
			if auth_user and auth_user.get("success", false) and auth_user.get("data", null):
				var auth_data = auth_user.get("data", {})
				var auth_id = auth_data.get("id", "")
				print("[Session] Auth user info retrieved: auth_id=%s" % auth_id)
				if auth_id != "":
					# Try to find matching game.users by auth_id
					var users_res = await Network.http_get("/rest/v1/users?select=*&auth_id=eq.%s" % auth_id)
					if users_res and users_res.get("success", false) and users_res.get("data", null) and users_res.data.size() > 0:
						var user = users_res.data[0]
						player_id = user.get("id", "")
						username = user.get("username", username)
						is_authenticated = true
						State.load_player_data(user)
						print("[Session] Restored session via userdata lookup for auth_id=%s" % auth_id)
						logged_in.emit(user)
						session_status_checked.emit(true)
					else:
						# DO NOT force logout if user table missing; keep token and surface the condition for UI to handle
						print("[Session] No game.users row found for auth_id=%s; keeping session active and emitting profile_missing" % auth_id)
						profile_missing.emit(auth_id)
						# Keep is_authenticated as true but defer loading user until resolved by UI/server
						is_authenticated = true
						session_status_checked.emit(true)
				else:
					print("[Session] Auth user had no id; cannot validate token. auth_user:", auth_user)
					logout()
					session_status_checked.emit(false)
			else:
				print("[Session] Fallback auth user fetch failed: %s" % auth_user)
				logout()
				session_status_checked.emit(false)
	else:
		print("[Session] No valid session found on startup.")
		is_authenticated = false
		# Emit session status checked false so UI can react if needed
		session_status_checked.emit(false)


func _save_username_email_map() -> void:
	var file = FileAccess.open(USER_MAP_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_username_email_map, "\t"))
		file.close()

func _load_username_email_map() -> void:
	if not FileAccess.file_exists(USER_MAP_FILE):
		return
	var file = FileAccess.open(USER_MAP_FILE, FileAccess.READ)
	if file:
		var txt = file.get_as_text()
		file.close()
		var j = JSON.new()
		if j.parse(txt) == OK:
			_username_email_map = j.data

const TOKEN_REFRESH_THRESHOLD = 300  # 5 dakika önce yenile
const TOKEN_STORAGE_KEY = "gk_tokens"
const DEVICE_ID_KEY = "gk_device_id"

var _token_expiry: int = 0
var _refresh_timer: Timer

func _setup_refresh_timer() -> void:
	_refresh_timer = Timer.new()
	_refresh_timer.wait_time = 60.0  # Her dakika kontrol et
	_refresh_timer.timeout.connect(_check_token_expiry)
	add_child(_refresh_timer)
	_refresh_timer.start()

## Register
func register(email: String, username_param: String, password: String, referral_code: String = "") -> void:
	var body = {
		"email": email,
		"username": username_param,
		"password": password,
		"device_id": device_id
	}
	
	if not referral_code.is_empty():
		body["referral_code"] = referral_code
	
	_last_register_credentials = {"email": email, "username": username_param, "password": password}
	var result = await Network.http_post(APIEndpoints.AUTH_REGISTER, body)
	_on_register_response(result)

func _on_register_response(result: Dictionary) -> void:
	if result.success:
		print("[Session] Registration successful")
		var data = result.data
		
		# Handle nested data if present (common in some API responses)
		if data.has("data") and data.data is Dictionary:
			data = data.data
			
		print("[Session] Register response data: ", data)
		if data.has("session"):
			set_tokens(data.session.access_token, data.session.refresh_token)
			player_id = data.user.id
			username = data.user.username
			is_authenticated = true
			_save_tokens()
			
			print("[Session] Registration created session - emitting logged_in")
			logged_in.emit(data.user)
			# Also notify session status checked
			session_status_checked.emit(true)
			
			# Wait one frame then force navigation
			await get_tree().process_frame
			print("[Session] Attempting direct navigation to home")
			var main_node = get_tree().root.get_node_or_null("Main")
			if main_node and main_node.has_method("show_screen"):
				main_node.call_deferred("show_screen", "home", false)
				print("[Session] Direct navigation call issued")
			
			register_completed.emit(true, "Kayıt başarılı!")
		elif data.has("user") and not data.has("session"):
			# Some auth flows return user but no session (e.g. email confirmation required)
			print("[Session] Register successful but no session (maybe email confirmation needed)")
			register_completed.emit(true, "Kayıt başarılı! Lütfen e-postanızı kontrol edin.")
		else:
			print("[Session] Register response missing session/user data: ", data)
			register_completed.emit(false, "Sunucu yanıtı geçersiz")
			# Attempt automatic login with the credentials used for registration
			if _last_register_credentials.has("email") and _last_register_credentials.has("password"):
				# Save mapping username -> email for future logins
				if _last_register_credentials.has("username"):
					_username_email_map[_last_register_credentials.username] = _last_register_credentials.email
					_save_username_email_map()
					print("[Session] Saved username->email mapping: %s -> %s" % [_last_register_credentials.username, _last_register_credentials.email])
				login(_last_register_credentials.email, _last_register_credentials.password)
	else:
		var error_msg = "Kayıt başarısız"
		if result.has("error"):
			var error_data = result.error
			if error_data is Dictionary:
				error_msg = error_data.get("message", error_msg)
			elif error_data is String:
				error_msg = error_data
		print("[Session] Registration failed: ", error_msg)
		register_completed.emit(false, error_msg)

## Login
func login(username_param: String, password: String) -> void:
	# Build login payload. Server may accept email or username; include both when possible.
	var body = {
		"password": password,
		"device_id": device_id
	}

	if username_param.find("@") >= 0:
		# Input looks like an email
		body["email"] = username_param
	else:
		# Input is username: include username field and try to resolve saved email mapping
		body["username"] = username_param
		if _username_email_map.has(username_param):
			body["email"] = _username_email_map[username_param]
		else:
			# Fallback: create a test email from username (some environments expect this)
			body["email"] = "%s@example.com" % username_param
	
	var result = await Network.http_post(APIEndpoints.AUTH_LOGIN, body)
	_on_login_response(result)
	print("[Session] Login payload: ", body)
	print("[Session] Login attempt with input: %s, resolved email: %s" % [username_param, body.get("email", "")])

func _on_login_response(result: Dictionary) -> void:
	if result.success:
		var data = result.data
		
		# Handle nested data if present (common in some API responses)
		if data.has("data") and data.data is Dictionary:
			data = data.data
			
		if data.has("session"):
			set_tokens(data.session.access_token, data.session.refresh_token)
			player_id = data.user.id
			username = data.user.username
			is_authenticated = true
			
			# State'e player data yükle
			State.load_player_data(data.user)
			
			_save_tokens()
			
			print("[Session] Login successful - emitting logged_in signal")
			logged_in.emit(data.user)
			# Also notify that session status is valid
			session_status_checked.emit(true)
			
			# Wait one frame then force navigation to ensure it happens
			await get_tree().process_frame
			print("[Session] Attempting direct navigation to home as fallback")
			var main_node = get_tree().root.get_node_or_null("Main")
			if main_node and main_node.has_method("show_screen"):
				main_node.call_deferred("show_screen", "home", false)
				print("[Session] Direct navigation call issued")
			else:
				print("[Session] WARNING: Main node not found or show_screen missing!")
			
			# Telemetry
			Telemetry.track_event("user", "login", {
				"login_method": "username",
				"user_id": player_id
			})
		else:
			print("[Session] Login response missing session data: ", data)
			login_failed.emit("Sunucu yanıtı geçersiz (Eksik oturum bilgisi)")
	else:
		var error_msg = "Giriş başarısız"
		if result.has("error"):
			var error_data = result.error
			if error_data is Dictionary:
				error_msg = error_data.get("message", error_msg)
			elif error_data is String:
				error_msg = error_data
		print("[Session] Login failed: ", error_msg)
		login_failed.emit(error_msg)

## Logout
func logout() -> void:
	access_token = ""
	refresh_token = ""
	player_id = ""
	is_authenticated = false
	
	_clear_saved_tokens()
	# Ensure session status update is propagated
	session_status_checked.emit(false)
	# Clear global state so UI updates immediately
	if State:
		State.logout()
	logged_out.emit()
	print("[Session] Logged out")

## Token Management
func set_tokens(access: String, refresh: String) -> void:
	access_token = access
	refresh_token = refresh
	_token_expiry = int(Time.get_unix_time_from_system()) + 900  # 15 dakika (varsayılan)
	_save_tokens()

func refresh_access_token() -> void:
	if refresh_token.is_empty():
		print("[Session] No refresh token available")
		session_expired.emit()
		return
	
	var body = {
		"refresh_token": refresh_token
	}
	
	var result = await Network.http_post(APIEndpoints.AUTH_REFRESH, body)
	_on_refresh_response(result)

func _on_refresh_response(result: Dictionary) -> void:
	if result.success:
		var data = result.data
		set_tokens(data.access_token, data.refresh_token)
		# After refreshing tokens, fetch player profile to initialize State
		var profile_result = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
		if profile_result.success and profile_result.data:
			State.load_player_data(profile_result.data)
			print("[Session] Player profile loaded from server after refresh")
			token_refreshed.emit()
			session_status_checked.emit(true)
		else:
			print("[Session] Failed to load player profile after refresh")
			session_expired.emit()
			logout()
			session_status_checked.emit(false)
	else:
		print("[Session] Token refresh failed")
		session_expired.emit()
		logout()
		session_status_checked.emit(false)

func refresh_profile() -> void:
	print("[Session] Manually refreshing profile...")
	var profile_result = await Network.http_get(APIEndpoints.PLAYER_PROFILE)
	if profile_result.success and profile_result.data:
		State.load_player_data(profile_result.data)
		print("[Session] Player profile refreshed manually")
		# We can optionally emit logged_in to force UI refresh, or just rely on State updates
		# logged_in.emit(profile_result.data) 
		session_status_checked.emit(true)
	else:
		print("[Session] Failed to refresh profile manually")


func _check_token_expiry() -> void:
	# Auto-refresh disabled by default per user preference; no action taken
	if not AUTO_REFRESH_TOKENS:
		return
	if not is_authenticated:
		return
	
	var current_time = Time.get_unix_time_from_system()
	var time_until_expiry = _token_expiry - current_time
	
	if time_until_expiry < TOKEN_REFRESH_THRESHOLD:
		print("[Session] Token expiring soon, refreshing...")
		refresh_access_token()

func is_token_expired() -> bool:
	return Time.get_unix_time_from_system() >= _token_expiry

## Persistence
func _save_tokens() -> void:
	var config = ConfigFile.new()
	config.set_value("session", "access_token", access_token)
	config.set_value("session", "refresh_token", refresh_token)
	config.set_value("session", "device_id", device_id)
	config.set_value("session", "player_id", player_id)
	config.set_value("session", "expiry", _token_expiry)
	
	var path = "user://session.cfg"
	var error = config.save(path)
	if error != OK:
		print("[Session] Failed to save tokens: ", error)

func _load_tokens() -> bool:
	var config = ConfigFile.new()
	var path = "user://session.cfg"
	
	var error = config.load(path)
	if error != OK:
		print("[Session] No saved session found")
		return false
	
	access_token = config.get_value("session", "access_token", "")
	refresh_token = config.get_value("session", "refresh_token", "")
	device_id = config.get_value("session", "device_id", device_id)
	player_id = config.get_value("session", "player_id", "")
	_token_expiry = config.get_value("session", "expiry", 0)
	
	var has_token = not access_token.is_empty()
	print("[Session] access_token present: %s, expiry: %d" % [has_token, _token_expiry])
	if has_token:
		print("[Session] Tokens loaded from storage (expiry ignored by policy).")
		return true
	else:
		print("[Session] No saved tokens in storage.")
		return false

func _clear_saved_tokens() -> void:
	var path = "user://session.cfg"
	var config = ConfigFile.new()
	if config.load(path) == OK:
		# Clear saved session values and write back
		config.set_value("session", "access_token", "")
		config.set_value("session", "refresh_token", "")
		config.set_value("session", "player_id", "")
		config.set_value("session", "expiry", 0)
		config.save(path)
		print("[Session] Cleared saved session file")
	else:
		# Fallback: attempt to remove file
		if FileAccess.file_exists(path):
			var ok = DirAccess.remove_absolute(path)
			if ok != OK:
				print("[Session] Failed to remove session file: ", ok)
	# Emit session status false so callers can't get stuck waiting
	session_status_checked.emit(false)

## Device ID
func _generate_device_id() -> String:
	var saved_id = _load_device_id()
	if not saved_id.is_empty():
		return saved_id
	
	# Benzersiz device ID oluştur
	var id = "%s-%s" % [
		Time.get_unix_time_from_system(),
		randi() % 999999
	]
	
	_save_device_id(id)
	return id

func _save_device_id(id: String) -> void:
	var config = ConfigFile.new()
	config.set_value("device", "id", id)
	config.save("user://device.cfg")

func _load_device_id() -> String:
	var config = ConfigFile.new()
	var error = config.load("user://device.cfg")
	if error == OK:
		return config.get_value("device", "id", "")
	return ""

## Getters
func get_player_id() -> String:
	return player_id

func get_device_id() -> String:
	return device_id

func is_logged_in() -> bool:
	return is_authenticated and not access_token.is_empty()
