extends Control
## Login Screen
## Authentication screen for login/register

@onready var username_input: LineEdit = $CenterContainer/VBoxContainer/UsernameInput
@onready var password_input: LineEdit = $CenterContainer/VBoxContainer/PasswordInput
@onready var login_button: Button = $CenterContainer/VBoxContainer/LoginButton
@onready var register_button: Button = $CenterContainer/VBoxContainer/RegisterButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var remember_checkbox: CheckBox = $CenterContainer/VBoxContainer/RememberCheck

var is_loading: bool = false

func _ready() -> void:
	# Connect buttons
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)

	# Listen for login failures
	Session.login_failed.connect(_on_login_failed)

	# On successful login, clear loading/status
	Session.logged_in.connect(_on_logged_in)

	# Instant session validation result handler
	if Session.has_signal("session_status_checked"):
		Session.session_status_checked.connect(_on_session_status_checked)

	# Listen for register completion
	Session.register_completed.connect(_on_register_completed)
	
	# Set password to secret
	password_input.secret = true
	
	# Clear status
	status_label.text = ""

	# Load saved credentials if present
	_load_saved_credentials()


func _on_login_pressed() -> void:
	if is_loading:
		return
	
	var username = username_input.text.strip_edges()
	var password = password_input.text
	
	# Validate
	var validation = null
	if username.find("@") >= 0:
		validation = ValidationUtils.validate_email(username)
	else:
		validation = ValidationUtils.validate_username(username)

	if not validation.is_valid:
		_show_error(validation.error_message)
		return
	
	validation = ValidationUtils.validate_password(password)
	if not validation.is_valid:
		_show_error(validation.error_message)
		return
	
	# Show loading
	_set_loading(true)
	status_label.text = "Giriş yapılıyor..."
	# Show global loading overlay during transition
	var main_node = get_tree().get_root().get_node_or_null("Main")
	if main_node and main_node.has_method("_show_loading_overlay"):
		main_node.call("_show_loading_overlay", true)
	
	# Attempt login (Session will emit signal when done)
	Session.login(username, password)

	# Save or clear credentials depending on checkbox
	if remember_checkbox and remember_checkbox.pressed:
		_save_credentials(username, password, true)
	else:
		_clear_saved_credentials()

func _on_register_pressed() -> void:
	if is_loading:
		return

	# Open detailed register dialog
	var dialog_scene = load("res://scenes/ui/dialogs/RegisterDialog.tscn")
	if dialog_scene:
		var main = null
		if get_tree().get_root().has_node("Main"):
			main = get_tree().get_root().get_node("Main")
		elif has_node("/root/Main"):
			main = get_node("/root/Main")

		if main and main.has_method("show_dialog"):
			main.show_dialog(dialog_scene)
		else:
			# Fallback: instantiate directly into this screen
			var d = dialog_scene.instantiate()
			add_child(d)


func _save_credentials(username: String, password: String, remember: bool) -> void:
	var data = {"username": username, "password": password, "remember": remember}
	var f = FileAccess.open("user://credentials.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()
	else:
		print("[LoginScreen] Failed to open credentials file for writing")

func _load_saved_credentials() -> void:
	if not FileAccess.file_exists("user://credentials.json"):
		return
	var f = FileAccess.open("user://credentials.json", FileAccess.READ)
	if not f:
		print("[LoginScreen] Failed to open credentials file for reading")
		return
	var txt = f.get_as_text()
	f.close()
	var j = JSON.new()
	var parse_result = j.parse(txt)
	if parse_result != OK:
		print("[LoginScreen] Failed to parse credentials JSON: ", parse_result)
		return
	var obj = j.data
	if obj.has("username"):
		username_input.text = str(obj.username)
	if obj.has("password"):
		password_input.text = str(obj.password)
	if obj.has("remember") and remember_checkbox:
		remember_checkbox.set_pressed_no_signal(bool(obj.remember))

func _clear_saved_credentials() -> void:
	if FileAccess.file_exists("user://credentials.json"):
		var ok = DirAccess.remove_absolute("user://credentials.json")
		if ok != OK:
			print("[LoginScreen] Failed to remove credentials file: ", ok)

func _set_loading(loading: bool) -> void:
	is_loading = loading
	login_button.disabled = loading
	register_button.disabled = loading
	username_input.editable = not loading
	password_input.editable = not loading

func _show_error(message: String) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", Color.RED)
	
	# Clear after 3 seconds
	await get_tree().create_timer(3.0).timeout
	status_label.text = ""


func _on_register_completed(success: bool, message: String) -> void:
	_set_loading(false)
	if success:
		status_label.add_theme_color_override("font_color", Color.GREEN)
		status_label.text = message
	else:
		status_label.add_theme_color_override("font_color", Color.RED)
		status_label.text = message

# Signal handlers
func _on_login_failed(message: String) -> void:
	_set_loading(false)
	# Hide global overlay if shown
	var main_node = get_tree().get_root().get_node_or_null("Main")
	if main_node and main_node.has_method("_show_loading_overlay"):
		main_node.call("_show_loading_overlay", false)
	_show_error(message)

func _on_logged_in(_player_data: Dictionary) -> void:
	_set_loading(false)
	status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
	status_label.text = "Giriş başarılı"
	await get_tree().create_timer(0.5).timeout
	status_label.text = ""

func _on_session_status_checked(is_auth: bool) -> void:
	_set_loading(false)
	status_label.text = ""
	if is_auth:
		status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1))
		status_label.text = "Oturum doğrulandı"
		await get_tree().create_timer(0.3).timeout
		status_label.text = ""
