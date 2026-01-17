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
# Resources
var item_card_scene = preload("res://scenes/ui/components/ItemCard.tscn")
var listing_row_scene = preload("res://scenes/ui/components/ListingRow.tscn")
var market_manager: Node
var current_filters: Dictionary = {}

# Overlay Components
@onready var detail_popup = $OverlayLayer/TradeOverlay/CenterContainer/Panel/PazarTradeView # We will rename this node in UI or script logic wrapper
# Actually, since PazarTradeView script is attached to the node in scene, we should ideally replace the node type if we can, or just re-bind.
# Since I cannot easily edit the .tscn structure without text editing which is risky for large scene files, I will assume I can instantiate ItemDetailPopup dynamically or that I replaced the child.
# Safer approach: Instantiate `ItemDetailPopup` effectively replacing the old view logic. 
# But wait, `PazarTradeView` is an `@onready` var pointing to a node in the scene tree. 
# I should change the script attached to that node or instantiate a new popup.
# PLAN: I will instantiate `ItemDetailPopup.tscn` dynamically and add it to the overlay when needed, and ignore the old `PazarTradeView` node or hide it.

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
		filter_toggle_btn.visible = true # Keep visible, filters work on listings too
		
	# Connect Tabs
	browse_tab.pressed.connect(func(): _switch_tab("browse"))
	sell_tab.pressed.connect(func(): _switch_tab("sell"))
	my_orders_tab.pressed.connect(func(): _switch_tab("orders"))
	
	close_button.pressed.connect(_on_close_screen)
	
	# Connect Trade View Signals
	if trade_view:
		trade_view.close_requested.connect(_on_close_trade_view)
		# trade_view.buy_order_placed.connect(_on_buy_order) # Removed: Buy flow handled by ItemDetailPopup
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
		
		# Validate Item Exists
		if not ItemDatabase.get_item(item_id): continue
		
		# Check Filters
		# We need to construct a dummy ItemData to check filters against
		var item_def = ItemDatabase.get_item(item_id)
		var dummy_item = ItemData.from_dict(item_def)
		# Populate with listing specific data for accurate filter (rarity/type is static)
		if not _passes_filters(dummy_item): continue
		
		var row = listing_row_scene.instantiate()
		browse_grid.add_child(row)
		
		# Setup Listing Row
		row.setup(order)
		
		# Connect Click
		row.inspect_requested.connect(_on_inspect_listing)


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

var my_order_row_scene = preload("res://scenes/ui/components/MyOrderRow.tscn")

# ... (Existing code)

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
		
		# Change MyOrdersView List from GridContainer to VBoxContainer if previously Grid?
		# Assuming it is a VBoxContainer or FlowContainer that works with rows now.
		# Note: If it's a FlowContainer, full width rows might look weird unless we force width.
		# Let's trust the container handles full width children if they expand.
		
		if result is Dictionary and result.get("success", false) and result.has("orders"):
			var my_listings = result.orders
			
			if my_listings.is_empty():
				var label = Label.new()
				label.text = "Aktif satış ilanınız yok."
				my_orders_list.add_child(label)
				return
				
			for order in my_listings:
				# Validate Item Exists
				var item_id = order.get("item_id")
				if not ItemDatabase.get_item(item_id): continue
				
				var row = my_order_row_scene.instantiate()
				my_orders_list.add_child(row)
				
				# Setup with direct order dict
				row.setup(order)
				
				# Connect Remove Signal
				row.remove_requested.connect(_on_cancel_order_requested)

func _on_cancel_order_requested(order_id: String, is_stackable: bool = false) -> void:
	print("PazarScreen: Cancel Requested for Order: ", order_id, " Stackable: ", is_stackable)
	
	if not market_manager: return
	
	# Show loading or disable interaction could be good here
	
	var result = await market_manager.cancel_order(order_id, is_stackable)
	
	if result.success:
		print("PazarScreen: Order cancelled successfully.")
		# Refresh the list
		_load_my_orders()
		# Optionally show a toast/notification
	else:
		var error_msg = result.get("error", "Unknown error")
		printerr("PazarScreen: Failed to cancel order: ", error_msg)
		
		if "full" in error_msg.to_lower() or "dolu" in error_msg.to_lower():
			_show_alert("İşlem başarısız: Envanter dolu!")
		else:
			_show_alert("Sipariş iptal edilemedi: %s" % error_msg)


