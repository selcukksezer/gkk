extends Control

# UI Nodes
@onready var filter_drawer = $MainLayout/RightPanel/ContentArea/FilterDrawer
@onready var filter_toggle_btn = $MainLayout/RightPanel/HeaderContainer/TopRow/FilterToggleButton
@onready var filter_panel = $MainLayout/RightPanel/ContentArea/FilterDrawer/PazarFilterPanel
@onready var browse_grid = $MainLayout/RightPanel/ContentArea/BrowseView/FlowContainer
@onready var sell_grid = $MainLayout/RightPanel/ContentArea/SellView/FlowContainer
@onready var my_orders_list = $MainLayout/RightPanel/ContentArea/MyOrdersView/List

# Views
@onready var browse_view = $MainLayout/RightPanel/ContentArea/BrowseView
@onready var sell_view = $MainLayout/RightPanel/ContentArea/SellView
@onready var my_orders_view = $MainLayout/RightPanel/ContentArea/MyOrdersView

# Tabs
@onready var browse_tab = $MainLayout/RightPanel/HeaderContainer/TabsRow/BrowseTab
@onready var sell_tab = $MainLayout/RightPanel/HeaderContainer/TabsRow/SellTab
@onready var my_orders_tab = $MainLayout/RightPanel/HeaderContainer/TabsRow/MyOrdersTab

# Overlay
@onready var overlay_layer = $OverlayLayer
@onready var trade_view = $OverlayLayer/TradeOverlay/CenterContainer/Panel/PazarTradeView
@onready var close_button = $MainLayout/RightPanel/HeaderContainer/TopRow/CloseButton

# Resources
var item_card_scene = preload("res://scenes/ui/components/ItemCard.tscn")
var market_manager: Node
var current_filters: Dictionary = {}

func _ready() -> void:
	market_manager = get_node_or_null("/root/PazarManager")
	
	# Connect Filter Signals
	if filter_panel:
		filter_panel.filters_changed.connect(_on_filters_changed)
	else:
		printerr("CRITICAL: PazarFilterPanel not found!")
		
	# Filter Toggle
	if filter_toggle_btn:
		filter_toggle_btn.toggled.connect(_on_filter_toggle)
		_on_filter_toggle(false) # Init as hidden
		
	# Connect Tabs
	browse_tab.pressed.connect(func(): _switch_tab("browse"))
	sell_tab.pressed.connect(func(): _switch_tab("sell"))
	my_orders_tab.pressed.connect(func(): _switch_tab("orders"))
	
	close_button.pressed.connect(_on_close_screen)
	
	# Connect Trade View Signals
	if trade_view:
		trade_view.close_requested.connect(_on_close_trade_view)
		trade_view.buy_order_placed.connect(_on_buy_order)
		trade_view.sell_order_placed.connect(_on_sell_order)
	else:
		printerr("CRITICAL: PazarTradeView not found!")
		
	# Initial State
	_switch_tab("browse")

func _on_filter_toggle(pressed: bool) -> void:
	if filter_drawer:
		filter_drawer.visible = pressed
	
	if filter_toggle_btn:
		# Keep pressed state visually synced if needed
		filter_toggle_btn.set_pressed_no_signal(pressed)

func _on_close_screen() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")

func _switch_tab(tab_name: String) -> void:
	print("PazarScreen: Switching to tab -> ", tab_name)
	
	# Reset all
	browse_view.visible = false
	sell_view.visible = false
	my_orders_view.visible = false
	
	browse_tab.set_pressed_no_signal(false)
	sell_tab.set_pressed_no_signal(false)
	my_orders_tab.set_pressed_no_signal(false)
	
	match tab_name:
		"browse":
			browse_view.visible = true
			browse_tab.set_pressed_no_signal(true)
			_populate_catalog()
		"sell":
			sell_view.visible = true
			sell_tab.set_pressed_no_signal(true)
			_load_sell_inventory()
		"orders":
			my_orders_view.visible = true
			my_orders_tab.set_pressed_no_signal(true)
			_load_my_orders()

func _on_filters_changed(filters: Dictionary) -> void:
	current_filters = filters
	if browse_view.visible:
		_populate_catalog()

# --- Browse Logic ---
# --- Browse Logic ---
func _populate_catalog() -> void:
	if not browse_grid: return
	
	# Clear
	for child in browse_grid.get_children():
		child.queue_free()
		
	# Fetch Listings (All active orders)
	var listings = []
	if market_manager:
		var result = await market_manager.fetch_active_listings(1)
		if result is Dictionary and result.get("success", false) and result.has("listings"):
			listings = result.listings
			
	if listings.is_empty():
		var label = Label.new()
		label.text = "Aktif ilan bulunamadı."
		browse_grid.add_child(label)
		return
	
	for order in listings:
		var item_id = order.get("item_id")
		var price = order.get("price", 0)
		var item_data_db = order.get("item_data", {})
		
		# Validate Item Exists
		if not ItemDatabase.get_item(item_id): continue
		
		# Create ItemData Object
		var item_def = ItemDatabase.get_item(item_id).duplicate()
		var display_item = ItemData.from_dict(item_def)
		
		# Updates from Order
		display_item.base_price = price # Set price for shop mode display
		
		# Apply Stats (Enhancement, etc.)
		if item_data_db is Dictionary:
			if item_data_db.has("enhancement_level"):
				display_item.enhancement_level = int(item_data_db.get("enhancement_level", 0))
		
		# Check Filters
		if not _passes_filters(display_item): continue
		
		var card = item_card_scene.instantiate()
		browse_grid.add_child(card)
		
		# Setup in Shop Mode (Show Price)
		card.setup(display_item, true)
		
		# When clicking, open generic trade view for now (matches cheapest)
		# TODO: Pass order_id if we want to buy usage specific listing
		card.item_selected.connect(func(itm): _open_trade_view(itm.item_id))

