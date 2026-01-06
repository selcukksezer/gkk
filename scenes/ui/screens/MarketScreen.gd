extends Control
## Market screen with order book and buy/sell functionality
## Shows market data, active orders, and trading interface

@onready var order_book_list: VBoxContainer = %OrderBookList
@onready var my_orders_list: VBoxContainer = %MyOrdersList
@onready var item_selector: OptionButton = %ItemSelector
@onready var price_input: SpinBox = %PriceInput
@onready var quantity_input: SpinBox = %QuantityInput
@onready var total_label: Label = %TotalLabel
@onready var buy_button: Button = %BuyButton
@onready var sell_button: Button = %SellButton
@onready var order_type_tabs: TabContainer = %OrderTypeTabs

var market_manager: Node
var selected_item_id: String = ""
var current_order_book: Dictionary = {}

enum OrderType {
	BUY,
	SELL
}

func _ready() -> void:
	print("[Market] MarketScreen ready")
	market_manager = get_node("/root/MarketManager") if has_node("/root/MarketManager") else null
	
	print("[Market] Market manager: ", market_manager)
	
	if market_manager:
		# Connect to market signals
		if market_manager.has_signal("order_placed"):
			market_manager.order_placed.connect(_on_order_placed)
		if market_manager.has_signal("order_filled"):
			market_manager.order_filled.connect(_on_order_filled)
		if market_manager.has_signal("order_cancelled"):
			market_manager.order_cancelled.connect(_on_order_cancelled)
		if market_manager.has_signal("market_updated"):
			market_manager.market_updated.connect(_on_market_updated)
	
	_setup_item_selector()
	_setup_inputs()
	
	buy_button.pressed.connect(_on_buy_pressed)
	sell_button.pressed.connect(_on_sell_pressed)

func _setup_item_selector() -> void:
	item_selector.clear()
	
	print("[Market] Setting up item selector...")
	
	# Get available items from market
	if market_manager and market_manager.has_method("get_tradeable_items"):
		var items = market_manager.get_tradeable_items()
		print("[Market] Market manager items: ", items.size())
		for item in items:
			item_selector.add_item(item.get("name", "Unknown"), item.get("id", 0))
	else:
		# Default items if no market manager
		print("[Market] Using default items")
		item_selector.add_item("Energy Potion", 1)
		item_selector.add_item("Health Potion", 2)
		item_selector.add_item("Mana Potion", 3)
	
	print("[Market] Item selector count: ", item_selector.item_count)
	
	item_selector.item_selected.connect(_on_item_selected)
	
	if item_selector.item_count > 0:
		_on_item_selected(0)

func _setup_inputs() -> void:
	price_input.min_value = 1
	price_input.max_value = 999999
	price_input.step = 1
	price_input.value = 100
	price_input.value_changed.connect(_update_total)
	
	quantity_input.min_value = 1
	quantity_input.max_value = 9999
	quantity_input.step = 1
	quantity_input.value = 1
	quantity_input.value_changed.connect(_update_total)
	
	_update_total(0)

func _on_item_selected(index: int) -> void:
	selected_item_id = str(item_selector.get_item_id(index))
	_load_order_book()
	_load_my_orders()

func _load_order_book() -> void:
	_clear_list(order_book_list)
	
	if not market_manager or not market_manager.has_method("get_order_book"):
		return
	
	current_order_book = market_manager.get_order_book(selected_item_id)
	
	# Display buy orders (bids)
	var bids = current_order_book.get("bids", [])
	if bids.size() > 0:
		var buy_header = _create_header_label("Alış Emirleri", Color.GREEN)
		order_book_list.add_child(buy_header)
		
		for order in bids:
			var order_item = _create_order_book_item(order, OrderType.BUY)
			order_book_list.add_child(order_item)
	
	# Add separator
	var separator = HSeparator.new()
	separator.custom_minimum_size.y = 20
	order_book_list.add_child(separator)
	
	# Display sell orders (asks)
	var asks = current_order_book.get("asks", [])
	if asks.size() > 0:
		var sell_header = _create_header_label("Satış Emirleri", Color.RED)
		order_book_list.add_child(sell_header)
		
		for order in asks:
			var order_item = _create_order_book_item(order, OrderType.SELL)
			order_book_list.add_child(order_item)

func _create_header_label(text: String, color: Color) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = color
	return label

