extends Control

## BlacksmithScreen.gd
## Manages the Item Upgrade UI with Drag & Drop and Component Grid support.

# Constants
const INVENTORY_MANAGER = preload("res://autoload/InventoryManager.gd")
const ITEM_SLOT_SCENE = preload("res://scenes/prefabs/ItemSlot.tscn")
const UPGRADE_RESULT_EFFECT = preload("res://scenes/vfx/UpgradeResultEffect.tscn")

# Nodes
var input_slot: BlacksmithSlot
var component_grid: GridContainer
var output_slot: BlacksmithSlot
var inventory_grid: GridContainer
var info_label: Label
var success_particles: CPUParticles2D
var upgrade_button: Button
var cancel_button: Button

# State
var current_input_item: ItemData = null
var current_scroll: ItemData = null
var enhancement_manager_ref: Node = null # Dynamically fetch
var is_upgrading: bool = false

func _ready() -> void:
	print("[BlacksmithScreen] _ready called. Finding children...")
	
	# FIND CHILDREN SAFELY
	# Input/Output
	input_slot = find_child("InputSlot", true, false)
	output_slot = find_child("OutputSlot", true, false)
	
	# Grids
	component_grid = find_child("ComponentGrid", true, false)
	inventory_grid = find_child("InventoryGrid", true, false)
	
	# UI Elements
	info_label = find_child("InfoLabel", true, false)
	upgrade_button = find_child("UpgradeButton", true, false)
	cancel_button = find_child("CancelButton", true, false)
	success_particles = find_child("SuccessParticles", true, false)

	# Safety Checks
	if not input_slot: printerr("[Blacksmith] CRITICAL: Missing InputSlot")
	if not output_slot: printerr("[Blacksmith] CRITICAL: Missing OutputSlot")
	if not component_grid: printerr("[Blacksmith] CRITICAL: Missing ComponentGrid")
	if not inventory_grid: printerr("[Blacksmith] CRITICAL: Missing InventoryGrid")

	# Connect Buttons
	if upgrade_button:
		if not upgrade_button.pressed.is_connected(_on_upgrade_pressed):
			upgrade_button.pressed.connect(_on_upgrade_pressed)
	
	if cancel_button:
		if not cancel_button.pressed.is_connected(_on_cancel_pressed):
			cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Initialize Slots
	if input_slot:
		if not input_slot.item_dropped.is_connected(_on_input_item_dropped):
			input_slot.item_dropped.connect(_on_input_item_dropped)
		if not input_slot.item_removed.is_connected(_on_input_item_removed):
			input_slot.item_removed.connect(_on_input_item_removed)
	
	# Initialize Component Slots
	if component_grid:
		for child in component_grid.get_children():
			if child is BlacksmithSlot:
				if not child.item_dropped.is_connected(_on_component_item_dropped):
					child.item_dropped.connect(_on_component_item_dropped.bind(child))
				if not child.item_removed.is_connected(_on_component_item_removed):
					child.item_removed.connect(_on_component_item_removed.bind(child))
			
	# Connect Signal Updates
	if State.inventory_updated.connect(_refresh_inventory) != OK:
		print("[BlacksmithScreen] Failed to connect inventory_updated (checked)")
		
	# Initialize Cancel Button Text
	if cancel_button:
		cancel_button.text = "İPTAL"

	_refresh_inventory()
	_update_ui_state()

# --- INVENTORY & DRAG DROP ---

func _refresh_inventory() -> void:
	if not inventory_grid: return

	# Clear grid
	for child in inventory_grid.get_children():
		child.queue_free()
		
	# Get items
	var all_items = State.get_all_items_data()
	
	# Filter items
	var items_to_show = []
	for item in all_items:
		if item.is_equipped: continue
		if current_input_item and item.row_id == current_input_item.row_id: continue
		if current_scroll and item.row_id == current_scroll.row_id: continue
		items_to_show.append(item)
		
	# Instantiate Slots
	for i in range(20):
		var item_in_slot = null
		for it in items_to_show:
			if it.slot_position == i:
				item_in_slot = it
				break
				
		if item_in_slot:
			var slot = ITEM_SLOT_SCENE.instantiate()
			slot.custom_minimum_size = Vector2(90, 90)
			slot.set_item(item_in_slot)
			slot.item_dropped.connect(_on_inventory_item_dragged_to_target)
			inventory_grid.add_child(slot)
		else:
			var empty_slot = Panel.new()
			empty_slot.custom_minimum_size = Vector2(90, 90)
			empty_slot.set_script(preload("res://scenes/ui/components/EmptyInventorySlot.gd"))
			empty_slot.item_placed.connect(_on_inventory_drop_received)
			
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.12, 0.12, 0.12, 0.7)
			style.border_color = Color(0.3, 0.3, 0.3)
			style.border_width_bottom = 2
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			empty_slot.add_theme_stylebox_override("panel", style)
			inventory_grid.add_child(empty_slot)

