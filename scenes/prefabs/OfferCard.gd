extends PanelContainer
## Special Offer Card

signal purchase_clicked(offer)

@onready var offer_name = $VBox/OfferName
@onready var description = $VBox/Description
@onready var price_label = $VBox/PriceLabel
@onready var discount_label = $VBox/DiscountLabel
@onready var buy_button = $VBox/BuyButton

var _offer: Dictionary

func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)

func set_offer(offer: Dictionary) -> void:
	_offer = offer
	
	offer_name.text = offer.get("name", "Special Offer")
	description.text = offer.get("description", "")
	
	var price = offer.get("price", 0)
	price_label.text = "$%.2f" % (price / 100.0)
	
	var discount = offer.get("discount_percent", 0)
	if discount > 0:
		discount_label.text = "%d%% OFF!" % discount
		discount_label.visible = true
	else:
		discount_label.visible = false

func _on_buy_pressed() -> void:
	purchase_clicked.emit(_offer)
