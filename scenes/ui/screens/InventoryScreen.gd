extends Control
## InventoryScreen.gd - Player inventory management UI (Vertical List Redesign)

signal item_selected(item: ItemData)
signal item_equipped(item: ItemData, slot: String)
signal item_unequipped(slot: String)
signal item_used(item: ItemData)

const InventoryManager = preload("res://autoload/InventoryManager.gd")
const SLOT_SCENE = preload("res://scenes/prefabs/ItemSlot.tscn")
const GRID_COLUMNS = 5  # 5 slot yan yana

# Node references (using %UniqueName where possible for better resilience)
@onready var equipped_container: HBoxContainer = %EquippedContainer
@onready var inventory_grid: GridContainer = %InventoryGrid
@onready var filter_bar: HBoxContainer = %FilterBar
@onready var trash_slot_container: Control = %TrashSlotContainer

# Details Panel
@onready var item_details_panel: PanelContainer = %ItemDetailsPanel
@onready var item_name_label: Label = %ItemNameLabel
@onready var item_description_label: Label = %ItemDescriptionLabel
@onready var item_stats_label: Label = %ItemStatsLabel
@onready var use_button: Button = %UseButton
@onready var equip_button: Button = %EquipButton
@onready var sell_button: Button = %SellButton
@onready var delete_button: Button = %DeleteButton
@onready var close_details_button: Button = $ItemDetailsPanel/DetailsVBox/Header/CloseDetailsButton
@onready var sort_button: Button = %SortButton

var inventory_manager: InventoryManager
var selected_item: ItemData = null
var equipped_items: Dictionary = {}
var current_filter: String = "All"
var current_sort: String = "name"  # "name", "type", "rarity", "level"
var sort_ascending: bool = true
var trash_slot: Control = null

func _ready() -> void:
	print("[InventoryScreen] Ready (Grid Redesign)")
	inventory_manager = InventoryManager.new()
	
	# Setup grid columns
	if inventory_grid:
		inventory_grid.columns = GRID_COLUMNS

	# Connect signals
	if State.has_user_signal("inventory_updated"):
		if not State.is_connected("inventory_updated", Callable(self, "_on_inventory_updated")):
			State.connect("inventory_updated", Callable(self, "_on_inventory_updated"))
			print("[InventoryScreen] Connected to inventory_updated signal")
	
	var inventory_singleton = get_node_or_null("/root/Inventory")
	if inventory_singleton:
		inventory_singleton.connect("item_equipped", Callable(self, "_on_equipment_updated"))
		inventory_singleton.connect("item_unequipped", Callable(self, "_on_equipment_updated"))

	# Setup filter button signals
	for btn in filter_bar.get_children():
		if btn is Button:
			if btn.name == "AllButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("All"))
			elif btn.name == "WeaponButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("Weapons"))
			elif btn.name == "ArmorButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("Armor"))
			elif btn.name == "PotionButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("Consumables"))
			elif btn.name == "MaterialButton":
				btn.pressed.connect(_on_filter_button_pressed.bind("Materials"))

	# Detail buttons
	use_button.pressed.connect(_on_use_button_pressed)
	equip_button.pressed.connect(_on_equip_button_pressed)
	sell_button.pressed.connect(_on_sell_button_pressed)
	# Delete button removed - use drag to trash instead
	close_details_button.pressed.connect(_hide_item_details)
	
	# Sort button
	if sort_button:
		sort_button.pressed.connect(_on_sort_button_pressed)
	
	# Create trash slot
	_create_trash_slot()

	_refresh_inventory()

func _create_trash_slot() -> void:
	if not trash_slot_container:
		print("[InventoryScreen] Warning: trash_slot_container not found!")
		return
		
	trash_slot = SLOT_SCENE.instantiate()
	trash_slot_container.add_child(trash_slot)
	trash_slot.set_trash_slot()
	trash_slot.custom_minimum_size = Vector2(100, 100)
	trash_slot.name = "TrashSlot"
	
	print("[InventoryScreen] Trash slot created successfully")

