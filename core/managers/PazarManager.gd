extends Node
## Market System Manager
## Handles order book, ticker data, buy/sell operations

signal ticker_updated(region_id: int, data: Dictionary)
signal order_placed(order: Dictionary)
signal order_filled(order: Dictionary)
signal order_cancelled(order_id: String)

# Import required classes
const InventoryManager = preload("res://autoload/InventoryManager.gd")

const MARKET_ENDPOINT = "/api/v1/market"

## Get market ticker for region
func fetch_ticker(region_id: int, use_cache: bool = true) -> Dictionary:
	# Check cache first
	if use_cache and State.is_ticker_cached(region_id):
		var cached = State.get_cached_ticker(region_id)
		return {"success": true, "ticker": cached, "cached": true}
	
	# Fetch from server
	var result = await Network.http_get(MARKET_ENDPOINT + "/ticker/%d" % region_id)
	
	if result.success and result.data.has("ticker"):
		var ticker = result.data.ticker
		State.cache_market_ticker(region_id, ticker)
		ticker_updated.emit(region_id, ticker)
		return {"success": true, "ticker": ticker, "cached": false}
	
	return {"success": false, "error": result.get("error", "Failed to fetch ticker")}

## Get order book for item
func fetch_order_book(item_id: String, region_id: int) -> Dictionary:
	var result = await Network.http_get(MARKET_ENDPOINT + "/orderbook/%s?region=%d" % [item_id, region_id])
	
	if result.success and result.data.has("orderbook"):
		return {"success": true, "orderbook": result.data.orderbook}
	
	return {"success": false, "error": result.get("error", "Failed to fetch order book")}

## Place buy order
func place_buy_order(item_id: String, quantity: int, price_per_unit: int, region_id: int) -> Dictionary:
	var total_cost = quantity * price_per_unit
	
	# Check if player has enough gold
	if State.gold < total_cost:
		return {"success": false, "error": "Not enough gold"}
	
	var result = await Network.http_post(MARKET_ENDPOINT + "/buy", {
		"item_id": item_id,
		"quantity": quantity,
		"price_per_unit": price_per_unit,
		"region_id": region_id
	})
	
	if result.success:
		var order = result.data.order
		order_placed.emit(order)
		
		# Update gold
		State.update_gold(-total_cost, true)
		
		Audio.play_coin()
		
		Telemetry.track_market("buy_order", item_id, {
			"quantity": quantity,
			"price": price_per_unit,
			"total": total_cost
		})
		
		return {"success": true, "order": order}
	
	return {"success": false, "error": result.get("error", "Failed to place order")}

## Place sell order
func place_sell_order(item_id: String, quantity: int, price_per_unit: int, region_id: int) -> Dictionary:
	# Check if player has item
	var inventory_manager = InventoryManager.new()
	var item_data = State.get_item_data_by_id(item_id)

	if not item_data or item_data.quantity < quantity:
		return {"success": false, "error": "Not enough items"}

	# Validate item can be traded
	if not item_data.is_tradeable:
		return {"success": false, "error": "Item cannot be traded"}

	var result = await Network.http_post(MARKET_ENDPOINT + "/sell", {
		"item_id": item_id,
		"quantity": quantity,
		"price_per_unit": price_per_unit,
		"region_id": region_id
	})

	if result.success:
		var order = result.data.order
		order_placed.emit(order)

		# Remove item from inventory (it's now in escrow)
		await inventory_manager.remove_item(item_id, quantity)

		Audio.play_coin()

		Telemetry.track_market("sell_order", item_id, {
			"quantity": quantity,
			"price": price_per_unit
		})
		
		return {"success": true, "order": order}
	
	return {"success": false, "error": result.get("error", "Failed to place order")}

## Cancel order
func cancel_order(order_id: String) -> Dictionary:
	var result = await Network.http_post(MARKET_ENDPOINT + "/cancel", {
		"order_id": order_id
	})
	
	if result.success:
		order_cancelled.emit(order_id)
		
		# Refund gold or return items (handled by server)
		if result.data.has("gold_refund"):
			State.update_gold(result.data.gold_refund, true)
		
		if result.data.has("items_returned"):
			for item in result.data.items_returned:
				State.add_item(item)
		
		Telemetry.track_market("cancel_order", order_id, {})
		
		return {"success": true}
	
	return {"success": false, "error": result.get("error", "Failed to cancel order")}

## Get player's active orders
func fetch_my_orders() -> Dictionary:
	var result = await Network.http_get(MARKET_ENDPOINT + "/orders/mine")
	
	if result.success and result.data.has("orders"):
		return {"success": true, "orders": result.data.orders}
	
	return {"success": false, "error": result.get("error", "Failed to fetch orders")}

## Get recent trades
func fetch_recent_trades(item_id: String, limit: int = 20) -> Dictionary:
	var result = await Network.http_get(MARKET_ENDPOINT + "/trades/%s?limit=%d" % [item_id, limit])
	
	if result.success and result.data.has("trades"):
		return {"success": true, "trades": result.data.trades}
	
	return {"success": false, "error": result.get("error", "Failed to fetch trades")}

## Get price history for chart
func fetch_price_history(item_id: String, period: String = "24h") -> Dictionary:
	var result = await Network.http_get(MARKET_ENDPOINT + "/history/%s?period=%s" % [item_id, period])
	
	if result.success and result.data.has("history"):
		return {"success": true, "history": result.data.history}
	
	return {"success": false, "error": result.get("error", "Failed to fetch history")}

## Calculate total with commission
func calculate_total_with_commission(amount: int) -> Dictionary:
	var config = Config.get_market_config()
	var commission_rate = config.get("commission_rate", 0.05)
	var commission = int(amount * commission_rate)
	var total = amount + commission
	
	return {
		"subtotal": amount,
		"commission": commission,
		"total": total,
		"commission_rate": commission_rate
	}

## Get market commission
func get_commission_rate() -> float:
	return Config.get_market_config().get("commission_rate", 0.05)
