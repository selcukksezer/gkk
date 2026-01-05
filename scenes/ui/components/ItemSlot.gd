extends PanelContainer
## Item Slot Component
## Displays inventory item in grid layout

signal clicked(inv_item: InventoryItemData)

@onready var icon: TextureRect = $MarginContainer/HBoxContainer/Icon
@onready var name_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/NameLabel
@onready var quantity_label: Label = $MarginContainer/HBoxContainer/VBoxContainer/QuantityLabel
@onready var enhancement_label: Label = $MarginContainer/HBoxContainer/EnhancementLabel
@onready var equipped_indicator: TextureRect = $EquippedIndicator
@onready var rarity_border: ColorRect = $RarityBorder

var inv_item: InventoryItemData = null
var show_quantity: bool = true
var show_equipped: bool = true

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_item(item: InventoryItemData) -> void:
	inv_item = item
	_update_display()

func _update_display() -> void:
	if not inv_item:
		_clear_display()
		return
	
	var item_data = ItemDatabase.get_item(inv_item.item_id)
	if not item_data:
		_clear_display()
		return
	
	# Icon
	if icon:
		var icon_path = item_data.icon_path
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path)
		else:
			icon.texture = null
	
	# Name
	if name_label:
		name_label.text = item_data.name
		name_label.add_theme_color_override("font_color", item_data.get_rarity_color())
	
	# Quantity
	if quantity_label and show_quantity:
		quantity_label.visible = inv_item.quantity > 1
		quantity_label.text = "x%d" % inv_item.quantity
	
	# Enhancement
	if enhancement_label:
		enhancement_label.visible = inv_item.enhancement_level > 0
		enhancement_label.text = "+%d" % inv_item.enhancement_level
	
	# Equipped indicator
	if equipped_indicator and show_equipped:
		equipped_indicator.visible = inv_item.is_equipped()
	
	# Rarity border
	if rarity_border:
		rarity_border.color = item_data.get_rarity_color()

func _clear_display() -> void:
	if icon:
		icon.texture = null
	if name_label:
		name_label.text = ""
	if quantity_label:
		quantity_label.visible = false
	if enhancement_label:
		enhancement_label.visible = false
	if equipped_indicator:
		equipped_indicator.visible = false
	if rarity_border:
		rarity_border.color = Color.WHITE

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if inv_item:
			clicked.emit(inv_item)

func get_item() -> InventoryItemData:
	return inv_item

func is_empty() -> bool:
	return inv_item == null