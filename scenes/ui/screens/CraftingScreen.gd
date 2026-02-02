extends Control
## CraftingScreen.gd - Facilities-Based Production System
## Tarifler → Tesisler entegrasyonu

# Node References (assigned in _ready)
var recipe_list: VBoxContainer
var recipe_name: Label
var materials_list: VBoxContainer
var product_info: Label
var time_label: Label
var quantity_label: Label
var craft_button: Button
var back_button: Button
var facility_tabs: HBoxContainer
var decrease_button: Button
var increase_button: Button
var facility_buttons: Dictionary = {}

# State
var current_facility_type: String = ""
var current_facility_id: String = ""
var recipes: Array[Dictionary] = []
var selected_recipe: Dictionary = {}
var craft_quantity: int = 1
var is_loading: bool = false

# Facility categories mapping
const FACILITY_ORDER = [
	"blacksmith", "armorer", "alchemy_lab", "runesmith", "scroll_library", "gem_cutter",
	"enhancement_master", "master_alchemist", "master_armorer"
]

func _ready() -> void:
	print("[CraftingScreen] _ready started")
	
	# Manually find nodes to ensure they exist/debug failures
	recipe_list = find_child("RecipeList", true, false)
	recipe_name = find_child("RecipeName", true, false)
	materials_list = find_child("MaterialsList", true, false)
	product_info = find_child("ProductInfo", true, false)
	time_label = find_child("TimeLabel", true, false)
	quantity_label = find_child("QuantityLabel", true, false)
	
	craft_button = find_child("CraftButton", true, false)
	back_button = find_child("BackButton", true, false)
	
	facility_tabs = find_child("CategoryTabs", true, false)
	
	decrease_button = find_child("DecreaseButton", true, false)
	increase_button = find_child("IncreaseButton", true, false)
	
	# Connect buttons Safely
	if decrease_button:
		decrease_button.pressed.connect(_decrease_quantity)
	else:
		print("[CraftingScreen] CRITICAL ERROR: DecreaseButton node not found!")

	if increase_button:
		increase_button.pressed.connect(_increase_quantity)
	else:
		print("[CraftingScreen] CRITICAL ERROR: IncreaseButton node not found!")

	if craft_button:
		craft_button.pressed.connect(_on_craft_button_pressed)
	else:
		print("[CraftingScreen] CRITICAL ERROR: CraftButton node not found! (Check scene file unique names or hierarchy)")

	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	else:
		print("[CraftingScreen] CRITICAL ERROR: BackButton node not found!")
	
	if not facility_tabs:
		print("[CraftingScreen] CRITICAL ERROR: CategoryTabs node not found!")

	# Setup facility buttons
	_setup_facility_tabs()
	
	# Connect to FacilityManager
	FacilityManager.facilities_updated.connect(_on_facilities_updated)
	
	# Load initial facility
	_refresh_facilities()
	
	print("[CraftingScreen] Ready with facilities integration (v2 - font fix)")

# ==================== FACILITY SETUP ====================

func _setup_facility_tabs() -> void:
	# Clear existing tabs
	for child in facility_tabs.get_children():
		child.queue_free()
	
	facility_buttons.clear()
	
	# Create buttons for production facilities only
	for facility_type in FACILITY_ORDER:
		var config = FacilityManager.FACILITIES_CONFIG.get(facility_type, {})
		if config.is_empty():
			continue
		
		var btn = Button.new()
		btn.text = config.get("name", facility_type)
		btn.custom_minimum_size = Vector2(100, 40)
		btn.pressed.connect(_on_facility_tab_pressed.bindv([facility_type]))
		
		facility_tabs.add_child(btn)
		facility_buttons[facility_type] = btn

func _on_facility_tab_pressed(facility_type: String) -> void:
	var facility = FacilityManager.get_facility_by_type(facility_type)
	
	if facility.is_empty():
		_show_error("Bu tesiyi önce açmanız gerekir!")
		return
	
	current_facility_type = facility_type
	current_facility_id = facility.get("id", "")
	_update_facility_tabs()
	_load_recipes_for_facility()

func _update_facility_tabs() -> void:
	for facility_type in facility_buttons.keys():
		var btn = facility_buttons[facility_type]
		var facility = FacilityManager.get_facility_by_type(facility_type)
		
		# Active tab highlight
		btn.disabled = (facility_type == current_facility_type)
		
		# Disabled if not unlocked
		if facility.is_empty():
			btn.modulate = Color.GRAY
		else:
			btn.modulate = Color.WHITE

func _on_facilities_updated() -> void:
	_update_facility_tabs()

func _refresh_facilities() -> void:
	var result = await FacilityManager.fetch_my_facilities()
	
	if result.get("success", false) and result.get("data", []).size() > 0:
		# Select first production facility
		for facility_type in FACILITY_ORDER:
			var facility = FacilityManager.get_facility_by_type(facility_type)
			if not facility.is_empty():
				current_facility_type = facility_type
				current_facility_id = facility.get("id", "")
				break
		
		_update_facility_tabs()
		_load_recipes_for_facility()
	else:
		_show_error("Henüz hiç tesis açılmamış!")

