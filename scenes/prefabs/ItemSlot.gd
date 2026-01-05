extends PanelContainer
## Item Slot for Inventory Grid

signal slot_clicked(item)

@onready var icon = $MarginContainer/VBox/Icon
@onready var quantity_label = $MarginContainer/VBox/QuantityLabel
@onready var enhancement_label = $MarginContainer/VBox/EnhancementLabel

var _item: ItemData

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_item(item: ItemData) -> void:
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

func set_equipment_slot(slot_name: String) -> void:
	# Equipment slot - no item initially
	_item = null
	
	# TODO: Set slot-specific styling or background
	# For now, just hide quantity and enhancement
	quantity_label.visible = false
	enhancement_label.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(_item)
