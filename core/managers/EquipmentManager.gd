extends Node
class_name EquipmentManager

## Equipment Manager
## Handles equipping/unequipping items and stat calculation

signal equipment_changed(slot: String, item: ItemData)
signal stats_recalculated(total_stats: Dictionary)

## Equipped items by slot
var equipped_items: Dictionary = {
	"WEAPON": null,
	"HEAD": null,
	"CHEST": null,
	"HANDS": null,
	"LEGS": null,
	"FEET": null,
	"ACCESSORY_1": null,
	"ACCESSORY_2": null
}

## Total stats from all equipped items
var total_stats: Dictionary = {
	"attack": 0,
	"defense": 0,
	"health": 0,
	"power": 0
}

func _ready():
	print("[EquipmentManager] Initialized")

## Equip item to appropriate slot
func equip_item(item: ItemData) -> Dictionary:
	if not item:
		return {"success": false, "error": "Invalid item"}
	
	# Validate equip slot
	if item.equip_slot == ItemData.EquipSlot.NONE:
		return {"success": false, "error": "Item cannot be equipped"}
	
	# Check if player can equip
	if not can_equip(item):
		return {"success": false, "error": "Cannot equip item - check level or class requirements"}
	
	# Get slot key
	var slot_key = get_slot_key_for_item(item)
	if slot_key == "":
		return {"success": false, "error": "Invalid equipment slot"}
	
	# Check if slot is already occupied
	var old_item = equipped_items[slot_key] if equipped_items.has(slot_key) else null
	if old_item:
		# Unequip old item first
		var unequip_result = await unequip_item(slot_key)
		if not unequip_result.success:
			return {"success": false, "error": "Failed to unequip existing item"}
	
	# Try to sync to server first (server-side validation)
	var server_result = await _sync_equip_to_server(item, slot_key)
	
	if server_result.success:
		# Server confirmed - now update locally
		item.is_equipped = true  # Mark as equipped
		
		# CRITICAL: Update the flag in State.inventory too
		for inv_item in State.inventory:
			if inv_item.row_id == item.row_id:
				inv_item.is_equipped = true
				print("[EquipmentManager] Updated is_equipped flag in State.inventory for: ", inv_item.name)
				break
		
		equipped_items[slot_key] = item
		print("[EquipmentManager] ✅ Equipped: ", item.name, " to slot: ", slot_key)
		equipment_changed.emit(slot_key, item)
		_recalculate_stats()
		
		# Update State.inventory to trigger UI refresh
		State.inventory_updated.emit()
		
		return {"success": true, "slot": slot_key}
	else:
		# Server rejected - don't equip
		print("[EquipmentManager] ❌ Server rejected equip: ", server_result.get("error", "Unknown"))
		return {"success": false, "error": server_result.get("error", "Server error")}

## Unequip item from slot
func unequip_item(slot_key: String, target_slot_index: int = -1) -> Dictionary:
	if not equipped_items.has(slot_key) or equipped_items[slot_key] == null:
		print("[EquipmentManager] No item equipped in slot: ", slot_key)
		return {"success": false, "error": "No item in slot"}
	
	var item = equipped_items[slot_key]
	print("[EquipmentManager] 🔄 Unequip request for slot: ", slot_key, " to target: ", target_slot_index)
	print("[EquipmentManager] Unequipping item: ", item.name, " from slot: ", slot_key)
	
	# Sync to server
	var server_result = await _sync_unequip_to_server(item, target_slot_index)
	
	if server_result.success:
		# Server confirmed
		item.is_equipped = false  # Mark as unequipped
		
		# Update slot position if returned
		if server_result.has("new_slot_position"):
			item.slot_position = int(server_result.new_slot_position)
		elif target_slot_index != -1:
			item.slot_position = target_slot_index
		
		# CRITICAL: Update the flag in State.inventory too
		for inv_item in State.inventory:
			if inv_item.row_id == item.row_id:
				inv_item.is_equipped = false
				inv_item.slot_position = item.slot_position # Sync position
				print("[EquipmentManager] Updated is_equipped flag in State.inventory for: ", inv_item.name)
				break
		
		equipped_items[slot_key] = null
		print("[EquipmentManager] ✅ Unequipped from slot: ", slot_key)
		equipment_changed.emit(slot_key, null)
		_recalculate_stats()
		
		# Update State.inventory to trigger UI refresh
		State.inventory_updated.emit()
		
		return {"success": true}
	else:
		print("[EquipmentManager] ❌ Server rejected unequip. Result: ", server_result)
		return {"success": false, "error": server_result.get("error", "Server error")}

## Check if player can equip item
func can_equip(item: ItemData) -> bool:
	# Check level requirement
	if State.player.level < item.required_level:
		print("[EquipmentManager] Level too low: ", State.player.level, " < ", item.required_level)
		return false
	
	# Check class requirement (if specified)
	if item.required_class != "" and item.required_class != "ANY":
		if State.player.get("class", "") != item.required_class:
			print("[EquipmentManager] Class mismatch")
			return false
	
	return true

