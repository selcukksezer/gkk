extends Control
## Market Screen
## Order book market for buying and selling items

@onready var item_search = $TopBar/SearchField
@onready var search_button = $TopBar/SearchButton

@onready var buy_orders_list = $OrderBook/BuyOrders/ScrollContainer/VBoxContainer
@onready var sell_orders_list = $OrderBook/SellOrders/ScrollContainer/VBoxContainer

@onready var market_stats = $StatsPanel
@onready var lowest_sell_label = $StatsPanel/LowestSell/Value
@onready var highest_buy_label = $StatsPanel/HighestBuy/Value
@onready var last_trade_label = $StatsPanel/LastTrade/Value
@onready var volume_24h_label = $StatsPanel/Volume24h/Value

@onready var place_order_panel = $PlaceOrderPanel
@onready var order_type_tabs = $PlaceOrderPanel/TabContainer
@onready var buy_quantity_spin = $PlaceOrderPanel/TabContainer/Buy/QuantitySpinBox
@onready var buy_price_spin = $PlaceOrderPanel/TabContainer/Buy/PriceSpinBox
@onready var buy_total_label = $PlaceOrderPanel/TabContainer/Buy/TotalLabel
@onready var buy_button = $PlaceOrderPanel/TabContainer/Buy/PlaceOrderButton

@onready var sell_quantity_spin = $PlaceOrderPanel/TabContainer/Sell/QuantitySpinBox
@onready var sell_price_spin = $PlaceOrderPanel/TabContainer/Sell/PriceSpinBox
@onready var sell_total_label = $PlaceOrderPanel/TabContainer/Sell/TotalLabel
@onready var sell_button = $PlaceOrderPanel/TabContainer/Sell/PlaceOrderButton

@onready var my_orders_button = $BottomBar/MyOrdersButton
@onready var back_button = $BottomBar/BackButton

var _current_item_id: String = ""
var _order_row_scene = preload("res://scenes/prefabs/MarketOrderRow.tscn")

func _ready() -> void:
	# Connect signals
	search_button.pressed.connect(_on_search_pressed)
	buy_button.pressed.connect(_on_place_buy_order)
	sell_button.pressed.connect(_on_place_sell_order)
	my_orders_button.pressed.connect(_on_my_orders_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	buy_quantity_spin.value_changed.connect(_update_buy_total)
	buy_price_spin.value_changed.connect(_update_buy_total)
	sell_quantity_spin.value_changed.connect(_update_sell_total)
	sell_price_spin.value_changed.connect(_update_sell_total)
	
	# Track screen
	Telemetry.track_screen("market")
	
	# Default search (popular item)
	_search_item("sword_epic_001")

func _search_item(item_id: String) -> void:
	_current_item_id = item_id
	item_search.text = item_id
	
	# Load market data
	var result = await Network.http_get("/market/orders?item_id=" + item_id)
	_on_market_data_loaded(result)

func _on_search_pressed() -> void:
	var search_text = item_search.text.strip_edges()
	if search_text.is_empty():
		return
	
	_search_item(search_text)
	Telemetry.track_event("market", "search", {"item_id": search_text})

func _on_market_data_loaded(result: Dictionary) -> void:
	if not result.success:
		print("[Market] Failed to load market data")
		return
	
	var data = result.data
	
	# Clear lists
	for child in buy_orders_list.get_children():
		child.queue_free()
	for child in sell_orders_list.get_children():
		child.queue_free()
	
	# Populate buy orders
	var buy_orders = data.get("buy_orders", [])
	for order_dict in buy_orders:
		var order = MarketOrderData.from_dict(order_dict)
		var row = _order_row_scene.instantiate()
		buy_orders_list.add_child(row)
		row.set_order(order)
		row.clicked.connect(_on_order_clicked.bind(order))
	
	# Populate sell orders
	var sell_orders = data.get("sell_orders", [])
	for order_dict in sell_orders:
		var order = MarketOrderData.from_dict(order_dict)
		var row = _order_row_scene.instantiate()
		sell_orders_list.add_child(row)
		row.set_order(order)
		row.clicked.connect(_on_order_clicked.bind(order))
	
	# Update stats
	var stats = data.get("market_stats", {})
	lowest_sell_label.text = str(stats.get("lowest_sell", 0)) + "g"
	highest_buy_label.text = str(stats.get("highest_buy", 0)) + "g"
	last_trade_label.text = str(stats.get("last_trade_price", 0)) + "g"
	volume_24h_label.text = str(stats.get("24h_volume", 0))

func _on_order_clicked(order: MarketOrderData) -> void:
	# Fill in price field with clicked order's price
	if order.order_type == "sell":
		# Clicked a sell order, fill buy form
		buy_price_spin.value = order.price_per_unit
	else:
		# Clicked a buy order, fill sell form
		sell_price_spin.value = order.price_per_unit

func _update_buy_total(_value: float = 0) -> void:
	var quantity = int(buy_quantity_spin.value)
	var price = int(buy_price_spin.value)
	var total = quantity * price
	buy_total_label.text = "Total: %d gold" % total

func _update_sell_total(_value: float = 0) -> void:
	var quantity = int(sell_quantity_spin.value)
	var price = int(sell_price_spin.value)
	var total = quantity * price
	var fee = int(total * 0.02)  # 2% fee
	sell_total_label.text = "Total: %d gold (Fee: %d)" % [total - fee, fee]

func _on_place_buy_order() -> void:
	var quantity = int(buy_quantity_spin.value)
	var price = int(buy_price_spin.value)
	
	if quantity <= 0:
		print("[Market] Invalid quantity")
		return
	
	if price <= 0:
		print("[Market] Invalid price")
		return
	
	var total_cost = quantity * price
	if State.gold < total_cost:
		print("[Market] Insufficient gold")
		return
	
	var body = {
		"item_id": _current_item_id,
		"order_type": "buy",
		"quantity": quantity,
		"price_per_unit": price
	}
	
	var result = await Network.http_post("/market/place_order", body)
	_on_order_placed(result)
	
	Telemetry.track_event("economy.market", "order_placed", {
		"order_type": "buy",
		"item_id": _current_item_id,
		"quantity": quantity,
		"price": price
	})

func _on_place_sell_order() -> void:
	var quantity = int(sell_quantity_spin.value)
	var price = int(sell_price_spin.value)
	
	if quantity <= 0:
		print("[Market] Invalid quantity")
		return
	
	if price <= 0:
		print("[Market] Invalid price")
		return
	
	# TODO: Check if player has item in inventory
	
	var body = {
		"item_id": _current_item_id,
		"order_type": "sell",
		"quantity": quantity,
		"price_per_unit": price
	}
	
	var result = await Network.http_post("/market/place_order", body)
	_on_order_placed(result)
	
	Telemetry.track_event("economy.market", "order_placed", {
		"order_type": "sell",
		"item_id": _current_item_id,
		"quantity": quantity,
		"price": price
	})

func _on_order_placed(result: Dictionary) -> void:
	if result.success:
		print("[Market] Order placed successfully")
		_search_item(_current_item_id)  # Refresh
		
		# Update gold
		State.gold = result.data.get("user", {}).get("gold", State.gold)
	else:
		print("[Market] Failed to place order: ", result.get("error", ""))

func _on_my_orders_pressed() -> void:
	# Show player's active orders
	Scenes.change_scene("res://scenes/ui/MyOrdersScreen.tscn")

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
