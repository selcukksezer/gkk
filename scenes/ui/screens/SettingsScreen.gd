extends Control
## Settings Screen
## Game settings including audio, graphics, and account management

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var notifications_toggle: CheckButton = %NotificationsToggle
@onready var auto_battle_toggle: CheckButton = %AutoBattleToggle
@onready var language_option: OptionButton = %LanguageOption
@onready var logout_button: Button = %LogoutButton
@onready var delete_account_button: Button = %DeleteAccountButton

var settings: Dictionary = {}

func _ready() -> void:
	# Connect signals
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	notifications_toggle.toggled.connect(_on_notifications_toggled)
	auto_battle_toggle.toggled.connect(_on_auto_battle_toggled)
	language_option.item_selected.connect(_on_language_selected)
	logout_button.pressed.connect(_on_logout_pressed)
	delete_account_button.pressed.connect(_on_delete_account_pressed)
	
	# Load settings
	_load_settings()

func _load_settings() -> void:
	# Load from Config autoload
	settings = {
		"music_volume": Config.get_setting("audio.music_volume", 0.7),
		"sfx_volume": Config.get_setting("audio.sfx_volume", 0.8),
		"notifications_enabled": Config.get_setting("notifications.enabled", true),
		"auto_battle": Config.get_setting("gameplay.auto_battle", false),
		"language": Config.get_setting("game.language", "tr")
	}
	
	_apply_settings_to_ui()

func _apply_settings_to_ui() -> void:
	music_slider.value = settings.get("music_volume", 0.7) * 100
	sfx_slider.value = settings.get("sfx_volume", 0.8) * 100
	notifications_toggle.button_pressed = settings.get("notifications_enabled", true)
	auto_battle_toggle.button_pressed = settings.get("auto_battle", false)
	
	# Set language
	var lang = settings.get("language", "tr")
	if lang == "tr":
		language_option.selected = 0
	elif lang == "en":
		language_option.selected = 1

func _on_music_volume_changed(value: float) -> void:
	var volume = value / 100.0
	settings["music_volume"] = volume
	Config.set_setting("audio.music_volume", volume)
	Audio.set_music_volume(volume)

func _on_sfx_volume_changed(value: float) -> void:
	var volume = value / 100.0
	settings["sfx_volume"] = volume
	Config.set_setting("audio.sfx_volume", volume)
	Audio.set_sfx_volume(volume)

func _on_notifications_toggled(enabled: bool) -> void:
	settings["notifications_enabled"] = enabled
	Config.set_setting("notifications.enabled", enabled)

func _on_auto_battle_toggled(enabled: bool) -> void:
	settings["auto_battle"] = enabled
	Config.set_setting("gameplay.auto_battle", enabled)

func _on_language_selected(index: int) -> void:
	var languages = ["tr", "en"]
	var lang = languages[index]
	settings["language"] = lang
	Config.set_setting("game.language", lang)
	
	# TODO: Apply language change
	_show_restart_required_dialog()

func _on_logout_pressed() -> void:
	# Confirm logout
	_confirm_logout()

func _confirm_logout() -> void:
	# Clear session
	Session.clear()
	State.clear()
	
	# Return to login screen
	Scenes.change_scene("res://scenes/ui/screens/LoginScreen.tscn")

func _on_delete_account_pressed() -> void:
	# Show confirmation dialog
	_confirm_delete_account()

func _confirm_delete_account() -> void:
	# TODO: Show actual confirmation dialog
	push_warning("Delete account functionality not yet implemented")

func _show_restart_required_dialog() -> void:
	print("Değişikliklerin geçerli olması için oyunu yeniden başlatın")
	# TODO: Show actual dialog
