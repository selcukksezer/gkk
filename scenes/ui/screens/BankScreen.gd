extends Control
## Bank Screen - Item Storage
## Banka deposu - güvenli item saklama

@onready var item_grid: GridContainer = %ItemGrid
@onready var slot_label: Label = %SlotLabel
@onready var cost_label: Label = %CostLabel
@onready var expand_button: Button = $MarginContainer/VBox/InfoPanel/HBox/ExpandButton
@onready var deposit_button: Button = $MarginContainer/VBox/ActionPanel/HBox/DepositButton
@onready var withdraw_button: Button = $MarginContainer/VBox/ActionPanel/HBox/WithdrawButton
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

# Tab buttons
@onready var all_button: Button = $MarginContainer/VBox/TabButtons/AllButton
@onready var weapon_button: Button = $MarginContainer/VBox/TabButtons/WeaponButton
@onready var armor_button: Button = $MarginContainer/VBox/TabButtons/ArmorButton
@onready var potion_button: Button = $MarginContainer/VBox/TabButtons/PotionButton

var current_filter: String = "all"
var bank_items: Array[Dictionary] = []
var selected_items: Array[Dictionary] = []
var max_slots: int = 50
var used_slots: int = 0

func _ready() -> void:
	# Connect buttons
	all_button.pressed.connect(func(): _change_filter("all"))
	weapon_button.pressed.connect(func(): _change_filter("weapon"))
	armor_button.pressed.connect(func(): _change_filter("armor"))
	potion_button.pressed.connect(func(): _change_filter("potion"))
	
	expand_button.pressed.connect(_on_expand_button_pressed)
	deposit_button.pressed.connect(_on_deposit_button_pressed)
	withdraw_button.pressed.connect(_on_withdraw_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	_load_bank_data()
	
	print("[BankScreen] Ready")

func _change_filter(filter: String) -> void:
	current_filter = filter
	_update_filter_buttons()
	_populate_grid()

func _update_filter_buttons() -> void:
	all_button.disabled = current_filter == "all"
	weapon_button.disabled = current_filter == "weapon"
	armor_button.disabled = current_filter == "armor"
	potion_button.disabled = current_filter == "potion"

func _load_bank_data() -> void:
	var result = await Network.http_get("/v1/bank/items")
	if result.success:
		bank_items = result.data.get("items", [])
		max_slots = result.data.get("max_slots", 50)
		used_slots = result.data.get("used_slots", 0)
		
		_update_ui()
		_populate_grid()

func _update_ui() -> void:
	slot_label.text = "%d/%d" % [used_slots, max_slots]
	
	# Calculate expansion cost
	var expansions = (max_slots - 50) / 25
	var cost = 500 * (expansions + 1)
	cost_label.text = "%d Gem" % cost
	
	# Disable expand if full or max
	expand_button.disabled = max_slots >= 200

func _clear_grid() -> void:
	for child in item_grid.get_children():
		child.queue_free()

func _populate_grid() -> void:
	_clear_grid()
	
	var filtered_items = _get_filtered_items()
	
	for item in filtered_items:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(230, 230)
		
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		# Item icon placeholder
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(150, 150)
		icon.color = _get_rarity_color(item.get("rarity", "common"))
		vbox.add_child(icon)
		
		# Item name
		var name_label = Label.new()
		name_label.text = item.get("name", "Unknown")
		name_label.theme_override_font_sizes["font_size"] = 18
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(name_label)
		
		# Quantity
		if item.get("quantity", 1) > 1:
			var qty_label = Label.new()
			qty_label.text = "x%d" % item.get("quantity", 1)
			qty_label.theme_override_font_sizes["font_size"] = 16
			qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(qty_label)
		
		# Click to select
		var button = Button.new()
		button.text = "Seç"
		button.pressed.connect(func(): _toggle_item_selection(item))
		vbox.add_child(button)
		
		item_grid.add_child(panel)

func _get_filtered_items() -> Array[Dictionary]:
	if current_filter == "all":
		return bank_items
	
	var filtered: Array[Dictionary] = []
	for item in bank_items:
		if item.get("type") == current_filter:
			filtered.append(item)
	return filtered

func _toggle_item_selection(item: Dictionary) -> void:
	var index = selected_items.find(item)
	if index >= 0:
		selected_items.remove_at(index)
	else:
		selected_items.append(item)

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.5, 0.5, 0.5)
		"uncommon": return Color(0.5, 1, 0.5)
		"rare": return Color(0.5, 0.5, 1)
		"epic": return Color(0.7, 0.5, 1)
		"legendary": return Color(1, 0.5, 0)
		_: return Color(0.3, 0.3, 0.3)

func _on_expand_button_pressed() -> void:
	# Show confirmation dialog
	var dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Depo Genişletme",
			"message": "25 slot eklemek için %s Gem harcansın mı?" % cost_label.text,
			"on_confirm": _execute_expansion
		})

func _execute_expansion() -> void:
	var result = await Network.http_post("/v1/bank/expand", {})
	if result.success:
		max_slots = result.data.get("new_max_slots", max_slots + 25)
		_update_ui()
		_show_success("Depo genişletildi!")
	else:
		_show_error(result.get("error", "Genişletme başarısız"))

func _on_deposit_button_pressed() -> void:
	# TODO: Open inventory selection
	_show_error("Yakında eklenecek")

func _on_withdraw_button_pressed() -> void:
	if selected_items.is_empty():
		_show_error("Lütfen çekmek istediğiniz itemleri seçin")
		return
	
	var item_ids = []
	for item in selected_items:
		item_ids.append(item.get("id"))
	
	var result = await Network.http_post("/v1/bank/withdraw", {"item_ids": item_ids})
	if result.success:
		_show_success("Itemler envantere eklendi")
		selected_items.clear()
		_load_bank_data()
	else:
		_show_error(result.get("error", "Çekme başarısız"))

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
