extends PanelContainer

signal remove_requested(order_id, is_stackable)

@onready var icon_rect = %Icon
@onready var name_label = %NameLabel
@onready var price_label = %PriceLabel
@onready var quantity_label = %QuantityLabel
@onready var remove_button = %RemoveButton

var _order_id: String = ""
var _is_stackable: bool = false

func setup(order: Dictionary) -> void:
	_order_id = order.get("id", "")
	var item_id = order.get("item_id", "")
	var price = order.get("price", 0)
	var quantity = order.get("quantity", 1)
	var item_data_db = order.get("item_data", {})
	
	# Load item definition
	var item_def = ItemDatabase.get_item(item_id)
	if not item_def: 
		push_error("MyOrderRow: Invalid item_id " + str(item_id))
		return
		
	_is_stackable = item_def.get("is_stackable", false)
	
	var item_name = item_def.get("name", "Unknown Item")
	var rarity_raw = item_def.get("rarity", ItemData.ItemRarity.COMMON)
	var rarity_enum = ItemData.ItemRarity.COMMON
	
	if typeof(rarity_raw) == TYPE_STRING:
		if ItemData.ItemRarity.has(rarity_raw):
			rarity_enum = ItemData.ItemRarity[rarity_raw]
	elif typeof(rarity_raw) == TYPE_INT:
		rarity_enum = rarity_raw
	
	# Set Icon
	var icon_path = item_def.get("icon", "")
	if icon_path.is_empty():
		icon_path = item_def.get("icon_path", "") # Fallback
		
	if not icon_path.is_empty():
		icon_rect.texture = load(icon_path)
	
	# Set Name (Color by rarity optionally, for now just text)
	name_label.text = item_name
	
	# Enhancement
	if item_data_db is Dictionary and item_data_db.has("enhancement_level"):
		var level = int(item_data_db.get("enhancement_level", 0))
		if level > 0:
			name_label.text += " +%d" % level
			
	# Price
	price_label.text = "%d Gold" % price
	
	# Quantity
	if quantity > 1:
		quantity_label.text = "x%d" % quantity
		quantity_label.visible = true
	else:
		quantity_label.visible = false
	
	# Colorize based on rarity (using global colors if available, or static)
	var rarity_color = ItemData.get_rarity_color_static(rarity_enum)
	name_label.modulate = rarity_color

func _ready():
	remove_button.pressed.connect(_on_remove_pressed)

func _on_remove_pressed():
	if not _order_id.is_empty():
		remove_requested.emit(_order_id)
