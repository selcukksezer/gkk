extends Control
## Main Menu Screen
## Hub for navigating to different game features

@onready var player_info = $PlayerInfo
@onready var username_label = $PlayerInfo/HBox/Username
@onready var level_label = $PlayerInfo/HBox/Level
@onready var energy_bar = $PlayerInfo/EnergyBar
@onready var energy_label = $PlayerInfo/EnergyBar/Label
@onready var gold_label = $PlayerInfo/Resources/Gold/Amount
@onready var gems_label = $PlayerInfo/Resources/Gems/Amount

@onready var quest_button = $MenuButtons/QuestButton
@onready var pvp_button = $MenuButtons/PvPButton
@onready var market_button = $MenuButtons/MarketButton
@onready var inventory_button = $MenuButtons/InventoryButton
@onready var guild_button = $MenuButtons/GuildButton
@onready var production_button = $MenuButtons/ProductionButton
@onready var enhancement_button = $MenuButtons/EnhancementButton
@onready var shop_button = $MenuButtons/ShopButton

@onready var chat_panel = $ChatPanel
@onready var notifications_panel = $NotificationsPanel

func _ready() -> void:
	# Connect buttons
	quest_button.pressed.connect(_on_quest_pressed)
	pvp_button.pressed.connect(_on_pvp_pressed)
	market_button.pressed.connect(_on_market_pressed)
	inventory_button.pressed.connect(_on_inventory_pressed)
	guild_button.pressed.connect(_on_guild_pressed)
	production_button.pressed.connect(_on_production_pressed)
	enhancement_button.pressed.connect(_on_enhancement_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	
	# Connect state updates
	State.player_updated.connect(_update_player_info)
	State.energy_updated.connect(_update_energy)
	
	# Initial update
	_update_player_info()
	
	# Track screen
	Telemetry.track_screen("main_menu")
	
	# Connect WebSocket for real-time updates
	Network.connect_websocket()
	Network.ws_subscribe("user:" + Session.player_id, _on_ws_event)

func _update_player_info() -> void:
	username_label.text = State.player.get("username", "Player")
	level_label.text = "Lv. %d" % State.level
	
	gold_label.text = _format_number(State.gold)
	gems_label.text = str(State.gems)
	
	_update_energy()

func _update_energy() -> void:
	var energy_percent = float(State.current_energy) / float(State.max_energy)
	energy_bar.value = energy_percent * 100
	energy_label.text = "%d/%d" % [State.current_energy, State.max_energy]
	
	# Color coding
	if energy_percent < 0.3:
		energy_bar.modulate = Color.RED
	elif energy_percent < 0.6:
		energy_bar.modulate = Color.YELLOW
	else:
		energy_bar.modulate = Color.GREEN

func _format_number(num: int) -> String:
	if num >= 1000000:
		return "%.1fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.1fK" % (num / 1000.0)
	else:
		return str(num)

func _on_quest_pressed() -> void:
	Telemetry.track_button_click("quest", "main_menu")
	Scenes.change_scene("res://scenes/ui/QuestScreen.tscn")

func _on_pvp_pressed() -> void:
	Telemetry.track_button_click("pvp", "main_menu")
	Scenes.change_scene("res://scenes/ui/PvPScreen.tscn")

func _on_market_pressed() -> void:
	Telemetry.track_button_click("market", "main_menu")
	Scenes.change_scene("res://scenes/ui/MarketScreen.tscn")

func _on_inventory_pressed() -> void:
	Telemetry.track_button_click("inventory", "main_menu")
	Scenes.change_scene("res://scenes/ui/InventoryScreen.tscn")

func _on_guild_pressed() -> void:
	Telemetry.track_button_click("guild", "main_menu")
	Scenes.change_scene("res://scenes/ui/GuildScreen.tscn")

func _on_production_pressed() -> void:
	Telemetry.track_button_click("production", "main_menu")
	Scenes.change_scene("res://scenes/ui/ProductionScreen.tscn")

func _on_enhancement_pressed() -> void:
	Telemetry.track_button_click("enhancement", "main_menu")
	Scenes.change_scene("res://scenes/ui/EnhancementScreen.tscn")

func _on_shop_pressed() -> void:
	Telemetry.track_button_click("shop", "main_menu")
	Scenes.change_scene("res://scenes/ui/ShopScreen.tscn")

func _on_ws_event(data: Dictionary) -> void:
	var event_type = data.get("event", "")
	
	match event_type:
		"energy_update":
			State.update_energy(data.get("energy", State.current_energy))
		
		"gold_update":
			State.gold = data.get("gold", State.gold)
			_update_player_info()
		
		"pvp_attacked":
			_show_notification("PvP Saldırısı!", "Bir oyuncu sana saldırdı!")
		
		"hospital_release":
			_show_notification("Hastane", "Hastaneden çıktın!")
		
		"guild_notification":
			var message = data.get("message", "")
			_show_notification("Lonca", message)

func _show_notification(title: String, message: String) -> void:
	# TODO: Implement notification panel
	print("[MainMenu] Notification: %s - %s" % [title, message])
