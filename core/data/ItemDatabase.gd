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
		"icon": "res://assets/sprites/items/bow.png",
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
		"max_stack": 500
	},
	
	"material_copper_ore": {
		"id": "material_copper_ore",
		"name": "Bakır Cevheri",
		"description": "Bakır ve tunç eşyalar üretmek için kullanılır.",
		"icon": "res://assets/sprites/items/ore_copper.png",
		"item_type": "MATERIAL",
		"material_type": "ORE",
		"rarity": "COMMON",
		"base_price": 8,
		"vendor_sell_price": 3,
		"production_building_type": "mine",
		"production_required_level": 1,
		"is_stackable": true,
		"max_stack": 500
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
		"max_stack": 500
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
	
	# ======================= RUNES =======================
	"scroll_upgrade_low": {
		"id": "scroll_upgrade_low",
		"name": "Düşük Sınıf Yükseltme Kağıdı",
		"description": "Common ve Uncommon eşyaları yükseltmek için kullanılır.",
		"icon": "res://assets/sprites/items/lowclassscroll.png",
		"item_type": "SCROLL",
		"rarity": "UNCOMMON",
		"base_price": 500,
		"vendor_sell_price": 250, 
		"is_stackable": true,
		"max_stack": 50
	},
	
	"scroll_upgrade_middle": {
		"id": "scroll_upgrade_middle",
		"name": "Orta Sınıf Yükseltme Kağıdı",
		"description": "Rare ve Epic eşyaları yükseltmek için kullanılır.",
		"icon": "res://assets/sprites/items/middleclassscroll.png",
		"item_type": "SCROLL",
		"rarity": "RARE",
		"base_price": 2500,
		"vendor_sell_price": 1250,
		"is_stackable": true,
		"max_stack": 50
	},
	
	"scroll_upgrade_high": {
		"id": "scroll_upgrade_high",
		"name": "Yüksek Sınıf Yükseltme Kağıdı",
		"description": "Legendary ve Mythic eşyaları yükseltmek için kullanılır.",
		"icon": "res://assets/sprites/items/highclassscroll.png",
		"item_type": "SCROLL",
		"rarity": "EPIC",
		"base_price": 10000,
		"vendor_sell_price": 5000,
		"is_stackable": true,
		"max_stack": 30
	},
	
	# ======================= RAW MATERIALS (MINE) =======================
	"material_gold_ore": {
		"id": "material_gold_ore",
		"name": "Altın Cevheri",
		"description": "Altın ve değerli eşyalar üretmek için kullanılır.",
		"icon": "res://assets/sprites/items/ore_gold.png",
		"item_type": "MATERIAL",
		"material_type": "ORE",
		"rarity": "UNCOMMON",
		"base_price": 20,
		"vendor_sell_price": 10,
		"production_building_type": "mine",
		"production_required_level": 5,
		"is_stackable": true,
		"max_stack": 500
	},
	
	"material_silver_ore": {
		"id": "material_silver_ore",
		"name": "Gümüş Cevheri",
		"description": "Gümüş ve aksesuarlar üretmek için kullanılır.",
		"icon": "res://assets/sprites/items/ore_silver.png",
		"item_type": "MATERIAL",
		"material_type": "ORE",
		"rarity": "UNCOMMON",
		"base_price": 15,
		"vendor_sell_price": 7,
		"production_building_type": "mine",
		"production_required_level": 3,
		"is_stackable": true,
		"max_stack": 500
	},
	
	"material_crystal": {
		"id": "material_crystal",
		"name": "Kristal",
		"description": "Büyü ve rün yapımında kullanılan değerli taş.",
		"icon": "res://assets/sprites/items/crystal.png",
		"item_type": "MATERIAL",
		"material_type": "CRYSTAL",
		"rarity": "RARE",
		"base_price": 50,
		"vendor_sell_price": 25,
		"production_building_type": "mine",
		"production_required_level": 7,
		"is_stackable": true,
		"max_stack": 500
	},
	
	"material_diamond": {
		"id": "material_diamond",
		"name": "Elmas",
		"description": "En değerli efsanevi eşyalar yapılırken gerekli olan taş.",
		"icon": "res://assets/sprites/items/diamond.png",
		"item_type": "MATERIAL",
		"material_type": "GEM",
		"rarity": "LEGENDARY",
		"base_price": 500,
		"vendor_sell_price": 250,
		"production_building_type": "mine",
		"production_required_level": 10,
		"is_stackable": true,
		"max_stack": 500
	},
	
	# ======================= RAW MATERIALS (SAWMILL) =======================
	"material_hardwood": {
		"id": "material_hardwood",
		"name": "Sert Kereste",
		"description": "Dayanıklı kaliteli kereste. Güçlü eşyalar yapmak için gerekli.",
		"icon": "res://assets/sprites/items/hardwood.png",
		"item_type": "MATERIAL",
		"material_type": "WOOD",
		"rarity": "UNCOMMON",
		"base_price": 10,
		"vendor_sell_price": 5,
		"production_building_type": "sawmill",
		"production_required_level": 4,
		"is_stackable": true,
		"max_stack": 500
	},
	
	"material_bamboo": {
		"id": "material_bamboo",
		"name": "Bambu",
		"description": "Hafif ve esnek. Yaylar ve çubuklardan yapılır.",
		"icon": "res://assets/sprites/items/bamboo.png",
		"item_type": "MATERIAL",
		"material_type": "WOOD",
		"rarity": "COMMON",
		"base_price": 5,
		"vendor_sell_price": 2,
		"production_building_type": "sawmill",
		"production_required_level": 3,
		"is_stackable": true,
		"max_stack": 500
	},
	
	# ======================= RAW MATERIALS (FARM) =======================
	"material_leather": {
		"id": "material_leather",
		"name": "Deri",
		"description": "Hayvan derisi. Zırh ve aksesuarlar yapımında kullanılır.",
		"icon": "res://assets/sprites/items/leather.png",
		"item_type": "MATERIAL",
		"material_type": "LEATHER",
		"rarity": "COMMON",
		"base_price": 8,
		"vendor_sell_price": 4,
		"production_building_type": "farm",
		"production_required_level": 1,
		"is_stackable": true,
		"max_stack": 500
	},
	
	"material_quality_leather": {
		"id": "material_quality_leather",
		"name": "Kaliteli Deri",
		"description": "Işlenmiş yüksek kaliteli deri. Ince zırh yapımında kullanılır.",
		"icon": "res://assets/sprites/items/quality_leather.png",
		"item_type": "MATERIAL",
		"material_type": "LEATHER",
		"rarity": "RARE",
		"base_price": 40,
		"vendor_sell_price": 20,
		"production_building_type": "farm",
		"production_required_level": 5,
		"is_stackable": true,
		"max_stack": 500
	},
	
	"material_wool": {
		"id": "material_wool",
		"name": "Yün",
		"description": "Dönerden alınan yün. Kumaş eşyalar yapımında kullanılır.",
		"icon": "res://assets/sprites/items/wool.png",
		"item_type": "MATERIAL",
		"material_type": "LEATHER",
		"rarity": "COMMON",
		"base_price": 6,
		"vendor_sell_price": 3,
		"production_building_type": "farm",
		"production_required_level": 2,
		"is_stackable": true,
		"max_stack": 500
	},
	
	# ======================= RAW MATERIALS (HERB GARDEN) =======================
	"material_herb": {
		"id": "material_herb",
		"name": "Tıbbi Ot",
		"description": "İksir yapımında temel malzeme. Şifa ve buff potionları için gerekli.",
		"icon": "res://assets/sprites/items/herb.png",
		"item_type": "MATERIAL",
		"material_type": "HERB",
		"rarity": "COMMON",
		"base_price": 5,
		"vendor_sell_price": 2,
		"production_building_type": "herb_garden",
		"production_required_level": 1,
		"is_stackable": true,
		"max_stack": 500
	},
	
	"material_rare_herb": {
		"id": "material_rare_herb",
		"name": "Nadir Ot",
		"description": "Nadir ve kuvvetli bitki. Güçlü potion yapımında gereklidir.",
		"icon": "res://assets/sprites/items/rare_herb.png",
		"item_type": "MATERIAL",
		"material_type": "HERB",
		"rarity": "EPIC",
		"base_price": 100,
		"vendor_sell_price": 50,
		"production_building_type": "herb_garden",
		"production_required_level": 5,
		"is_stackable": true,
		"max_stack": 500
	},
	
	"material_dragon_blood": {
		"id": "material_dragon_blood",
		"name": "Ejderhain Kanı",
		"description": "Efsanevi gücü olan sıvı. En güçlü potion ve runeler gereklidir.",
		"icon": "res://assets/sprites/items/dragon_blood.png",
		"item_type": "MATERIAL",
		"material_type": "HERB",
		"rarity": "LEGENDARY",
		"base_price": 300,
		"vendor_sell_price": 150,
		"production_building_type": "herb_garden",
		"production_required_level": 10,
		"is_stackable": true,
		"max_stack": 500
	},
	
	# ======================= CRAFTED WEAPONS =======================
	"weapon_iron_sword": {
		"id": "weapon_iron_sword",
		"name": "Demir Kılıç",
		"description": "Temel demir kılıç. İyi bir başlangıç silahı.",
		"icon": "res://assets/sprites/items/iron_sword.png",
		"item_type": "WEAPON",
		"weapon_type": "SWORD",
		"rarity": "COMMON",
		"equip_slot": "WEAPON",
		"base_price": 100,
		"vendor_sell_price": 50,
		"attack": 12,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	"weapon_steel_sword": {
		"id": "weapon_steel_sword",
		"name": "Çelik Kılıç",
		"description": "Çelikten yapılmış güçlü kılıç. Daha yüksek saldırı gücü.",
		"icon": "res://assets/sprites/items/steel_sword.png",
		"item_type": "WEAPON",
		"weapon_type": "SWORD",
		"rarity": "RARE",
		"equip_slot": "WEAPON",
		"base_price": 400,
		"vendor_sell_price": 200,
		"attack": 25,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	"weapon_legendary_sword": {
		"id": "weapon_legendary_sword",
		"name": "Efsanevi Kılıç",
		"description": "Eski zamanlardan kalma efsanevi kılıç. Muazzam gücü vardır.",
		"icon": "res://assets/sprites/items/legendary_sword.png",
		"item_type": "WEAPON",
		"weapon_type": "SWORD",
		"rarity": "LEGENDARY",
		"equip_slot": "WEAPON",
		"base_price": 2000,
		"vendor_sell_price": 1000,
		"attack": 50,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	# ======================= CRAFTED ARMOR =======================
	"armor_leather_armor": {
		"id": "armor_leather_armor",
		"name": "Deri Zırh",
		"description": "Hafif deri zırh. İyi hareket kabiliyeti sağlar.",
		"icon": "res://assets/sprites/items/leather_armor.png",
		"item_type": "ARMOR",
		"armor_type": "LEATHER",
		"rarity": "COMMON",
		"equip_slot": "CHEST",
		"base_price": 150,
		"vendor_sell_price": 75,
		"defense": 15,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	"armor_chain_mail": {
		"id": "armor_chain_mail",
		"name": "Zincir Zırh",
		"description": "Zincir halkalarından yapılmış zırh. Orta derecede koruma sağlar.",
		"icon": "res://assets/sprites/items/chain_mail.png",
		"item_type": "ARMOR",
		"armor_type": "CHAIN",
		"rarity": "UNCOMMON",
		"equip_slot": "CHEST",
		"base_price": 400,
		"vendor_sell_price": 200,
		"defense": 25,
		"health": 20,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	"armor_plate_armor": {
		"id": "armor_plate_armor",
		"name": "Plaka Zırh",
		"description": "Ağır plaka zırh. Maksimum koruma sağlar ama hareket yavaşlatır.",
		"icon": "res://assets/sprites/items/plate_armor.png",
		"item_type": "ARMOR",
		"armor_type": "PLATE",
		"rarity": "RARE",
		"equip_slot": "CHEST",
		"base_price": 1000,
		"vendor_sell_price": 500,
		"defense": 40,
		"health": 50,
		"can_enhance": true,
		"max_enhancement": 10,
		"is_stackable": false
	},
	
	# ======================= CRAFTED POTIONS =======================
	"potion_health": {
		"id": "potion_health",
		"name": "Sağlık İksiri",
		"description": "Can sağlığını geri yükler. 50 HP'yi tamamen iyileştirir.",
		"icon": "res://assets/sprites/items/potion_health.png",
		"item_type": "POTION",
		"potion_type": "HEALING",
		"rarity": "COMMON",
		"base_price": 50,
		"vendor_sell_price": 25,
		"health_restore": 50,
		"is_stackable": true,
		"max_stack": 50
	},
	
	"potion_mana": {
		"id": "potion_mana",
		"name": "Mana İksiri",
		"description": "Mana reservini geri yükler. Büyüler açmada yardımcı.",
		"icon": "res://assets/sprites/items/potion_mana.png",
		"item_type": "POTION",
		"potion_type": "HEALING",
		"rarity": "UNCOMMON",
		"base_price": 75,
		"vendor_sell_price": 37,
		"mana_restore": 50,
		"is_stackable": true,
		"max_stack": 50
	},
	
	"potion_stamina": {
		"id": "potion_stamina",
		"name": "Dayanıklılık İksiri",
		"description": "Çabukluk ve dayanıklılık arttırır. 1 saat etkili.",
		"icon": "res://assets/sprites/items/potion_stamina.png",
		"item_type": "POTION",
		"potion_type": "BUFF",
		"rarity": "UNCOMMON",
		"base_price": 100,
		"vendor_sell_price": 50,
		"buff_duration": 3600,
		"is_stackable": true,
		"max_stack": 30
	},
	
	# ======================= RUNES =======================
	"rune_attack_minor": {
		"id": "rune_attack_minor",
		"name": "Küçük Saldırı Rünü",
		"description": "Geliştirme başarı oranını %5 artırır.",
		"icon": "res://assets/sprites/items/rune_attack_minor.png",
		"item_type": "RUNE",
		"rarity": "UNCOMMON",
		"base_price": 200,
		"vendor_sell_price": 100,
		"rune_enhancement_type": "attack",
		"rune_success_bonus": 5.0,
		"rune_destruction_reduction": 2.0,
		"is_stackable": false
	},
	
	"rune_defense_minor": {
		"id": "rune_defense_minor",
		"name": "Küçük Savunma Rünü",
		"description": "Zırh geliştirme başarı oranını %5 artırır.",
		"icon": "res://assets/sprites/items/rune_defense_minor.png",
		"item_type": "RUNE",
		"rarity": "UNCOMMON",
		"base_price": 200,
		"vendor_sell_price": 100,
		"rune_enhancement_type": "defense",
		"rune_success_bonus": 5.0,
		"rune_destruction_reduction": 3.0,
		"is_stackable": false
	},
	
	"rune_attack_major": {
		"id": "rune_attack_major",
		"name": "Büyük Saldırı Rünü",
		"description": "Geliştirme başarı oranını %10 artırır.",
		"icon": "res://assets/sprites/items/rune_attack_major.png",
		"item_type": "RUNE",
		"rarity": "RARE",
		"base_price": 800,
		"vendor_sell_price": 400,
		"rune_enhancement_type": "attack",
		"rune_success_bonus": 10.0,
		"rune_destruction_reduction": 5.0,
		"is_stackable": false
	},
	
	"rune_defense_major": {
		"id": "rune_defense_major",
		"name": "Büyük Savunma Rünü",
		"description": "Zırh geliştirme başarı oranını %10 artırır.",
		"icon": "res://assets/sprites/items/rune_defense_major.png",
		"item_type": "RUNE",
		"rarity": "RARE",
		"base_price": 800,
		"vendor_sell_price": 400,
		"rune_enhancement_type": "defense",
		"rune_success_bonus": 10.0,
		"rune_destruction_reduction": 7.0,
		"is_stackable": false
	},
	
	"rune_legendary": {
		"id": "rune_legendary",
		"name": "Efsanevi Rüne",
		"description": "Tüm geliştirme işlemlerine %15 başarı ve %5 hasar azaltma bonus verir.",
		"icon": "res://assets/sprites/items/rune_legendary.png",
		"item_type": "RUNE",
		"rarity": "LEGENDARY",
		"base_price": 5000,
		"vendor_sell_price": 2500,
		"rune_enhancement_type": "all",
		"rune_success_bonus": 15.0,
		"rune_destruction_reduction": 10.0,
		"is_stackable": false
	},
	
	# ======================= GEMS =======================
	"gem_ruby": {
		"id": "gem_ruby",
		"name": "Yakut",
		"description": "Kırmızı taş. Saldırı gücü +10 verir.",
		"icon": "res://assets/sprites/items/gem_ruby.png",
		"item_type": "MATERIAL",
		"material_type": "GEM",
		"rarity": "RARE",
		"equip_slot": "ACCESSORY",
		"base_price": 300,
		"vendor_sell_price": 150,
		"attack": 10,
		"is_stackable": false
	},
	
	"gem_sapphire": {
		"id": "gem_sapphire",
		"name": "Safir",
		"description": "Mavi taş. Savunma +15 verir.",
		"icon": "res://assets/sprites/items/gem_sapphire.png",
		"item_type": "MATERIAL",
		"material_type": "GEM",
		"rarity": "EPIC",
		"equip_slot": "ACCESSORY",
		"base_price": 600,
		"vendor_sell_price": 300,
		"defense": 15,
		"is_stackable": false
	},
	
	"gem_emerald": {
		"id": "gem_emerald",
		"name": "Zümrüt",
		"description": "Yeşil taş. Can sağlığı +50 verir.",
		"icon": "res://assets/sprites/items/gem_emerald.png",
		"item_type": "MATERIAL",
		"material_type": "GEM",
		"rarity": "LEGENDARY",
		"equip_slot": "ACCESSORY",
		"base_price": 1500,
		"vendor_sell_price": 750,
		"health": 50,
		"is_stackable": false
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

## Get all scrolls
static func get_scrolls() -> Array:
	return get_items_by_type("SCROLL")

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