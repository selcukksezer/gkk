## ItemSystemTest.gd - Test script for item system functionality
## Run this to verify ItemData and ItemDatabase work correctly

extends Node

func _ready():
	print("=== ITEM SYSTEM TEST ===")
	test_basic_item_creation()
	test_weapon_subtypes()
	test_recipe_system()
	test_rune_system()
	test_database_queries()
	print("=== TEST COMPLETE ===")

func test_basic_item_creation():
	print("\n--- Testing Basic Item Creation ---")
	
	# Create a basic sword
	var sword_data = {
		"id": "test_sword",
		"name": "Test Sword",
		"description": "A test sword",
		"item_type": "WEAPON",
		"weapon_type": "SWORD",
		"rarity": "COMMON",
		"equip_slot": "WEAPON",
		"attack": 25,
		"defense": 5,
		"can_enhance": true,
		"required_level": 5
	}
	
	var sword = ItemData.from_dict(sword_data)
	print("Created sword: %s" % sword.name)
	print("Attack: %d, Defense: %d" % [sword.attack, sword.defense])
	print("Can equip at level 3: %s" % sword.can_equip(3))
	print("Can equip at level 5: %s" % sword.can_equip(5))

func test_weapon_subtypes():
	print("\n--- Testing Weapon Subtypes ---")
	
	var weapons = [
		{"type": "SWORD", "name": "Sword"},
		{"type": "BOW", "name": "Bow"},
		{"type": "SPEAR", "name": "Spear"},
		{"type": "AXE", "name": "Axe"}
	]
	
	for weapon in weapons:
		var data = {
			"id": "weapon_%s" % weapon.type.to_lower(),
			"name": weapon.name,
			"item_type": "WEAPON",
			"weapon_type": weapon.type,
			"rarity": "COMMON",
			"equip_slot": "WEAPON",
			"attack": 20
		}
		var item = ItemData.from_dict(data)
		print("%s: %s (is_weapon: %s)" % [weapon.name, item.get_category_display_name(), item.is_weapon()])

func test_recipe_system():
	print("\n--- Testing Recipe System ---")
	
	var recipe_data = {
		"id": "recipe_test",
		"name": "Test Recipe",
		"item_type": "RECIPE",
		"recipe_result_item_id": "weapon_sword_basic",
		"recipe_requirements": {
			"material_iron_ore": 3,
			"material_wood": 1
		},
		"recipe_building_type": "blacksmith",
		"recipe_production_time": 300,
		"recipe_required_level": 2
	}
	
	var recipe = ItemData.from_dict(recipe_data)
	print("Recipe: %s" % recipe.name)
	print("Requirements: %s" % recipe.get_recipe_display_requirements())
	print("Building: %s, Time: %d seconds" % [recipe.recipe_building_type, recipe.recipe_production_time])
	
	# Test inventory check
	var inventory = {"material_iron_ore": 5, "material_wood": 2}
	print("Can craft with inventory: %s" % recipe.can_craft_with_inventory(inventory))

func test_rune_system():
	print("\n--- Testing Rune System ---")
	
	var rune_data = {
		"id": "rune_attack",
		"name": "Attack Rune",
		"item_type": "RUNE",
		"rune_enhancement_type": "attack",
		"rune_success_bonus": 10.0,
		"rune_destruction_reduction": 5.0
	}
	
	var rune = ItemData.from_dict(rune_data)
	print("Rune: %s" % rune.name)
	print("Success modifier: %.2f" % rune.get_rune_success_modifier())
	print("Destruction modifier: %.2f" % rune.get_rune_destruction_modifier())
	
	# Test rune application
	var sword_data = {
		"id": "sword",
		"item_type": "WEAPON",
		"weapon_type": "SWORD",
		"attack": 25,
		"can_enhance": true
	}
	var sword = ItemData.from_dict(sword_data)
	print("Can apply rune to sword: %s" % rune.can_apply_to_item(sword))

func test_database_queries():
	print("\n--- Testing Database Queries ---")
	
	# Test database item creation
	var sword = ItemDatabase.create_item("weapon_sword_basic")
	if sword:
		print("Created from database: %s" % sword.name)
		print("Attack: %d, Rarity: %s" % [sword.attack, sword.get_rarity_color()])
	else:
		print("Failed to create item from database")
	
	# Test queries
	print("Weapons count: %d" % ItemDatabase.get_weapons().size())
	print("Armor count: %d" % ItemDatabase.get_armor().size())
	print("Potions count: %d" % ItemDatabase.get_potions().size())
	print("Materials count: %d" % ItemDatabase.get_materials().size())
	
	# Test random item
	var random_rare = ItemDatabase.get_random_item_by_rarity("RARE")
	if not random_rare.is_empty():
		print("Random rare item: %s" % random_rare.get("name", "Unknown"))
	
	# Test item value
	var value = ItemDatabase.get_item_value("weapon_sword_basic")
	print("Sword value: %d gold" % value)