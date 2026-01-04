extends PanelContainer
## Item Card for Selection

signal clicked(item)

@onready var icon = $VBox/Icon
@onready var name_label = $VBox/NameLabel
@onready var enhancement_label = $VBox/EnhancementLabel

var _item: InventoryItemData

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_item(item: InventoryItemData) -> void:
	_item = item
	
	# TODO: Load icon and name from ItemData
	name_label.text = item.item_id
	
	if item.enhancement_level > 0:
		enhancement_label.text = "+%d" % item.enhancement_level
		enhancement_label.visible = true
	else:
		enhancement_label.visible = false

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(_item)