# --- Trade View Logic ---
# Updated signature to accept optional item_instance (for selling specific inventory items)
func _open_trade_view(item_id: String, item_instance: ItemData = null) -> void:
	print("PazarScreen: Opening Trade View for ", item_id)
	if overlay_layer:
		overlay_layer.visible = true
		
	var trade_overlay = $OverlayLayer/TradeOverlay
	if trade_overlay:
		trade_overlay.visible = true
	if trade_view:
		trade_view.setup(item_id, item_instance)

func _on_close_trade_view() -> void:
	if overlay_layer:
		overlay_layer.visible = false

var active_detail_popup: Node = null
var detail_popup_scene = preload("res://scenes/ui/components/ItemDetailPopup.tscn")

func _on_inspect_listing(listing: Dictionary) -> void:
	print("PazarScreen: Inspecting Listing -> ", listing)
	
	if overlay_layer:
		overlay_layer.visible = true
		
	var trade_overlay = $OverlayLayer/TradeOverlay
	if trade_overlay:
		trade_overlay.visible = false # Hide default trade view
		
	# Instantiate Detail Popup
	if active_detail_popup:
		active_detail_popup.queue_free()
		
	active_detail_popup = detail_popup_scene.instantiate()
	overlay_layer.add_child(active_detail_popup)
	
	# Center it? The scene anchors should handle it if added to a center container, 
	# but overlay_layer is likely a CanvasLayer with a full rect Control. 
	# Let's add it to the existing CenterContainer if possible or just center it.
	# The scene has anchors_preset = 8 (Center), so if overlay_layer is full rect, it should center.
	
	active_detail_popup.setup(listing)
	active_detail_popup.close_requested.connect(_close_detail_popup)
	active_detail_popup.buy_requested.connect(_on_buy_listing_requested)

func _close_detail_popup() -> void:
	if active_detail_popup:
		active_detail_popup.queue_free()
		active_detail_popup = null
		
	if overlay_layer:
		overlay_layer.visible = false

func _on_buy_listing_requested(listing: Dictionary) -> void:
	var order_id = listing.get("id") # Order ID from view
	var qty = listing.get("buy_quantity", 1)
	var total_price = listing.get("total_price", listing.get("price", 0)) # Default to unit price if total missing
	
	if State.gold < total_price:
		print("PazarScreen: Not enough gold!")
		_show_alert("Bakiye yetersiz! Gerekli: %d Altın" % total_price)
		return
		
	if market_manager:
		var item_id = listing.get("item_id", "")
		var item_def = ItemDatabase.get_item(item_id)
		var is_stackable = item_def.get("is_stackable", false)
		
		var result = await market_manager.purchase_listing(order_id, qty, int(total_price), is_stackable)
		if result.success:
			print("PazarScreen: Purchase successful!")
			Audio.play_coin()
			_close_detail_popup()
			_populate_catalog() # Refresh list
			# Update Header Gold display if it exists (State updates signal it automatically usually)
		else:
			var error = result.get("error", "Unknown Error")
			print("PazarScreen: Purchase failed: ", error)
			
			if error == "Inventory full":
				_show_alert("Envanter dolu! Satın alma gerçekleştirilemedi.")
			else:
				_show_alert("Satın alma başarısız: %s" % error)

func _show_alert(message: String) -> void:
	# Create a full-screen dimmer
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.5)
	
	# Create the dialog panel
	var panel = PanelContainer.new()
	# Center the panel
	panel.set_anchors_preset(Control.PRESET_CENTER)
	# Add some minimum size
	panel.custom_minimum_size = Vector2(300, 0)
	
	dimmer.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	# Add some padding via margin container if needed, but VBox is fine for simple alert
	
	# Title
	var title = Label.new()
	title.text = "Pazar"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(title)
	
	# Message
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg_label)
	
	# OK Button
	var btn = Button.new()
	btn.text = "Tamam"
	btn.custom_minimum_size = Vector2(100, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pressed.connect(func(): dimmer.queue_free())
	vbox.add_child(btn)
	
	panel.add_child(vbox)
	
	# Add to self (Screen Root) to ensure it is visible regardless of OverlayLayer state
	add_child(dimmer)
	
	# Ensure it's on top
	move_child(dimmer, get_child_count() - 1)

# Keep Sell Order Logic (it uses ItemCard and existing SellView)
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
