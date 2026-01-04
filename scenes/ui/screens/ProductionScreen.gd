extends Control
## Production Screen - Production Queue & Chains
## Üretim zinciri yönetimi (Ham madde → İşlenmiş ürün)

@onready var active_list: VBoxContainer = %ActiveList
@onready var recipe_list: VBoxContainer = %RecipeList
@onready var history_list: VBoxContainer = %HistoryList
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton
@onready var tab_container: TabContainer = $MarginContainer/VBox/TabContainer

const PRODUCTION_CHAINS = [
	{
		"id": "iron_ingot",
		"name": "Demir Külçesi",
		"icon": "🔩",
		"building": "blacksmith",
		"time": 300,
		"materials": {"iron_ore": 5},
		"output": {"iron_ingot": 1}
	},
	{
		"id": "leather_strip",
		"name": "Deri Şerit",
		"icon": "🎀",
		"building": "leatherwork",
		"time": 240,
		"materials": {"leather": 3},
		"output": {"leather_strip": 2}
	},
	{
		"id": "wooden_plank",
		"name": "Tahta Kalası",
		"icon": "🪵",
		"building": "lumber",
		"time": 180,
		"materials": {"lumber": 4},
		"output": {"wooden_plank": 3}
	},
	{
		"id": "health_potion",
		"name": "Can İksiri",
		"icon": "🧪",
		"building": "alchemy",
		"time": 600,
		"materials": {"herb": 5, "water": 2},
		"output": {"health_potion": 1}
	},
	{
		"id": "iron_sword",
		"name": "Demir Kılıç",
		"icon": "⚔️",
		"building": "blacksmith",
		"time": 900,
		"materials": {"iron_ingot": 3, "wooden_plank": 1},
		"output": {"iron_sword": 1}
	}
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	tab_container.tab_changed.connect(_on_tab_changed)
	
	_load_active_productions()
	_populate_recipes()
	
	print("[ProductionScreen] Ready")

func _load_active_productions() -> void:
	var result = await Network.http_get("/v1/production/active")
	if result.success:
		_populate_active_list(result.data.get("productions", []))

func _populate_active_list(productions: Array) -> void:
	for child in active_list.get_children():
		child.queue_free()
	
	if productions.is_empty():
		var label = Label.new()
		label.text = "Aktif üretim yok"
		label.add_theme_font_size_override("font_size", 24)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		active_list.add_child(label)
		return
	
	for prod in productions:
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		# Icon + Name
		var icon_label = Label.new()
		icon_label.text = prod.get("icon", "⚙️")
		icon_label.add_theme_font_size_override("font_size", 40)
		hbox.add_child(icon_label)
		
		var name_label = Label.new()
		name_label.text = prod.get("item_name", "Üretim")
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_font_size_override("font_size", 28)
		hbox.add_child(name_label)
		
		# Progress
		var progress_bar = ProgressBar.new()
		progress_bar.max_value = prod.get("total_time", 100)
		progress_bar.value = prod.get("elapsed_time", 0)
		vbox.add_child(progress_bar)
		
		var time_label = Label.new()
		var remaining = prod.get("total_time", 0) - prod.get("elapsed_time", 0)
		time_label.text = "Kalan Süre: %s" % _format_time(remaining)
		time_label.add_theme_font_size_override("font_size", 20)
		vbox.add_child(time_label)
		
		# Actions
		var button_box = HBoxContainer.new()
		vbox.add_child(button_box)
		
		var speedup_btn = Button.new()
		speedup_btn.text = "Hızlandır (💎 50)"
		speedup_btn.add_theme_font_size_override("font_size", 20)
		speedup_btn.pressed.connect(func(): _speedup_production(prod.get("id")))
		button_box.add_child(speedup_btn)
		
		var cancel_btn = Button.new()
		cancel_btn.text = "İptal"
		cancel_btn.add_theme_font_size_override("font_size", 20)
		cancel_btn.pressed.connect(func(): _cancel_production(prod.get("id")))
		button_box.add_child(cancel_btn)
		
		active_list.add_child(panel)

func _populate_recipes() -> void:
	for child in recipe_list.get_children():
		child.queue_free()
	
	for recipe in PRODUCTION_CHAINS:
		var panel = PanelContainer.new()
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		
		# Icon + Name
		var icon_label = Label.new()
		icon_label.text = recipe.get("icon", "⚙️")
		icon_label.add_theme_font_size_override("font_size", 40)
		hbox.add_child(icon_label)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = recipe.get("name", "Üretim")
		name_label.add_theme_font_size_override("font_size", 28)
		info_vbox.add_child(name_label)
		
		var time_label = Label.new()
		time_label.text = "Süre: %s" % _format_time(recipe.get("time", 0))
		time_label.add_theme_font_size_override("font_size", 20)
		info_vbox.add_child(time_label)
		
		# Materials
		var materials_text = "Malzemeler: "
		var materials = recipe.get("materials", {})
		for mat in materials:
			materials_text += "%s x%d  " % [mat, materials[mat]]
		
		var mat_label = Label.new()
		mat_label.text = materials_text
		mat_label.add_theme_font_size_override("font_size", 18)
		info_vbox.add_child(mat_label)
		
		# Start button
		var start_btn = Button.new()
		start_btn.custom_minimum_size = Vector2(200, 80)
		start_btn.text = "BAŞLAT"
		start_btn.add_theme_font_size_override("font_size", 24)
		start_btn.pressed.connect(func(): _start_production(recipe))
		hbox.add_child(start_btn)
		
		recipe_list.add_child(panel)

func _start_production(recipe: Dictionary) -> void:
	var data = {
		"recipe_id": recipe.get("id"),
		"building_type": recipe.get("building")
	}
	
	var result = await Network.http_post("/v1/production/start", data)
	if result.success:
		_show_success("Üretim başlatıldı!")
		_load_active_productions()
		tab_container.current_tab = 0
	else:
		_show_error(result.get("error", "Başlatma başarısız"))

func _speedup_production(prod_id: int) -> void:
	var result = await Network.http_post("/v1/production/speedup", {"production_id": prod_id})
	if result.success:
		_show_success("Üretim hızlandırıldı!")
		_load_active_productions()
	else:
		_show_error(result.get("error", "Hızlandırma başarısız"))

func _cancel_production(prod_id: int) -> void:
	var result = await Network.http_post("/v1/production/cancel", {"production_id": prod_id})
	if result.success:
		_show_success("Üretim iptal edildi")
		_load_active_productions()
	else:
		_show_error(result.get("error", "İptal başarısız"))

func _format_time(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	else:
		return "%d:%02d" % [minutes, secs]

func _on_tab_changed(tab: int) -> void:
	if tab == 2:  # History tab
		_load_history()

func _load_history() -> void:
	var result = await Network.http_get("/v1/production/history?limit=20")
	if result.success:
		_populate_history(result.data.get("history", []))

func _populate_history(history: Array) -> void:
	for child in history_list.get_children():
		child.queue_free()
	
	for entry in history:
		var label = Label.new()
		label.text = "%s - %s (%s)" % [
			entry.get("date", ""),
			entry.get("item_name", ""),
			entry.get("status", "")
		]
		label.theme_override_font_sizes["font_size"] = 20
		history_list.add_child(label)

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
