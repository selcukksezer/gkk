extends Control
## Login Screen
## Handles user authentication (login/register)

@onready var tab_container = $TabContainer
@onready var login_tab = $TabContainer/Login
@onready var register_tab = $TabContainer/Register

# Login fields
@onready var login_username = $TabContainer/Login/VBox/UsernameField
@onready var login_password = $TabContainer/Login/VBox/PasswordField
@onready var login_button = $TabContainer/Login/VBox/LoginButton
@onready var login_error = $TabContainer/Login/VBox/ErrorLabel

# Register fields
@onready var register_email = $TabContainer/Register/VBox/EmailField
@onready var register_username = $TabContainer/Register/VBox/UsernameField
@onready var register_password = $TabContainer/Register/VBox/PasswordField
@onready var register_confirm = $TabContainer/Register/VBox/ConfirmPasswordField
@onready var register_button = $TabContainer/Register/VBox/RegisterButton
@onready var register_error = $TabContainer/Register/VBox/ErrorLabel

var _loading: bool = false

func _ready() -> void:
	# Connect signals
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	
	Session.logged_in.connect(_on_logged_in)
	Session.register_completed.connect(_on_register_completed)
	
	# Clear errors
	login_error.text = ""
	register_error.text = ""
	
	# Track screen view
	Telemetry.track_screen("login")

func _on_login_pressed() -> void:
	if _loading:
		return
	
	var username = login_username.text.strip_edges()
	var password = login_password.text
	
	# Validation
	if username.is_empty():
		login_error.text = "Kullanıcı adı gerekli"
		return
	
	if password.is_empty():
		login_error.text = "Şifre gerekli"
		return
	
	if password.length() < 8:
		login_error.text = "Şifre en az 8 karakter olmalı"
		return
	
	# Clear error
	login_error.text = ""
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
	
	var email = register_email.text.strip_edges()
	var username = register_username.text.strip_edges()
	var password = register_password.text
	var confirm = register_confirm.text
	
	# Validation
	if email.is_empty():
		register_error.text = "E-posta gerekli"
		return
	
	if not _is_valid_email(email):
		register_error.text = "Geçersiz e-posta formatı"
		return
	
	if username.is_empty():
		register_error.text = "Kullanıcı adı gerekli"
		return
	
	if username.length() < 3 or username.length() > 20:
		register_error.text = "Kullanıcı adı 3-20 karakter olmalı"
		return
	
	if not username.is_valid_identifier():
		register_error.text = "Kullanıcı adı sadece harf, rakam ve _ içerebilir"
		return
	
	if password.is_empty():
		register_error.text = "Şifre gerekli"
		return
	
	if password.length() < 8:
		register_error.text = "Şifre en az 8 karakter olmalı"
		return
	
	if password != confirm:
		register_error.text = "Şifreler eşleşmiyor"
		return
	
	# Clear error
	register_error.text = ""
	_loading = true
	register_button.disabled = true
	register_button.text = "Kayıt yapılıyor..."
	
	# Track attempt
	Telemetry.track_event("user", "register_attempt", {"username": username})
	
	# Attempt register
	Session.register(email, username, password)

func _on_logged_in(player_data: Dictionary) -> void:
	_loading = false
	print("[LoginScreen] Login successful, transitioning to main menu...")
	
	# Track success
	Telemetry.track_event("user", "login_success", {
		"user_id": player_data.get("id", ""),
		"level": player_data.get("level", 1)
	})
	
	# Transition to main menu
	Scenes.change_scene("res://scenes/main/MainMenu.tscn")

func _on_register_completed(success: bool, message: String) -> void:
	_loading = false
	register_button.disabled = false
	register_button.text = "Kayıt Ol"
	
	if success:
		register_error.text = ""
		register_error.add_theme_color_override("font_color", Color.GREEN)
		register_error.text = message
		
		# Track success
		Telemetry.track_event("user", "register_success", {
			"username": register_username.text
		})
		
		# If auto-logged in after register, transition will happen via logged_in signal
	else:
		register_error.add_theme_color_override("font_color", Color.RED)
		register_error.text = message
		
		# Track failure
		Telemetry.track_event("user", "register_failed", {
			"reason": message
		})

func _is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null
