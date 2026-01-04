extends Control
## Inventory Screen
## Displays and manages player inventory

@onready var inventory_grid: GridContainer = $VBoxContainer/ScrollContainer/InventoryGrid
@onready var filter_buttons: HBoxContainer = $VBoxContainer/FilterBar
@onready var sort_button: Button = $VBoxContainer/TopBar/SortButton
@onready var capacity_label: Label = $VBoxContainer/TopBar/CapacityLabel

# Filters
@onready var all_filter: Button = $VBoxContainer/FilterBar/AllButton
@onready var weapon_filter: Button = $VBoxContainer/FilterBar/WeaponButton
@onready var armor_filter: Button = $VBoxContainer/FilterBar/ArmorButton
@onready var potion_filter: Button = $VBoxContainer/FilterBar/PotionButton
@onready var material_filter: Button = $VBoxContainer/FilterBar/MaterialButton

var current_filter: int = -1  # -1 = all
var current_sort: String = "name"  # name, rarity, type

var item_card_scene = preload("res://scenes/ui/components/ItemCard.tscn")

func _ready() -> void:
	# Connect signals
	State.inventory_updated.connect(_refresh_inventory)
	
	# Connect filter buttons
	all_filter.pressed.connect(func(): _set_filter(-1))
	weapon_filter.pressed.connect(func(): _set_filter(ItemData.ItemType.WEAPON))
	armor_filter.pressed.connect(func(): _set_filter(ItemData.ItemType.ARMOR))
	potion_filter.pressed.connect(func(): _set_filter(ItemData.ItemType.POTION))
	material_filter.pressed.connect(func(): _set_filter(ItemData.ItemType.MATERIAL))
	
	# Connect sort button
	sort_button.pressed.connect(_cycle_sort)
	
	# Initial load
	_refresh_inventory()

func _refresh_inventory() -> void:
	# Clear grid
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Get items
	var items = State.get_inventory_items()
	
	# Filter
	if current_filter >= 0:
		items = items.filter(func(item): return item.get("item_type", 0) == current_filter)
	
	# Sort
	match current_sort:
		"name":
			items.sort_custom(func(a, b): return a.get("name", "") < b.get("name", ""))
		"rarity":
			items.sort_custom(func(a, b): return a.get("rarity", 0) > b.get("rarity", 0))
		"type":
			items.sort_custom(func(a, b): return a.get("item_type", 0) < b.get("item_type", 0))
	
	# Create cards
	for item in items:
		var card = item_card_scene.instantiate()
		inventory_grid.add_child(card)
		card.setup(item)
		if card.has_signal("item_selected"):
			card.item_selected.connect(_on_item_selected)
		if card.has_signal("item_long_pressed"):
			card.item_long_pressed.connect(_on_item_long_pressed)
	
	# Update capacity
	_update_capacity(items.size())

func _update_capacity(used: int) -> void:
	var max_capacity = State.player.get("max_inventory_slots", 50)
	capacity_label.text = "%d / %d" % [used, max_capacity]
	
	# Color warning
	if used >= max_capacity * 0.9:
		capacity_label.add_theme_color_override("font_color", Color.RED)
	elif used >= max_capacity * 0.7:
		capacity_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		capacity_label.remove_theme_color_override("font_color")

func _set_filter(filter_type: int) -> void:
	current_filter = filter_type
	_refresh_inventory()
	
	# Update button states
	_update_filter_buttons()

func _update_filter_buttons() -> void:
	all_filter.button_pressed = current_filter == -1
	weapon_filter.button_pressed = current_filter == ItemData.ItemType.WEAPON
	armor_filter.button_pressed = current_filter == ItemData.ItemType.ARMOR
	potion_filter.button_pressed = current_filter == ItemData.ItemType.POTION
	material_filter.button_pressed = current_filter == ItemData.ItemType.MATERIAL

