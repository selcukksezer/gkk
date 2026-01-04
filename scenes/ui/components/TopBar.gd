extends PanelContainer
## Top Bar
## Displays player info and resources

@onready var player_name_label: Label = $MarginContainer/HBox/PlayerInfo/PlayerName
@onready var level_label: Label = $MarginContainer/HBox/PlayerInfo/LevelLabel
@onready var gold_label: Label = $MarginContainer/HBox/GoldLabel
@onready var gems_label: Label = $MarginContainer/HBox/GemsLabel
@onready var energy_label: Label = $MarginContainer/HBox/EnergyLabel
@onready var logout_button: Button = $MarginContainer/HBox/LogoutButton

func _ready() -> void:
	# Connect to state signals
	State.player_updated.connect(_update_player_info)
	State.energy_updated.connect(_update_energy)
	State.state_changed.connect(_on_state_changed)
	
	# Connect logout button
	if logout_button:
		logout_button.pressed.connect(_on_logout_pressed)
	
	# Initial update
	_update_player_info()
	_update_energy()

func _on_logout_pressed() -> void:
	# Show confirmation dialog via Main
	var dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
	if dialog_scene:
		var main = get_tree().get_root().get_node_or_null("Main")
		if main:
			main.show_dialog(dialog_scene, {
				"title": "Çıkış",
				"message": "Oturumdan çıkmak istiyor musunuz?",
				"confirm_text": "Çıkış",
				"on_confirm": Callable(self, "_confirm_logout")
			})

func _on_state_changed(key: String, value: Variant) -> void:
	match key:
		"gems":
			if gems_label:
				gems_label.text = str(value) + " 💎"
		"gold":
			if gold_label:
				gold_label.text = str(value) + " 💰"

func _update_player_info() -> void:
	var player = State.get_player_data()
	# Safely update UI elements only if they exist
	if player.is_empty():
		if player_name_label:
			player_name_label.text = "Oyuncu"
		if level_label:
			level_label.text = "Seviye 1"
		if gold_label:
			gold_label.text = "0 💰"
		if gems_label:
			gems_label.text = "0 💎"
		return
	
	# Prefer display_name if available
	if player_name_label:
		player_name_label.text = player.get("display_name", player.get("username", "Oyuncu"))
	if level_label:
		level_label.text = "Seviye " + str(player.get("level", 1))
	if gold_label:
		gold_label.text = str(player.get("gold", 0)) + " 💰"
	if gems_label:
		gems_label.text = str(player.get("gems", 0)) + " 💎"

func _update_energy() -> void:
	if energy_label:
		energy_label.text = str(State.current_energy) + " ⚡"
	
		# Color based on energy level
		var max_e = State.max_energy if State.max_energy > 0 else 1
		var energy_percent = float(State.current_energy) / float(max_e)
		if energy_percent < 0.2:
			energy_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		elif energy_percent < 0.5:
			energy_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
		else:
			energy_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1))

func _confirm_logout() -> void:
	# Perform logout
	if Session:
		Session.logout()
	else:
		push_error("[TopBar] Session manager not available for logout")
