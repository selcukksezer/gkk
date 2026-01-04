extends Control
## Warehouse Screen - Material Storage Management
## Depo yönetimi, bina bazlı depolama, transfer

@onready var all_list: VBoxContainer = %AllList
@onready var mine_list: VBoxContainer = %MineList
@onready var lumber_list: VBoxContainer = %LumberList
@onready var alchemy_list: VBoxContainer = %AlchemyList
@onready var blacksmith_list: VBoxContainer = %BlacksmithList
@onready var leatherwork_list: VBoxContainer = %LeatherworkList
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton
@onready var building_tabs: TabContainer = %BuildingTabs

const BUILDING_TYPES = {
	"mine": {"icon": "⛏️", "name": "Maden", "list": "mine_list"},
	"lumber": {"icon": "🪵", "name": "Kereste", "list": "lumber_list"},
	"alchemy": {"icon": "⚗️", "name": "Simya", "list": "alchemy_list"},
	"blacksmith": {"icon": "⚒️", "name": "Demirci", "list": "blacksmith_list"},
	"leatherwork": {"icon": "🦌", "name": "Deri İşleme", "list": "leatherwork_list"}
}

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	building_tabs.tab_changed.connect(_on_tab_changed)
	
	_load_warehouses()
	
	print("[WarehouseScreen] Ready")

func _load_warehouses() -> void:
	var result = await Network.http_get("/v1/warehouses")
	if result.success:
		_populate_all_warehouses(result.data.get("warehouses", []))

func _populate_all_warehouses(warehouses: Array) -> void:
	for child in all_list.get_children():
		child.queue_free()
	
	if warehouses.is_empty():
		var label = Label.new()
		label.text = "Depo bulunamadı"
		label.theme_override_font_sizes["font_size"] = 24
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		all_list.add_child(label)
		return
	
	for warehouse in warehouses:
		var panel = _create_warehouse_panel(warehouse)
		all_list.add_child(panel)

func _create_warehouse_panel(warehouse: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Header
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	var type = warehouse.get("building_type", "")
	var building_info = BUILDING_TYPES.get(type, {"icon": "📦", "name": "Depo"})
	
	var icon_label = Label.new()
	icon_label.text = building_info.get("icon", "📦")
	icon_label.theme_override_font_sizes["font_size"] = 48
	header.add_child(icon_label)
	
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(info_vbox)
	
	var name_label = Label.new()
	name_label.text = "%s Deposu (Seviye %d)" % [
		building_info.get("name", "Depo"),
		warehouse.get("level", 1)
	]
	name_label.theme_override_font_sizes["font_size"] = 28
	info_vbox.add_child(name_label)
	
	# Capacity
	var current = warehouse.get("current_storage", 0)
	var max_storage = warehouse.get("max_storage", 100)
	var capacity_bar = ProgressBar.new()
	capacity_bar.max_value = max_storage
	capacity_bar.value = current
	info_vbox.add_child(capacity_bar)
	
	var capacity_label = Label.new()
	capacity_label.text = "Kapasite: %d / %d (%%%d dolu)" % [
		current,
		max_storage,
		(current * 100) / max(max_storage, 1)
	]
	capacity_label.theme_override_font_sizes["font_size"] = 20
	info_vbox.add_child(capacity_label)
	
	# Items
	var items = warehouse.get("items", [])
	if not items.is_empty():
		var items_label = Label.new()
		items_label.text = "Saklanan Malzemeler:"
		items_label.theme_override_font_sizes["font_size"] = 22
		vbox.add_child(items_label)
		
		var items_grid = GridContainer.new()
		items_grid.columns = 3
		vbox.add_child(items_grid)
		
		for item in items:
			var item_label = Label.new()
			item_label.text = "%s: %d" % [
				item.get("name", "Malzeme"),
				item.get("amount", 0)
			]
			item_label.theme_override_font_sizes["font_size"] = 18
			items_grid.add_child(item_label)
	
	# Actions
	var button_box = HBoxContainer.new()
	vbox.add_child(button_box)
	
	var transfer_btn = Button.new()
	transfer_btn.text = "Transfer"
	transfer_btn.theme_override_font_sizes["font_size"] = 20
	transfer_btn.pressed.connect(func(): _show_transfer_dialog(warehouse))
	button_box.add_child(transfer_btn)
	
	var upgrade_btn = Button.new()
	upgrade_btn.text = "Genişlet"
	upgrade_btn.theme_override_font_sizes["font_size"] = 20
	upgrade_btn.pressed.connect(func(): _upgrade_warehouse(warehouse.get("id")))
	button_box.add_child(upgrade_btn)
	
	return panel

func _load_building_warehouse(building_type: String, target_list: VBoxContainer) -> void:
	var result = await Network.http_get("/v1/warehouses?type=%s" % building_type)
	if result.success:
		_populate_building_list(target_list, result.data.get("warehouses", []))

func _populate_building_list(list: VBoxContainer, warehouses: Array) -> void:
	for child in list.get_children():
		child.queue_free()
	
	if warehouses.is_empty():
		var label = Label.new()
		label.text = "Malzeme yok"
		label.theme_override_font_sizes["font_size"] = 20
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(label)
		return
	
	for warehouse in warehouses:
		var items = warehouse.get("items", [])
		for item in items:
			var hbox = HBoxContainer.new()
			
			var name_label = Label.new()
			name_label.text = item.get("name", "Malzeme")
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			name_label.theme_override_font_sizes["font_size"] = 22
			hbox.add_child(name_label)
			
			var amount_label = Label.new()
			amount_label.text = "x%d" % item.get("amount", 0)
			amount_label.theme_override_font_sizes["font_size"] = 24
			amount_label.theme_override_colors["font_color"] = Color(0.5, 1, 0.5)
			hbox.add_child(amount_label)
			
			list.add_child(hbox)

func _show_transfer_dialog(warehouse: Dictionary) -> void:
	_show_success("Transfer sistemi geliştirme aşamasında")

func _upgrade_warehouse(warehouse_id: int) -> void:
	var result = await Network.http_post("/v1/warehouses/upgrade", {"warehouse_id": warehouse_id})
	if result.success:
		_show_success("Depo genişletildi!")
		_load_warehouses()
	else:
		_show_error(result.get("error", "Genişletme başarısız"))

func _on_tab_changed(tab: int) -> void:
	match tab:
		1:  # Mine
			_load_building_warehouse("mine", mine_list)
		2:  # Lumber
			_load_building_warehouse("lumber", lumber_list)
		3:  # Alchemy
			_load_building_warehouse("alchemy", alchemy_list)
		4:  # Blacksmith
			_load_building_warehouse("blacksmith", blacksmith_list)
		5:  # Leatherwork
			_load_building_warehouse("leatherwork", leatherwork_list)

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
