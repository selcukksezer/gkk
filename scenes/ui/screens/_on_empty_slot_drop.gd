## Handler for items dropped on empty inventory slots
func _on_empty_slot_drop(item: ItemData, target_position: int) -> void:
	print("[InventoryScreen] Item dropped on empty slot: ", item.name, " -> position ", target_position)
	
	# For now, just log - full implementation requires InventoryManager.move_item_to_slot()
	# which needs backend support
	print("[InventoryScreen] TODO: Call InventoryManager.move_item_to_slot(item, target_position)")
	
	# Temporary: Just refresh to show current state
	_refresh_inventory()