func _on_inventory_item_dragged_to_target(item: ItemData, target_control: Control) -> void:
	if is_upgrading: return
	if target_control == input_slot:
		if input_slot._can_drop_data(Vector2.ZERO, item):
			_on_input_item_dropped(item)
	elif component_grid and target_control in component_grid.get_children():
		var slot = target_control as BlacksmithSlot
		if slot and slot._can_drop_data(Vector2.ZERO, item):
			_on_component_item_dropped(item, slot)

func _on_input_item_dropped(item: ItemData) -> void:
	if is_upgrading: return
	current_input_item = item
	if input_slot: 
		input_slot.set_item(item)
	_refresh_inventory()
	_update_ui_state()

func _on_input_item_removed(item: ItemData) -> void:
	if is_upgrading: return
	current_input_item = null
	if input_slot: 
		input_slot.clear()
	_refresh_inventory()
	_update_ui_state()

func _on_component_item_dropped(item: ItemData, slot_control: BlacksmithSlot) -> void:
	if is_upgrading: return
	if item.item_type == ItemData.ItemType.SCROLL:
		if current_scroll:
			# Remove old scroll from its slot if it exists
			if component_grid:
				for child in component_grid.get_children():
					if child != slot_control and child.get_item() and child.get_item().row_id == current_scroll.row_id:
						child.clear()
						break
		current_scroll = item
		slot_control.set_item(item)
	
	_refresh_inventory()
	_update_ui_state()
	
func _on_component_item_removed(item: ItemData, slot_control: BlacksmithSlot) -> void:
	if is_upgrading: return
	if item.item_type == ItemData.ItemType.SCROLL:
		current_scroll = null
	slot_control.clear()
	_refresh_inventory()
	_update_ui_state()

func _on_inventory_drop_received(item: ItemData, _slot_idx: int) -> void:
	if is_upgrading: return
	if current_input_item and current_input_item.row_id == item.row_id:
		_on_input_item_removed(item)
	elif current_scroll and current_scroll.row_id == item.row_id:
		# Find slot
		if component_grid:
			for child in component_grid.get_children():
				if child.get_item() and child.get_item().row_id == item.row_id:
					_on_component_item_removed(item, child)
					break

# --- LOGIC ---

func _update_ui_state() -> void:
	if output_slot: output_slot.clear()
	
	if not current_input_item:
		if info_label: info_label.text = "Lütfen yükseltilecek eşyayı yerleştirin."
		if upgrade_button: upgrade_button.disabled = true
		if input_slot: input_slot.set_border_color(Color(0.6, 0.5, 0.1)) # Reset gold
		return
		
	# Reset input slot border
	if input_slot: input_slot.set_border_color(Color(0.6, 0.5, 0.1))
		
	if not current_scroll:
		var required = "Bilinmeyen"
		match current_input_item.rarity:
			ItemData.ItemRarity.COMMON, ItemData.ItemRarity.UNCOMMON: required = "Düşük Sınıf"
			ItemData.ItemRarity.RARE, ItemData.ItemRarity.EPIC: required = "Orta Sınıf"
			_: required = "Yüksek Sınıf"
		
		if info_label: info_label.text = "Gerekli: %s Parşömen" % required
		if upgrade_button: upgrade_button.disabled = true
		return

	# Compatibility Check
	var is_compatible = false
	if current_input_item.rarity <= ItemData.ItemRarity.UNCOMMON:
		is_compatible = (current_scroll.item_id == "scroll_upgrade_low")
	elif current_input_item.rarity <= ItemData.ItemRarity.EPIC:
		is_compatible = (current_scroll.item_id == "scroll_upgrade_middle")
	else:
		is_compatible = (current_scroll.item_id == "scroll_upgrade_high")
		 
	if not is_compatible:
		if info_label:
			info_label.text = "Hatalı Parşömen!"
			info_label.add_theme_color_override("font_color", Color.RED)
		if upgrade_button: upgrade_button.disabled = true
	else:
		# Success Rate Calculation (Range Display)
		var rate_min = 0
		var rate_max = 0
		var mgr = get_node_or_null("/root/EnhancementManager")
		if mgr:
			var rates = mgr.BASE_SUCCESS_RATES.get(current_input_item.enhancement_level, {"min": 0, "max": 0})
			rate_min = rates.min
			rate_max = rates.max
			
		var cost = 1000 * (current_input_item.enhancement_level + 1)
		var player_gold = State.gold
		
		if player_gold < cost:
			if info_label:
				info_label.text = "Yetersiz Altın!\nGerekli: %d | Mevcut: %d" % [cost, player_gold]
				info_label.add_theme_color_override("font_color", Color.RED)
			if upgrade_button: upgrade_button.disabled = true
		else:
			if info_label:
				info_label.text = "Başarı Şansı: %% %d-%d\nÜcret: %d Altın" % [rate_min, rate_max, cost]
				info_label.remove_theme_color_override("font_color")
			if upgrade_button: upgrade_button.disabled = false
		
		# Show Preview in Output Slot
		if output_slot:
			var preview_item = current_input_item.duplicate()
			preview_item.enhancement_level += 1
			output_slot.set_item(preview_item)
			output_slot.modulate = Color(1, 1, 1, 0.5) # Dim preview

