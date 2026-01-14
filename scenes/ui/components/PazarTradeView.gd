extends VBoxContainer

signal close_requested
signal buy_order_placed(item_id, price, quantity)
signal sell_order_placed(item_id, price, quantity)

@onready var item_icon: TextureRect = $Header/MarginContainer/HBoxContainer/ItemIcon
@onready var item_name: Label = $Header/MarginContainer/HBoxContainer/VBoxContainer/ItemName
@onready var item_rarity: Label = $Header/MarginContainer/HBoxContainer/VBoxContainer/ItemRarity
@onready var close_button: Button = $Header/MarginContainer/HBoxContainer/CloseButton
@onready var order_list: VBoxContainer = $Content/OrderBookPanel/ScrollContainer/OrderList

# Buy Inputs
@onready var price_input: SpinBox = $"Content/ActionPanel/TabContainer/Alış/VBoxContainer/PriceInput"
@onready var quantity_input: SpinBox = $"Content/ActionPanel/TabContainer/Alış/VBoxContainer/QuantityInput"
@onready var total_label: Label = $"Content/ActionPanel/TabContainer/Alış/VBoxContainer/TotalLabel"
@onready var buy_button: Button = $"Content/ActionPanel/TabContainer/Alış/VBoxContainer/BuyButton"

# Sell Inputs
@onready var sell_price_input: SpinBox = $"Content/ActionPanel/TabContainer/Satış/VBoxContainer/SellPriceInput"
@onready var sell_quantity_input: SpinBox = $"Content/ActionPanel/TabContainer/Satış/VBoxContainer/SellQuantityInput"
@onready var sell_total_label: Label = $"Content/ActionPanel/TabContainer/Satış/VBoxContainer/SellTotalLabel"
@onready var sell_button: Button = $"Content/ActionPanel/TabContainer/Satış/VBoxContainer/SellButton"

var current_item_id: String = ""
var market_manager: Node

func _ready() -> void:
	close_button.pressed.connect(func(): close_requested.emit())
	
	# Buy Logic
	price_input.value_changed.connect(_update_buy_total)
	quantity_input.value_changed.connect(_update_buy_total)
	buy_button.pressed.connect(_on_buy_pressed)
	
	# Sell Logic
	sell_price_input.value_changed.connect(_update_sell_total)
	sell_quantity_input.value_changed.connect(_update_sell_total)
	sell_button.pressed.connect(_on_sell_pressed)
	
	market_manager = get_node_or_null("/root/PazarManager")
	
	_update_buy_total(0)
	_update_sell_total(0)

func setup(item_id: String) -> void:
	current_item_id = item_id
	
	# Load item details from database
	var item = ItemDatabase.get_item(item_id)
	if not item:
		return
		
	item_name.text = item.get("name", "Unknown")
	var rarity = item.get("rarity", 0)
	
	var rarity_names = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]
	var rarity_int = 0
	
	if rarity is String:
		# If it's a string, try to find index in names, or default to 0
		var idx = rarity_names.find(rarity)
		if idx != -1:
			rarity_int = idx
			item_rarity.text = rarity
		else:
			item_rarity.text = rarity # Fallback
	elif rarity is int:
		rarity_int = rarity
		if rarity >= 0 and rarity < rarity_names.size():
			item_rarity.text = rarity_names[rarity]
		else:
			item_rarity.text = "UNKNOWN"
			
	item_rarity.modulate = ItemData.get_rarity_color_static(rarity_int)
	
	var icon_path = item.get("icon", "")
	if ResourceLoader.exists(icon_path):
		item_icon.texture = load(icon_path)
		
	# Fetch Order Book
	if market_manager:
		_fetch_order_book()

func _fetch_order_book() -> void:
	# Clear list
	for child in order_list.get_children():
		child.queue_free()
		
	if not market_manager: return
	
	# In a real implementation this would be async
	# For now we simulate or assume sync if cached, or handle the callback
	# In Godot 4, await works for both immediate values and coroutines
	var result = await market_manager.fetch_order_book(current_item_id, 1) # Region 1 default
	
	if result is Dictionary and result.get("success", false):
		if result.has("orderbook"):
			_display_orders(result.orderbook)

func _display_orders(book: Dictionary) -> void:
	# Bids (Buy Orders) - Green
	var bids = book.get("bids", [])
	if bids.size() > 0:
		var header = Label.new()
		header.text = "ALIŞ EMİRLERİ"
		header.modulate = Color.GREEN
		order_list.add_child(header)
		for bid in bids:
			_add_order_row(bid, Color.GREEN)
			
	var sep = HSeparator.new()
	order_list.add_child(sep)
	
	# Asks (Sell Orders) - Red
	var asks = book.get("asks", [])
	if asks.size() > 0:
		var header = Label.new()
		header.text = "SATIŞ EMİRLERİ"
		header.modulate = Color.RED
		order_list.add_child(header)
		for ask in asks:
			_add_order_row(ask, Color.RED)

func _add_order_row(order: Dictionary, color: Color) -> void:
	var hbox = HBoxContainer.new()
	var price_lbl = Label.new()
	price_lbl.text = "%d G" % order.get("price", 0)
	price_lbl.modulate = color
	price_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(price_lbl)
	
	var qty_lbl = Label.new()
	qty_lbl.text = "x%d" % order.get("quantity", 0)
	hbox.add_child(qty_lbl)
	
	order_list.add_child(hbox)

func _update_buy_total(_val) -> void:
	var total = price_input.value * quantity_input.value
	total_label.text = "Toplam: %d Altın" % total

func _update_sell_total(_val) -> void:
	var total = sell_price_input.value * sell_quantity_input.value
	sell_total_label.text = "Toplam: %d Altın" % total

func _on_buy_pressed() -> void:
	buy_order_placed.emit(current_item_id, int(price_input.value), int(quantity_input.value))

func _on_sell_pressed() -> void:
	sell_order_placed.emit(current_item_id, int(sell_price_input.value), int(sell_quantity_input.value))
