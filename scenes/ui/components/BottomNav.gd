extends PanelContainer
## Bottom Navigation Bar
## Handles navigation between main screens

signal navigation_changed(screen_name: String)

@onready var home_button: Button = $HBox/HomeButton
@onready var hospital_button: Button = $HBox/HospitalButton
@onready var dungeon_button: Button = $HBox/DungeonButton
@onready var shop_button: Button = $HBox/ShopButton
@onready var menu_button: Button = $HBox/MenuButton

var current_screen: String = ""

func _ready() -> void:
	# Connect buttons
	home_button.pressed.connect(func(): _navigate_to("home"))
	hospital_button.pressed.connect(func(): _navigate_to("hospital"))
	dungeon_button.pressed.connect(func(): _navigate_to("dungeon"))
	shop_button.pressed.connect(func(): _navigate_to("shop"))
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
	hospital_button.modulate = Color.WHITE if active_screen == "hospital" else Color(0.7, 0.7, 0.7)
	dungeon_button.modulate = Color.WHITE if active_screen == "dungeon" else Color(0.7, 0.7, 0.7)
	shop_button.modulate = Color.WHITE if active_screen == "shop" else Color(0.7, 0.7, 0.7)

func _show_menu() -> void:
	# Create popup menu
	var popup = PopupMenu.new()
	add_child(popup)
	
	# Main actions
	popup.add_item("📋 Görevler", 0)
	popup.add_item("⚔️ PvP Arena", 1)
	popup.add_item("🏪 Pazar", 2)
	popup.add_item("🎄 Mevsim", 3)
	popup.add_separator()
	
	# Core screens
	popup.add_item("📦 Envanter", 4)
	popup.add_item("👤 Karakter", 5)
	popup.add_item("🏰 Lonca", 6)
	popup.add_item("👤 Profilim", 7)
	popup.add_separator()
	
	# Production & Economy
	popup.add_item("🏗️ Binalar", 8)
	popup.add_item("⛏️ Kaynak Toplama", 9)
	popup.add_item("⚙️ Üretim Yönetimi", 10)
	popup.add_item("📦 Depo", 11)
	popup.add_separator()
	
	# Systems
	popup.add_item("⚒️ Demirci (Örs)", 12)
	popup.add_item("⚗️ Zanaatkarlık", 13)
	popup.add_item("🏦 Banka", 14)
	popup.add_item("🤝 Ticaret", 15)
	popup.add_separator()
	
	# Adventure
	popup.add_item("🗺️ Harita", 16)
	popup.add_item("⚔️ Lonca Savaşları", 17)
	popup.add_separator()
	
	# Info & Settings
	popup.add_item("🏆 Sıralama", 18)
	popup.add_item("🏅 Başarımlar", 19)
	popup.add_item("⭐ İtibar", 20)
	popup.add_item("🎪 Etkinlikler", 21)
	popup.add_item("⚙️ Ayarlar", 22)
	popup.add_item("👮 Hapishane", 23)
	
	popup.id_pressed.connect(_on_menu_item_selected)
	
	# Position popup above button
	var button_pos = menu_button.global_position
	popup.position = Vector2i(button_pos.x, button_pos.y - 900)
	popup.popup()

func _on_menu_item_selected(id: int) -> void:
	match id:
		0: navigation_changed.emit("quest")
		1: navigation_changed.emit("pvp")
		2: navigation_changed.emit("market")
		3: navigation_changed.emit("season")
		4: navigation_changed.emit("inventory")
		5: navigation_changed.emit("character")
		6: navigation_changed.emit("guild")
		7: navigation_changed.emit("profile")
		8: navigation_changed.emit("building")
		9: navigation_changed.emit("facilities")
		10: navigation_changed.emit("production")
		11: navigation_changed.emit("warehouse")
		12: navigation_changed.emit("anvil")
		13: navigation_changed.emit("crafting")
		14: navigation_changed.emit("bank")
		15: navigation_changed.emit("trade")
		16: navigation_changed.emit("map")
		17: navigation_changed.emit("guild_war")
		18: navigation_changed.emit("leaderboard")
		19: navigation_changed.emit("achievement")
		20: navigation_changed.emit("reputation")
		21: navigation_changed.emit("event")
		22: navigation_changed.emit("settings")
		23: navigation_changed.emit("prison")
