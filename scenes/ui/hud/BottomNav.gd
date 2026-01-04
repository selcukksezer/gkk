extends Control
## Bottom Navigation Bar
## Main navigation between screens

signal navigation_changed(screen_name: String)

@onready var home_button: Button = $HBoxContainer/HomeButton
@onready var map_button: Button = $HBoxContainer/MapButton
@onready var inventory_button: Button = $HBoxContainer/InventoryButton
@onready var market_button: Button = $HBoxContainer/MarketButton
@onready var guild_button: Button = $HBoxContainer/GuildButton

var current_tab: String = "home"

func _ready() -> void:
	# Connect buttons
	home_button.pressed.connect(_on_home_pressed)
	map_button.pressed.connect(_on_map_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	market_button.pressed.connect(_on_market_pressed)
	guild_button.pressed.connect(_on_guild_pressed)
	
	# Set initial state
	_update_button_states()

func _update_button_states() -> void:
	# Update visual state of buttons based on current_tab
	_set_button_active(home_button, current_tab == "home")
	_set_button_active(map_button, current_tab == "map")
	_set_button_active(inventory_button, current_tab == "inventory")
	_set_button_active(market_button, current_tab == "market")
	_set_button_active(guild_button, current_tab == "guild")

func _set_button_active(button: Button, active: bool) -> void:
	if active:
		button.add_theme_color_override("font_color", Color.GOLD)
		button.add_theme_color_override("font_pressed_color", Color.GOLD)
	else:
		button.remove_theme_color_override("font_color")
		button.remove_theme_color_override("font_pressed_color")

func navigate_to(screen_name: String) -> void:
	if current_tab != screen_name:
		current_tab = screen_name
		_update_button_states()
		navigation_changed.emit(screen_name)

## Button handlers
func _on_home_pressed() -> void:
	navigate_to("home")

func _on_map_pressed() -> void:
	navigate_to("map")

func _on_inventory_pressed() -> void:
	navigate_to("inventory")

func _on_market_pressed() -> void:
	navigate_to("market")

func _on_guild_pressed() -> void:
	if State.player.guild_id.is_empty():
		# Show guild join/create screen
		get_tree().root.get_node("Main").show_screen("guild")
	else:
		# Show guild screen
		navigate_to("guild")
