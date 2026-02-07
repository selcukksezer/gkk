extends "res://scenes/ui/dialogs/BaseDialog.gd"
## Register Dialog
## Detailed registration form

@onready var email_input: LineEdit = $Panel/MarginContainer/VBoxContainer/EmailInput
@onready var username_input: LineEdit = $Panel/MarginContainer/VBoxContainer/UsernameInput
@onready var password_input: LineEdit = $Panel/MarginContainer/VBoxContainer/PasswordInput
@onready var confirm_input: LineEdit = $Panel/MarginContainer/VBoxContainer/ConfirmPasswordInput
@onready var referral_input: LineEdit = $Panel/MarginContainer/VBoxContainer/ReferralInput
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var register_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/RegisterButton
@onready var cancel_button: Button = $Panel/MarginContainer/VBoxContainer/Buttons/CancelButton
@onready var panel: PanelContainer = $Panel

var is_loading: bool = false

func _ready() -> void:
    super._ready()
    register_button.pressed.connect(_on_register_pressed)
    cancel_button.pressed.connect(_on_cancel_pressed)
    Session.register_completed.connect(_on_register_completed)
    password_input.secret = true
    confirm_input.secret = true
    status_label.text = ""
    
    # Ensure dialog fits on screen
    _adjust_dialog_size()

func _adjust_dialog_size() -> void:
    # Get viewport size
    var viewport_size = get_viewport_rect().size
    
    # Set max width to 90% of screen width or 600px, whichever is smaller
    var max_width = min(viewport_size.x * 0.9, 600.0)
    
    # Adjust panel size if needed
    if panel:
        var panel_width = panel.size.x
        if panel_width > max_width:
            # Recalculate offsets to fit
            var half_width = max_width / 2.0
            panel.offset_left = -half_width
            panel.offset_right = half_width

func _set_loading(loading: bool) -> void:
    is_loading = loading
    register_button.disabled = loading
    cancel_button.disabled = loading
    email_input.editable = not loading
    username_input.editable = not loading
    password_input.editable = not loading
    confirm_input.editable = not loading

func _show_status(message: String, success: bool = false) -> void:
    status_label.text = message
    status_label.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2, 1) if success else Color(1, 0.4, 0.4, 1))

func _on_register_pressed() -> void:
    if is_loading:
        return

    var email = email_input.text.strip_edges()
    var username = username_input.text.strip_edges()
    var password = password_input.text
    var confirm = confirm_input.text
    var referral = referral_input.text.strip_edges()

    var v = ValidationUtils.validate_email(email)
    if not v.is_valid:
        _show_status(v.error_message)
        return

    v = ValidationUtils.validate_username(username)
    if not v.is_valid:
        _show_status(v.error_message)
        return

    v = ValidationUtils.validate_password(password)
    if not v.is_valid:
        _show_status(v.error_message)
        return

    if password != confirm:
        _show_status("Şifreler eşleşmiyor")
        return

    _set_loading(true)
    _show_status("Kayıt oluşturuluyor...")

    Session.register(email, username, password, referral)

func _on_register_completed(success: bool, message: String) -> void:
    _set_loading(false)
    _show_status(message, success)
    if success:
        await get_tree().create_timer(1.0).timeout
        close_dialog({"success": true, "message": message})

func _on_cancel_pressed() -> void:
    close_dialog({"success": false, "cancelled": true})
