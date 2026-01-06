extends PanelContainer
## Gem Package Card

signal purchase_clicked(package)

@onready var icon_label = $VBox/Icon
@onready var gems_label = $VBox/GemsLabel
@onready var bonus_label = $VBox/BonusLabel
@onready var price_label = $VBox/PriceLabel
@onready var buy_button = $VBox/BuyButton

var _package: Dictionary

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)

func set_package(package: Dictionary) -> void:
	_package = package
	
	var gems = package.get("gems", 0)
	var gold = package.get("gold", 0)
	var bonus = package.get("bonus", 0)
	var price = package.get("price", 0)
	
	if gold > 0:
		icon_label.text = "💰"
		gems_label.text = "%d Altın" % gold
		price_label.text = "💎 %s" % price
	else:
		icon_label.text = "💎"
		gems_label.text = "%d Elmas" % gems
		price_label.text = "💰 %s" % price
	
	if bonus > 0:
		bonus_label.text = "+%d Bonus!" % bonus
		bonus_label.visible = true
	else:
		bonus_label.visible = false

func _on_buy_pressed() -> void:
	purchase_clicked.emit(_package)
