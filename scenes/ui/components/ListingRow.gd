extends PanelContainer

signal inspect_requested(item_data)

@onready var icon_rect = %Icon
@onready var name_label = %NameLabel
@onready var seller_label = %SellerLabel
@onready var price_label = %PriceLabel
@onready var inspect_button = %InspectButton

var _listing_data: Dictionary = {}

func setup(listing: Dictionary) -> void:
	_listing_data = listing
	
	var item_id = listing.get("item_id", "")
	var price = listing.get("price", 0)
	var seller_name = listing.get("seller_name", "Unknown Seller")
	var item_data_db = listing.get("item_data", {})
	
	# Load base item
	var item_def = ItemDatabase.get_item(item_id)
	if not item_def: return
	
	# Visuals
	var icon = item_def.get("icon", "")
	if icon.is_empty(): icon = item_def.get("icon_path", "")
	if not icon.is_empty():
		icon_rect.texture = load(icon)
		
	var item_name = item_def.get("name", "Item")
	var rarity = item_def.get("rarity", ItemData.ItemRarity.COMMON)
	
	# Rarity Color
	# Handle String vs Int rarity
	var rarity_int = 0
	if typeof(rarity) == TYPE_STRING:
		if ItemData.ItemRarity.has(rarity):
			rarity_int = ItemData.ItemRarity[rarity]
	elif typeof(rarity) == TYPE_INT:
		rarity_int = rarity
		
	name_label.modulate = ItemData.get_rarity_color_static(rarity_int)
	
	# Enhancement
	if item_data_db is Dictionary and item_data_db.has("enhancement_level"):
		var level = int(item_data_db.get("enhancement_level", 0))
		if level > 0:
			item_name += " +%d" % level
			
	# Quantity
	var quantity = listing.get("quantity", 1)
	if quantity > 1:
		item_name = "%d x %s" % [quantity, item_name]
			
	name_label.text = item_name
	seller_label.text = "Satıcı: %s" % seller_name
	price_label.text = "%d Gold" % price
	
	# Connect
	if not inspect_button.pressed.is_connected(_on_inspect_pressed):
		inspect_button.pressed.connect(_on_inspect_pressed)

func _on_inspect_pressed() -> void:
	inspect_requested.emit(_listing_data)
