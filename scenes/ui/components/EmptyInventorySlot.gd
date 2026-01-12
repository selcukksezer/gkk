extends Panel
## Empty inventory slot that accepts drops

signal item_placed(item: ItemData, position: int)

var slot_position: int = -1  # Tracks which slot position (0-19)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

# Duck-typing methods to be detected by ItemSlot's custom drag system
func set_item(_item: Variant) -> void:
	# Dummy function to satisfy ItemSlot's _find_slot_recursive check
	# We don't actually set the item here, InventoryScreen handles the logic
	pass

func get_item() -> Variant:
	# Always return null since this is an empty slot
	return null

func get_slot_position() -> int:
	return slot_position

# Native drop handlers are not used by ItemSlot.gd's custom system, 
# but kept as fallback/debug or for cross-window interactions if needed.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_drop = data is Object and data.has_method("get_item_type")
	return can_drop

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data:
		item_placed.emit(data, slot_position)
