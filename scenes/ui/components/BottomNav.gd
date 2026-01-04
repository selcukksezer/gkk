extends PanelContainer
## Bottom Navigation Bar
## Handles navigation between main screens

signal navigation_changed(screen_name: String)

@onready var home_button: Button = $HBox/HomeButton
@onready var quest_button: Button = $HBox/QuestButton
@onready var market_button: Button = $HBox/MarketButton
@onready var pvp_button: Button = $HBox/PvPButton
@onready var menu_button: Button = $HBox/MenuButton

var current_screen: String = ""

func _ready() -> void:
	# Connect buttons
	home_button.pressed.connect(func(): _navigate_to("home"))
	quest_button.pressed.connect(func(): _navigate_to("quest"))
	market_button.pressed.connect(func(): _navigate_to("market"))
	pvp_button.pressed.connect(func(): _navigate_to("pvp"))
	menu_button.pressed.connect(_show_menu)

func _navigate_to(screen: String) -> void:
	if current_screen == screen:
		return
	
	current_screen = screen
	navigation_changed.emit(screen)
	
	# Update button states (highlight active)
	_update_button_states(screen)

func _update_button_states(active_screen: String) -> void:
	home_button.modulate = Color.WHITE if active_screen == "home" else Color(0.7, 0.7, 0.7)
	quest_button.modulate = Color.WHITE if active_screen == "quest" else Color(0.7, 0.7, 0.7)
	market_button.modulate = Color.WHITE if active_screen == "market" else Color(0.7, 0.7, 0.7)
	pvp_button.modulate = Color.WHITE if active_screen == "pvp" else Color(0.7, 0.7, 0.7)

func _show_menu() -> void:
	# Create popup menu
	var popup = PopupMenu.new()
	add_child(popup)
	
	# Core screens
	popup.add_item("📦 Envanter", 0)
	popup.add_item("👤 Karakter", 1)
	popup.add_item("🏰 Lonca", 2)
	popup.add_item("👤 Profilim", 3)
	popup.add_separator()
	
	# Production & Economy
	popup.add_item("🏗️ Binalar", 4)
	popup.add_item("⛏️ Kaynak Toplama", 5)
	popup.add_item("⚙️ Üretim Yönetimi", 6)
	popup.add_item("📦 Depo", 7)
	popup.add_separator()
	
	# Systems
	popup.add_item("⚒️ Demirci (Örs)", 8)
	popup.add_item("⚗️ Zanaatkarlık", 9)
	popup.add_item("🏦 Banka", 10)
	popup.add_item("🤝 Ticaret", 11)
	popup.add_separator()
	
	# Adventure
	popup.add_item("⚔️ Zindanlar", 12)
	popup.add_item("🗺️ Harita", 13)
	popup.add_item("⚔️ Lonca Savaşları", 14)
	popup.add_separator()
	
	# Info & Settings
	popup.add_item("🏆 Sıralama", 15)
	popup.add_item("🏅 Başarımlar", 16)
	popup.add_item("⭐ İtibar", 17)
	popup.add_item("🎪 Etkinlikler", 18)
	popup.add_item("🏥 Hastane", 19)
	popup.add_item("🛒 Dükkan", 20)
	popup.add_item("⚙️ Ayarlar", 21)
	
	popup.id_pressed.connect(_on_menu_item_selected)
	
	# Position popup above button
	var button_pos = menu_button.global_position
	popup.position = Vector2i(button_pos.x, button_pos.y - 900)
	popup.popup()

func _on_menu_item_selected(id: int) -> void:
	match id:
		0: navigation_changed.emit("inventory")
		1: navigation_changed.emit("character")
		2: navigation_changed.emit("guild")
		3: navigation_changed.emit("profile")
		4: navigation_changed.emit("building")
		5: navigation_changed.emit("mining")
		6: navigation_changed.emit("production")
		7: navigation_changed.emit("warehouse")
		8: navigation_changed.emit("anvil")
		9: navigation_changed.emit("crafting")
		10: navigation_changed.emit("bank")
		11: navigation_changed.emit("trade")
		12: navigation_changed.emit("dungeon")
		13: navigation_changed.emit("map")
		14: navigation_changed.emit("guild_war")
		15: navigation_changed.emit("leaderboard")
		16: navigation_changed.emit("achievement")
		17: navigation_changed.emit("reputation")
		18: navigation_changed.emit("event")
		19: navigation_changed.emit("hospital")
		20: navigation_changed.emit("shop")
		21: navigation_changed.emit("settings")
