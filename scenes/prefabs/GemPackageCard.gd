extends PanelContainer
## Gem Package Card

signal purchase_clicked(package)

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
	var bonus = package.get("bonus", 0)
	var price = package.get("price", 0)
	
	gems_label.text = "%d Gems" % gems
	
	if bonus > 0:
		bonus_label.text = "+%d Bonus!" % bonus
		bonus_label.visible = true
	else:
		bonus_label.visible = false
	
	# Convert cents to dollars
	price_label.text = "$%.2f" % (price / 100.0)

func _on_buy_pressed() -> void:
	purchase_clicked.emit(_package)
