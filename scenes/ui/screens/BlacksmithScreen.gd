extends Control

# UI References
@onready var inventory_grid = $MainContainer/InventoryPanel/VBox/ScrollContainer/GridContainer
@onready var target_slot_icon = $MainContainer/UpgradePanel/VBox/AnvilArea/TargetSlot/Icon
@onready var target_slot_label = $MainContainer/UpgradePanel/VBox/AnvilArea/TargetSlot/Label
@onready var scroll_slot_icon = $MainContainer/UpgradePanel/VBox/AnvilArea/ScrollSlot/Icon
@onready var scroll_slot_label = $MainContainer/UpgradePanel/VBox/AnvilArea/ScrollSlot/Label
@onready var info_label = $MainContainer/UpgradePanel/VBox/InfoLabel
@onready var cost_label = $MainContainer/UpgradePanel/VBox/CostLabel
@onready var upgrade_button = $MainContainer/UpgradePanel/VBox/UpgradeButton
@onready var close_button = $CloseButton

# State
var selected_item: ItemData = null
var selected_scroll_id: String = ""
var is_processing: bool = false

# Preload
var item_card_scene = preload("res://scenes/ui/components/CompactItemCard.tscn")
# Enhancement Manager is an Autoload (EnhancementManager)

func _ready():
	# Connect signals
	close_button.pressed.connect(_on_close_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	
	# Initial UI state
	_clear_selection()
	_refresh_inventory()
	
	# Listen for inventory updates
	if State.has_user_signal("inventory_updated"):
		State.connect("inventory_updated", _refresh_inventory)

func _refresh_inventory():
	# Clear grid
	for child in inventory_grid.get_children():
		child.queue_free()
		
	# Get upgradable items (Weapons/Armor)
	var items = State.get_all_items_data()
	for item in items:
		if item.can_enhance and not item.is_scroll() and item.quantity > 0:
			var card = item_card_scene.instantiate()
			inventory_grid.add_child(card)
			card.setup(item)
			# Assuming ItemCard has a signal for click/selection
			if card.has_signal("item_selected"):
				card.item_selected.connect(_on_inventory_item_selected)

func _on_inventory_item_selected(item: ItemData):
	if is_processing: return
	selected_item = item
	_update_ui_state()

func _update_ui_state():
	if not selected_item:
		_clear_selection()
		return
		
	# Update Target Slot
	target_slot_icon.texture = load(selected_item.icon) if selected_item.icon else null
	target_slot_label.text = selected_item.name
	target_slot_label.visible = target_slot_icon.texture == null
	
	# Determine Required Scroll
	var requirements = EnhancementManager.get_upgrade_requirements(selected_item)
	selected_scroll_id = requirements.scroll_id
	var scroll_name = requirements.scroll_name
	var owned_scrolls = requirements.owned_scrolls
	
	# Update Scroll Slot
	# Load icon from ItemDatabase if possible, or use placeholder
	var scroll_item = ItemDatabase.get_item(selected_scroll_id)
	var icon_path = scroll_item.get("icon", "")
	if icon_path:
		scroll_slot_icon.texture = load(icon_path)
		scroll_slot_label.visible = false
	else:
		scroll_slot_icon.texture = null
		scroll_slot_label.text = "Scroll"
		scroll_slot_label.visible = true
		
	# Validation
	var can_afford_scroll = owned_scrolls > 0
	var enhancement_info = EnhancementManager.get_enhancement_info(selected_item.enhancement_level)
	var gold_cost = enhancement_info.cost.total
	var can_afford_gold = State.gold >= gold_cost
	var valid_level = selected_item.enhancement_level < selected_item.max_enhancement
	
	# Update Info Text
	if not valid_level:
		info_label.text = "Maksimum seviyeye ulaşıldı!"
		upgrade_button.disabled = true
	elif not can_afford_scroll:
		info_label.text = "Gerekli: %s (Sahip: %d)\nParşömen Eksik!" % [scroll_name, owned_scrolls]
		info_label.add_theme_color_override("font_color", Color.RED)
		upgrade_button.disabled = true
	elif not can_afford_gold:
		info_label.text = "Yetersiz Altın!"
		info_label.add_theme_color_override("font_color", Color.RED)
		upgrade_button.disabled = true
	else:
		info_label.text = "Başarı Şansı: %%%.1f" % enhancement_info.success_rate
		info_label.add_theme_color_override("font_color", Color.GREEN)
		upgrade_button.disabled = false
		
	cost_label.text = "Maliyet: %d Altın" % gold_cost

func _clear_selection():
	selected_item = null
	selected_scroll_id = ""
	target_slot_icon.texture = null
	target_slot_label.visible = true
	target_slot_label.text = "Eşya Seçiniz"
	scroll_slot_icon.texture = null
	scroll_slot_label.visible = true
	scroll_slot_label.text = " "
	info_label.text = "Sol taraftan bir eşya seçin"
	info_label.remove_theme_color_override("font_color")
	cost_label.text = ""
	upgrade_button.disabled = true

@onready var success_particles = $MainContainer/UpgradePanel/VBox/AnvilArea/SuccessParticles

func _on_upgrade_pressed():
	if not selected_item or is_processing: return
	
	is_processing = true
	upgrade_button.disabled = true
	upgrade_button.text = "İşleniyor..."
	
	# Simulate hammer strike delay
	await get_tree().create_timer(0.5).timeout
	
	# Perform upgrade
	var result = await EnhancementManager.enhance_item(selected_item)
	
	if result.success:
		info_label.text = "Yükseltme Başarılı! (+%d)" % result.new_level
		info_label.add_theme_color_override("font_color", Color.GREEN)
		
		# Play particles
		if success_particles:
			success_particles.position = target_slot_icon.global_position + target_slot_icon.size / 2
			success_particles.restart()
			success_particles.emitting = true
			
		# Sfx?
	else:
		if result.get("destroyed", false):
			info_label.text = "Yükseltme Başarısız... Eşya Yok Oldu!"
			info_label.add_theme_color_override("font_color", Color.DARK_RED)
			selected_item = null # Item is gone
			
			# Shake effect could go here
		else:
			info_label.text = "Yükseltme Başarısız. Seviye düştü."
			info_label.add_theme_color_override("font_color", Color.ORANGE)
			
	is_processing = false
	upgrade_button.text = "YÜKSELT"
	
	# Delay refresh to show message
	await get_tree().create_timer(1.5).timeout
	
	_refresh_inventory() # Refresh list
	_update_ui_state() # Update checks if item still exists

func _on_close_pressed():
	# Assuming this is part of a view stack or modal
	if get_parent().has_method("go_back"):
		get_parent().go_back()
	else:
		visible = false
		# Or change scene back to home
		# Scenes.change_scene("res://scenes/ui/HomeScreen.tscn")
