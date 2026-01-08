extends Node
## Inventory Manager - Singleton autoload
## Singleton autoload: Inventory

signal item_added(item: ItemData)
signal item_removed(item_id: String)
signal item_equipped(item: ItemData, slot: String)
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
func add_item(item: ItemData) -> Dictionary:
	# Try to add via server
	var payload = {"item": item.to_dict()}
	var endpoint = INVENTORY_ENDPOINT + "/add"
	print("[InventoryManager] Adding item via server: ", endpoint, payload)
	var result = await Network.http_post(endpoint, payload)

	if result.success:
		# Server returned canonical item (with IDs, timestamps, etc.)
		State.add_item(result.data.item)
		var item_data = ItemData.from_dict(result.data.item)
		item_added.emit(item_data)
		Audio.play_item_pickup()
		return {"success": true, "item": item_data, "synced": true}

	# Fallback: if server add failed (missing endpoint, network error, etc.), try REST fallback then enqueue and/or add locally
	print("[InventoryManager] Server add failed: %s - %s" % [endpoint, result])
	# 1) Try Supabase REST insertion as an alternate path
	var rest_endpoint = "/rest/v1/inventory"
	print("[InventoryManager] Attempting fallback REST insert to: %s" % rest_endpoint)
	var rest_result = await Network.http_post(rest_endpoint, item.to_dict())
	if rest_result.success:
		# Use returned data if available. Supabase may return an array of rows.
		var returned = item.to_dict()
		if rest_result.data:
			if typeof(rest_result.data) == TYPE_ARRAY and rest_result.data.size() > 0:
				returned = rest_result.data[0]
			elif typeof(rest_result.data) == TYPE_DICTIONARY:
				returned = rest_result.data
		# Add returned/inserted item
		State.add_item(returned)
		var rest_item = ItemData.from_dict(returned)
		item_added.emit(rest_item)
		Audio.play_item_pickup()
		print("[InventoryManager] Fallback REST insert succeeded")
		return {"success": true, "item": rest_item, "synced": true}

	# 2) REST fallback failed — enqueue REST endpoint for later retry if available
	print("[InventoryManager] REST fallback failed: %s" % rest_result)
	if typeof(Queue) != TYPE_NIL and Queue.has_method("enqueue"):
		Queue.enqueue("POST", rest_endpoint, {"item": item.to_dict()}, 1)
		print("[InventoryManager] Enqueued REST add_item request for later sync")
	else:
		print("[InventoryManager] Queue not available; request not enqueued")

	# 3) Locally add item so player sees immediate feedback (client-first UX)
	var local_dict = item.to_dict()
	local_dict["pending_sync"] = true
	State.add_item(local_dict)
	var local_item = ItemData.from_dict(local_dict)
	item_added.emit(local_item)
	Audio.play_item_pickup()

	return {"success": true, "item": local_item, "synced": false, "error": result.get("error", "Failed to add item") }

## Add item by ID (convenience method)
func add_item_by_id(item_id: String, quantity: int = 1) -> Dictionary:
	var item = ItemDatabase.create_item(item_id, quantity)
	if not item:
		return {"success": false, "error": "Invalid item ID: %s" % item_id}

	return await add_item(item)

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
func use_item(item: ItemData) -> Dictionary:
	if not item.is_consumable():
		return {"success": false, "error": "Item cannot be used"}

	# Handle different item types
	if item.is_potion():
		return await _use_potion(item)
	else:
		return await _use_consumable(item)

## Use potion
func _use_potion(potion: ItemData) -> Dictionary:
	var result = await Network.http_post("/api/v1/potion/consume", {"potion_id": potion.item_id})

	if result.success:
		var potion_manager = PotionManager.new()
		var consume_result = potion_manager.consume_potion(potion.to_dict())

		# Remove from inventory if consumed
		if consume_result.success:
			await remove_item(potion.item_id, 1)

		return consume_result

	return {"success": false, "error": result.get("error", "Failed to use potion")}

## Use generic consumable
func _use_consumable(item: ItemData) -> Dictionary:
	var result = await Network.http_post("/api/v1/inventory/use", {"item_id": item.item_id})
	
	if result.success:
		await remove_item(item.item_id, 1)
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
