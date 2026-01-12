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
	
	# Use v2 RPC which supports slot_position (finds first empty slot automatically)
	var endpoint = "/rest/v1/rpc/add_inventory_item_v2"
	var payload = {"item_data": item_dict, "p_slot_position": null}  # null = auto-assign
	
	print("[InventoryManager] Adding item via RPC v2: ", endpoint)
	var result = await Network.http_post(endpoint, payload)

	if result.success:
		# Server returned the inventory row
		var returned_data = result.data
		
		# If RPC returns stringified JSON, parse it matches other RPCs
		if typeof(returned_data) == TYPE_STRING:
			var json = JSON.new()
			if json.parse(returned_data) == OK:
				returned_data = json.data
		
		# Unwrap 'data' if present (RPC v2 wrapper)
		if typeof(returned_data) == TYPE_DICTIONARY and returned_data.has("data"):
			returned_data = returned_data.data
		
		# Merge local definition with server instance data
		var final_item = item_dict.duplicate()
		if typeof(returned_data) == TYPE_DICTIONARY:
			# Update quantity, row_id, slot_position etc from server response
			for k in returned_data:
				final_item[k] = returned_data[k]
			
			print("[InventoryManager] Merged server data: row_id=%s slot=%s" % [final_item.get("row_id"), final_item.get("slot_position")])
		
		# CRITICAL: Ensure slot_position is valid (0-19) for UI display
		if not final_item.has("slot_position") or final_item.slot_position == null or int(final_item.slot_position) < 0:
			print("[InventoryManager] Item missing slot_position from server, finding local slot...")
			final_item["slot_position"] = _find_first_empty_slot()
			print("[InventoryManager] Assigned local slot: ", final_item.slot_position)
		
		State.add_item(final_item)
		var item_obj = ItemData.from_dict(final_item)
		item_added.emit(item_obj)
		Audio.play_item_pickup()
		
		# Force immediate update
		if State.has_user_signal("inventory_updated"):
			State.emit_signal("inventory_updated")
			
		return {"success": true, "item": item_obj, "synced": true}

	print("[InventoryManager] Server RPC add failed: %s" % result)
	
	# Fallback: Local Add (Offline / Error Tolerance)
	print("[InventoryManager] Adding locally (pending sync)")
	var local_dict = item.to_dict()
	local_dict["pending_sync"] = true
	local_dict["slot_position"] = _find_first_empty_slot() # Assign local slot
	
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

## Remove item by row_id (specific instance)
func remove_item_by_row_id(row_id: String, quantity: int = 1) -> Dictionary:
	print("[InventoryManager] Removing item by row_id: ", row_id, " quantity: ", quantity)
	
	# Find item in local state
	var item_to_remove = null
	for item in State.inventory:
		if item.get("row_id") == row_id:
			item_to_remove = item
			break
	
	if not item_to_remove:
		return {"success": false, "error": "Item not found in local inventory"}
	
	# Try RPC endpoint first (preferred for precise removal)
	var rpc_result = await Network.http_post("/rest/v1/rpc/remove_inventory_item_by_row", {
		"p_row_id": row_id,
		"p_quantity": quantity
	})
	
	if rpc_result.success:
		print("[InventoryManager] Item removed/updated via RPC by row_id")
		
		# Update local state
		var current_qty = item_to_remove.get("quantity", 1)
		
		if quantity >= current_qty:
			# Removed completely
			State.inventory.erase(item_to_remove)
		else:
			# Reduced quantity
			item_to_remove["quantity"] = current_qty - quantity
			
		var item_id = item_to_remove.get("item_id")
		item_removed.emit(item_id)
		
		if State.has_user_signal("inventory_updated"):
			State.emit_signal("inventory_updated")
			
		return {"success": true}
	
	print("[InventoryManager] RPC remove_by_row failed, falling back to basic remove")
	# Fallback: Use item_id for server call (less precise)
	var item_id = item_to_remove.get("item_id")
	var result = await remove_item(item_id, quantity)
	
	return result


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
	return 20  # Fixed 20 slots (0-19)

## Get current inventory size (count items with assigned slots)
func get_current_size() -> int:
	var assigned_slots = 0
	for item in State.inventory:
		var slot_pos = item.get("slot_position")
		# Count only items with valid slot positions (0-19)
		if slot_pos != null and slot_pos >= 0 and slot_pos <= 19:
			assigned_slots += 1
	return assigned_slots

## Check if inventory is full
func is_inventory_full() -> bool:
	return get_current_size() >= get_capacity()

## Move item to specific slot position (for drag-and-drop)
func move_item_to_slot(item: ItemData, target_position: int) -> Dictionary:
	print("[InventoryManager] Moving item ", item.name, " to slot position ", target_position)
	
	# Validate position (0-19)
	if target_position < 0 or target_position > 19:
		return {"success": false, "error": "Invalid slot position: %d (must be 0-19)" % target_position}
	
	# Call server RPC to update position
	var payload = {
		"p_updates": [
			{
				"row_id": item.row_id,
				"slot_position": target_position
			}
		]
	}
	
	var result = await Network.http_post("/rest/v1/rpc/update_item_positions", payload)
	
	if result.success:
		print("[InventoryManager] Item position updated successfully")
		# Update local state
		for inv_item in State.inventory:
			if inv_item.get("row_id") == item.row_id:
				inv_item["slot_position"] = target_position
				break
		
		if State.has_user_signal("inventory_updated"):
			State.emit_signal("inventory_updated")
		return {"success": true}
	
	print("[InventoryManager] Failed to update item position: ", result.get("error", "Unknown"))
	return {"success": false, "error": result.get("error", "Failed to update position")}

## Batch update item positions (for sort operations)
func batch_update_positions(items: Array[ItemData]) -> Dictionary:
	print("[InventoryManager] Batch updating positions for %d items" % items.size())
	
	# Build updates array
	var updates = []
	for i in range(items.size()):
		var item = items[i]
		updates.append({
			"row_id": item.row_id,
			"slot_position": i  # Sequential positions 0,1,2...
		})
	
	# Call server RPC
	var payload = {"p_updates": updates}
	var result = await Network.http_post("/rest/v1/rpc/update_item_positions", payload)
	
	if result.success:
		print("[InventoryManager] Batch position update successful")
		# Update local state
		for update in updates:
			for inv_item in State.inventory:
				if inv_item.get("row_id") == update.row_id:
					inv_item["slot_position"] = update.slot_position
					break
		
		if State.has_user_signal("inventory_updated"):
			State.emit_signal("inventory_updated")
		return {"success": true, "updated_count": updates.size()}
	
	print("[InventoryManager] Failed to batch update positions: ", result.get("error", "Unknown"))
	return {"success": false, "error": result.get("error", "Failed to update positions")}

## Helper: Find first empty slot (0-19) in local state
func _find_first_empty_slot() -> int:
	var occupied_slots = []
	for item in State.inventory:
		var pos = item.get("slot_position")
		if pos != null and pos >= 0:
			occupied_slots.append(int(pos))
	
	for i in range(20):
		if not i in occupied_slots:
			return i
	return -1 # Full
