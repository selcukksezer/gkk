class_name InventoryManager
extends RefCounted
## Inventory Management
## Handles item CRUD operations, equipped items, and inventory validation

signal item_added(item: Dictionary)
signal item_removed(item_id: String)
signal item_equipped(item: Dictionary, slot: String)
signal item_unequipped(slot: String)

const INVENTORY_ENDPOINT = "/api/v1/inventory"

## Get player inventory from server
func fetch_inventory() -> Dictionary:
	var result = await Network.http_get(INVENTORY_ENDPOINT)
	
	if result.success and result.data.has("items"):
		State.set_inventory(result.data.items)
		return {"success": true, "items": result.data.items}
	
	return {"success": false, "error": result.get("error", "Unknown error")}

## Add item to inventory
func add_item(item: Dictionary) -> Dictionary:
	var result = await Network.http_post(INVENTORY_ENDPOINT + "/add", {"item": item})
	
	if result.success:
		State.add_item(result.data.item)
		item_added.emit(result.data.item)
		Audio.play_item_pickup()
		return {"success": true, "item": result.data.item}
	
	return {"success": false, "error": result.get("error", "Failed to add item")}

## Remove item from inventory
func remove_item(item_id: String, quantity: int = 1) -> Dictionary:
	var result = await Network.http_post(INVENTORY_ENDPOINT + "/remove", {
		"item_id": item_id,
		"quantity": quantity
	})
	
	if result.success:
		if quantity >= _get_item_quantity(item_id):
			State.remove_item(item_id)
		else:
			# Update quantity
			_update_item_quantity(item_id, -quantity)
		
		item_removed.emit(item_id)
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Failed to remove item")}

## Use item (consumable)
func use_item(item_id: String) -> Dictionary:
	var item = State.get_item_by_id(item_id)
	
	if item.is_empty():
		return {"success": false, "error": "Item not found"}
	
	var item_type = item.get("type", "")
	
	# Handle different item types
	match item_type:
		"potion":
			return await _use_potion(item)
		"consumable":
			return await _use_consumable(item)
		_:
			return {"success": false, "error": "Item cannot be used"}

## Use potion
func _use_potion(potion: Dictionary) -> Dictionary:
	var result = await Network.http_post("/api/v1/potion/consume", {"potion_id": potion.id})
	
	if result.success:
		var potion_manager = PotionManager.new()
		var consume_result = potion_manager.consume_potion(result.data.potion)
		
		# Remove from inventory if consumed
		if consume_result.success:
			await remove_item(potion.id, 1)
		
		return consume_result
	
	return {"success": false, "error": result.get("error", "Failed to use potion")}

## Use generic consumable
func _use_consumable(item: Dictionary) -> Dictionary:
	var result = await Network.http_post("/api/v1/inventory/use", {"item_id": item.id})
	
	if result.success:
		await remove_item(item.id, 1)
		return {"success": true, "effect": result.data.get("effect", {})}
	
	return {"success": false, "error": result.get("error", "Failed to use item")}

## Equip item
func equip_item(item_id: String) -> Dictionary:
	var item = State.get_item_by_id(item_id)
	
	if item.is_empty():
		return {"success": false, "error": "Item not found"}
	
	if not item.has("equip_slot"):
		return {"success": false, "error": "Item cannot be equipped"}
	
	var result = await Network.http_post("/api/v1/inventory/equip", {"item_id": item_id})
	
	if result.success:
		var slot = item.equip_slot
		State.equipped_items[slot] = item
		item_equipped.emit(item, slot)
		return {"success": true, "slot": slot}
	
	return {"success": false, "error": result.get("error", "Failed to equip item")}

## Unequip item
func unequip_item(slot: String) -> Dictionary:
	if not State.equipped_items.has(slot):
		return {"success": false, "error": "No item equipped in slot"}
	
	var item = State.equipped_items[slot]
	
	var result = await Network.http_post("/api/v1/inventory/unequip", {"slot": slot})
	
	if result.success:
		State.equipped_items.erase(slot)
		item_unequipped.emit(slot)
		return {"success": true, "item": item}
	
	return {"success": false, "error": result.get("error", "Failed to unequip item")}

## Get item quantity
func _get_item_quantity(item_id: String) -> int:
	var item = State.get_item_by_id(item_id)
	return item.get("quantity", 1)

## Update item quantity
func _update_item_quantity(item_id: String, delta: int) -> void:
	for item in State.inventory:
		if item.get("id", "") == item_id:
			item.quantity = max(0, item.get("quantity", 1) + delta)
			State.inventory_updated.emit()
			return

## Get total inventory value
func get_total_value() -> int:
	var total = 0
	for item in State.inventory:
		var price = item.get("price", 0)
		var quantity = item.get("quantity", 1)
		total += price * quantity
	return total

## Get items by type
func get_items_by_type(item_type: String) -> Array:
	var filtered = []
	for item in State.inventory:
		if item.get("type", "") == item_type:
			filtered.append(item)
	return filtered

## Get equipped item in slot
func get_equipped_item(slot: String) -> Dictionary:
	return State.equipped_items.get(slot, {})

## Check if slot is equipped
func is_slot_equipped(slot: String) -> bool:
	return State.equipped_items.has(slot)

## Get inventory capacity (if implemented)
func get_capacity() -> int:
	return 100  # TODO: Make dynamic based on player level/upgrades

## Get current inventory size
func get_current_size() -> int:
	var total = 0
	for item in State.inventory:
		total += item.get("quantity", 1)
	return total

## Check if inventory is full
func is_inventory_full() -> bool:
	return get_current_size() >= get_capacity()
