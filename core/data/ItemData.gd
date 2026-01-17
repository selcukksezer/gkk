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
	POTION,
	RECIPE,      # Üretim tarifleri
	RUNE,        # Geliştirme için rün taşları
	SCROLL,      # Geliştirme kağıtları (Upgrade Scrolls)
	COSMETIC     # Kozmetik eşyalar
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
	HEAD,        # Helmet/Helm
	CHEST,       # Body armor
	HANDS,       # Gloves
	LEGS,        # Pants/Greaves
	FEET,        # Boots
	ACCESSORY    # Rings, Amulets, Belts
}

# Weapon subtypes
enum WeaponType {
	NONE,
	SWORD,       # Kılıç
	SPEAR,       # Mızrak
	BOW,         # Yay
	AXE,         # Balta
	DAGGER,      # Hançer
	STAFF,       # Asa
	SHIELD       # Kalkan
}

# Armor subtypes
enum ArmorType {
	NONE,
	PLATE,       # Plaka zırh
	CHAIN,       # Zincir zırh
	LEATHER,     # Deri zırh
	CLOTH        # Kumaş zırh
}

# Material subtypes
enum MaterialType {
	NONE,
	ORE,         # Cevher (demir, altın, gümüş)
	WOOD,        # Kereste
	LEATHER,     # Deri
	HERB,        # Bitki/ot
	CRYSTAL,     # Kristal
	GEM          # Değerli taş
}

# Potion subtypes
enum PotionType {
	NONE,
	ENERGY,      # Enerji iksiri
	HEALING,     # İyileştirme iksiri
	BUFF,        # Buff iksiri
	ANTIDOTE     # Antidot
}

@export var item_id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: String = ""
@export var item_type: ItemType = ItemType.MATERIAL
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var equip_slot: EquipSlot = EquipSlot.NONE

# Subtype exports
@export var weapon_type: WeaponType = WeaponType.NONE
@export var armor_type: ArmorType = ArmorType.NONE
@export var material_type: MaterialType = MaterialType.NONE
@export var potion_type: PotionType = PotionType.NONE

## Economy
@export var base_price: int = 0
@export var vendor_sell_price: int = 0
@export var is_tradeable: bool = true
@export var is_stackable: bool = true
@export var max_stack: int = 50

## Recipe System (for RECIPE type items)
@export var recipe_result_item_id: String = ""  # Üretilecek item ID'si
@export var recipe_requirements: Dictionary = {}  # {"item_id": quantity}
@export var recipe_building_type: String = ""  # "blacksmith", "alchemy", "farm"
@export var recipe_production_time: int = 0  # Saniye cinsinden
@export var recipe_required_level: int = 1  # Üretim seviyesi

## Rune System (for RUNE type items)
@export var rune_enhancement_type: String = ""  # "attack", "defense", "health", "power"
@export var rune_success_bonus: float = 0.0  # Başarı oranı bonusu (%)
@export var rune_destruction_reduction: float = 0.0  # Yok olma riski azaltma (%)

## Cosmetic System (for COSMETIC type items)
@export var cosmetic_effect: String = ""  # Görsel efekt adı
@export var cosmetic_bind_on_pickup: bool = true  # Alınca bağlanır
@export var cosmetic_showcase_only: bool = false  # Sadece gösterim

## Production System (for MATERIAL type items)
@export var production_building_type: String = ""  # "mine", "sawmill", "farm"
@export var production_rate_per_hour: int = 0  # Saat başına üretim miktarı
@export var production_required_level: int = 1  # Bina seviyesi

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

## Instance tracking
@export var row_id: String = ""  # Database UUID (server-side ID)
@export var is_equipped: bool = false  # Whether item is currently equipped
@export var quantity: int = 1
@export var obtained_at: int = 0
@export var bound_to_player: bool = false
@export var is_favorite: bool = false
@export var slot_position: int = -1  # Inventory slot position (0-19), -1 = unassigned
## Client-only flags
@export var pending_sync: bool = false