## Get slot key for item based on equip_slot
func get_slot_key_for_item(item: ItemData) -> String:
	print("[EquipmentManager] get_slot_key_for_item - Item: ", item.name, " equip_slot value: ", item.equip_slot, " (", ItemData.EquipSlot.keys()[item.equip_slot], ")")
	
	match item.equip_slot:
		ItemData.EquipSlot.WEAPON:
			return "WEAPON"
		ItemData.EquipSlot.HEAD:
			return "HEAD"
		ItemData.EquipSlot.CHEST:
			return "CHEST"
		ItemData.EquipSlot.HANDS:
			return "HANDS"
		ItemData.EquipSlot.LEGS:
			return "LEGS"
		ItemData.EquipSlot.FEET:
			return "FEET"
		ItemData.EquipSlot.ACCESSORY:
			# Check which accessory slot is free
			if equipped_items["ACCESSORY_1"] == null:
				return "ACCESSORY_1"
			elif equipped_items["ACCESSORY_2"] == null:
				return "ACCESSORY_2"
			else:
				# Both occupied, replace first one
				return "ACCESSORY_1"
		_:
			return ""

## Calculate total stats from all equipped items
func _recalculate_stats() -> void:
	# Reset stats
	total_stats = {
		"attack": 0,
		"defense": 0,
		"health": 0,
		"power": 0
	}
	
	# Sum up all equipped items
	for slot_key in equipped_items:
		var item = equipped_items[slot_key]
		if item:
			total_stats.attack += item.attack
			total_stats.defense += item.defense
			total_stats.health += item.health
			total_stats.power += item.power
			
			# Apply enhancement bonus (10% per level)
			if item.enhancement_level > 0:
				var bonus_multiplier = 1.0 + (item.enhancement_level * 0.1)
				total_stats.attack = int(total_stats.attack * bonus_multiplier)
				total_stats.defense = int(total_stats.defense * bonus_multiplier)
				total_stats.health = int(total_stats.health * bonus_multiplier)
				total_stats.power = int(total_stats.power * bonus_multiplier)
	
	print("[EquipmentManager] Stats recalculated: ", total_stats)
	stats_recalculated.emit(total_stats)

## Get current total stats
func get_total_stats() -> Dictionary:
	return total_stats.duplicate()

## Get equipped item in slot
func get_equipped_item(slot_key: String) -> ItemData:
	return equipped_items[slot_key] if equipped_items.has(slot_key) else null

## Check if item is currently equipped
func is_item_equipped(item: ItemData) -> bool:
	if not item:
		return false
	
	for slot_key in equipped_items:
		var equipped = equipped_items[slot_key]
		if equipped and equipped.item_id == item.item_id:
			return true
	
	return false

## Sync equip action to server
func _sync_equip_to_server(item: ItemData, slot_key: String) -> Dictionary:
	# Check if item has row_id (from inventory)
	var item_instance_id = item.row_id if "row_id" in item else ""
	if item_instance_id == "":
		print("[EquipmentManager] Warning: Item has no row_id, using item_id")
		item_instance_id = item.item_id
	
	var endpoint = "/rest/v1/rpc/equip_item"
	var payload = {
		"item_instance_id": item_instance_id,
		"target_slot": slot_key
	}
	
	var result = await Network.http_post(endpoint, payload)
	if result == null:
		return {"success": false, "error": "Network error"}
	return result

## Sync unequip action to server
func _sync_unequip_to_server(item: ItemData, target_slot_index: int = -1) -> Dictionary:
	var item_instance_id = item.row_id if "row_id" in item else item.item_id
	
	var endpoint = "/rest/v1/rpc/unequip_item"
	var payload = {
		"item_instance_id": item_instance_id
	}
	
	if target_slot_index != -1:
		payload["target_slot_position"] = target_slot_index
	
	var result = await Network.http_post(endpoint, payload)
	if result == null:
		return {"success": false, "error": "Network error"}
	return result

## Load equipped items from server on game start
func fetch_equipped_items() -> void:
	print("[EquipmentManager] Fetching equipped items from server...")
	
	var endpoint = "/rest/v1/inventory?is_equipped=eq.true"
	var result = await Network.http_get(endpoint)
	
	# Check for null result
	if result == null:
		print("[EquipmentManager] Failed to fetch equipped items: Network returned null")
		return
	
	if result.success:
		equipped_items.clear()
		
		for item_dict in result.data:
			var item = ItemData.from_dict(item_dict)
			var slot_key = item_dict.get("equip_slot", "")
			
			if slot_key != "":
				equipped_items[slot_key] = item
				equipment_changed.emit(slot_key, item)
		
		_recalculate_stats()
		print("[EquipmentManager] Loaded ", result.data.size(), " equipped items")
	else:
		print("[EquipmentManager] Failed to fetch equipped items: ", result.get("error", "Unknown error"))
