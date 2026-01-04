extends PanelContainer
## Item Slot for Inventory Grid

signal clicked(item)

@onready var icon = $MarginContainer/VBox/Icon
@onready var quantity_label = $MarginContainer/VBox/QuantityLabel
@onready var enhancement_label = $MarginContainer/VBox/EnhancementLabel

var _item: InventoryItemData

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_item(item: InventoryItemData) -> void:
	_item = item
	
	# TODO: Load icon texture from item_id
	# icon.texture = load("res://assets/sprites/items/%s.png" % item.item_id)
	
	# Show quantity
	if item.quantity > 1:
		quantity_label.text = str(item.quantity)
		quantity_label.visible = true
	else:
		quantity_label.visible = false
	
	# Show enhancement level
	if item.enhancement_level > 0:
		enhancement_label.text = "+%d" % item.enhancement_level
		enhancement_label.visible = true
	else:
		enhancement_label.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(_item)