## Create from dictionary
static func from_dict(data: Dictionary) -> ItemData:
	var item = ItemData.new()
	
	# Helper function to safely get string values (handle null/Nil from JSON)
	# JSON'dan gelen null değerler Godot'da Nil olarak gelir ve String'e atanamaz
	var safe_string = func(key: String, default: String = "") -> String:
		var value = data.get(key, default)
		if value == null:
			return default
		return str(value)
	
	# IMPORTANT: First, try to load base definition from ItemDatabase
	# This ensures we always have the latest item properties (icon, rarity, description, etc.)
	var item_id = safe_string.call("id", safe_string.call("item_id", ""))
	
	# If we have an item_id, try to get base definition from ItemDatabase
	var base_definition: Dictionary = {}
	var has_database_def = false
	if item_id != "" and ItemDatabase.item_exists(item_id):
		base_definition = ItemDatabase.get_item(item_id)
		has_database_def = true
		# Verbose log disabled: Loading base definition from ItemDatabase
	else:
		pass # No ItemDatabase definition found - using data as-is
	
	# CRITICAL: Only merge instance-specific properties from server data
	# Static properties (name, icon, rarity, stats, equip_slot) should ALWAYS come from ItemDatabase
	var instance_only_keys = ["quantity", "enhancement_level", "obtained_at", "bound_to_player", "pending_sync", "is_equipped"]
	
	var parse_data: Dictionary
	if has_database_def:
		# Use ItemDatabase as base, only override with instance properties
		parse_data = base_definition.duplicate()
		for key in instance_only_keys:
			if data.has(key):
				parse_data[key] = data[key]
		# If server provided a custom icon path, prefer it when valid (supports res:// paths)
		if data.has("icon") and data.icon != null and typeof(data.icon) == TYPE_STRING:
			var server_icon = str(data.icon)
			# If the DB stores a raw path (no res://), try to resolve it to res://
			var candidate_paths = [server_icon]
			if not server_icon.begins_with("res://"):
				# Strip leading slash if present and try res://<path>
				var stripped = server_icon.strip_prefix("/")
				candidate_paths.append("res://" + stripped)
				# Also try res://assets/<path> if it was uploaded without the top folder
				candidate_paths.append("res://" + "assets/" + stripped)
			
			var used_path = null
			for p in candidate_paths:
				if ResourceLoader.exists(p):
					used_path = p
					break
			
			if used_path:
				parse_data["icon"] = used_path
				print("[ItemData] Using server-provided icon for item ", item_id, ": ", used_path)
			else:
				print("[ItemData] Server-provided icon not usable for item ", item_id, ": ", server_icon, " tried: ", candidate_paths)
		# Verbose log disabled: Using ItemDatabase definition with instance overrides
	else:
		# No database definition, use all data from server
		parse_data = data.duplicate()
		# Verbose log disabled: Using server data directly
	
	# Now parse from merged data
	item.item_id = item_id
	item.name = parse_data.get("name", "")
	item.description = parse_data.get("description", "")
	item.icon = parse_data.get("icon", "")
	
	# Use merged_data for parsing to get base definition values with instance overrides
	# (renamed from merged_data to parse_data for clarity)
	
	# Parse enums - safely handle null values
	var type_str = parse_data.get("item_type", null)
	if type_str == null:
		type_str = "MATERIAL"
	type_str = str(type_str)
	item.item_type = ItemType[type_str] if type_str in ItemType else ItemType.MATERIAL
	
	var rarity_str = parse_data.get("rarity", null)
	if rarity_str == null:
		rarity_str = "COMMON"
	rarity_str = str(rarity_str)
	item.rarity = ItemRarity[rarity_str] if rarity_str in ItemRarity else ItemRarity.COMMON
	
	var slot_str = parse_data.get("equip_slot", null)
	if slot_str == null:
		slot_str = "NONE"
	slot_str = str(slot_str)
	item.equip_slot = EquipSlot[slot_str] if slot_str in EquipSlot else EquipSlot.NONE
	
	# Parse subtypes
	var weapon_type_str = parse_data.get("weapon_type", null)
	if weapon_type_str == null:
		weapon_type_str = "NONE"
	weapon_type_str = str(weapon_type_str)
	item.weapon_type = WeaponType.get(weapon_type_str) if WeaponType.has(weapon_type_str) else WeaponType.NONE
	
	var armor_type_str = parse_data.get("armor_type", null)
	if armor_type_str == null:
		armor_type_str = "NONE"
	armor_type_str = str(armor_type_str)
	item.armor_type = ArmorType.get(armor_type_str) if ArmorType.has(armor_type_str) else ArmorType.NONE
	
	var material_type_str = parse_data.get("material_type", null)
	if material_type_str == null:
		material_type_str = "NONE"
	material_type_str = str(material_type_str)
	item.material_type = MaterialType.get(material_type_str) if MaterialType.has(material_type_str) else MaterialType.NONE
	
	var potion_type_str = parse_data.get("potion_type", null)
	if potion_type_str == null:
		potion_type_str = "NONE"
	potion_type_str = str(potion_type_str)
	item.potion_type = PotionType.get(potion_type_str) if PotionType.has(potion_type_str) else PotionType.NONE
	
	# Numeric values - handle null - use parse_data for base values
	item.base_price = parse_data.get("base_price", 0) if parse_data.get("base_price", null) != null else 0
	item.vendor_sell_price = parse_data.get("vendor_sell_price", 0) if parse_data.get("vendor_sell_price", null) != null else 0
	item.is_tradeable = parse_data.get("is_tradeable", true) if parse_data.get("is_tradeable", null) != null else true
	item.is_stackable = parse_data.get("is_stackable", true) if parse_data.get("is_stackable", null) != null else true
	item.max_stack = parse_data.get("max_stack", 50) if parse_data.get("max_stack", null) != null else 50
	
	# Recipe system
	var recipe_result_id = parse_data.get("recipe_result_item_id", null)
	item.recipe_result_item_id = str(recipe_result_id) if recipe_result_id != null else ""
	item.recipe_requirements = parse_data.get("recipe_requirements", {}) if parse_data.get("recipe_requirements", null) != null else {}
	var recipe_building = parse_data.get("recipe_building_type", null)
	item.recipe_building_type = str(recipe_building) if recipe_building != null else ""
	item.recipe_production_time = parse_data.get("recipe_production_time", 0) if parse_data.get("recipe_production_time", null) != null else 0
	item.recipe_required_level = parse_data.get("recipe_required_level", 1) if parse_data.get("recipe_required_level", null) != null else 1
	
	# Rune system
	var rune_type = parse_data.get("rune_enhancement_type", null)
	item.rune_enhancement_type = str(rune_type) if rune_type != null else ""
	item.rune_success_bonus = parse_data.get("rune_success_bonus", 0.0) if parse_data.get("rune_success_bonus", null) != null else 0.0
	item.rune_destruction_reduction = parse_data.get("rune_destruction_reduction", 0.0) if parse_data.get("rune_destruction_reduction", null) != null else 0.0
	
	# Cosmetic system
	var cosmetic_fx = parse_data.get("cosmetic_effect", null)
	item.cosmetic_effect = str(cosmetic_fx) if cosmetic_fx != null else ""
	item.cosmetic_bind_on_pickup = parse_data.get("cosmetic_bind_on_pickup", true) if parse_data.get("cosmetic_bind_on_pickup", null) != null else true
	item.cosmetic_showcase_only = parse_data.get("cosmetic_showcase_only", false) if parse_data.get("cosmetic_showcase_only", null) != null else false
	
	# Production system
	var prod_building = parse_data.get("production_building_type", null)
	item.production_building_type = str(prod_building) if prod_building != null else ""
	item.production_rate_per_hour = parse_data.get("production_rate_per_hour", 0) if parse_data.get("production_rate_per_hour", null) != null else 0
	item.production_required_level = parse_data.get("production_required_level", 1) if parse_data.get("production_required_level", null) != null else 1
	
	# Stats - handle null - use parse_data for base stats
	item.attack = parse_data.get("attack", 0) if parse_data.get("attack", null) != null else 0
	item.defense = parse_data.get("defense", 0) if parse_data.get("defense", null) != null else 0
	item.health = parse_data.get("health", 0) if parse_data.get("health", null) != null else 0
	item.power = parse_data.get("power", 0) if parse_data.get("power", null) != null else 0
	
	# Enhancement - INSTANCE-SPECIFIC - use original data, not base definition
	item.enhancement_level = data.get("enhancement_level", 0) if data.get("enhancement_level", null) != null else 0
	item.max_enhancement = parse_data.get("max_enhancement", 10) if parse_data.get("max_enhancement", null) != null else 10
	item.can_enhance = parse_data.get("can_enhance", false) if parse_data.get("can_enhance", null) != null else false
	
	# Consumable stats - handle null
	item.energy_restore = parse_data.get("energy_restore", 0) if parse_data.get("energy_restore", null) != null else 0
	item.tolerance_increase = parse_data.get("tolerance_increase", 0) if parse_data.get("tolerance_increase", null) != null else 0
	item.overdose_risk = parse_data.get("overdose_risk", 0.0) if parse_data.get("overdose_risk", null) != null else 0.0
	item.heal_amount = parse_data.get("heal_amount", 0) if parse_data.get("heal_amount", null) != null else 0
	
	item.required_level = parse_data.get("required_level", 1) if parse_data.get("required_level", null) != null else 1
	var req_class = parse_data.get("required_class", null)
	item.required_class = str(req_class) if req_class != null else ""
	
	# Meta - INSTANCE-SPECIFIC - always use original data
	item.row_id = data.get("row_id", "") if data.get("row_id", null) != null else ""
	item.is_equipped = data.get("is_equipped", false) if data.get("is_equipped", null) != null else false
	item.quantity = data.get("quantity", 1) if data.get("quantity", null) != null else 1
	item.obtained_at = data.get("obtained_at", 0) if data.get("obtained_at", null) != null else 0
	item.bound_to_player = data.get("bound_to_player", false) if data.get("bound_to_player", null) != null else false
	item.is_favorite = data.get("is_favorite", false) if data.get("is_favorite", null) != null else false
	item.slot_position = data.get("slot_position", -1) if data.get("slot_position", null) != null else -1
	item.pending_sync = data.get("pending_sync", false) if data.get("pending_sync", null) != null else false
	
	return item

