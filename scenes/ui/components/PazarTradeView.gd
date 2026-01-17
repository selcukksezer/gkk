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
var current_item_instance: ItemData = null
var market_manager: Node

func _ready() -> void:
	close_button.pressed.connect(func(): close_requested.emit())
	
	# Buy Logic Removed
	# price_input.value_changed.connect(_update_buy_total)
	# quantity_input.value_changed.connect(_update_buy_total)
	# buy_button.pressed.connect(_on_buy_pressed)
	
	# Sell Logic
	sell_price_input.value_changed.connect(_update_sell_total)
	sell_quantity_input.value_changed.connect(_update_sell_total)
	sell_button.pressed.connect(_on_sell_pressed)
	
	market_manager = get_node_or_null("/root/PazarManager")
	
	_update_buy_total(0)
	_update_sell_total(0)

func setup(item_id: String, item_instance: ItemData = null) -> void:
	current_item_id = item_id
	current_item_instance = item_instance
	
	# Load item details (base definition)
	var item = ItemDatabase.get_item(item_id)
	if not item: return
		
	item_name.text = item.get("name", "Unknown")
	var rarity = item.get("rarity", 0)
	
	# Rarity Visuals
	var rarity_names = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]
	var rarity_int = 0
	if rarity is String:
		var idx = rarity_names.find(rarity)
		rarity_int = idx if idx != -1 else 0
		item_rarity.text = rarity if idx != -1 else rarity
	elif rarity is int:
		rarity_int = rarity
		item_rarity.text = rarity_names[rarity] if rarity >= 0 and rarity < rarity_names.size() else "UNKNOWN"
	
	item_rarity.modulate = ItemData.get_rarity_color_static(rarity_int)
	
	var icon_path = item.get("icon", "")
	if ResourceLoader.exists(icon_path):
		item_icon.texture = load(icon_path)
		
	# Setup Sell Tab State
	# Setup Sell Tab State
	_setup_sell_inputs()
	
	# Hide Buy Tab and Ensure Sell Tab
	var tab_container = $"Content/ActionPanel/TabContainer"
	if tab_container:
		var buy_tab = tab_container.get_node_or_null("Alış")
		if buy_tab:
			# In Godot 4, use set_tab_hidden to hide the tab selector
			var idx = buy_tab.get_index()
			tab_container.set_tab_hidden(idx, true)
			
		var sell_tab = tab_container.get_node_or_null("Satış")
		if sell_tab:
			tab_container.current_tab = sell_tab.get_index()
			
	# Update "Order Book" Label to "Stats"
	if order_list and order_list.get_parent() and order_list.get_parent().get_parent():
		var panel = order_list.get_parent().get_parent()
		var label = panel.get_node_or_null("Label")
		if label:
			label.text = "   Özellikler" # Update existing label
		
	# Display Stats
	_display_stats(item_id, item, item_instance)

var sell_commission_label: Label
var sell_earnings_label: Label

func _setup_sell_inputs() -> void:
	# Default: Enable inputs, max 999
	sell_quantity_input.editable = true
	sell_quantity_input.max_value = 9999
	sell_quantity_input.value = 1
	sell_button.disabled = false
	sell_button.text = "SATIŞ EMRİ GİR"
	
	# Create Tax Labels dynamically if missing
	if not sell_commission_label:
		sell_commission_label = Label.new()
		sell_commission_label.modulate = Color(1, 0.5, 0.5) # reddish
		var p = sell_total_label.get_parent()
		p.add_child(sell_commission_label)
		p.move_child(sell_commission_label, sell_total_label.get_index() + 1)
		
	if not sell_earnings_label:
		sell_earnings_label = Label.new()
		sell_earnings_label.modulate = Color(0.5, 1, 0.5) # greenish
		var p2 = sell_total_label.get_parent()
		p2.add_child(sell_earnings_label)
		p2.move_child(sell_earnings_label, sell_commission_label.get_index() + 1)
	
	if current_item_instance:
		# We are in SELL mode (opened from inventory)
		
		# Set max quantity to owned amt
		var max_qty = current_item_instance.quantity
		sell_quantity_input.max_value = max_qty
		sell_quantity_input.value = 1 # Default to 1
		
		if current_item_instance.is_equipment():
			# Equipment is single item
			sell_quantity_input.value = 1
			sell_quantity_input.editable = false # Cannot change qty for unique equip
			
	else:
		# We are in BROWSE mode (no specific item selected to sell)
		sell_button.disabled = true
		sell_button.text = "Satış için 'Sat' sekmesinden seçin"
		sell_quantity_input.value = 0
		sell_quantity_input.editable = false

func _display_stats(item_id: String, base_def: Dictionary, instance: ItemData) -> void:
	# Use OrderList container for stats
	for child in order_list.get_children():
		child.queue_free()
		
	# Ensure parent is visible
	if order_list.get_parent() and order_list.get_parent().get_parent():
		order_list.get_parent().get_parent().visible = true
		
	# Header is already updated in setup ("Label" node)
	# But just in case we are reusing this func, we won't add a new header here.
	
	var item_obj = instance
	if not item_obj:
		item_obj = ItemData.from_dict(base_def)
		
	if item_obj.attack > 0: _add_stat_row("Saldırı Gücü", item_obj.get_total_attack())
	if item_obj.defense > 0: _add_stat_row("Defans", item_obj.get_total_defense())
	if item_obj.health > 0: _add_stat_row("Can", item_obj.get_total_health())
	if item_obj.power > 0: _add_stat_row("Güç", item_obj.get_total_power())
	
	if not item_obj.description.is_empty():
		var desc = Label.new()
		desc.text = item_obj.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.modulate = Color(0.7, 0.7, 0.7)
		order_list.add_child(HSeparator.new())
		order_list.add_child(desc)

func _add_stat_row(label: String, value: int) -> void:
	var hbox = HBoxContainer.new()
	var l_lbl = Label.new()
	l_lbl.text = label
	l_lbl.modulate = Color(0.8, 0.8, 0.8)
	l_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var v_lbl = Label.new()
	v_lbl.text = str(value)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v_lbl.modulate = Color(0.5, 1, 0.5) # Greenish for stats
	
	hbox.add_child(l_lbl)
	hbox.add_child(v_lbl)
	order_list.add_child(hbox)

func _update_buy_total(_val) -> void:
	var total = price_input.value * quantity_input.value
	total_label.text = "Toplam: %d Altın" % total

func _update_sell_total(_val) -> void:
	var qty = int(sell_quantity_input.value)
	var price = int(sell_price_input.value)
	var total = price * qty
	
	var tax = int(total * 0.05)
	var earnings = total - tax
	
	sell_total_label.text = "Satış Tutarı: %d Altın" % total
	if sell_commission_label:
		sell_commission_label.text = "Pazar Komisyonu (%%5): -%d Altın" % tax
	if sell_earnings_label:
		sell_earnings_label.text = "Net Kazanç: %d Altın" % earnings

func _on_buy_pressed() -> void:
	buy_order_placed.emit(current_item_id, int(price_input.value), int(quantity_input.value))

func _on_sell_pressed() -> void:
	if not current_item_instance: return
	
	var qty = int(sell_quantity_input.value)
	var price = int(sell_price_input.value)
	
	# Validate Quantity again locally
	if qty > current_item_instance.quantity:
		# Could show error UI here
		print("Error: Attempting to sell more than owned")
		return
		
	sell_order_placed.emit(current_item_id, price, qty, current_item_instance.row_id)
