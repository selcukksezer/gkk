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
	# Try RPC endpoint first (preferred)
	# Note: Supabase RPC functions without parameters should be called with empty dict
	var rpc_result = await Network.http_post("/rest/v1/rpc/get_inventory", {})
	
	print("[InventoryManager] Fetch inventory RPC result: ", rpc_result)
	
	if rpc_result.success and rpc_result.data:
		var response_data = rpc_result.data
		
		# Handle nested response structure
		if typeof(response_data) == TYPE_DICTIONARY:
			if response_data.has("items"):
				print("[InventoryManager] Found items in response: %d items" % response_data.items.size())
				State.set_inventory(response_data.items)
				return {"success": true, "items": response_data.items}
			elif response_data.has("data"):
				# Sometimes Supabase wraps the response
				var data = response_data.data
				if typeof(data) == TYPE_DICTIONARY and data.has("items"):
					print("[InventoryManager] Found items in data.items: %d items" % data.items.size())
					State.set_inventory(data.items)
					return {"success": true, "items": data.items}
				elif typeof(data) == TYPE_ARRAY:
					print("[InventoryManager] Found items as array in data: %d items" % data.size())
					State.set_inventory(data)
					return {"success": true, "items": data}
		
		# Fallback: try direct array
		if typeof(response_data) == TYPE_ARRAY:
			print("[InventoryManager] Found items as direct array: %d items" % response_data.size())
			State.set_inventory(response_data)
			return {"success": true, "items": response_data}
		
		print("[InventoryManager] Unexpected response structure: ", response_data)
	
	# Fallback to old endpoint if RPC fails
	print("[InventoryManager] RPC failed, trying old endpoint...")
	var result = await Network.http_get(INVENTORY_ENDPOINT)
	
	if result.success and result.data.has("items"):
		State.set_inventory(result.data.items)
		return {"success": true, "items": result.data.items}
	
	print("[InventoryManager] All inventory fetch methods failed")
	return {"success": false, "error": rpc_result.get("error", result.get("error", "Unknown error"))}

## Add item to inventory
func add_item(item: ItemData) -> Dictionary:
	# Convert item to dict - RPC expects full data and handles normalization server-side
	var item_dict = item.to_dict()
	
	# Try to add via Server RPC (Normalized DB Handler)
	var endpoint = "/rest/v1/rpc/add_inventory_item"
	var payload = {"item_data": item_dict}
	
	print("[InventoryManager] Adding item via RPC: ", endpoint)
	var result = await Network.http_post(endpoint, payload)

	if result.success:
		# Server returned the inventory row
		var returned_data = result.data
		
		# If RPC returns stringified JSON, parse it
		if typeof(returned_data) == TYPE_STRING:
			var json = JSON.new()
			if json.parse(returned_data) == OK:
				returned_data = json.data
				
		# Merge local definition with server instance data
		var final_item = item_dict.duplicate()
		if typeof(returned_data) == TYPE_DICTIONARY:
			# Update quantity, row_id, etc from server response
			for k in returned_data:
				final_item[k] = returned_data[k]
				
		State.add_item(final_item)
		var item_obj = ItemData.from_dict(final_item)
		item_added.emit(item_obj)
		Audio.play_item_pickup()
		if State.has_user_signal("inventory_updated"):
			State.emit_signal("inventory_updated")
		return {"success": true, "item": item_obj, "synced": true}

	print("[InventoryManager] Server RPC add failed: %s" % result)
	
	# Fallback: Local Add (Offline / Error Tolerance)
	print("[InventoryManager] Adding locally (pending sync)")
	var local_dict = item.to_dict()
	local_dict["pending_sync"] = true
	State.add_item(local_dict)
	var local_item = ItemData.from_dict(local_dict)
	item_added.emit(local_item)
	Audio.play_item_pickup()
	if State.has_user_signal("inventory_updated"):
		State.emit_signal("inventory_updated")

	return {"success": true, "item": local_item, "synced": false, "error": result.get("error", "RPC failed") }

## Add item by ID (convenience method)
func add_item_by_id(item_id: String, quantity: int = 1) -> Dictionary:
	var item = ItemDatabase.create_item(item_id, quantity)
	if not item:
		return {"success": false, "error": "Invalid item ID: %s" % item_id}

	return await add_item(item)

## Remove item from inventory
func remove_item(item_id: String, quantity: int = 1) -> Dictionary:
	print("[InventoryManager] Removing item: ", item_id, " quantity: ", quantity)
	
	# Check if item exists and has enough quantity
	var current_quantity = _get_item_quantity(item_id)
	if current_quantity <= 0:
		return {"success": false, "error": "Item not found in inventory"}
	
	if quantity > current_quantity:
		return {"success": false, "error": "Not enough items (have: %d, trying to remove: %d)" % [current_quantity, quantity]}
	
	# Try RPC endpoint first
	var rpc_result = await Network.http_post("/rest/v1/rpc/remove_inventory_item", {
		"p_item_id": item_id,
		"p_quantity": quantity
	})
	
	if rpc_result.success:
		print("[InventoryManager] Item removed from database via RPC")
		# Update local state (current_quantity already declared at function start)
		if quantity >= current_quantity:
			# Remove completely
			State.remove_item(item_id)
		else:
			# Update quantity
			var new_quantity = current_quantity - quantity
			State.update_item_quantity(item_id, new_quantity)
		
		item_removed.emit(item_id)
		if State.has_user_signal("inventory_updated"):
			State.emit_signal("inventory_updated")
		return {"success": true}
	
	print("[InventoryManager] RPC failed, trying fallback endpoint")
	# Fallback to old endpoint
	var result = await Network.http_post(INVENTORY_ENDPOINT + "/remove", {
		"item_id": item_id,
		"quantity": quantity
	})
	
	if result.success:
		print("[InventoryManager] Item removed from database via fallback")
		# Update local state (current_quantity already declared at function start)
		if quantity >= current_quantity:
			# Remove completely
			State.remove_item(item_id)
		else:
			# Update quantity
			var new_quantity = current_quantity - quantity
			State.update_item_quantity(item_id, new_quantity)
		
		item_removed.emit(item_id)
		if State.has_user_signal("inventory_updated"):
			State.emit_signal("inventory_updated")
		return {"success": true}
	
	print("[InventoryManager] All remove methods failed: ", result.get("error", "Unknown"))
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
	var all_items = State.get_all_items_data()
	for item in all_items:
		if item.item_id == item_id:
			return item.quantity
	return 0

## Update item quantity
func _update_item_quantity(item_id: String, delta: int) -> void:
	var all_items = State.get_all_items_data()
	for item in all_items:
		if item.item_id == item_id:
			var new_quantity = max(0, item.quantity + delta)
			print("[InventoryManager] Updating quantity for ", item_id, " from ", item.quantity, " to ", new_quantity)
			State.update_item_quantity(item_id, new_quantity)
			return
	print("[InventoryManager] Item not found for quantity update: ", item_id)

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
