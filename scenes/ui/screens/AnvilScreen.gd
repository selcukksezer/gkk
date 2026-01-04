extends Control
## Anvil Screen - Equipment Upgrade System
## Ekipman geliştirme ekranı (+0→+10)

@onready var item_name: Label = %ItemName
@onready var current_level: Label = %CurrentLevel
@onready var rune_name_1: Label = %RuneName1
@onready var rune_name_2: Label = %RuneName2
@onready var rune_name_3: Label = %RuneName3
@onready var chance_bar: ProgressBar = %ProgressBar
@onready var chance_label: Label = %ChanceLabel
@onready var cost_label: Label = %CostLabel
@onready var risk_label: Label = %RiskLabel
@onready var upgrade_button: Button = $MarginContainer/VBox/ScrollContainer/ContentVBox/UpgradeButton
@onready var select_button: Button = $MarginContainer/VBox/ScrollContainer/ContentVBox/ItemPanel/VBox/SelectButton
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton
@onready var animation_panel: Panel = %AnimationPanel
@onready var result_label: Label = %ResultLabel

var selected_item: Dictionary = {}
var selected_runes: Array[Dictionary] = [{}, {}, {}]
var is_upgrading: bool = false

## Upgrade rates (from docs)
const UPGRADE_CHANCES = {
	0: 100, 1: 100, 2: 100, 3: 100,
	4: 70, 5: 60, 6: 50,
	7: 35,
	8: 20,
	9: 10,
	10: 3
}

const UPGRADE_COSTS = {
	0: 1000, 1: 2000, 2: 3000, 3: 5000,
	4: 15000, 5: 35000, 6: 75000,
	7: 150000,
	8: 500000,
	9: 2000000,
	10: 10000000
}

func _ready() -> void:
	# Connect buttons
	select_button.pressed.connect(_on_select_button_pressed)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Disable upgrade initially
	upgrade_button.disabled = true
	
	print("[AnvilScreen] Ready")

func _update_ui() -> void:
	if selected_item.is_empty():
		item_name.text = "Ekipman Seçiniz"
		current_level.text = "+0"
		upgrade_button.disabled = true
		_update_chance_display(0, 0, "")
		return
	
	# Update item info
	var level = selected_item.get("level", 0)
	item_name.text = selected_item.get("name", "Bilinmeyen")
	current_level.text = "+%d" % level
	
	# Calculate chance with runes
	var base_chance = UPGRADE_CHANCES.get(level, 0)
	var rune_bonus = _calculate_rune_bonus()
	var final_chance = min(base_chance + rune_bonus, 100)
	
	# Calculate cost
	var cost = UPGRADE_COSTS.get(level, 1000)
	
	# Determine risk
	var risk_text = ""
	if level >= 8:
		risk_text = "⚠️ YOK OLMA RİSKİ: %%%d" % (100 - final_chance)
	elif level >= 7:
		risk_text = "⚠️ Seviye düşebilir"
	elif level >= 4:
		risk_text = "Seviye düşmez"
	else:
		risk_text = "Risksiz"
	
	_update_chance_display(final_chance, cost, risk_text)
	
	# Enable upgrade if enough gold
	var player_gold = State.get_player_gold()
	upgrade_button.disabled = player_gold < cost or level >= 10

func _update_chance_display(chance: int, cost: int, risk: String) -> void:
	chance_bar.value = chance
	chance_label.text = "Başarı: %%%d" % chance
	cost_label.text = "Maliyet: %s Altın" % StringUtils.format_number(cost)
	risk_label.text = risk
	
	# Color coding
	if chance >= 70:
		chance_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
	elif chance >= 35:
		chance_label.add_theme_color_override("font_color", Color(1, 1, 0.5))
	else:
		chance_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))

func _calculate_rune_bonus() -> int:
	var bonus = 0
	for rune in selected_runes:
		if not rune.is_empty():
			bonus += rune.get("bonus", 0)
	return bonus

func _on_select_button_pressed() -> void:
	# TODO: Open inventory to select item
	# For now, simulate selection
	selected_item = {
		"id": "test_sword_1",
		"name": "Demir Kılıç",
		"level": 0,
		"type": "weapon"
	}
	_update_ui()

func _on_upgrade_button_pressed() -> void:
	if is_upgrading or selected_item.is_empty():
		return
	
	is_upgrading = true
	upgrade_button.disabled = true
	
	# API call
	var level = selected_item.get("level", 0)
	var cost = UPGRADE_COSTS.get(level, 1000)
	
	var data = {
		"item_id": selected_item.get("id"),
		"rune_ids": _get_rune_ids()
	}
	
	is_upgrading = true
	upgrade_button.disabled = true
	
	var result = await Network.http_post("/v1/anvil/upgrade", data)
	is_upgrading = false
	upgrade_button.disabled = false
	
	if result.success:
		_play_result_animation(result.data)
	else:
		_show_error(result.get("error", "Geliştirme başarısız"))

func _get_rune_ids() -> Array:
	var ids = []
	for rune in selected_runes:
		if not rune.is_empty():
			ids.append(rune.get("id"))
	return ids

func _play_result_animation(result_data: Dictionary) -> void:
	animation_panel.visible = true
	
	var success = result_data.get("success", false)
	var new_level = result_data.get("new_level", 0)
	var destroyed = result_data.get("destroyed", false)
	
	if destroyed:
		result_label.text = "❌ YOK OLDU!"
		result_label.add_theme_color_override("font_color", Color(1, 0, 0, 1))
		selected_item = {}
	elif success:
		result_label.text = "✅ BAŞARILI!\n+%d → +%d" % [selected_item.get("level", 0), new_level]
		result_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
		selected_item["level"] = new_level
	else:
		var old_level = selected_item.get("level", 0)
		result_label.text = "❌ BAŞARISIZ\n+%d → +%d" % [old_level, new_level]
		result_label.add_theme_color_override("font_color", Color(1, 0.5, 0, 1))
		selected_item["level"] = new_level
	
	# Hide after 2 seconds
	await get_tree().create_timer(2.0).timeout
	animation_panel.visible = false
	
	_update_ui()

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()

func _show_error(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Hata",
			"message": message
		})