## Convert to dictionary
func to_dict() -> Dictionary:
	# Explicitly cast integer values to ensure they serialize as integers, not floats
	return {
		"id": item_id,
		"name": name,
		"description": description,
		"icon": icon,
		"item_type": ItemType.keys()[item_type],
		"rarity": ItemRarity.keys()[rarity],
		"equip_slot": EquipSlot.keys()[equip_slot],
		"weapon_type": WeaponType.keys()[weapon_type],
		"armor_type": ArmorType.keys()[armor_type],
		"material_type": MaterialType.keys()[material_type],
		"potion_type": PotionType.keys()[potion_type],
		"base_price": int(base_price),
		"vendor_sell_price": int(vendor_sell_price),
		"is_tradeable": is_tradeable,
		"is_stackable": is_stackable,
		"max_stack": int(max_stack),
		"recipe_result_item_id": recipe_result_item_id,
		"recipe_requirements": recipe_requirements,
		"recipe_building_type": recipe_building_type,
		"recipe_production_time": int(recipe_production_time),
		"recipe_required_level": int(recipe_required_level),
		"rune_enhancement_type": rune_enhancement_type,
		"rune_success_bonus": float(rune_success_bonus),
		"rune_destruction_reduction": float(rune_destruction_reduction),
		"cosmetic_effect": cosmetic_effect,
		"cosmetic_bind_on_pickup": cosmetic_bind_on_pickup,
		"cosmetic_showcase_only": cosmetic_showcase_only,
		"production_building_type": production_building_type,
		"production_rate_per_hour": int(production_rate_per_hour),
		"production_required_level": int(production_required_level),
		"attack": int(attack),
		"defense": int(defense),
		"health": int(health),
		"power": int(power),
		"enhancement_level": int(enhancement_level),
		"max_enhancement": int(max_enhancement),
		"can_enhance": can_enhance,
		"energy_restore": int(energy_restore),
		"tolerance_increase": int(tolerance_increase),
		"overdose_risk": float(overdose_risk),
		"heal_amount": int(heal_amount),
		"required_level": int(required_level),
		"required_class": required_class,
		"quantity": int(quantity),
		"obtained_at": int(obtained_at),
		"bound_to_player": bound_to_player,
		"pending_sync": pending_sync
	}