func _on_upgrade_pressed() -> void:
	if not current_input_item or not current_scroll: return
	if is_upgrading: return
	
	var cost = 1000 * (current_input_item.enhancement_level + 1)
	if State.gold < cost:
		if info_label: info_label.text = "Yetersiz Altın!"
		return
	
	is_upgrading = true
	State.update_gold(-cost, true) # Deduct gold
	
	if upgrade_button: upgrade_button.disabled = true
	if cancel_button: cancel_button.disabled = true
	if info_label: 
		info_label.text = "İşleniyor..."
		# Remove text after 3 seconds
		get_tree().create_timer(3.0).timeout.connect(func(): if info_label: info_label.text = "")
	
	# Simulate processing delay visual
	await get_tree().create_timer(1.0).timeout
	
	var mgr = get_node_or_null("/root/EnhancementManager")
	if mgr:
		var result = await mgr.enhance_item(current_input_item, current_scroll)
		
		if output_slot: output_slot.modulate = Color(1, 1, 1, 1) # Reset fade
		
		if result.success:
			# if info_label: info_label.text = "BAŞARILI!" # Removed as per request
			
			# Spawn Upgrade Effect
			if output_slot:
				var effect = UPGRADE_RESULT_EFFECT.instantiate()
				output_slot.add_child(effect)
				# Center in slot (90x90) -> (45, 45)
				effect.position = Vector2(45, 45)
				
				# Get icon texture either from current item or load it
				var icon_tex = null
				if current_input_item and current_input_item.icon:
					if ResourceLoader.exists(current_input_item.icon):
						icon_tex = load(current_input_item.icon)
						
				effect.setup(icon_tex)
				effect.play_effect(true) # Success
			
			# Green Light Effect (Removed)
			# Screen Flash (Removed)
			
			if output_slot:
				output_slot.set_item(current_input_item) # Shows new level
			
			# Wait 7 seconds
			await get_tree().create_timer(7.0).timeout
			
			current_input_item = null
			if input_slot: 
				input_slot.clear()
				input_slot.set_border_color(Color(0.6, 0.5, 0.1))
				
			current_scroll = null
			if component_grid:
				for child in component_grid.get_children():
					child.clear()
			
			if output_slot:
				output_slot.set_border_color(Color.RED) # Reset to default red-ish
				output_slot.clear()
					
			_refresh_inventory()
		else:
			# if info_label: info_label.text = "BAŞARISIZ! Eşya Yandı." # Removed as per request
			
			# Spawn Upgrade Effect (Fail)
			if output_slot:
				var effect = UPGRADE_RESULT_EFFECT.instantiate()
				output_slot.add_child(effect)
				effect.position = Vector2(45, 45)
				
				var icon_tex = null
				if current_input_item and current_input_item.icon:
					if ResourceLoader.exists(current_input_item.icon):
						icon_tex = load(current_input_item.icon)
						
				effect.setup(icon_tex)
				effect.play_effect(false) # Fail
			
			if output_slot:
				output_slot.clear() # Burned
			
			if input_slot:
				input_slot.clear()
				input_slot.set_border_color(Color.RED) # Burn visual
			
			await get_tree().create_timer(7.0).timeout 
			
			current_input_item = null
			if input_slot: 
				input_slot.clear()
				input_slot.set_border_color(Color(0.6, 0.5, 0.1))
				
			current_scroll = null
			if component_grid:
				for child in component_grid.get_children():
					child.clear()
					
			_refresh_inventory()
			
	if upgrade_button: upgrade_button.disabled = false
	if cancel_button: cancel_button.disabled = false
	is_upgrading = false

func _on_cancel_pressed() -> void:
	# Clear Input
	current_input_item = null
	if input_slot: 
		input_slot.clear()
		input_slot.set_border_color(Color(0.6, 0.5, 0.1))
		input_slot.stop_flame()
	
	# Clear Components
	current_scroll = null
	if component_grid:
		for child in component_grid.get_children():
			child.clear()
			# Components shouldn't have flames usually, but safe to ignore
			
	# Clear Output
	if output_slot: 
		output_slot.clear()
		output_slot.set_border_color(Color.RED)
		output_slot.stop_flame()

	_refresh_inventory()
	_update_ui_state()