func _create_order_book_item(order: Dictionary, type: OrderType) -> Control:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size.y = 30
	
	# Price
	var price_label = Label.new()
	price_label.text = "%d G" % order.get("price", 0)
	price_label.custom_minimum_size.x = 100
	price_label.modulate = Color.GREEN if type == OrderType.BUY else Color.RED
	hbox.add_child(price_label)
	
	# Quantity
	var qty_label = Label.new()
	qty_label.text = "×%d" % order.get("quantity", 0)
	qty_label.custom_minimum_size.x = 80
	hbox.add_child(qty_label)
	
	# Total
	var row_total_label = Label.new()
	var total = order.get("price", 0) * order.get("quantity", 0)
	row_total_label.text = "%d G" % total
	row_total_label.custom_minimum_size.x = 120
	row_total_label.modulate = Color(0.8, 0.8, 0.8)
	hbox.add_child(row_total_label)
	
	# Quick trade button
	var trade_button = Button.new()
	trade_button.text = "Hızlı Al" if type == OrderType.SELL else "Hızlı Sat"
	trade_button.custom_minimum_size.x = 100
	trade_button.pressed.connect(_on_quick_trade.bind(order, type))
	hbox.add_child(trade_button)
	
	return hbox

func _load_my_orders() -> void:
	_clear_list(my_orders_list)
	
	if not market_manager or not market_manager.has_method("get_player_orders"):
		return
	
	var orders = market_manager.get_player_orders(selected_item_id)
	
	if orders.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Aktif emriniz yok"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		my_orders_list.add_child(empty_label)
		return
	
	for order in orders:
		var order_item = _create_my_order_item(order)
		my_orders_list.add_child(order_item)

func _create_my_order_item(order: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size.y = 60
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margin)
	
	var hbox = HBoxContainer.new()
	margin.add_child(hbox)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)
	
	# Order type and price
	var type_label = Label.new()
	var order_type = order.get("type", "buy")
	type_label.text = "%s - %d G × %d" % [
		"ALIŞ" if order_type == "buy" else "SATIŞ",
		order.get("price", 0),
		order.get("quantity", 0)
	]
	type_label.modulate = Color.GREEN if order_type == "buy" else Color.RED
	vbox.add_child(type_label)
	
	# Status
	var status_label = Label.new()
	status_label.text = "Durum: %s" % order.get("status", "pending")
	status_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(status_label)
	
	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "İptal"
	cancel_button.custom_minimum_size.x = 80
	cancel_button.pressed.connect(_on_cancel_order.bind(order))
	hbox.add_child(cancel_button)
	
	return panel

func _update_total(_value: float) -> void:
	var total = price_input.value * quantity_input.value
	total_label.text = "Toplam: %d Altın" % int(total)

func _on_buy_pressed() -> void:
	if not market_manager or not market_manager.has_method("place_buy_order"):
		return
	
	var price = int(price_input.value)
	var quantity = int(quantity_input.value)
	
	market_manager.place_buy_order(selected_item_id, price, quantity)

func _on_sell_pressed() -> void:
	if not market_manager or not market_manager.has_method("place_sell_order"):
		return
	
	var price = int(price_input.value)
	var quantity = int(quantity_input.value)
	
	market_manager.place_sell_order(selected_item_id, price, quantity)

func _on_quick_trade(order: Dictionary, type: OrderType) -> void:
	if not market_manager:
		return
	
	# Quick trade = match with existing order
	if type == OrderType.SELL and market_manager.has_method("quick_buy"):
		market_manager.quick_buy(order.get("id", ""))
	elif type == OrderType.BUY and market_manager.has_method("quick_sell"):
		market_manager.quick_sell(order.get("id", ""))

func _on_cancel_order(order: Dictionary) -> void:
	if market_manager and market_manager.has_method("cancel_order"):
		market_manager.cancel_order(order.get("id", ""))

func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()

# Signal handlers
func _on_order_placed(_order_id: String) -> void:
	_load_order_book()
	_load_my_orders()

func _on_order_filled(_order_id: String) -> void:
	_load_order_book()
	_load_my_orders()

func _on_order_cancelled(_order_id: String) -> void:
	_load_my_orders()

func _on_market_updated(_item_id: String) -> void:
	if _item_id == selected_item_id:
		_load_order_book()

func refresh() -> void:
	_load_order_book()
	_load_my_orders()
