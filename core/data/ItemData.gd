class_name ItemData
extends Resource
## Item Data Model
## Represents any item in the game (equipment, consumable, material, etc.)

enum ItemType {
	WEAPON,
	ARMOR,
	ACCESSORY,
	CONSUMABLE,
	MATERIAL,
	QUEST_ITEM,
	POTION
}

enum ItemRarity {
	COMMON,      # Beyaz
	UNCOMMON,    # Yeşil
	RARE,        # Mavi
	EPIC,        # Mor
	LEGENDARY,   # Turuncu
	MYTHIC       # Kırmızı
}

enum EquipSlot {
	NONE,
	WEAPON,
	HELMET,
	CHEST,
	LEGS,
	BOOTS,
	GLOVES,
	RING,
	AMULET,
	BELT
}

@export var item_id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var equip_slot: EquipSlot = EquipSlot.NONE

## Economy
@export var base_price: int = 0
@export var vendor_sell_price: int = 0
@export var is_tradeable: bool = true
@export var is_stackable: bool = true
@export var max_stack: int = 999

## Stats (for equipment)
@export var attack: int = 0
@export var defense: int = 0
@export var health: int = 0
@export var power: int = 0

## Enhancement
@export var enhancement_level: int = 0  # +0 to +10
@export var max_enhancement: int = 10
@export var can_enhance: bool = false

## Special properties
@export var energy_restore: int = 0  # For consumables
@export var tolerance_increase: int = 0  # For potions
@export var overdose_risk: float = 0.0  # For potions
@export var heal_amount: int = 0  # For healing items

## Requirements
@export var required_level: int = 1
@export var required_class: String = ""  # Empty = all classes

## Meta
@export var quantity: int = 1
@export var obtained_at: int = 0
@export var bound_to_player: bool = false

## Create from dictionary
static func from_dict(data: Dictionary) -> ItemData:
	var item = ItemData.new()
	
	item.item_id = data.get("id", "")
	item.name = data.get("name", "")
	item.description = data.get("description", "")
	item.icon = data.get("icon", "")
	
	# Parse enums
	var type_str = data.get("item_type", "MATERIAL")
	item.item_type = ItemType.get(type_str) if ItemType.has(type_str) else ItemType.MATERIAL
	
	var rarity_str = data.get("rarity", "COMMON")
	item.rarity = ItemRarity.get(rarity_str) if ItemRarity.has(rarity_str) else ItemRarity.COMMON
	
	var slot_str = data.get("equip_slot", "NONE")
	item.equip_slot = EquipSlot.get(slot_str) if EquipSlot.has(slot_str) else EquipSlot.NONE
	
	item.base_price = data.get("base_price", 0)
	item.vendor_sell_price = data.get("vendor_sell_price", 0)
	item.is_tradeable = data.get("is_tradeable", true)
	item.is_stackable = data.get("is_stackable", true)
	item.max_stack = data.get("max_stack", 999)
	
	item.attack = data.get("attack", 0)
	item.defense = data.get("defense", 0)
	item.health = data.get("health", 0)
	item.power = data.get("power", 0)
	
	item.enhancement_level = data.get("enhancement_level", 0)
	item.max_enhancement = data.get("max_enhancement", 10)
	item.can_enhance = data.get("can_enhance", false)
	
	item.energy_restore = data.get("energy_restore", 0)
	item.tolerance_increase = data.get("tolerance_increase", 0)
	item.overdose_risk = data.get("overdose_risk", 0.0)
	item.heal_amount = data.get("heal_amount", 0)
	
	item.required_level = data.get("required_level", 1)
	item.required_class = data.get("required_class", "")
	
	item.quantity = data.get("quantity", 1)
	item.obtained_at = data.get("obtained_at", 0)
	item.bound_to_player = data.get("bound_to_player", false)
	
	return item

## Convert to dictionary
func to_dict() -> Dictionary:
	return {
		"id": item_id,
		"name": name,
		"description": description,
		"icon": icon,
		"item_type": ItemType.keys()[item_type],
		"rarity": ItemRarity.keys()[rarity],
		"equip_slot": EquipSlot.keys()[equip_slot],
		"base_price": base_price,
		"vendor_sell_price": vendor_sell_price,
		"is_tradeable": is_tradeable,
		"is_stackable": is_stackable,
		"max_stack": max_stack,
		"attack": attack,
		"defense": defense,
		"health": health,
		"power": power,
		"enhancement_level": enhancement_level,
		"max_enhancement": max_enhancement,
		"can_enhance": can_enhance,
		"energy_restore": energy_restore,
		"tolerance_increase": tolerance_increase,
		"overdose_risk": overdose_risk,
		"heal_amount": heal_amount,
		"required_level": required_level,
		"required_class": required_class,
		"quantity": quantity,
		"obtained_at": obtained_at,
		"bound_to_player": bound_to_player
	}

## Get rarity color
func get_rarity_color() -> Color:
	match rarity:
		ItemRarity.COMMON:
			return Color.WHITE
		ItemRarity.UNCOMMON:
			return Color.GREEN
		ItemRarity.RARE:
			return Color.CORNFLOWER_BLUE
		ItemRarity.EPIC:
			return Color.PURPLE
		ItemRarity.LEGENDARY:
			return Color.ORANGE
		ItemRarity.MYTHIC:
			return Color.RED
		_:
			return Color.WHITE

## Get enhancement bonus
func get_enhancement_bonus() -> float:
	return 1.0 + (enhancement_level * 0.1)  # +10% per level

## Calculate total stats (with enhancement)
func get_total_attack() -> int:
	return int(attack * get_enhancement_bonus())

func get_total_defense() -> int:
	return int(defense * get_enhancement_bonus())

func get_total_health() -> int:
	return int(health * get_enhancement_bonus())

func get_total_power() -> int:
	return int(power * get_enhancement_bonus())

## Check if player can equip
func can_equip(player_level: int) -> bool:
	return player_level >= required_level

## Get enhancement display string
func get_enhancement_display() -> String:
	if enhancement_level > 0:
		return "+%d" % enhancement_level
	return ""

## Calculate enhancement success rate
func get_enhancement_success_rate() -> float:
	match enhancement_level:
		0, 1, 2, 3:
			return 1.0  # 100%
		4, 5:
			return 0.8  # 80%
		6, 7:
			return 0.6  # 60%
		8:
			return 0.4  # 40%
		9:
			return 0.2  # 20%
		10:
			return 0.1  # 10%
		_:
			return 0.0

## Calculate enhancement destruction rate
func get_enhancement_destruction_rate() -> float:
	if enhancement_level < 8:
		return 0.0  # No destruction risk below +8
	elif enhancement_level == 8:
		return 0.05  # 5%
	elif enhancement_level == 9:
		return 0.1   # 10%
	elif enhancement_level == 10:
		return 0.15  # 15%
	return 0.0
