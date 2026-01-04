extends Control
## Crafting Screen - Production System
## İksir, ekipman, malzeme üretim ekranı

@onready var recipe_list: VBoxContainer = %RecipeList
@onready var recipe_name: Label = %RecipeName
@onready var materials_list: VBoxContainer = %MaterialsList
@onready var product_info: Label = %ProductInfo
@onready var time_label: Label = %TimeLabel
@onready var quantity_label: Label = %QuantityLabel
@onready var craft_button: Button = $MarginContainer/VBox/RecipePanel/VBox/CraftButton
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

# Category buttons
@onready var alchemy_button: Button = $MarginContainer/VBox/CategoryTabs/AlchemyButton
@onready var blacksmith_button: Button = $MarginContainer/VBox/CategoryTabs/BlacksmithButton
@onready var woodwork_button: Button = $MarginContainer/VBox/CategoryTabs/WoodworkButton
@onready var leatherwork_button: Button = $MarginContainer/VBox/CategoryTabs/LeatherworkButton

# Quantity buttons
@onready var decrease_button: Button = $MarginContainer/VBox/RecipePanel/VBox/QuantityHBox/DecreaseButton
@onready var increase_button: Button = $MarginContainer/VBox/RecipePanel/VBox/QuantityHBox/IncreaseButton

var current_category: String = "alchemy"
var recipes: Array[Dictionary] = []
var selected_recipe: Dictionary = {}
var craft_quantity: int = 1
var is_loading: bool = false

func _ready() -> void:
	# Connect buttons
	alchemy_button.pressed.connect(func(): _change_category("alchemy"))
	blacksmith_button.pressed.connect(func(): _change_category("blacksmith"))
	woodwork_button.pressed.connect(func(): _change_category("woodwork"))
	leatherwork_button.pressed.connect(func(): _change_category("leatherwork"))
	
	decrease_button.pressed.connect(_decrease_quantity)
	increase_button.pressed.connect(_increase_quantity)
	craft_button.pressed.connect(_on_craft_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Load initial category
	_load_recipes()
	
	print("[CraftingScreen] Ready")

func _change_category(category: String) -> void:
	if current_category == category:
		return
	
	current_category = category
	_update_category_buttons()
	_load_recipes()

func _update_category_buttons() -> void:
	alchemy_button.disabled = current_category == "alchemy"
	blacksmith_button.disabled = current_category == "blacksmith"
	woodwork_button.disabled = current_category == "woodwork"
	leatherwork_button.disabled = current_category == "leatherwork"

func _load_recipes() -> void:
	if is_loading:
		return
	
	is_loading = true
	_clear_recipe_list()
	
	var result = await Network.http_get("/v1/crafting/recipes?category=" + current_category)
	is_loading = false
	
	if result.success:
		recipes = result.data.get("recipes", [])
		_populate_recipe_list()
	else:
		_show_error("Tarifler yüklenemedi")

func _clear_recipe_list() -> void:
	for child in recipe_list.get_children():
		child.queue_free()

func _populate_recipe_list() -> void:
	for recipe in recipes:
		var recipe_button = Button.new()
		recipe_button.custom_minimum_size = Vector2(0, 80)
		recipe_button.text = "%s\n%s" % [
			recipe.get("name", "Bilinmeyen"),
			_format_time(recipe.get("duration_seconds", 0))
		]
		recipe_button.theme_override_font_sizes["font_size"] = 20
		recipe_button.pressed.connect(func(): _select_recipe(recipe))
		
		# Color code by rarity
		var rarity = recipe.get("rarity", "common")
		match rarity:
			"uncommon":
				recipe_button.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
			"rare":
				recipe_button.add_theme_color_override("font_color", Color(0.5, 0.5, 1))
			"epic":
				recipe_button.add_theme_color_override("font_color", Color(0.7, 0.5, 1))
			"legendary":
				recipe_button.add_theme_color_override("font_color", Color(1, 0.5, 0))
		
		recipe_list.add_child(recipe_button)

func _select_recipe(recipe: Dictionary) -> void:
	selected_recipe = recipe
	craft_quantity = 1
	_update_recipe_display()

func _update_recipe_display() -> void:
	if selected_recipe.is_empty():
		recipe_name.text = "Tarif Seçiniz"
		craft_button.disabled = true
		return
	
	recipe_name.text = selected_recipe.get("name", "Bilinmeyen")
	
	# Update materials
	_clear_materials_list()
	var materials = selected_recipe.get("materials", [])
	var can_craft = true
	
	for mat_data in materials:
		var label = Label.new()
		var required = mat_data.get("quantity", 1) * craft_quantity
		var available = _get_material_count(mat_data.get("item_id", ""))
		var has_enough = available >= required
		
		label.text = "%s: %d/%d" % [
			mat_data.get("name", "???"),
			available,
			required
		]
		label.theme_override_font_sizes["font_size"] = 20
		
		if has_enough:
			label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		else:
			label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
			can_craft = false
		
		materials_list.add_child(label)
	
	# Update product info
	var product_quantity = selected_recipe.get("product_quantity", 1) * craft_quantity
	var duration = selected_recipe.get("duration_seconds", 0) * craft_quantity
	
	product_info.text = "Miktar: %dx\nSüre: %s" % [
		product_quantity,
		_format_time(duration)
	]
	
	time_label.text = "Üretim Süresi: %s" % _format_time(duration)
	quantity_label.text = str(craft_quantity)
	
	# Enable/disable craft button
	craft_button.disabled = not can_craft

func _clear_materials_list() -> void:
	for child in materials_list.get_children():
		child.queue_free()

func _get_material_count(item_id: String) -> int:
	# Get from inventory
	var inventory = State.get_inventory()
	for item in inventory:
		if item.get("id") == item_id:
			return item.get("quantity", 0)
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
	if is_loading or selected_recipe.is_empty():
		return
	
	is_loading = true
	craft_button.disabled = true
	
	var data = {
		"recipe_id": selected_recipe.get("id"),
		"quantity": craft_quantity
	}
	
	var result = await Network.http_post("/v1/crafting/start", data)
	is_loading = false
	craft_button.disabled = false
	
	if result.success:
		_show_success("Üretim başlatıldı!")
		_load_recipes()
	else:
		_show_error(result.get("error", "Üretim başlatılamazdı"))

func _format_time(seconds: int) -> String:
	if seconds < 60:
		return "%d saniye" % seconds
	elif seconds < 3600:
		return "%d dakika" % (seconds / 60)
	else:
		return "%.1f saat" % (seconds / 3600.0)

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
