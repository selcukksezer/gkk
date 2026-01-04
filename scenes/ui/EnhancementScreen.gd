extends Control
## Enhancement Screen
## Item enhancement from +0 to +10

@onready var item_selector = $ItemSelectorPanel/ScrollContainer/GridContainer
@onready var selected_item_display = $EnhancementPanel/SelectedItem
@onready var current_level_label = $EnhancementPanel/CurrentLevel
@onready var success_chance_label = $EnhancementPanel/SuccessChance
@onready var rune_selector = $EnhancementPanel/RuneSelector

@onready var cost_label = $EnhancementPanel/CostLabel
@onready var enhance_button = $EnhancementPanel/EnhanceButton

@onready var result_popup = $ResultPopup
@onready var result_text = $ResultPopup/ResultText
@onready var result_close = $ResultPopup/CloseButton

@onready var back_button = $BackButton

var _selected_item: InventoryItemData = InventoryItemData.new()
var _selected_rune: String = "none"
var _item_card_scene = preload("res://scenes/prefabs/ItemCard.tscn")

# Enhancement success rates by level
const SUCCESS_RATES = {
	0: 100,
	1: 95,
	2: 90,
	3: 80,
	4: 70,
	5: 60,
	6: 50,
	7: 40,
	8: 30,
	9: 20,
	10: 10
}

# Enhancement costs by level
const ENHANCEMENT_COSTS = {
	0: 100,
	1: 200,
	2: 400,
	3: 800,
	4: 1600,
	5: 3200,
	6: 6400,
	7: 12800,
	8: 25600,
	9: 51200
}

# Rune modifiers (success chance bonus)
const RUNE_MODIFIERS = {
	"none": 0,
	"basic": 5,
	"advanced": 10,
	"superior": 20,
	"legendary": 30
}

func _ready() -> void:
	# Connect signals
	enhance_button.pressed.connect(_on_enhance_pressed)
	result_close.pressed.connect(_on_result_close)
	back_button.pressed.connect(_on_back_pressed)
	rune_selector.item_selected.connect(_on_rune_selected)
	
	# Track screen
	Telemetry.track_screen("enhancement")
	
	# Load enhanceable items
	_load_items()

func _load_items() -> void:
	# Clear selector
	for child in item_selector.get_children():
		child.queue_free()
	
	# Filter enhanceable items from inventory
	for inv_item in State.inventory:
		# Only equipment can be enhanced
		# TODO: Check item type
		if inv_item.enhancement_level >= 10:
			continue  # Max level
		
		var card = _item_card_scene.instantiate()
		item_selector.add_child(card)
		card.set_item(inv_item)
		card.clicked.connect(_on_item_selected.bind(inv_item))

func _on_item_selected(inv_item: InventoryItemData) -> void:
	_selected_item = inv_item
	_update_enhancement_display()

func _update_enhancement_display() -> void:
	if not _selected_item:
		selected_item_display.text = "No item selected"
		enhance_button.disabled = true
		return
	
	# Show current level
	var current_level = _selected_item.enhancement_level
	current_level_label.text = "Current: +%d → +%d" % [current_level, current_level + 1]
	
	# Calculate success chance
	var base_chance = SUCCESS_RATES.get(current_level, 0)
	var rune_bonus = RUNE_MODIFIERS.get(_selected_rune, 0)
	var total_chance = min(100, base_chance + rune_bonus)
	
	success_chance_label.text = "Success Chance: %d%%" % total_chance
	
	# Show cost
	var gold_cost = ENHANCEMENT_COSTS.get(current_level, 0)
	cost_label.text = "Cost: %d gold" % gold_cost
	
	# Enable/disable button
	if State.gold < gold_cost:
		enhance_button.disabled = true
		enhance_button.text = "Insufficient Gold"
	else:
		enhance_button.disabled = false
		enhance_button.text = "Enhance"

func _on_rune_selected(index: int) -> void:
	var rune_names = ["none", "basic", "advanced", "superior", "legendary"]
	_selected_rune = rune_names[index]
	_update_enhancement_display()

func _on_enhance_pressed() -> void:
	if not _selected_item:
		return
	
	var current_level = _selected_item.enhancement_level
	var gold_cost = ENHANCEMENT_COSTS.get(current_level, 0)
	
	if State.gold < gold_cost:
		print("[Enhancement] Insufficient gold")
		return
	
	var body = {
		"inventory_item_id": _selected_item.instance_id,
		"rune_type": _selected_rune
	}
	
	var result = await Network.http_post("/enhancement/enhance", body)
	_on_enhanced(result)
	
	# Track attempt
	Telemetry.track_event("enhancement", "attempt", {
		"item_id": _selected_item.item_id,
		"current_level": current_level,
		"rune_type": _selected_rune
	})
	
	# Disable button during request
	enhance_button.disabled = true

func _on_enhanced(result: Dictionary) -> void:
	enhance_button.disabled = false
	
	if not result.success:
		print("[Enhancement] Enhancement failed: ", result.get("error", ""))
		return
	
	var data = result.data
	var success = data.get("success", false)
	var new_level = data.get("new_level", 0)
	var destroyed = data.get("destroyed", false)
	
	# Update state
	State.gold = data.get("gold", State.gold)
	
	if destroyed:
		# Item destroyed on failure (only at high levels)
		_show_result("DESTROYED!", "Item destroyed on enhancement failure!", Color.DARK_RED)
		
		# Remove from inventory
		State.inventory.erase(_selected_item)
		_selected_item = InventoryItemData.new()
		
		# Track destruction
		Telemetry.track_event("enhancement", "destroyed", {
			"item_id": _selected_item.item_id if _selected_item else "",
			"old_level": _selected_item.enhancement_level if _selected_item else 0
		})
	elif success:
		# Success!
		_selected_item.enhancement_level = new_level
		_show_result("SUCCESS!", "Item enhanced to +%d!" % new_level, Color.GREEN)
		
		# Track success
		Telemetry.track_event("enhancement", "success", {
			"item_id": _selected_item.item_id,
			"new_level": new_level
		})
	else:
		# Failed but not destroyed
		_show_result("FAILED", "Enhancement attempt failed. Item not upgraded.", Color.ORANGE)
		
		# Track failure
		Telemetry.track_event("enhancement", "failed", {
			"item_id": _selected_item.item_id,
			"level": _selected_item.enhancement_level
		})
	
	# Refresh display
	_update_enhancement_display()

func _show_result(title: String, message: String, color: Color) -> void:
	result_popup.visible = true
	result_text.text = title + "\n\n" + message
	result_text.add_theme_color_override("font_color", color)

func _on_result_close() -> void:
	result_popup.visible = false

func _on_back_pressed() -> void:
	Scenes.change_scene("res://scenes/ui/MainMenu.tscn")