func _refresh_inventory(filter_type: String = "") -> void:
	# Clean up logic
	_clear_container(inventory_grid)
	_clear_container(equipped_container)
	
	# Use stored filter if none provided
	if filter_type == "":
		filter_type = current_filter
	else:
		current_filter = filter_type

	var all_items = State.get_all_items_data()
	
	# Filter items
	var filtered_items: Array[ItemData] = []
	for item in all_items:
		if item.quantity <= 0: continue
		if _should_show_item(item, filter_type):
			filtered_items.append(item)
	
	# Sort items
	_sort_items(filtered_items)
	
	# 1. Update Equipped Slots (Horizontal Scroll)
	_create_equipped_slots()

	# 2. Update Inventory Grid (5 columns)
	for item in filtered_items:
		var slot = SLOT_SCENE.instantiate()
		inventory_grid.add_child(slot)
		slot.set_item(item)
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.item_dragged.connect(_on_item_dragged)
		slot.item_dropped.connect(_on_item_dropped)

func _clear_container(container: Node) -> void:
	if not container: return
	for child in container.get_children():
		child.queue_free()

func _create_equipped_slots() -> void:
	var equipment_slots = ["weapon", "helmet", "chest", "legs", "boots", "gloves", "ring", "amulet", "belt"]
	
	for slot_name in equipment_slots:
		var slot = SLOT_SCENE.instantiate()
		equipped_container.add_child(slot)
		
		# Override size for horizontal scroll - make them square
		slot.custom_minimum_size = Vector2(80, 80)
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		# Find if something is equipped here
		# Note: In a real implementation we would check State.player.equipment[slot_name]
		# For now, we use our local tracked dictionary or assume empty if not synced
		if equipped_items.has(slot_name):
			slot.set_item(equipped_items[slot_name])
		else:
			slot.set_equipment_slot(slot_name)
			
		slot.slot_clicked.connect(func(item): _on_equipment_slot_clicked(slot_name, item))

func _should_show_item(item: ItemData, filter: String) -> bool:
	if filter == "All" or filter == "Hepsi" or filter == "":
		return true
		
	match filter:
		"Weapons", "Silah":
			return item.is_weapon()
		"Armor", "Zırh":
			return item.is_armor()
		"Consumables", "İksir", "Potion":
			return item.is_consumable()
		"Materials", "Materyal":
			return item.is_material()
	
	return true

func _sort_items(items: Array[ItemData]) -> void:
	match current_sort:
		"name":
			items.sort_custom(func(a, b): return _compare_strings(a.name, b.name))
		"type":
			items.sort_custom(func(a, b): return _compare_strings(ItemData.ItemType.keys()[a.item_type], ItemData.ItemType.keys()[b.item_type]))
		"rarity":
			items.sort_custom(func(a, b): return a.rarity < b.rarity if sort_ascending else a.rarity > b.rarity)
		"level":
			items.sort_custom(func(a, b): return a.required_level < b.required_level if sort_ascending else a.required_level > b.required_level)
	
	if not sort_ascending and current_sort in ["name", "type"]:
		items.reverse()

func _compare_strings(a: String, b: String) -> bool:
	return a < b if sort_ascending else a > b

func _on_slot_clicked(item: ItemData) -> void:
	if not item: return
	selected_item = item
	_update_item_details(item)

func _on_equipment_slot_clicked(slot_name: String, item: ItemData) -> void:
	if item:
		selected_item = item
		_update_item_details(item)
	else:
		# Empty slot clicked
		pass

