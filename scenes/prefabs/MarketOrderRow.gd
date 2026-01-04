extends PanelContainer
## Market Order Row

signal clicked(order)

@onready var username_label = $HBox/Username
@onready var quantity_label = $HBox/Quantity
@onready var price_label = $HBox/Price
@onready var total_label = $HBox/Total

var _order: MarketOrderData

func _ready() -> void:
	gui_input.connect(_on_gui_input)

func set_order(order: MarketOrderData) -> void:
	_order = order
	
	username_label.text = order.username if "username" in order else "Anonymous"
	quantity_label.text = "x%d" % order.quantity
	price_label.text = "%d g" % order.price_per_unit
	total_label.text = "%d g" % (order.quantity * order.price_per_unit)
	
	# Color coding for buy/sell
	if order.order_type == "buy":
		modulate = Color(0.8, 1.0, 0.8)  # Green tint
	else:
		modulate = Color(1.0, 0.8, 0.8)  # Red tint

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit(_order)
