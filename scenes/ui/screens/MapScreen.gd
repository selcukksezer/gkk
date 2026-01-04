extends Control
## Map Screen - World Map & Travel
## Dünya haritası ve bölgeler arası seyahat

@onready var region_list: VBoxContainer = %RegionList
@onready var location_label: Label = %LocationLabel
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

var regions: Array[Dictionary] = []
var current_region: String = ""

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_load_map_data()
	print("[MapScreen] Ready")

func _load_map_data() -> void:
	var result = await Network.http_get("/v1/map/regions")
	if result.success:
		regions = result.data.get("regions", [])
		current_region = result.data.get("current_region", "")
		
		# Update current location
		for region in regions:
			if region.get("id") == current_region:
				location_label.text = region.get("name", "Bilinmeyen")
				break
		
		_populate_regions()

func _populate_regions() -> void:
	for child in region_list.get_children():
		child.queue_free()
	
	for region in regions:
		var panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		# Region info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = region.get("name", "Bilinmeyen Bölge")
		name_label.theme_override_font_sizes["font_size"] = 28
		info_vbox.add_child(name_label)
		
		var details_label = Label.new()
		var danger = region.get("danger_level", 0)
		var danger_text = _get_danger_text(danger)
		details_label.text = "Tehlike: %s | Seyahat Süresi: %d dk | Maliyet: %d enerji" % [
			danger_text,
			region.get("travel_time_minutes", 5),
			region.get("travel_energy", 5)
		]
		details_label.theme_override_font_sizes["font_size"] = 20
		info_vbox.add_child(details_label)
		
		var desc_label = Label.new()
		desc_label.text = region.get("description", "")
		desc_label.theme_override_font_sizes["font_size"] = 18
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		info_vbox.add_child(desc_label)
		
		# Travel button
		var travel_button = Button.new()
		travel_button.custom_minimum_size = Vector2(200, 100)
		
		if region.get("id") == current_region:
			travel_button.text = "Buradasınız"
			travel_button.disabled = true
		else:
			travel_button.text = "SEYAHAT ET"
			travel_button.theme_override_font_sizes["font_size"] = 24
			travel_button.pressed.connect(func(): _travel_to_region(region))
		
		hbox.add_child(travel_button)
		
		region_list.add_child(panel)

func _get_danger_text(danger: int) -> String:
	if danger < 20:
		return "⭐ Güvenli"
	elif danger < 40:
		return "⭐⭐ Düşük"
	elif danger < 60:
		return "⭐⭐⭐ Orta"
	elif danger < 80:
		return "⭐⭐⭐⭐ Yüksek"
	else:
		return "⭐⭐⭐⭐⭐ Çok Tehlikeli"

func _travel_to_region(region: Dictionary) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Seyahat",
			"message": "%s bölgesine seyahat etmek istiyor musunuz?\nMaliyet: %d enerji" % [
				region.get("name", ""),
				region.get("travel_energy", 5)
			],
			"on_confirm": func(): _execute_travel(region)
		})

func _execute_travel(region: Dictionary) -> void:
	var data = {
		"region_id": region.get("id")
	}
	
	var result = await Network.http_post("/v1/map/travel", data)
	if result.success:
		current_region = region.get("id")
		location_label.text = region.get("name", "")
		_populate_regions()
		_show_success("Seyahat tamamlandı!")
	else:
		_show_error(result.get("error", "Seyahat başarısız"))

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
