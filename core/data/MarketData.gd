class_name MarketData
extends Resource
## Market Data Model
## Represents market orders, ticker data, and trading information

enum OrderType {
	BUY,   # Alış emri
	SELL   # Satış emri
}

enum OrderStatus {
	PENDING,   # Bekliyor
	FILLED,    # Tamamlandı
	CANCELLED, # İptal edildi
	EXPIRED    # Süresi doldu
}

@export var order_id: String = ""
@export var player_id: String = ""
@export var item_id: String = ""
@export var order_type: OrderType = OrderType.SELL
@export var status: OrderStatus = OrderStatus.PENDING

@export var quantity: int = 1
@export var price_per_unit: int = 0
@export var total_price: int = 0
@export var filled_quantity: int = 0

@export var region: String = "central"  # Market region
@export var created_at: int = 0
@export var expires_at: int = 0
@export var filled_at: int = 0

## Create from dictionary
static func from_dict(data: Dictionary) -> MarketData:
	var market = MarketData.new()
	
	market.order_id = data.get("id", "")
	market.player_id = data.get("player_id", "")
	market.item_id = data.get("item_id", "")
	
	var type_str = data.get("order_type", "SELL")
	market.order_type = OrderType.get(type_str) if OrderType.has(type_str) else OrderType.SELL
	
	var status_str = data.get("status", "PENDING")
	market.status = OrderStatus.get(status_str) if OrderStatus.has(status_str) else OrderStatus.PENDING
	
	market.quantity = data.get("quantity", 1)
	market.price_per_unit = data.get("price_per_unit", 0)
	market.total_price = data.get("total_price", 0)
	market.filled_quantity = data.get("filled_quantity", 0)
	
	market.region = data.get("region", "central")
	market.created_at = data.get("created_at", 0)
	market.expires_at = data.get("expires_at", 0)
	market.filled_at = data.get("filled_at", 0)
	
	return market

func to_dict() -> Dictionary:
	return {
		"id": order_id,
		"player_id": player_id,
		"item_id": item_id,
		"order_type": OrderType.keys()[order_type],
		"status": OrderStatus.keys()[status],
		"quantity": quantity,
		"price_per_unit": price_per_unit,
		"total_price": total_price,
		"filled_quantity": filled_quantity,
		"region": region,
		"created_at": created_at,
		"expires_at": expires_at,
		"filled_at": filled_at
	}

## Check if order is active
func is_active() -> bool:
	if status != OrderStatus.PENDING:
		return false
	if expires_at > 0 and Time.get_unix_time_from_system() > expires_at:
		return false
	return true

## Get remaining quantity
func get_remaining_quantity() -> int:
	return quantity - filled_quantity

## Calculate order fee (2% fee)
static func calculate_fee(amount: int) -> int:
	return int(amount * 0.02)

## Market ticker data
class MarketTicker:
	var item_id: String = ""
	var item_name: String = ""
	var region: String = "central"
	
	var last_price: int = 0
	var best_buy_price: int = 0  # Highest buy order
	var best_sell_price: int = 0  # Lowest sell order
	
	var volume_24h: int = 0  # 24 saat hacim
	var trades_24h: int = 0  # 24 saat işlem sayısı
	
	var price_change_24h: int = 0  # Fiyat değişimi
	var price_change_percent: float = 0.0
	
	var high_24h: int = 0
	var low_24h: int = 0
	
	var last_update: int = 0
	
	static func from_dict(data: Dictionary) -> MarketTicker:
		var ticker = MarketTicker.new()
		
		ticker.item_id = data.get("item_id", "")
		ticker.item_name = data.get("item_name", "")
		ticker.region = data.get("region", "central")
		
		ticker.last_price = data.get("last_price", 0)
		ticker.best_buy_price = data.get("best_buy_price", 0)
		ticker.best_sell_price = data.get("best_sell_price", 0)
		
		ticker.volume_24h = data.get("volume_24h", 0)
		ticker.trades_24h = data.get("trades_24h", 0)
		
		ticker.price_change_24h = data.get("price_change_24h", 0)
		ticker.price_change_percent = data.get("price_change_percent", 0.0)
		
		ticker.high_24h = data.get("high_24h", 0)
		ticker.low_24h = data.get("low_24h", 0)
		
		ticker.last_update = data.get("last_update", 0)
		
		return ticker
	
	func to_dict() -> Dictionary:
		return {
			"item_id": item_id,
			"item_name": item_name,
			"region": region,
			"last_price": last_price,
			"best_buy_price": best_buy_price,
			"best_sell_price": best_sell_price,
			"volume_24h": volume_24h,
			"trades_24h": trades_24h,
			"price_change_24h": price_change_24h,
			"price_change_percent": price_change_percent,
			"high_24h": high_24h,
			"low_24h": low_24h,
			"last_update": last_update
		}
	
	## Get spread (difference between buy and sell)
	func get_spread() -> int:
		if best_sell_price > 0 and best_buy_price > 0:
			return best_sell_price - best_buy_price
		return 0
	
	## Get spread percentage
	func get_spread_percent() -> float:
		if best_sell_price > 0:
			return (float(get_spread()) / best_sell_price) * 100.0
		return 0.0
	
	## Is price rising
	func is_rising() -> bool:
		return price_change_24h > 0
	
	## Get trend color
	func get_trend_color() -> Color:
		if price_change_24h > 0:
			return Color.GREEN
		elif price_change_24h < 0:
			return Color.RED
		else:
			return Color.GRAY
