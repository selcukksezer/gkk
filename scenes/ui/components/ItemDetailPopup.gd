extends PanelContainer

signal close_requested
signal buy_requested(listing)

@onready var icon_rect = %Icon
@onready var name_label = %NameLabel
@onready var rarity_label = %RarityLabel
@onready var desc_label = %DescriptionLabel
@onready var seller_label = %SellerLabel
@onready var price_label = %PriceLabel
@onready var buy_button = %BuyButton
@onready var close_button = %CloseButton
@onready var stats_vbox = %StatsVBox

var _current_listing: Dictionary = {}

var quantity_selector: SpinBox

func _ready() -> void:
	close_button.pressed.connect(func(): close_requested.emit())
	buy_button.pressed.connect(_on_buy_pressed)

func setup(listing: Dictionary) -> void:
	_current_listing = listing
	
	var item_id = listing.get("item_id", "")
	var price = listing.get("price", 0)
	var seller_name = listing.get("seller_name", "Unknown")
	var item_data_db = listing.get("item_data", {})
	var available_qty = listing.get("quantity", 1)
	
	var item_def = ItemDatabase.get_item(item_id)
	if not item_def: return
	
	# Icon
	var icon = item_def.get("icon", "")
	if icon.is_empty(): icon = item_def.get("icon_path", "")
	if not icon.is_empty():
		icon_rect.texture = load(icon)
		
	# Name & Rarity
	var item_name = item_def.get("name", "Unknown")
	var rarity_raw = item_def.get("rarity", ItemData.ItemRarity.COMMON)
	var rarity_enum = ItemData.ItemRarity.COMMON
	
	if typeof(rarity_raw) == TYPE_STRING:
		if ItemData.ItemRarity.has(rarity_raw):
			rarity_enum = ItemData.ItemRarity[rarity_raw]
	elif typeof(rarity_raw) == TYPE_INT:
		rarity_enum = rarity_raw
		
	rarity_label.text = ItemData.ItemRarity.keys()[rarity_enum]
	rarity_label.modulate = ItemData.get_rarity_color_static(rarity_enum)
	
	# Enhancement
	if item_data_db is Dictionary and item_data_db.has("enhancement_level"):
		var level = int(item_data_db.get("enhancement_level", 0))
		if level > 0:
			item_name += " +%d" % level
			
	name_label.text = item_name
	name_label.modulate = ItemData.get_rarity_color_static(rarity_enum)
	
	# Description
	desc_label.text = item_def.get("description", "")
	
	# Seller & Price
	seller_label.text = "Satıcı: %s" % seller_name
	
	# Quantity Selector Logic
	if available_qty > 1:
		if not quantity_selector:
			quantity_selector = SpinBox.new()
			quantity_selector.min_value = 1
			quantity_selector.max_value = available_qty
			quantity_selector.value = 1
			quantity_selector.alignment = HORIZONTAL_ALIGNMENT_CENTER
			quantity_selector.value_changed.connect(_update_total_price)
			# Add before Price Label (assuming price label is in a VBox/HBox)
			# Price label parent is likely a VBox since it is a popup.
			# Let's verify stats_vbox or price_label parent.
			# price_label is %PriceLabel.
			# We'll try to add it before price label.
			# Using move_child to ensure correct positioning
			var parent = price_label.get_parent()
			parent.add_child(quantity_selector)
			parent.move_child(quantity_selector, seller_label.get_index() + 1)
			
		quantity_selector.visible = true
		quantity_selector.max_value = available_qty
		quantity_selector.value = 1
		# Trigger update
		_update_total_price(1)
	else:
		if quantity_selector: quantity_selector.visible = false
		price_label.text = "%d Altın" % price

	# Self Purchace Check
	var current_user_id = State.player.get("id")
	var current_auth_id = State.player.get("auth_id")
	var seller_id = listing.get("seller_id")
	
	if seller_id == current_user_id or seller_id == current_auth_id:
		buy_button.disabled = true
		buy_button.text = "Senin İlanın"
	else:
		buy_button.disabled = false
		buy_button.text = "SATIN AL"
	
	# Display Stats
	_display_stats(item_id, item_def, item_data_db)

func _display_stats(item_id: String, base_def: Dictionary, instance_data: Dictionary) -> void:
	# Clear previous stats
	for child in stats_vbox.get_children():
		child.queue_free()
		
	# Create ItemData instance to calculate total stats (including enhancement)
	# Merge DB data to simulate the item
	var simulated_data = base_def.duplicate()
	if instance_data:
		for k in instance_data:
			simulated_data[k] = instance_data[k]
			
	var item_obj = ItemData.from_dict(simulated_data)
	
	# Add Stats Rows
	if item_obj.attack > 0: _add_stat_row("Saldırı Gücü", item_obj.get_total_attack())
	if item_obj.defense > 0: _add_stat_row("Defans", item_obj.get_total_defense())
	if item_obj.health > 0: _add_stat_row("Can", item_obj.get_total_health())
	if item_obj.power > 0: _add_stat_row("Güç", item_obj.get_total_power())
	
func _add_stat_row(label: String, value: int) -> void:
	var hbox = HBoxContainer.new()
	var l_lbl = Label.new()
	l_lbl.text = label
	l_lbl.modulate = Color(0.7, 0.7, 0.7)
	l_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var v_lbl = Label.new()
	v_lbl.text = str(value)
	v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	hbox.add_child(l_lbl)
	hbox.add_child(v_lbl)
	stats_vbox.add_child(hbox)

func _update_total_price(qty: float) -> void:
	var unit_price = _current_listing.get("price", 0)
	var total = unit_price * int(qty)
	price_label.text = "%d Altın (%d adet)" % [total, int(qty)]

func _on_buy_pressed() -> void:
	var qty = 1
	if quantity_selector and quantity_selector.visible:
		qty = int(quantity_selector.value)
		
	_current_listing["buy_quantity"] = qty
	# Also update total price in listing so PazarScreen knows how much to pay/deduct optimistically
	var unit_price = _current_listing.get("price", 0)
	_current_listing["total_price"] = unit_price * qty
	
	buy_requested.emit(_current_listing)
