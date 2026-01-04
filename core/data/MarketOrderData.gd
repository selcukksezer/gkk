# MarketOrderData.gd
class_name MarketOrderData

var order_id: String = ""
var item_id: String = ""
var order_type: String = "" # "buy" veya "sell"
var price_per_unit: int = 0
var quantity: int = 0
var user_id: String = ""

static func from_dict(data: Dictionary) -> MarketOrderData:
	var order = MarketOrderData.new()
	order.order_id = data.get("order_id", "")
	order.item_id = data.get("item_id", "")
	order.order_type = data.get("order_type", "")
	order.price_per_unit = data.get("price_per_unit", 0)
	order.quantity = data.get("quantity", 0)
	order.user_id = data.get("user_id", "")
	return order
