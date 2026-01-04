extends Control
## Trade Screen - Direct Player Trade
## Oyuncular arası güvenli ticaret

@onready var player_input: LineEdit = %PlayerInput
@onready var search_button: Button = $MarginContainer/VBox/PlayerSearchPanel/HBox/SearchButton
@onready var my_item_list: VBoxContainer = %MyItemList
@onready var their_item_list: VBoxContainer = %TheirItemList
@onready var their_label: Label = %Label
@onready var status_label: Label = %StatusLabel
@onready var add_item_button: Button = $MarginContainer/VBox/TradeContainer/MyPanel/VBox/AddItemButton
@onready var confirm_button: Button = $MarginContainer/VBox/ActionButtons/ConfirmButton
@onready var cancel_button: Button = $MarginContainer/VBox/ActionButtons/CancelButton
@onready var back_button: Button = $MarginContainer/VBox/Header/BackButton

var trade_session_id: String = ""
var target_player: String = ""
var my_confirmed: bool = false
var their_confirmed: bool = false

func _ready() -> void:
	search_button.pressed.connect(_on_search_button_pressed)
	add_item_button.pressed.connect(_on_add_item_button_pressed)
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)
	
	confirm_button.disabled = true
	add_item_button.disabled = true
	
	print("[TradeScreen] Ready")

func _on_search_button_pressed() -> void:
	var player_name = player_input.text.strip_edges()
	if player_name.is_empty():
		_show_error("Lütfen oyuncu adı giriniz")
		return
	
	_initiate_trade(player_name)

func _initiate_trade(player_name: String) -> void:
	var data = {
		"target_player": player_name
	}
	
	var result = await Network.http_post("/v1/trade/initiate", data)
	if result.success:
		trade_session_id = result.data.get("session_id", "")
		target_player = player_name
		their_label.text = player_name
		status_label.text = "Ticaret başlatılddı"
		
		add_item_button.disabled = false
		confirm_button.disabled = false
	else:
		_show_error(result.get("error", "Ticaret başlatılamazdı"))

func _on_add_item_button_pressed() -> void:
	# TODO: Open inventory selection
	_show_error("Yakında eklenecek - Envanterden item seçimi")

func _on_confirm_button_pressed() -> void:
	if trade_session_id.is_empty():
		return
	
	var data = {
		"session_id": trade_session_id
	}
	
	var result = await Network.http_post("/v1/trade/confirm", data)
	if result.success:
		my_confirmed = true
		confirm_button.disabled = true
		status_label.text = "Onayınız alındı - Karşı taraf bekleniyor..."
		
		if their_confirmed:
			_complete_trade()

func _complete_trade() -> void:
	status_label.text = "Ticaret tamamlandı!"
	await get_tree().create_timer(1.0).timeout
	_on_back_button_pressed()

func _on_cancel_button_pressed() -> void:
	if trade_session_id.is_empty():
		_on_back_button_pressed()
		return
	
	var data = {
		"session_id": trade_session_id
	}
	
	var result = await Network.http_post("/v1/trade/cancel", data)
	_on_back_button_pressed()

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").go_back()

func _show_error(message: String) -> void:
	var dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Hata",
			"message": message
		})