func _cycle_sort() -> void:
	match current_sort:
		"name":
			current_sort = "rarity"
			sort_button.text = "Sıralama: Nadir"
		"rarity":
			current_sort = "type"
			sort_button.text = "Sıralama: Tür"
		"type":
			current_sort = "name"
			sort_button.text = "Sıralama: İsim"
	
	_refresh_inventory()

func _on_item_selected(item: Dictionary) -> void:
	# Show item actions menu
	_show_item_menu(item)

func _on_item_long_pressed(item: Dictionary) -> void:
	# Show detailed info
	var item_card = item_card_scene.instantiate()
	add_child(item_card)
	item_card.setup(item)
	if item_card.has_method("show_details"):
		item_card.show_details()
	item_card.queue_free()

func _show_item_menu(item: Dictionary) -> void:
	# Create action menu
	var menu = PopupMenu.new()
	add_child(menu)
	
	var item_type = item.get("item_type", 0)
	
	# Add actions based on item type
	if item_type == ItemData.ItemType.WEAPON or item_type == ItemData.ItemType.ARMOR:
		menu.add_item("Kuşan", 0)
		menu.add_item("Geliştir", 1)
		menu.add_item("Sat", 2)
	elif item_type == ItemData.ItemType.POTION:
		menu.add_item("Kullan", 0)
		menu.add_item("Sat", 2)
	else:
		menu.add_item("Sat", 2)
	
	menu.add_separator()
	menu.add_item("İptal", 99)
	
	# Connect
	menu.id_pressed.connect(func(id): _on_item_action(id, item))
	
	# Show at mouse position
	menu.popup(Rect2(get_global_mouse_position(), Vector2(200, 100)))

func _on_item_action(action_id: int, item: Dictionary) -> void:
	var item_type = item.get("item_type", 0)
	match action_id:
		0:  # Use/Equip
			if item_type == ItemData.ItemType.POTION:
				_use_potion(item)
			else:
				_equip_item(item)
		
		1:  # Enhance
			_enhance_item(item)
		
		2:  # Sell
			_sell_item(item)
		
		99:  # Cancel
			pass

func _use_potion(item: Dictionary) -> void:
	# Show potion dialog
	var dialog_scene = load("res://scenes/ui/dialogs/PotionUseDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"item": item
		})

func _equip_item(item: Dictionary) -> void:
	# TODO: Implement equipment system
	print("[Inventory] Equip item: ", item.get("name", "Unknown"))

func _enhance_item(_item: Dictionary) -> void:
	# Navigate to anvil/enhancement screen
	print("[Inventory] Navigate to enhancement")

func _sell_item(item: Dictionary) -> void:
	# Show confirm dialog
	var dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
	if dialog_scene:
		var sell_price = int(item.get("price", 0) * 0.7)  # 70% of original price
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Eşya Sat",
			"message": "%s'i %s altına satmak istiyor musun?" % [item.get("name", "Eşya"), MathUtils.format_number(sell_price)],
			"confirm_text": "Sat",
			"on_confirm": func(): _confirm_sell(item)
		})

func _confirm_sell(item: Dictionary) -> void:
	# Call API to sell (non-blocking)
	Network.post("/api/v1/inventory/sell", {
		"item_instance_id": item.get("instance_id", ""),
		"quantity": 1
	}, func(result: Dictionary) -> void:
		if result.success:
			# Update state
			State.remove_item(item.get("instance_id", ""))
			State.add_gold(result.data.gold_received)
			
			# Show success
			var dialog_scene = load("res://scenes/ui/dialogs/InfoDialog.tscn")
			if dialog_scene:
				get_tree().root.get_node("Main").show_dialog(dialog_scene, {
					"title": "Satış Başarılı",
					"message": "%s satıldı! +%s altın" % [item.get("name", "Eşya"), MathUtils.format_number(result.data.gold_received)]
				})
		else:
			# Show error
			var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
			if dialog_scene:
				get_tree().root.get_node("Main").show_dialog(dialog_scene, {
					"message": result.error or "Satış başarısız"
				})
	)