# ==================== RECIPE LOADING ====================

func _load_recipes_for_facility() -> void:
	if is_loading or current_facility_type.is_empty():
		return
	
	is_loading = true
	_clear_recipe_list()
	
	if recipe_name:
		recipe_name.text = "Tarifler yükleniyor..."
	else:
		print("[CraftingScreen] ERROR: recipe_name node is null!")
		return
	
	var result = await FacilityManager.fetch_recipes_for_facility(current_facility_type)
	is_loading = false
	
	if result.get("success", false):
		var data = result.get("data", [])
		print("[CraftingScreen] Recipe data for %s: type=%s, size=%s" % [current_facility_type, typeof(data), "N/A" if not data is Array else data.size()])
		
		if data is Array:
			recipes.clear()
			for item in data:
				if item is Dictionary:
					# Validate recipe has required fields
					if item.has("id") and item.has("output_item_id"):
						recipes.append(item)
					else:
						print("[CraftingScreen] Skipping invalid recipe: %s" % item.get("id", "unknown"))
				else:
					print("[CraftingScreen] Recipe item not a dictionary: %s" % typeof(item))
			
			if recipes.size() > 0:
				print("[CraftingScreen] Populated %d valid recipes" % recipes.size())
				_populate_recipe_list()
				# Auto-select first recipe
				_select_recipe(recipes[0])
			else:
				print("[CraftingScreen] No valid recipes found for %s" % current_facility_type)
				if recipe_name:
					recipe_name.text = "Tarif bulunamadı"
		else:
			print("[CraftingScreen] Data is not an array: %s" % typeof(data))
			if recipe_name:
				recipe_name.text = "Veri hatası"
	else:
		var error_msg = result.get("error", "Unknown error")
		print("[CraftingScreen] Recipe fetch failed: %s" % error_msg)
		_show_error("Tarifler yüklenemedi: %s" % error_msg)
		if recipe_name:
			recipe_name.text = "Hata!"

func _load_recipes() -> void:
	_load_recipes_for_facility()

func _clear_recipe_list() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

func _populate_recipe_list() -> void:
	if recipes.size() == 0:
		print("[CraftingScreen] No recipes to populate")
		return
	
	print("[CraftingScreen] Populating %d recipes" % recipes.size())
	
	for recipe in recipes:
		if not recipe is Dictionary:
			print("[CraftingScreen] Skipping non-dict recipe: %s" % typeof(recipe))
			continue
		
		# Validate required fields
		var recipe_id = recipe.get("id", "")
		if recipe_id.is_empty():
			print("[CraftingScreen] Skipping recipe with no id")
			continue
		
		var recipe_button = Button.new()
		recipe_button.custom_minimum_size = Vector2(0, 80)
		
		# Use recipe ID as display name (e.g., "recipe_forge_iron_sword" -> "Forge Iron Sword")
		var display_name = str(recipe_id).replace("recipe_", "").replace("_", " ").capitalize()
		var duration_raw = recipe.get("duration_seconds", 0)
		var duration = int(duration_raw) if duration_raw else 0
		
		recipe_button.text = "%s\n%s" % [
			display_name,
			_format_time(duration)
		]
		recipe_button.pressed.connect(func(): _select_recipe(recipe))
		
		# Color code by success rate (higher = better)
		var success_rate = recipe.get("success_rate", 50)
		if success_rate is String:
			success_rate = int(success_rate)
		
		if success_rate >= 90:
			recipe_button.add_theme_color_override("font_color", Color(0.5, 1, 0.5))  # Green for high success
		elif success_rate >= 75:
			recipe_button.add_theme_color_override("font_color", Color(0.5, 0.5, 1))  # Blue for good
		elif success_rate >= 50:
			recipe_button.add_theme_color_override("font_color", Color(1, 1, 0.5))  # Yellow for medium
		else:
			recipe_button.add_theme_color_override("font_color", Color(1, 0.5, 0.5))  # Red for low
		
		recipe_list.add_child(recipe_button)
		print("[CraftingScreen] Added recipe button: %s (success_rate=%d)" % [recipe_id, success_rate])

func _select_recipe(recipe: Dictionary) -> void:
	selected_recipe = recipe
	craft_quantity = 1
	_update_recipe_display()

