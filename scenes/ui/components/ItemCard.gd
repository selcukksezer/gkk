extends PanelContainer
## Item Card Component
## Displays item information in a card format

signal item_selected(item: ItemData)
signal item_long_pressed(item: ItemData)

@onready var name_label: Label = %NameLabel
@onready var quantity_label: Label = %QuantityLabel
@onready var enhancement_label: Label = %EnhancementLabel
@onready var rarity_indicator: ColorRect = $RarityIndicator
@onready var price_label: Label = %PriceLabel
@onready var purchase_button: Button = %PurchaseButton
@onready var icon_rect: TextureRect = %Icon

var item: ItemData = ItemData.new()
var show_enhancement: bool = true
var show_quantity: bool = true
var shop_mode: bool = false  # Show price and purchase button in shop

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	# Long press timer for contextual menu
	_long_press_timer = Timer.new()
	_long_press_timer.wait_time = 0.5  # 500ms for long press
	_long_press_timer.one_shot = true
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	add_child(_long_press_timer)

func setup(item_data: ItemData, is_shop: bool = false) -> void:
	item = item_data
	shop_mode = is_shop
	_update_display()

func _update_display() -> void:
	if not item:
		return
	
	# Icon
	if icon_rect:
		if item.icon and not item.icon.is_empty() and ResourceLoader.exists(item.icon):
			icon_rect.texture = load(item.icon)
		else:
			icon_rect.texture = null
	
	# Name (Shown at bottom as requested)
	if name_label:
		name_label.text = item.name
		name_label.visible = true
	
	# Quantity
	if quantity_label and show_quantity:
		quantity_label.visible = item.quantity > 1 or item.is_stackable
		quantity_label.text = "x%d" % item.quantity
	
	# Enhancement
	if enhancement_label and show_enhancement:
		enhancement_label.visible = item.enhancement_level > 0
		enhancement_label.text = "+%d" % item.enhancement_level
		
		# Color based on enhancement level
		if item.enhancement_level >= 7:
			enhancement_label.add_theme_color_override("font_color", Color.RED)
		elif item.enhancement_level >= 4:
			enhancement_label.add_theme_color_override("font_color", Color.PURPLE)
		else:
			enhancement_label.add_theme_color_override("font_color", Color.CYAN)
	
	# Rarity indicator (Use as border color)
	if rarity_indicator:
		# Ensure we have a unique stylebox for this instance
		if not has_theme_stylebox_override("panel"):
			var current_style = get_theme_stylebox("panel")
			if current_style:
				add_theme_stylebox_override("panel", current_style.duplicate())
		
		# Now modify the unique stylebox
		var style = get_theme_stylebox("panel")
		if style and style is StyleBoxFlat:
			style.border_color = item.get_rarity_color()
		else:
			# Fallback if no stylebox or wrong type
			rarity_indicator.color = item.get_rarity_color()
			rarity_indicator.visible = false # Hide fill
	
	# Price (shop mode only)
	if price_label:
		price_label.visible = shop_mode
		if shop_mode:
			price_label.text = "%s" % MathUtils.format_number(item.base_price) # Just number
	
	# Purchase button (Hidden, click card to buy)
	if purchase_button:
		purchase_button.visible = false

func _on_purchase_pressed() -> void:
	item_selected.emit(item)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			item_selected.emit(item)
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			item_long_pressed.emit(item)
	
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Start long press timer
			_start_long_press_timer()
		else:
			# Cancel long press, emit click
			_cancel_long_press_timer()
			if not _long_press_triggered:
				item_selected.emit(item)

var _long_press_timer: Timer
var _long_press_triggered: bool = false

func _cancel_long_press_timer() -> void:
	if _long_press_timer and _long_press_timer.time_left > 0:
		_long_press_timer.stop()
	_long_press_triggered = false

func _start_long_press_timer() -> void:
	_long_press_triggered = false
	if _long_press_timer:
		_long_press_timer.start()

func _on_long_press_timeout() -> void:
	_long_press_triggered = true
	item_long_pressed.emit(item)

## Show detailed item info
func show_details() -> void:
	if not item:
		return
	
	var details = """
	%s
	%s
	
	Tür: %s
	Nadir: %s
	""" % [
		item.name,
		"+" + str(item.enhancement_level) if item.enhancement_level > 0 else "",
		ItemData.ItemType.keys()[item.item_type],
		ItemData.ItemRarity.keys()[item.rarity]
	]
	
	# Add stats
	if item.attack > 0:
		details += "\n⚔️ Saldırı: %d" % item.attack
	if item.defense > 0:
		details += "\n🛡️ Savunma: %d" % item.defense
	if item.energy_restore > 0:
		details += "\n⚡ Enerji: +%d" % item.energy_restore
	
	# Add description
	if not item.description.is_empty():
		details += "\n\n%s" % item.description
	
	# Add price
	if item.price > 0:
		details += "\n\n💰 Değer: %s" % MathUtils.format_number(item.price)
	
	# Show dialog
	var dialog_scene = load("res://scenes/ui/dialogs/InfoDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Eşya Detayı",
			"message": details
		})
