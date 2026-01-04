extends Control
## Shop Screen
## Allows players to purchase energy potions and other items with gold

@onready var gold_label: Label = %GoldLabel
@onready var gems_label: Label = %GemsLabel
@onready var shop_items_container: VBoxContainer = %ShopItemsContainer
@onready var purchase_button: Button = %PurchaseButton
@onready var purchase_amount_spin: SpinBox = %PurchaseAmountSpin

var shop_items: Array = []
var selected_item: Dictionary = {}

func _ready() -> void:
	# Connect signals
	State.player_updated.connect(_update_gold_display)
	State.player_updated.connect(_update_gems_display)
	purchase_button.pressed.connect(_on_purchase_pressed)
	
	# Load shop data
	_load_shop_items()
	_update_gold_display()
	_update_gems_display()

func _load_shop_items() -> void:
	var result = await Network.http_get("/shop/items")
	_on_shop_items_loaded(result)

func _on_shop_items_loaded(result: Dictionary) -> void:
	if not result.success:
		push_error("Failed to load shop items: " + str(result.get("error", "Unknown")))
		_load_default_items()
		return
	
	shop_items = result.data.get("items", [])
	_display_shop_items()

func _load_default_items() -> void:
	shop_items = [
		{
			"id": "gems_100",
			"name": "100 Elmas",
			"description": "100 elmas satın al",
			"price": 0,
			"gems": 100,
			"type": "gems"
		},
		{
			"id": "energy_potion_small",
			"name": "Küçük Enerji İksiri",
			"description": "25 enerji yeniler",
			"price": 100,
			"energy_restore": 25,
			"type": "potion"
		},
		{
			"id": "energy_potion_medium",
			"name": "Orta Enerji İksiri",
			"description": "50 enerji yeniler",
			"price": 180,
			"energy_restore": 50,
			"type": "potion"
		},
		{
			"id": "energy_potion_large",
			"name": "Büyük Enerji İksiri",
			"description": "100 enerji yeniler (tam doldurur)",
			"price": 300,
			"energy_restore": 100,
			"type": "potion"
		},
		{
			"id": "tolerance_boost",
			"name": "Tolerans Artırıcı",
			"description": "Toleransı 10 puan artırır",
			"price": 500,
			"tolerance_boost": 10,
			"type": "boost"
		}
	]
	_display_shop_items()

func _display_shop_items() -> void:
	# Clear existing items
	for child in shop_items_container.get_children():
		child.queue_free()
	
	# Add items
	for item in shop_items:
		var item_card = _create_shop_item_card(item)
		shop_items_container.add_child(item_card)

func _create_shop_item_card(item: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 120)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	# Item info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = item.get("name", "Unknown Item")
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vbox.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.text = item.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_label)
	
	var price_label = Label.new()
	price_label.text = str(item.get("price", 0)) + " Altın"
	price_label.add_theme_font_size_override("font_size", 22)
	price_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	vbox.add_child(price_label)
	
	# Buy button
	var buy_button = Button.new()
	buy_button.text = "Satın Al"
	buy_button.custom_minimum_size = Vector2(200, 0)
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.pressed.connect(_on_item_selected.bind(item))
	hbox.add_child(buy_button)
	
	return panel

func _on_item_selected(item: Dictionary) -> void:
	selected_item = item
	_show_purchase_dialog()

func _show_purchase_dialog() -> void:
	if selected_item.is_empty():
		return
	
	var player_gold = State.get_player_data().get("gold", 0)
	var item_price = selected_item.get("price", 0)
	
	if player_gold < item_price:
		_show_error_dialog("Yetersiz Altın", "Bu ürünü almak için yeterli altınınız yok.")
		return
	
	# Show confirmation dialog
	_confirm_purchase()

func _confirm_purchase() -> void:
	var item_name = selected_item.get("name", "")
	var item_price = selected_item.get("price", 0)
	
	# For now, directly purchase
	_execute_purchase()

func _execute_purchase() -> void:
	var item_type = selected_item.get("type", "")
	
	if item_type == "gems":
		_purchase_gems()
	else:
		_purchase_item()

func _purchase_gems() -> void:
	var amount = selected_item.get("gems", 100)
	
	if not ShopManager:
		push_error("[ShopScreen] ShopManager not available")
		return
	
	# Show loading
	_show_loading(true)
	
	# Purchase gems
	var result = await ShopManager.purchase_gems(amount)
	
	# Hide loading
	_show_loading(false)
	
	if result.success:
		# Update UI
		_update_gems_display()
		
		# Show success message
		_show_success_dialog("Başarılı!", "%d elmas satın alındı!" % amount)
		
		print("[ShopScreen] Purchased %d gems successfully" % amount)
	else:
		# Show error message
		_show_error_dialog("Hata", "Elmas satın alınamadı: %s" % result.get("error", "Bilinmeyen hata"))
		
		push_error("[ShopScreen] Failed to purchase gems: %s" % result.get("error", "Unknown error"))
	
	selected_item = {}

func _purchase_item() -> void:
	var player_id = Session.player_id
	if not player_id:
		_show_error_dialog("Hata", "Oyuncu ID bulunamadı")
		return
	
	var request_data = {
		"item_id": selected_item.get("id", ""),
		"quantity": 1
	}
	
	Network.post(
		"/shop/purchase",
		request_data,
		_on_purchase_success
	)

func _on_purchase_success(result: Dictionary) -> void:
	if not result.success:
		_show_error_dialog("Satın Alma Hatası", str(result.get("error", "Unknown")))
		return
	
	# Update player data
	State.update_player_data(result.data.get("player", {}))
	
	# Show success message
	var item_name = selected_item.get("name", "Ürün")
	_show_success_dialog("Başarılı!", item_name + " satın alındı!")
	
	selected_item = {}

func _on_purchase_pressed() -> void:
	if selected_item.is_empty():
		return
	_execute_purchase()

func _update_gold_display() -> void:
	var player = State.get_player_data()
	gold_label.text = str(player.get("gold", 0)) + " Altın"

func _show_error_dialog(title: String, message: String) -> void:
	push_warning(title + ": " + message)
	# TODO: Show actual dialog

func _show_success_dialog(title: String, message: String) -> void:
	print(title + ": " + message)
	# TODO: Show actual dialog

func _update_gems_display() -> void:
	var player = State.get_player_data()
	gems_label.text = str(player.get("gems", 0)) + " Elmas"

func _show_loading(show: bool) -> void:
	# TODO: Show/hide loading indicator
	if show:
		print("Loading...")
	else:
		print("Loading complete")
