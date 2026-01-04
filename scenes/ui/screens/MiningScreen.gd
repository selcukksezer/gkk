extends Control
## Mining Screen - Resource Gathering
## Kaynak toplama (Demir cevheri, Kereste, Deri)

@onready var resource_list: VBoxContainer = %ResourceList
@onready var energy_label: Label = %EnergyLabel
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

const RESOURCES = [
	{"id": "iron_ore", "name": "Demir Cevheri", "icon": "⛏️", "energy": 5, "time": 30, "amount": "5-10"},
	{"id": "lumber", "name": "Kereste", "icon": "🪵", "energy": 7, "time": 45, "amount": "3-8"},
	{"id": "leather", "name": "Deri", "icon": "🦌", "energy": 8, "time": 60, "amount": "2-5"},
	{"id": "stone", "name": "Taş", "icon": "🪨", "energy": 6, "time": 40, "amount": "4-9"},
	{"id": "herb", "name": "Şifalı Ot", "icon": "🌿", "energy": 10, "time": 90, "amount": "1-3"}
]

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)
	_update_energy()
	_populate_list()
	
	# Listen for energy updates
	if State:
		State.energy_updated.connect(_update_energy)
	
	print("[MiningScreen] Ready")

func _update_energy() -> void:
	var current = State.get_player_energy()
	var max_energy = State.get_max_energy()
	energy_label.text = "%d/%d" % [current, max_energy]

func _populate_list() -> void:
	for child in resource_list.get_children():
		child.queue_free()
	
	for resource in RESOURCES:
		var panel = PanelContainer.new()
		var hbox = HBoxContainer.new()
		panel.add_child(hbox)
		
		# Icon
		var icon_label = Label.new()
		icon_label.text = resource.get("icon", "⛏️")
		icon_label.add_theme_font_size_override("font_size", 48)
		hbox.add_child(icon_label)
		
		# Info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var name_label = Label.new()
		name_label.text = resource.get("name", "Kaynak")
		name_label.add_theme_font_size_override("font_size", 28)
		info_vbox.add_child(name_label)
		
		var details_label = Label.new()
		details_label.text = "Miktar: %s | Süre: %d sn | Enerji: %d" % [
			resource.get("amount", "1"),
			resource.get("time", 30),
			resource.get("energy", 5)
		]
		details_label.add_theme_font_size_override("font_size", 20)
		info_vbox.add_child(details_label)
		
		# Gather button
		var gather_button = Button.new()
		gather_button.custom_minimum_size = Vector2(200, 100)
		gather_button.text = "TOPLA"
		gather_button.add_theme_font_size_override("font_size", 28)
		
		var current_energy = State.get_player_energy()
		var required_energy = resource.get("energy", 5)
		gather_button.disabled = current_energy < required_energy
		
		gather_button.pressed.connect(func(): _gather_resource(resource))
		hbox.add_child(gather_button)
		
		resource_list.add_child(panel)

func _gather_resource(resource: Dictionary) -> void:
	var data = {
		"resource_id": resource.get("id")
	}
	
	var result = await Network.http_post("/v1/mining/gather", data)
	if result.success:
		var amount = result.data.get("amount", 0)
		_show_success("Toplandı: %d %s" % [amount, resource.get("name", "Kaynak")])
		_update_energy()
		_populate_list()
	else:
		_show_error(result.get("error", "Toplama başarısız"))

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