## Convert to instance-specific dictionary (for database storage)
## This only includes instance data, not static ItemDatabase properties
func to_instance_dict() -> Dictionary:
	return {
		"item_id": item_id,  # Reference to ItemDatabase
		"quantity": int(quantity),
		"enhancement_level": int(enhancement_level),
		"bound_to_player": bound_to_player,
		"obtained_at": int(obtained_at),
		"pending_sync": pending_sync
	}

static func get_rarity_color_static(rarity_enum: int) -> Color:
	match rarity_enum:
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

## Get rarity color
func get_rarity_color() -> Color:
	return ItemData.get_rarity_color_static(rarity)

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

## Recipe System Methods
func can_craft_with_inventory(inventory: Dictionary) -> bool:
	"""Check if player has required materials to craft this recipe"""
	for item_id in recipe_requirements:
		var required_qty = recipe_requirements[item_id]
		var available_qty = inventory.get(item_id, 0)
		if available_qty < required_qty:
			return false
	return true

func get_recipe_display_requirements() -> String:
	"""Get formatted string of recipe requirements"""
	var requirements = []
	for item_id in recipe_requirements:
		var qty = recipe_requirements[item_id]
		requirements.append("%s x%d" % [item_id, qty])
	return ", ".join(requirements)

## Rune System Methods
func get_rune_success_modifier() -> float:
	"""Get success rate modifier from rune"""
	return rune_success_bonus / 100.0

