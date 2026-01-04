extends Control
## Building Screen - Production Buildings Management
## Üretim binaları yönetimi (Maden, Kereste, Simya, Demirci, Deri İşleme)

@onready var building_list: VBoxContainer = %BuildingList
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

var buildings: Array[Dictionary] = []

## Building types with icons and descriptions
const BUILDING_INFO = {
	"mine": {"icon": "⛏️", "name": "Maden", "resource": "Demir Cevheri"},
	"lumber": {"icon": "🪵", "name": "Kereste Deposu", "resource": "Kereste"},
	"alchemy": {"icon": "⚗️", "name": "Simya Lab", "resource": "İksir Malzemesi"},
	"blacksmith": {"icon": "⚒️", "name": "Demirci", "resource": "Ekipman Parçası"},
	"leatherwork": {"icon": "🦌", "name": "Deri İşleme", "resource": "Deri"}
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_load_buildings()
	print("[BuildingScreen] Ready")

func _load_buildings() -> void:
	var result = await Network.http_get("/v1/buildings")
	if result.success:
		buildings = result.data.get("buildings", [])
		_populate_list()

func _populate_list() -> void:
	for child in building_list.get_children():
		child.queue_free()
	
	for building in buildings:
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		# Header with icon and name
		var header_hbox = HBoxContainer.new()
		vbox.add_child(header_hbox)
		
		var type = building.get("type", "mine")
		var info = BUILDING_INFO.get(type, {"icon": "🏗️", "name": "Bina"})
		
		var icon_label = Label.new()
		icon_label.text = info.get("icon", "🏗️")
		icon_label.theme_override_font_sizes["font_size"] = 48
		header_hbox.add_child(icon_label)
		
		var name_vbox = VBoxContainer.new()
		name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_hbox.add_child(name_vbox)
		
		var name_label = Label.new()
		name_label.text = info.get("name", "Bilinmeyen")
		name_label.theme_override_font_sizes["font_size"] = 28
		name_vbox.add_child(name_label)
		
		var level_label = Label.new()
		var level = building.get("level", 1)
		level_label.text = "Seviye %d" % level
		level_label.theme_override_font_sizes["font_size"] = 20
		level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		name_vbox.add_child(level_label)
		
		# Production info
		var production_hbox = HBoxContainer.new()
		vbox.add_child(production_hbox)
		
		var prod_vbox = VBoxContainer.new()
		prod_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		production_hbox.add_child(prod_vbox)
		
		var resource_label = Label.new()
		var production_rate = building.get("production_rate", 10)
		resource_label.text = "Üretim: %d %s/saat" % [production_rate, info.get("resource", "Kaynak")]
		resource_label.theme_override_font_sizes["font_size"] = 20
		prod_vbox.add_child(resource_label)
		
		var storage_label = Label.new()
		var current = building.get("current_storage", 0)
		var max_storage = building.get("max_storage", 100)
		storage_label.text = "Depo: %d/%d" % [current, max_storage]
		storage_label.theme_override_font_sizes["font_size"] = 20
		prod_vbox.add_child(storage_label)
		
		# Progress bar for storage
		var progress = ProgressBar.new()
		progress.value = (float(current) / max_storage) * 100 if max_storage > 0 else 0
		prod_vbox.add_child(progress)
		
		# Action buttons
		var button_hbox = HBoxContainer.new()
		button_hbox.alignment = BoxContainer.ALIGNMENT_END
		production_hbox.add_child(button_hbox)
		
		# Collect button
		if current > 0:
			var collect_button = Button.new()
			collect_button.custom_minimum_size = Vector2(150, 60)
			collect_button.text = "Topla"
			collect_button.pressed.connect(func(): _collect_resources(building))
			button_hbox.add_child(collect_button)
		
		# Upgrade button
		var upgrade_button = Button.new()
		upgrade_button.custom_minimum_size = Vector2(150, 60)
		var upgrade_cost = _calculate_upgrade_cost(level)
		upgrade_button.text = "Geliştir\n%s altın" % StringUtils.format_number(upgrade_cost)
		upgrade_button.theme_override_font_sizes["font_size"] = 18
		upgrade_button.pressed.connect(func(): _upgrade_building(building))
		button_hbox.add_child(upgrade_button)
		
		building_list.add_child(panel)
	
	# Add "Build New" button if less than 5 buildings
	if buildings.size() < 5:
		var build_button = Button.new()
		build_button.custom_minimum_size = Vector2(0, 100)
		build_button.text = "+ YENİ BİNA İNŞA ET"
		build_button.theme_override_font_sizes["font_size"] = 28
		build_button.pressed.connect(_on_build_new_pressed)
		building_list.add_child(build_button)

func _calculate_upgrade_cost(level: int) -> int:
	return 10000 * level * level

func _collect_resources(building: Dictionary) -> void:
	var data = {
		"building_id": building.get("id")
	}
	
	var result = await Network.http_post("/v1/buildings/collect", data)
	if result.success:
		var amount = result.data.get("collected", 0)
		_show_success("Toplandi: %d kaynak" % amount)
		_load_buildings()
	else:
		_show_error(result.get("error", "Toplama başarısız"))

func _upgrade_building(building: Dictionary) -> void:
	var level = building.get("level", 1)
	var cost = _calculate_upgrade_cost(level)
	
	var dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Bina Geliştirme",
			"message": "Seviye %d → %d\nMaliyet: %s altın" % [level, level + 1, StringUtils.format_number(cost)],
			"on_confirm": func(): _execute_upgrade(building)
		})

func _execute_upgrade(building: Dictionary) -> void:
	var data = {
		"building_id": building.get("id")
	}
	
	var result = await Network.http_post("/v1/buildings/upgrade", data)
	if result.success:
		_show_success("Bina geliştirildi!")
		_load_buildings()
	else:
		_show_error(result.get("error", "Geliştirme başarısız"))

func _on_build_new_pressed() -> void:
	# Show building type selection dialog
	var popup = PopupMenu.new()
	add_child(popup)
	
	popup.add_item("⛏️ Maden", 0)
	popup.add_item("🪵 Kereste Deposu", 1)
	popup.add_item("⚗️ Simya Lab", 2)
	popup.add_item("⚒️ Demirci", 3)
	popup.add_item("🦌 Deri İşleme", 4)
	
	popup.id_pressed.connect(_on_building_type_selected)
	popup.position = get_global_mouse_position()
	popup.popup()

func _on_building_type_selected(id: int) -> void:
	var types = ["mine", "lumber", "alchemy", "blacksmith", "leatherwork"]
	var type = types[id]
	
	var data = {
		"type": type
	}
	
	var result = await Network.http_post("/v1/buildings/build", data)
	if result.success:
		_show_success("Bina inşaa edildi!")
		_load_buildings()
	else:
		_show_error(result.get("error", "İnşaa başarısız"))

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