func _passes_filters(item: ItemData) -> bool:
	if not item.is_tradeable: return false
	
	var search = current_filters.get("search", "").to_lower()
	if not search.is_empty() and not item.name.to_lower().contains(search):
		return false
		
	var cat_id = current_filters.get("category", 0)
	if cat_id != 0:
		var type = item.item_type
		match cat_id:
			1: if type != ItemData.ItemType.WEAPON: return false
			2: if type != ItemData.ItemType.ARMOR: return false
			3: if type != ItemData.ItemType.POTION: return false
			4: if type != ItemData.ItemType.SCROLL: return false
			5: if type != ItemData.ItemType.MATERIAL: return false
			
	var rarities = current_filters.get("rarities", [])
	if not rarities.is_empty() and not item.rarity in rarities:
		return false
		
	return true

# --- Sell Logic ---
# --- Sell Logic ---
func _load_sell_inventory() -> void:
	if not sell_grid: return
	for child in sell_grid.get_children(): child.queue_free()
	
	var inventory = State.inventory
	if inventory.is_empty():
		var label = Label.new()
		label.text = "Envanter boş."
		sell_grid.add_child(label)
		return
		
	for item_dict in inventory:
		var item = ItemData.from_dict(item_dict)
		
		# P2P Sell Logic:
		# 1. Must be tradeable
		# 2. Must NOT be equipped
		if not item.is_tradeable: continue
		if item.is_equipped: continue 
		
		var card = item_card_scene.instantiate()
		sell_grid.add_child(card)
		card.setup(item, false)
		# Pass the full item object so we have the row_id for selling
		card.item_selected.connect(func(itm): _open_trade_view(itm.item_id, itm))

# --- Orders Logic ---
func _load_my_orders() -> void:
	if not my_orders_list: return
	for child in my_orders_list.get_children(): child.queue_free()
	
	if market_manager:
		# Use Server-Side Filtering (Efficient for 50k+ items)
		var result = await market_manager.fetch_my_orders()
		
		# Debug for user
		var user_id = State.player.get("id")
		print("[Performance] Fetching My Orders from Server for ID: ", user_id)
		
		if result is Dictionary and result.get("success", false) and result.has("orders"):
			var my_listings = result.orders
			
			if my_listings.is_empty():
				var label = Label.new()
				label.text = "Aktif satış ilanınız yok."
				my_orders_list.add_child(label)
				return
				
			for order in my_listings:
				# ... Same Display Logic ...
				var item_id = order.get("item_id")
				var price = order.get("price", 0)
				var item_data_db = order.get("item_data", {})
				
				if not ItemDatabase.get_item(item_id): continue
				
				var item_def = ItemDatabase.get_item(item_id).duplicate()
				var display_item = ItemData.from_dict(item_def)
				display_item.base_price = price
				
				if item_data_db is Dictionary:
					if item_data_db.has("enhancement_level"):
						display_item.enhancement_level = int(item_data_db.get("enhancement_level", 0))
						
				var card = item_card_scene.instantiate()
				my_orders_list.add_child(card)
				card.setup(display_item, true) # Shop mode shows price
			# TODO: Click to Cancel?
			# card.item_selected.connect(...)

# --- Trade View Logic ---
# Updated signature to accept optional item_instance (for selling specific inventory items)
func _open_trade_view(item_id: String, item_instance: ItemData = null) -> void:
	print("PazarScreen: Opening Trade View for ", item_id)
	if overlay_layer:
		overlay_layer.visible = true
	if trade_view:
		trade_view.setup(item_id, item_instance)

func _on_close_trade_view() -> void:
	if overlay_layer:
		overlay_layer.visible = false

func _on_buy_order(item_id, price, quantity) -> void:
	if market_manager:
		# Buying is generic by item_id
		market_manager.place_buy_order(item_id, quantity, price, 1)

func _on_sell_order(item_id, price, quantity, item_row_id) -> void:
	print("PazarScreen: _on_sell_order called with ID:", item_id, " Qty:", quantity, " Price:", price, " RowID:", item_row_id)
	if market_manager and item_row_id:
		# Selling requires specific row_id
		print("PazarScreen: Calling market_manager.place_sell_order...")
		var result = await market_manager.place_sell_order(item_row_id, quantity, price)
		
		print("PazarScreen: Sell result -> ", result)
		
		if result.success:
			print("PazarScreen: Order placed successfully!")
			_on_close_trade_view()
			# Switch to orders to show the new listing
			_switch_tab("orders")
			
			# Refresh sell view if we go back to it
			_load_sell_inventory()
		else:
			printerr("PazarScreen: Failed to place order: ", result.get("error", "Unknown"))
			# TODO: Show error dialog
			
	else:
		printerr("PazarScreen: Cannot sell - Missing MarketManager or RowID!")
