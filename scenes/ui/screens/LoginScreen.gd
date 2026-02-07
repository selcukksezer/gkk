extends Control
## Login Screen
## Handles user authentication (login/register)

@onready var username_input = $CenterContainer/MarginContainer/VBoxContainer/UsernameInput
@onready var password_input = $CenterContainer/MarginContainer/VBoxContainer/PasswordInput
@onready var status_label = $CenterContainer/MarginContainer/VBoxContainer/StatusLabel
@onready var remember_check = $CenterContainer/MarginContainer/VBoxContainer/RememberCheck
@onready var login_button = $CenterContainer/MarginContainer/VBoxContainer/LoginButton
@onready var register_button = $CenterContainer/MarginContainer/VBoxContainer/RegisterButton

var _loading: bool = false
const CREDENTIALS_FILE = "user://login_credentials.json"
const REGISTER_DIALOG_SCENE = preload("res://scenes/ui/dialogs/RegisterDialog.tscn")

func _ready() -> void:
	# Connect signals
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	
	Session.logged_in.connect(_on_logged_in)
	Session.login_failed.connect(_on_login_failed)
	
	# Load remembered credentials
	_load_credentials()
	
	# Clear status
	status_label.text = ""
	
	# Track screen view
	Telemetry.track_screen("login")

func _on_login_pressed() -> void:
	if _loading:
		return
	
	var username = username_input.text.strip_edges()
	var password = password_input.text
	
	# Validation
	if username.is_empty():
		status_label.text = "Kullanıcı adı gerekli"
		return
	
	if password.is_empty():
		status_label.text = "Şifre gerekli"
		return
	
	if password.length() < 8:
		status_label.text = "Şifre en az 8 karakter olmalı"
		return
	
	# Clear status
	status_label.text = ""
	_loading = true
	login_button.disabled = true
	login_button.text = "Giriş yapılıyor..."
	
	# Track attempt
	Telemetry.track_event("user", "login_attempt", {"username": username})
	
	# Attempt login
	Session.login(username, password)

func _on_register_pressed() -> void:
	if _loading:
		return
	
	# Open register dialog in a separate window
	var register_dialog = REGISTER_DIALOG_SCENE.instantiate()
	add_child(register_dialog)
	
	# Connect to dialog closed signal to handle registration completion
	register_dialog.closed.connect(_on_register_dialog_closed)
	
	# Track dialog open
	Telemetry.track_event("user", "register_dialog_opened", {})

func _on_logged_in(player_data: Dictionary) -> void:
	_loading = false
	login_button.disabled = false
	login_button.text = "Giriş Yap"
	print("[LoginScreen] Login successful, transitioning to main menu...")
	
	# Save or clear credentials based on remember check
	if remember_check.button_pressed:
		_save_credentials(username_input.text, password_input.text)
	else:
		_clear_credentials()
	
	# Track success
	Telemetry.track_event("user", "login_success", {
		"user_id": player_data.get("id", ""),
		"level": player_data.get("level", 1)
	})
	
	# Transition to main menu
	Scenes.change_scene("main")

func _on_login_failed(error_message: String) -> void:
	_loading = false
	login_button.disabled = false
	login_button.text = "Giriş Yap"
	
	status_label.add_theme_color_override("font_color", Color.RED)
	status_label.text = error_message
	
	# Track failure
	Telemetry.track_event("user", "login_failed", {
		"reason": error_message
	})

func _on_register_dialog_closed(result: Variant) -> void:
	# Dialog closed, check if registration was successful
	# If successful, user will be auto-logged in via Session.logged_in signal
	if result is Dictionary and result.get("success", false):
		status_label.add_theme_color_override("font_color", Color.GREEN)
		status_label.text = "Kayıt başarılı! Giriş yapılıyor..."

func _is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

func _load_credentials() -> void:
	if FileAccess.file_exists(CREDENTIALS_FILE):
		var file = FileAccess.open(CREDENTIALS_FILE, FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			file.close()
			if error == OK:
				var data = json.get_data()
				if data.has("username") and data.has("password"):
					username_input.text = data.username
					password_input.text = data.password
					remember_check.button_pressed = true

func _save_credentials(username: String, password: String) -> void:
	var data = {
		"username": username,
		"password": password
	}
	var file = FileAccess.open(CREDENTIALS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _clear_credentials() -> void:
	if FileAccess.file_exists(CREDENTIALS_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(CREDENTIALS_FILE))
