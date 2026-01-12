## ItemDatabase.gd - Static item definitions and database
## Contains all game items with their base stats and properties

extends Node

class_name ItemDatabase

## Predefined items database
const ITEMS = {
	# Weapons
	"weapon_sword_basic": {
		"id": "weapon_sword_basic",
		"name": "Demir Kılıç",
		"description": "Basit bir demir kılıç. Yeni başlayanlar için ideal.",
		"icon": "res://assets/sprites/items/sword_basic.png",
		"item_type": "WEAPON",
		"weapon_type": "SWORD",
		"rarity": "COMMON",
		"equip_slot": "WEAPON",
		"base_price": 100,
		"vendor_sell_price": 50,
		"attack": 15,
		"defense": 5,
		"required_level": 1,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	"weapon_bow_elven": {
		"id": "weapon_bow_elven",
		"name": "Elf Yayı",
		"description": "Elf ustalarının yaptığı hafif ve güçlü yay.",
		"icon": "res://assets/sprites/items/bow_elven.png",
		"item_type": "WEAPON",
		"weapon_type": "BOW",
		"rarity": "RARE",
		"equip_slot": "WEAPON",
		"base_price": 2500,
		"vendor_sell_price": 1250,
		"attack": 35,
		"power": 10,
		"required_level": 15,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},

	"weapon_custom_longsword": {
		"id": "weapon_custom_longsword",
		"name": "Eşsiz Uzun Kılıç",
		"description": "Kullanıcının eklediği kılıç.",
		"icon": "res://assets/sprites/items/sword_custom.png",
		"item_type": "WEAPON",
		"weapon_type": "SWORD",
		"rarity": "EPIC",
		"equip_slot": "WEAPON",
		"base_price": 1200,
		"vendor_sell_price": 600,
		"attack": 60,
		"required_level": 10,
		"can_enhance": true,
		"max_enhancement": 15,
		"is_stackable": false
	},

	"armor_custom_plate": {
		"id": "armor_custom_plate",
		"name": "Eşsiz Zırh",
		"description": "Kullanıcının eklediği plaka zırh.",
		"icon": "res://assets/sprites/items/armor_custom.png",
		"item_type": "ARMOR",
		"armor_type": "PLATE",
		"rarity": "EPIC",
		"equip_slot": "CHEST",
		"base_price": 1500,
		"vendor_sell_price": 750,
		"defense": 80,
		"health": 120,
		"required_level": 12,
		"can_enhance": true,
		"max_enhancement": 15,
		"is_stackable": false
	},

	# Armor
	"armor_chest_leather": {
		"id": "armor_chest_leather",
		"name": "Deri Göğüslük",
		"description": "Esnek deri zırh. Hareket özgürlüğü sağlar.",
		"icon": "res://assets/sprites/items/chest_leather.png",
		"item_type": "ARMOR",
		"armor_type": "LEATHER",
		"rarity": "COMMON",
		"equip_slot": "CHEST",
		"base_price": 80,
		"vendor_sell_price": 40,
		"defense": 12,
		"health": 20,
		"required_level": 1,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	"armor_chest_plate": {
		"id": "armor_chest_plate",
		"name": "Plaka Göğüslük",
		"description": "Ağır plaka zırh. Maksimum koruma sağlar.",
		"icon": "res://assets/sprites/items/chest_plate.png",
		"item_type": "ARMOR",
		"armor_type": "PLATE",
		"rarity": "UNCOMMON",
		"equip_slot": "CHEST",
		"base_price": 500,
		"vendor_sell_price": 250,
		"defense": 25,
		"health": 40,
		"required_level": 8,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	# Potions
	"potion_energy_minor": {
		"id": "potion_energy_minor",
		"name": "Minör Enerji İksiri",
		"description": "+20 enerji geri yükler. Hafif bağımlılık yapar.",
		"icon": "res://assets/sprites/items/potion_energy.png",
		"item_type": "POTION",
		"potion_type": "ENERGY",
		"rarity": "COMMON",
		"base_price": 25,
		"vendor_sell_price": 10,
		"energy_restore": 20,
		"tolerance_increase": 1,
		"overdose_risk": 0.01,
		"is_stackable": true,
		"max_stack": 50
	},
	
	"potion_antidote": {
		"id": "potion_antidote",
		"name": "Antidot",
		"description": "Bağımlılığı azaltır ve toleransı sıfırlar.",
		"icon": "res://assets/sprites/items/potion_antidote.png",
		"item_type": "POTION",
		"potion_type": "ANTIDOTE",
		"rarity": "UNCOMMON",
		"base_price": 100,
		"vendor_sell_price": 50,
		"tolerance_increase": -5,
		"is_stackable": true,
		"max_stack": 50
	},
	
	# Materials
	"material_iron_ore": {
		"id": "material_iron_ore",
		"name": "Demir Cevheri",
		"description": "Demir üretimi için kullanılır.",
		"icon": "res://assets/sprites/items/ore_iron.png",
		"item_type": "MATERIAL",
		"material_type": "ORE",
		"rarity": "COMMON",
		"base_price": 5,
		"vendor_sell_price": 2,
		"production_building_type": "mine",
		"production_rate_per_hour": 10,
		"production_required_level": 1,
		"is_stackable": true,
		"max_stack": 50
	},
	
	"material_wood": {
		"id": "material_wood",
		"name": "Kereste",
		"description": "İnşaat ve üretim için kullanılır.",
		"icon": "res://assets/sprites/items/wood.png",
		"item_type": "MATERIAL",
		"material_type": "WOOD",
		"rarity": "COMMON",
		"base_price": 3,
		"vendor_sell_price": 1,
		"production_building_type": "sawmill",
		"production_rate_per_hour": 15,
		"production_required_level": 1,
		"is_stackable": true,
		"max_stack": 50
	},
	
	# Recipes
	"recipe_sword_basic": {
		"id": "recipe_sword_basic",
		"name": "Demir Kılıç Tarifi",
		"description": "Demir kılıç üretme tarifi.",
		"icon": "res://assets/sprites/items/recipe_sword.png",
		"item_type": "RECIPE",
		"rarity": "COMMON",
		"base_price": 50,
		"recipe_result_item_id": "weapon_sword_basic",
		"recipe_requirements": {
			"material_iron_ore": 3,
			"material_wood": 1
		},
		"recipe_building_type": "blacksmith",
		"recipe_production_time": 300,  # 5 minutes
		"recipe_required_level": 1
	},
	
	# Runes
	"rune_attack_minor": {
		"id": "rune_attack_minor",
		"name": "Küçük Saldırı Rünü",
		"description": "Geliştirme başarı oranını %5 artırır.",
		"icon": "res://assets/sprites/items/rune_attack.png",
		"item_type": "RUNE",
		"rarity": "UNCOMMON",
		"base_price": 200,
		"rune_enhancement_type": "attack",
		"rune_success_bonus": 5.0,
		"rune_destruction_reduction": 2.0
	},
	
	# Cosmetics
	"cosmetic_crown_gold": {
		"id": "cosmetic_crown_gold",
		"name": "Altın Taç",
		"description": "Altın taç efekti. Sadece gösterim amaçlı.",
		"icon": "res://assets/sprites/items/crown_gold.png",
		"item_type": "COSMETIC",
		"rarity": "EPIC",
		"base_price": 5000,
		"cosmetic_effect": "golden_crown",
		"cosmetic_bind_on_pickup": true,
		"cosmetic_showcase_only": false,
		"is_tradeable": false
	}
}

## Get item by ID
static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

## Get all items of a specific type
static func get_items_by_type(item_type: String) -> Array:
	var result = []
	for item_id in ITEMS:
		if ITEMS[item_id].get("item_type", "") == item_type:
			result.append(ITEMS[item_id])
	return result

## Get all weapons
static func get_weapons() -> Array:
	return get_items_by_type("WEAPON")

## Get all armor
static func get_armor() -> Array:
	return get_items_by_type("ARMOR")

## Get all potions
static func get_potions() -> Array:
	return get_items_by_type("POTION")

## Get all materials
static func get_materials() -> Array:
	return get_items_by_type("MATERIAL")

## Get all recipes
static func get_recipes() -> Array:
	return get_items_by_type("RECIPE")

## Get all runes
static func get_runes() -> Array:
	return get_items_by_type("RUNE")

## Get all cosmetics
static func get_cosmetics() -> Array:
	return get_items_by_type("COSMETIC")

## Create ItemData instance from database
static func create_item(item_id: String, quantity: int = 1) -> ItemData:
	var item_data = get_item(item_id)
	if item_data.is_empty():
		push_error("Item not found in database: %s" % item_id)
		return null
	
	var item = ItemData.from_dict(item_data)
	item.quantity = quantity
	item.obtained_at = int(Time.get_unix_time_from_system())
	
	return item

## Get random item by rarity
static func get_random_item_by_rarity(rarity: String) -> Dictionary:
	var matching_items = []
	for item_id in ITEMS:
		if ITEMS[item_id].get("rarity", "") == rarity:
			matching_items.append(ITEMS[item_id])
	
	if matching_items.is_empty():
		return {}
	
	return matching_items[randi() % matching_items.size()]

## Get item value for market calculations
static func get_item_value(item_id: String) -> int:
	var item = get_item(item_id)
	return item.get("base_price", 0)

## Check if item exists
static func item_exists(item_id: String) -> bool:
	return ITEMS.has(item_id)

## Get all items as ItemData array
static func get_all_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item_id in ITEMS:
		var item_data = create_item(item_id, 1)
		if item_data:
			result.append(item_data)
	return result