func _update_recipe_display() -> void:
	if selected_recipe.is_empty():
		if recipe_name:
			recipe_name.text = "Tarif Seçiniz"
		if craft_button:
			craft_button.disabled = true
		return
	
	# Type check
	if not selected_recipe is Dictionary:
		print("[CraftingScreen] ERROR: selected_recipe is not a Dictionary: %s" % typeof(selected_recipe))
		if recipe_name:
			recipe_name.text = "Veri Hatası"
		if craft_button:
			craft_button.disabled = true
		return
	
	# Use recipe ID as display name
	var recipe_id = selected_recipe.get("id", "Bilinmeyen")
	var display_name = str(recipe_id).replace("recipe_", "").replace("_", " ").capitalize()
	if recipe_name:
		recipe_name.text = display_name
	print("[CraftingScreen] Displaying recipe: %s" % recipe_id)
	
	# Update materials from input_materials field
	_clear_materials_list()
	var input_materials = selected_recipe.get("input_materials", {})
	var can_craft = true
	
	print("[CraftingScreen] input_materials type: %s, is_dict: %s, size: %s" % [
		typeof(input_materials),
		input_materials is Dictionary,
		"?" if not input_materials is Dictionary else input_materials.size()
	])
	
	if input_materials is Dictionary and input_materials.size() > 0:
		for item_id in input_materials.keys():
			var quantity_value = input_materials[item_id]
			var required = int(quantity_value) * craft_quantity
			var available = _get_material_count(item_id)
			var has_enough = available >= required
			
			var label = Label.new()
			label.text = "%s: %d/%d" % [
				str(item_id).replace("_", " ").capitalize(),
				available,
				required
			]
			
			if has_enough:
				label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			else:
				label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
				can_craft = false
			
			materials_list.add_child(label)
			print("[CraftingScreen] Added material: %s (%d/%d)" % [item_id, available, required])
	else:
		# No input materials required - free recipe
		var label = Label.new()
		label.text = "Malzeme Gerekmiyor"
		label.add_theme_color_override("font_color", Color(1, 1, 0.5))
		materials_list.add_child(label)
	
	# Update product info from output_item_id and output_quantity
	var output_item = selected_recipe.get("output_item_id", "Unknown")
	var output_qty_raw = selected_recipe.get("output_quantity", 1)
	var duration_raw = selected_recipe.get("duration_seconds", 0)
	
	var output_qty = int(output_qty_raw) * craft_quantity
	var duration = int(duration_raw) * craft_quantity
	
	product_info.text = "Çıktı: %s\nMiktar: %dx\nSüre: %s" % [
		str(output_item).replace("_", " ").capitalize(),
		output_qty,
		_format_time(duration)
	]
	
	time_label.text = "Üretim Süresi: %s" % _format_time(duration)
	quantity_label.text = str(craft_quantity)
	
	# Enable/disable craft button
	craft_button.disabled = not can_craft
	print("[CraftingScreen] Recipe display updated: %s, can_craft=%s" % [recipe_id, can_craft])

func _clear_materials_list() -> void:
	for child in materials_list.get_children():
		child.queue_free()

func _get_material_count(item_id: String) -> int:
	# Get from inventory
	var inventory = State.get_inventory_items()
	
	if not inventory is Array:
		print("[CraftingScreen] ERROR: Inventory is not an Array: %s" % typeof(inventory))
		return 0
	
	for item in inventory:
		if not item is Dictionary:
			print("[CraftingScreen] WARNING: Inventory item is not a Dictionary: %s" % typeof(item))
			continue
		
		if item.get("id") == item_id:
			var qty = item.get("quantity", 0)
			if qty is int:
				return qty
			else:
				return int(qty)
	
	return 0

func _decrease_quantity() -> void:
	if craft_quantity > 1:
		craft_quantity -= 1
		_update_recipe_display()

func _increase_quantity() -> void:
	if craft_quantity < 100:
		craft_quantity += 1
		_update_recipe_display()

func _on_craft_button_pressed() -> void:
	if is_loading or selected_recipe.is_empty() or current_facility_id.is_empty():
		print("[CraftingScreen] Craft button blocked: loading=%s, recipe_empty=%s, facility_empty=%s" % [
			is_loading, selected_recipe.is_empty(), current_facility_id.is_empty()
		])
		return
	
	# Validate recipe has required fields
	var recipe_id = selected_recipe.get("id", "")
	if recipe_id.is_empty():
		print("[CraftingScreen] ERROR: Selected recipe has no 'id' field")
		_show_error("Tarif bilgisi eksik!")
		return
	
	is_loading = true
	craft_button.disabled = true
	
	print("[CraftingScreen] Starting production for recipe=%s, facility=%s, quantity=%d" % [
		recipe_id, current_facility_type, craft_quantity
	])
	
	# Call FacilityManager to start production
	var result = await FacilityManager.start_production(
		current_facility_type,
		recipe_id,
		craft_quantity
	)
	
	is_loading = false
	craft_button.disabled = false
	
	if result.get("success", false):
		_show_success("Üretim başlatıldı!")
		await get_tree().create_timer(1.0).timeout
		# Refresh to show new queue item
		selected_recipe = {}
		_load_recipes_for_facility()
	else:
		_show_error(result.get("error", "Üretim başlatılamazdı"))

func _format_time(seconds) -> String:
	var sec = seconds if seconds is int else int(seconds)
	if sec < 0:
		sec = 0
	
	if sec < 60:
		return "%d saniye" % sec
	elif sec < 3600:
		return "%d dakika" % (sec / 60)
	else:
		return "%.1f saat" % (float(sec) / 3600.0)

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()

func _show_error(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Hata",
			"message": message
		})

func _show_success(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/InfoDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Başarılı",
			"message": message
		})
