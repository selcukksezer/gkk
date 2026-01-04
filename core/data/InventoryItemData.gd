class_name InventoryItemData
extends Resource
## Inventory Item Instance
## Player-owned item with instance-specific properties

@export var instance_id: String = ""  # UUID from database
@export var item_id: String = ""  # Reference to ItemData
@export var quantity: int = 1

## Enhancement
@export var enhancement_level: int = 0  # 0-10

## Binding
@export var bound_to_user: bool = false

## Equipment slot
@export var equipped_slot: String = ""  # weapon|helmet|chest|legs|boots (empty = not equipped)

## Metadata
@export var acquired_at: String = ""  # ISO timestamp
@export var acquired_from: String = ""  # quest|market|pvp|craft

## Cached item data (for quick access)
var _cached_item: ItemData = ItemData.new()  # cached for future use (unused currently)

## Parse from API response
static func from_dict(data: Dictionary) -> InventoryItemData:
	var inv_item = InventoryItemData.new()
	
	inv_item.instance_id = data.get("id", "")
	inv_item.item_id = data.get("item_id", "")
	inv_item.quantity = data.get("quantity", 1)
	inv_item.enhancement_level = data.get("enhancement_level", 0)
	inv_item.bound_to_user = data.get("bound", false)
	inv_item.equipped_slot = data.get("equipped_slot", "")
	inv_item.acquired_at = data.get("acquired_at", "")
	inv_item.acquired_from = data.get("acquired_from", "")
	
	return inv_item

## Get total power (with enhancement)
func get_total_power(base_item: ItemData) -> int:
	var base_power = base_item.power
	var bonus_power = enhancement_level * 30  # +30 per level
	return base_power + bonus_power

## Get total defense (with enhancement)
func get_total_defense(base_item: ItemData) -> int:
	var base_defense = base_item.defense
	var bonus_defense = enhancement_level * 20  # +20 per level
	return base_defense + bonus_defense

## Get enhancement display
func get_enhancement_display() -> String:
	if enhancement_level == 0:
		return ""
	return "+%d" % enhancement_level