func _update_item_details(item: ItemData) -> void:
	item_details_panel.visible = true
	item_name_label.text = item.name
	item_name_label.add_theme_color_override("font_color", item.get_rarity_color())
	
	# Detailed description
	var desc_text = item.description if item.description else "Açıklama yok"
	item_description_label.text = desc_text
	
	# Detailed stats
	var stats_text = ""
	
	# Rarity and Type
	var rarity_name = ItemData.ItemRarity.keys()[item.rarity]
	var type_name = ItemData.ItemType.keys()[item.item_type]
	stats_text += "Nadirlik: %s\n" % rarity_name
	stats_text += "Tip: %s\n" % type_name
	stats_text += "Miktar: %d\n" % item.quantity
	
	# Equipment stats
	if item.is_equipment():
		stats_text += "\n[Savaş İstatistikleri]\n"
		if item.attack > 0:
			stats_text += "Saldırı: %d (+%d)\n" % [item.attack, item.get_total_attack() - item.attack]
		if item.defense > 0:
			stats_text += "Savunma: %d (+%d)\n" % [item.defense, item.get_total_defense() - item.defense]
		if item.health > 0:
			stats_text += "Can: +%d\n" % item.health
		if item.power > 0:
			stats_text += "Güç: +%d\n" % item.power
		if item.enhancement_level > 0:
			stats_text += "Geliştirme: +%d\n" % item.enhancement_level
		if item.required_level > 0:
			stats_text += "Gerekli Seviye: %d\n" % item.required_level
		if item.required_class != "":
			stats_text += "Gerekli Sınıf: %s\n" % item.required_class
		if item.equip_slot != ItemData.EquipSlot.NONE:
			var slot_name = ItemData.EquipSlot.keys()[item.equip_slot]
			stats_text += "Yer: %s\n" % slot_name
	# Consumable stats
	elif item.is_consumable():
		stats_text += "\n[Kullanım Etkileri]\n"
		if item.energy_restore > 0:
			stats_text += "Enerji: +%d\n" % item.energy_restore
		if item.heal_amount > 0:
			stats_text += "Can: +%d\n" % item.heal_amount
		if item.tolerance_increase > 0:
			stats_text += "Tolerans: +%d\n" % item.tolerance_increase
		if item.overdose_risk > 0:
			stats_text += "Aşırı Doz Riski: %.1f%%\n" % (item.overdose_risk * 100)
	# Material info
	elif item.is_material():
		stats_text += "\n[Malzeme Bilgisi]\n"
		var mat_type = ItemData.MaterialType.keys()[item.material_type] if item.material_type != ItemData.MaterialType.NONE else "Genel"
		stats_text += "Malzeme Tipi: %s\n" % mat_type
		if item.production_building_type != "":
			stats_text += "Üretim Binası: %s\n" % item.production_building_type
	
	# Economy info
	if item.base_price > 0 or item.vendor_sell_price > 0:
		stats_text += "\n[Ekonomi]\n"
		if item.base_price > 0:
			stats_text += "Taban Fiyat: %d Altın\n" % item.base_price
		if item.vendor_sell_price > 0:
			stats_text += "Satış Fiyatı: %d Altın\n" % item.vendor_sell_price
		stats_text += "Ticarete Açık: %s\n" % ("Evet" if item.is_tradeable else "Hayır")
	
	# Stacking info
	if item.is_stackable:
		stats_text += "\nYığınlanabilir: Evet (Max: %d)\n" % item.max_stack
	
	item_stats_label.text = stats_text
	
	# Button visibility
	use_button.visible = item.is_consumable()
	equip_button.visible = item.is_equipment() and not item.is_equipped if item.has_method("is_equipped") else item.is_equipment()
	sell_button.visible = item.is_tradeable
	# Delete button hidden - use drag to trash instead

func _hide_item_details() -> void:
	item_details_panel.visible = false
	selected_item = null

func _on_filter_button_pressed(filter_type: String) -> void:
	print("[InventoryScreen] Filter button pressed: ", filter_type)
	current_filter = filter_type
	
	# Update toggle button states visually
	for btn in filter_bar.get_children():
		if btn is Button:
			var should_press = false
			if filter_type == "All" or filter_type == "Hepsi":
				should_press = (btn.name == "AllButton")
			elif filter_type == "Weapons" or filter_type == "Silah":
				should_press = (btn.name == "WeaponButton")
			elif filter_type == "Armor" or filter_type == "Zırh":
				should_press = (btn.name == "ArmorButton")
			elif filter_type == "Consumables" or filter_type == "İksir":
				should_press = (btn.name == "PotionButton")
			elif filter_type == "Materials" or filter_type == "Materyal":
				should_press = (btn.name == "MaterialButton")
			
			btn.button_pressed = should_press

	_refresh_inventory(filter_type)

func _on_use_button_pressed() -> void:
	if selected_item:
		await inventory_manager.use_item(selected_item)
		_refresh_inventory() # Refresh will re-apply current filter if we stored it, simplified here to reset or keep

func _on_equip_button_pressed() -> void:
	if selected_item:
		var result = await inventory_manager.equip_item(selected_item.item_id)
		if result.success:
			_refresh_inventory()

