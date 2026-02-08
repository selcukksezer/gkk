extends Control
## Top Bar HUD
## Displays energy, gold, gems, and player info

const MathUtils = preload("res://core/utils/MathUtils.gd")

@onready var player_name_label: Label = $MarginContainer/HBox/PlayerInfo/PlayerName
@onready var level_label: Label = $MarginContainer/HBox/PlayerInfo/LevelLabel
@onready var gold_label: Label = $MarginContainer/HBox/GoldLabel
@onready var gem_label: Label = $MarginContainer/HBox/GemsLabel
@onready var energy_label: Label = $MarginContainer/HBox/EnergyLabel
@onready var logout_button: Button = $MarginContainer/HBox/LogoutButton

func _ready() -> void:
	# Connect state signals
	State.energy_updated.connect(_on_energy_updated)
	State.player_updated.connect(_on_player_updated)
	
	# Connect logout button
	if logout_button:
		logout_button.pressed.connect(_on_logout_pressed)
	
	# Initial update
	_update_display()

func _update_display() -> void:
	_update_energy()
	_update_resources()
	_update_player_info()

func _update_energy() -> void:
	if energy_label:
		energy_label.text = "%d ⚡" % State.current_energy
		
		# Color based on energy level
		var ratio = float(State.current_energy) / float(State.max_energy) if State.max_energy > 0 else 0.0
		if ratio > 0.5:
			energy_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1))
		elif ratio > 0.25:
			energy_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		else:
			energy_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))

func _update_resources() -> void:
	if gold_label:
		gold_label.text = "%s 💰" % MathUtils.format_number(State.gold)
	
	if gem_label:
		gem_label.text = "%s 💎" % MathUtils.format_number(int(State.gems))

func _update_player_info() -> void:
	if level_label:
		level_label.text = "Lv.%d" % int(State.level)
	
	if player_name_label:
		var player_data = State.get_player_data()
		if player_data.is_empty():
			player_name_label.text = "Oyuncu"
		else:
			player_name_label.text = player_data.get("display_name", player_data.get("username", "Oyuncu"))

func _on_logout_pressed() -> void:
	# Show confirmation dialog via Main
	var dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
	if dialog_scene:
		var main = get_tree().get_root().get_node_or_null("Main")
		if main and main.has_method("show_dialog"):
			main.show_dialog(dialog_scene, {
				"title": "Çıkış",
				"message": "Oturumdan çıkmak istiyor musunuz?",
				"confirm_text": "Çıkış",
				"on_confirm": Callable(self, "_confirm_logout")
			})

func _confirm_logout() -> void:
	# Perform logout
	if Session:
		Session.logout()
	else:
		push_error("[TopBar] Session manager not available for logout")

## Signal handlers
func _on_energy_updated() -> void:
	_update_energy()

func _on_player_updated() -> void:
	_update_resources()
	_update_player_info()