func get_rune_destruction_modifier() -> float:
	"""Get destruction rate modifier from rune (negative = reduction)"""
	return -rune_destruction_reduction / 100.0

func can_apply_to_item(target_item: ItemData) -> bool:
	"""Check if rune can be applied to target item"""
	if not target_item.can_enhance:
		return false
	
	match rune_enhancement_type:
		"attack":
			return target_item.attack > 0
		"defense":
			return target_item.defense > 0
		"health":
			return target_item.health > 0
		"power":
			return target_item.power > 0
		_:
			return false

## Cosmetic System Methods
func is_cosmetic_equipped() -> bool:
	"""Check if cosmetic item is equipped (cosmetics are always 'equipped' when owned)"""
	return item_type == ItemType.COSMETIC and not cosmetic_showcase_only

## Production System Methods
func get_production_per_hour(building_level: int) -> int:
	"""Calculate production rate based on building level"""
	if building_level < production_required_level:
		return 0
	return production_rate_per_hour * building_level

func get_production_time_seconds(quantity: int) -> int:
	"""Calculate time to produce given quantity"""
	if production_rate_per_hour <= 0:
		return 0
	return int((quantity * 3600.0) / production_rate_per_hour)

## Item Category Helpers
func is_weapon() -> bool:
	return item_type == ItemType.WEAPON

func is_armor() -> bool:
	return item_type == ItemType.ARMOR

func is_potion() -> bool:
	return item_type == ItemType.POTION

func is_equipment() -> bool:
	return item_type in [ItemType.WEAPON, ItemType.ARMOR, ItemType.ACCESSORY]

func is_consumable() -> bool:
	return item_type in [ItemType.CONSUMABLE, ItemType.POTION]

func is_material() -> bool:
	return item_type == ItemType.MATERIAL

func is_recipe() -> bool:
	return item_type == ItemType.RECIPE

func is_rune() -> bool:
	return item_type == ItemType.RUNE

func is_cosmetic() -> bool:
	return item_type == ItemType.COSMETIC

func is_scroll() -> bool:
	return item_type == ItemType.SCROLL

## Get item category display name
func get_category_display_name() -> String:
	match item_type:
		ItemType.WEAPON:
			return WeaponType.keys()[weapon_type]
		ItemType.ARMOR:
			return ArmorType.keys()[armor_type]
		ItemType.MATERIAL:
			return MaterialType.keys()[material_type]
		ItemType.POTION:
			return PotionType.keys()[potion_type]
		ItemType.RECIPE:
			return "Recipe"
		ItemType.RUNE:
			return "Rune"
		ItemType.COSMETIC:
			return "Cosmetic"
		ItemType.SCROLL:
			return "Upgrade Scroll"
		_:
			return ItemType.keys()[item_type]

## Get detailed item info for tooltips
func get_detailed_info() -> Dictionary:
	var info = {
		"name": name,
		"description": description,
		"type": get_category_display_name(),
		"rarity": ItemRarity.keys()[rarity],
		"rarity_color": get_rarity_color(),
		"tradeable": is_tradeable,
		"stackable": is_stackable,
		"max_stack": max_stack if is_stackable else 1
	}
	
	# Equipment stats
	if is_equipment():
		info["stats"] = {
			"attack": get_total_attack(),
			"defense": get_total_defense(),
			"health": get_total_health(),
			"power": get_total_power(),
			"enhancement": get_enhancement_display(),
			"required_level": required_level
		}
	
	# Consumable effects
	if is_consumable():
		info["effects"] = {}
		if energy_restore > 0:
			info["effects"]["energy"] = energy_restore
		if heal_amount > 0:
			info["effects"]["heal"] = heal_amount
		if tolerance_increase > 0:
			info["effects"]["tolerance"] = tolerance_increase
		if overdose_risk > 0:
			info["effects"]["overdose_risk"] = overdose_risk
	
	# Recipe info
	if is_recipe():
		info["recipe"] = {
			"result": recipe_result_item_id,
			"requirements": recipe_requirements,
			"building": recipe_building_type,
			"time": recipe_production_time,
			"level": recipe_required_level
		}
	
	# Rune info
	if is_rune():
		info["rune"] = {
			"type": rune_enhancement_type,
			"success_bonus": rune_success_bonus,
			"destruction_reduction": rune_destruction_reduction
		}
	
	# Production info
	if is_material() and production_building_type != "":
		info["production"] = {
			"building": production_building_type,
			"rate_per_hour": production_rate_per_hour,
			"required_level": production_required_level
		}
	
	return info