func _on_sell_button_pressed() -> void:
	if selected_item:
		var confirm_dialog = AcceptDialog.new()
		confirm_dialog.title = "Eşya Sat"
		confirm_dialog.dialog_text = "%s'yi %d altın karşılığında satmak istediğinize emin misiniz?" % [selected_item.name, selected_item.vendor_sell_price]
		add_child(confirm_dialog)
		confirm_dialog.confirmed.connect(func():
			var result = await inventory_manager.remove_item(selected_item.item_id, 1)
			if result.success:
				if selected_item.vendor_sell_price > 0:
					State.update_gold(selected_item.vendor_sell_price, true)
				print("[InventoryScreen] Item sold, refreshing inventory")
			else:
				print("[InventoryScreen] Sell failed: ", result.get("error", "Unknown"))
				_show_error_message(result.get("error", "Satış işlemi başarısız"))
			_hide_item_details()
			_refresh_inventory()
			confirm_dialog.queue_free()
		)
		confirm_dialog.canceled.connect(func():
			confirm_dialog.queue_free()
		)
		confirm_dialog.popup_centered()

func _on_sort_button_pressed() -> void:
	# Cycle through sort options: name -> type -> rarity -> level -> name (reverse)
	var sort_options = ["name", "type", "rarity", "level"]
	var current_index = sort_options.find(current_sort)
	
	if current_index == -1:
		current_index = 0
	
	# If we're at the last option, reverse direction
	if current_index == sort_options.size() - 1:
		sort_ascending = not sort_ascending
		current_index = 0
	else:
		current_index += 1
	
	current_sort = sort_options[current_index]
	
	# Update button text
	var sort_text = ""
	match current_sort:
		"name":
			sort_text = "İsim %s" % ("↑" if sort_ascending else "↓")
		"type":
			sort_text = "Tip %s" % ("↑" if sort_ascending else "↓")
		"rarity":
			sort_text = "Nadirlik %s" % ("↑" if sort_ascending else "↓")
		"level":
			sort_text = "Seviye %s" % ("↑" if sort_ascending else "↓")
	
	if sort_button:
		sort_button.text = sort_text
	
	_refresh_inventory()

func _show_error_message(message: String) -> void:
	var error_dialog = AcceptDialog.new()
	error_dialog.title = "Hata"
	error_dialog.dialog_text = message
	error_dialog.ok_button_text = "Tamam"
	add_child(error_dialog)
	error_dialog.popup_centered()
	error_dialog.confirmed.connect(func():
		error_dialog.queue_free()
	)
	# Auto-close after 3 seconds
	await get_tree().create_timer(3.0).timeout
	if error_dialog and is_instance_valid(error_dialog):
		error_dialog.queue_free()

func _on_inventory_updated() -> void:
	_refresh_inventory()

func _on_equipment_updated() -> void:
	_refresh_inventory()

func _on_item_dragged(item: ItemData, from_slot: Control) -> void:
	print("[InventoryScreen] Item dragged: ", item.name)

func _on_item_dropped(item: ItemData, to_slot: Control) -> void:
	print("[InventoryScreen] Item dropped: ", item.name if item else "null", " to slot: ", to_slot.name if to_slot and to_slot.name else "unnamed")
	
	if not to_slot or not item:
		print("[InventoryScreen] Invalid drop - no target or no item")
		return
	
	# Check if dropped on trash slot
	if to_slot.has_method("is_trash_slot") and to_slot.is_trash_slot():
		print("[InventoryScreen] Dropped on trash slot - deleting item")
		_delete_item_with_quantity_check(item)
		return
	
	# Check if dropped on equipment slot
	if to_slot.has_method("get") and "_is_equipment_slot" in to_slot:
		if to_slot._is_equipment_slot:
			print("[InventoryScreen] Dropped on equipment slot - equipping")
			_equip_item_to_slot(item, to_slot._slot_name)
			return
	
	# Dropped on another inventory slot - could implement swapping here
	print("[InventoryScreen] Item swap not yet implemented")

func _delete_item_with_quantity_check(item: ItemData) -> void:
	print("[InventoryScreen] Deleting item: ", item.name, " quantity: ", item.quantity)
	
	if item.quantity == 1:
		# Tek item - onay sor
		print("[InventoryScreen] Single item - showing confirmation")
		var confirm_dialog = _create_single_delete_confirmation(item)
		confirm_dialog.popup_centered()
	else:
		# Birden fazla, kullanıcıya miktar sor
		print("[InventoryScreen] Multiple items - showing quantity dialog")
		var quantity_dialog = _create_quantity_dialog(item)
		quantity_dialog.popup_centered()

func _create_single_delete_confirmation(item: ItemData) -> ConfirmationDialog:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Eşya Sil"
	dialog.dialog_text = "%s'yi silmek istediğinize emin misiniz?\nBu işlem geri alınamaz!" % item.name
	dialog.ok_button_text = "Sil"
	dialog.cancel_button_text = "İptal"
	
	add_child(dialog)
	
	dialog.confirmed.connect(func():
		print("[InventoryScreen] User confirmed single item deletion")
		var result = await inventory_manager.remove_item(item.item_id, 1)
		if result.success:
			print("[InventoryScreen] Item deleted successfully")
		else:
			print("[InventoryScreen] Delete failed: ", result.get("error", "Unknown"))
			_show_error_message(result.get("error", "Silme işlemi başarısız"))
		_hide_item_details()
		_refresh_inventory()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		print("[InventoryScreen] User cancelled deletion")
		dialog.queue_free()
	)
	
	return dialog

func _create_quantity_dialog(item: ItemData) -> ConfirmationDialog:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Eşya Sil"
	dialog.dialog_text = "%s'den kaç tane silmek istersiniz?\nMevcut: %d adet" % [item.name, item.quantity]
	dialog.ok_button_text = "Sil"
	dialog.cancel_button_text = "İptal"
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog.add_child(vbox)
	
	var spinbox = SpinBox.new()
	spinbox.min_value = 1
	spinbox.max_value = item.quantity
	spinbox.value = 1
	spinbox.step = 1
	spinbox.allow_greater = false
	spinbox.allow_lesser = false
	spinbox.custom_minimum_size = Vector2(200, 40)
	
	# LineEdit'e erişip input validasyonu ekle
	var line_edit = spinbox.get_line_edit()
	if line_edit:
		# Sadece sayı girişine izin ver
		line_edit.text_changed.connect(func(new_text: String):
			# Boş string kontrolü
			if new_text.is_empty():
				return
				
			# Sayı dışı karakter kontrolü
			var valid_text = ""
			for c in new_text:
				if c.is_valid_int():
					valid_text += c
			
			if valid_text != new_text:
				line_edit.text = valid_text
				line_edit.caret_column = valid_text.length()
				return
			
			# Max değer kontrolü
			var num_value = valid_text.to_int()
			if num_value > item.quantity:
				line_edit.text = str(item.quantity)
				line_edit.caret_column = line_edit.text.length()
				spinbox.value = item.quantity
			elif num_value < 1 and valid_text.length() > 0:
				line_edit.text = "1"
				line_edit.caret_column = 1
				spinbox.value = 1
		)
		
		# Focus kaybedildiğinde de kontrol et
		line_edit.focus_exited.connect(func():
			var current_value = line_edit.text.to_int()
			if current_value > item.quantity:
				line_edit.text = str(item.quantity)
				spinbox.value = item.quantity
			elif current_value < 1:
				line_edit.text = "1"
				spinbox.value = 1
		)
	
	vbox.add_child(spinbox)
	
	add_child(dialog)
	
	dialog.confirmed.connect(func():
		# SpinBox değerini al ve clamp et
		var amount = int(clamp(spinbox.value, 1, item.quantity))
		
		# Çift kontrol - eğer hala geçersizse hata göster
		if amount > item.quantity:
			print("[InventoryScreen] Trying to delete more than available: ", amount, " > ", item.quantity)
			_show_error_message("Mevcut miktardan fazla silemezsiniz! (Mevcut: %d)" % item.quantity)
			dialog.queue_free()
			return
		
		if amount < 1:
			print("[InventoryScreen] Invalid quantity: ", amount)
			_show_error_message("En az 1 adet silmelisiniz!")
			dialog.queue_free()
			return
		
		print("[InventoryScreen] Deleting ", amount, " items")
		var result = await inventory_manager.remove_item(item.item_id, amount)
		if result.success:
			print("[InventoryScreen] Items deleted successfully")
		else:
			print("[InventoryScreen] Delete failed: ", result.get("error", "Unknown"))
			_show_error_message(result.get("error", "Silme işlemi başarısız"))
		_hide_item_details()
		_refresh_inventory()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		print("[InventoryScreen] User cancelled quantity deletion")
		dialog.queue_free()
	)
	
	return dialog

func _equip_item_to_slot(item: ItemData, slot_name: String) -> void:
	if not item.is_equipment():
		print("[InventoryScreen] Cannot equip non-equipment item")
		return
		
	var result = await inventory_manager.equip_item(item.item_id)
	if result.success:
		_refresh_inventory()
	else:
		print("[InventoryScreen] Failed to equip item: ", result.get("error", "Unknown"))
