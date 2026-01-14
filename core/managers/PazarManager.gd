extends Node
## Market System Manager
## Handles order book, ticker data, buy/sell operations

signal ticker_updated(region_id: int, data: Dictionary)
signal order_placed(order: Dictionary)
signal order_filled(order: Dictionary)
signal order_cancelled(order_id: String)

# Import required classes
# ...
# Remove this preload line if present, or just don't use it as instance
# const InventoryManager = preload("res://autoload/InventoryManager.gd") 

# ...

# ...


const MARKET_ENDPOINT = "/api/v1/market"

## Get market ticker for region
# Deprecated/Legacy
func fetch_ticker(region_id: int, use_cache: bool = true) -> Dictionary:
	# ... (Existing logic, keeping for safety)
	return {"success": false, "error": "Use fetch_active_listings"}

## Get all active market listings
# Returns individual orders for populating the catalog
func fetch_active_listings(region_id: int) -> Dictionary:
	# Fetch all active orders with item data
	var result = await Network.http_get("/rest/v1/market_orders?select=*,item_data&status=eq.active&order=price.asc")
	
	if result.success:
		var orders = result.data
		if typeof(orders) == TYPE_DICTIONARY and orders.has("data"): orders = orders.data # Unwrap
		
		if typeof(orders) == TYPE_ARRAY:
			return {"success": true, "listings": orders}
	
	return {"success": false, "error": result.get("error", "Failed to fetch listings")}

## Get order book for item
func fetch_order_book(item_id: String, region_id: int) -> Dictionary:
	# Fetch from DB: all orders for this item, sorted by price ASC (Best Sell Request first)
	var endpoint = "/rest/v1/market_orders?select=*&item_id=eq.%s&order=price.asc" % item_id
	var result = await Network.http_get(endpoint)
	
	if result.success:
		var orders = result.data
		if typeof(orders) == TYPE_DICTIONARY and orders.has("data"): orders = orders.data
		
		# Convert to OrderBook format: { asks: [], bids: [] }
		if typeof(orders) == TYPE_ARRAY:
			var asks = []
			for o in orders:
				asks.append({
					"price": o.get("price"),
					"quantity": o.get("quantity"),
					"seller_id": o.get("seller_id"),
					"order_id": o.get("id")
				})
			return {"success": true, "orderbook": {"asks": asks, "bids": []}}
	
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

## Place sell order (RPC)
func place_sell_order(item_row_id: String, quantity: int, price_per_unit: int) -> Dictionary:
	var payload = {
		"p_item_row_id": item_row_id,
		"p_quantity": quantity,
		"p_price": price_per_unit
	}
	
	# Use Network singleton for RPC
	print("PazarManager: Sending RPC to /rest/v1/rpc/place_sell_order with payload:", payload)
	var result = await Network.http_post("/rest/v1/rpc/place_sell_order", payload)
	
	print("PazarManager: Raw RPC Result -> ", result)
	
	if result.success:
		# If RPC returns data (e.g. {success: true}), checking if it's wrapped
		var data = result.data
		if typeof(data) == TYPE_STRING: # Handle stringified JSON
			var json = JSON.new()
			if json.parse(data) == OK: data = json.data
			
		if data is Dictionary and data.get("success") == true:
			order_placed.emit(data)
			# Refresh inventory locally since it changed
			var inv_manager = get_node_or_null("/root/InventoryManager")
			if inv_manager:
				await inv_manager.fetch_inventory()
			return {"success": true, "data": data}
		
		# If RPC returned specific error in JSON
		return {"success": false, "error": data.get("error", "Unknown DB Error")}
		
	return {"success": false, "error": result.get("error", "Network/DB Error")}

## Cancel order (RPC)
func cancel_order(order_id: String) -> Dictionary:
	var payload = {
		"p_order_id": order_id
	}
	
	var result = await Network.http_post("/rest/v1/rpc/cancel_sell_order", payload)
	
	if result.success:
		var data = result.data
		if typeof(data) == TYPE_STRING:
			var json = JSON.new()
			if json.parse(data) == OK: data = json.data
			
		if data is Dictionary and data.get("success") == true:
			order_cancelled.emit(order_id)
			var inv_manager = get_node_or_null("/root/InventoryManager")
			if inv_manager:
				await inv_manager.fetch_inventory()
			return {"success": true}
			
		return {"success": false, "error": data.get("error", "Failed to cancel")}
		
	return {"success": false, "error": result.get("error", "Network Error")}

## Get player's active orders (Table Select)
func fetch_my_orders() -> Dictionary:
	# Explicitly filter by our own user ID
	# We cannot rely solely on RLS because the table is public readable (for Browse tab)
	# Prioritize auth_id as it maps directly to seller_id (auth.uid())
	var user_id = State.player.get("auth_id")
	if user_id == null or str(user_id).is_empty():
		user_id = State.player.get("id", "")
		
	if str(user_id).is_empty():
		return {"success": false, "error": "User not authenticated"}
		
	print("PazarManager: Fetching Orders for SellerID: ", user_id)
		
	var endpoint = "/rest/v1/market_orders?select=*,item_data&seller_id=eq.%s" % user_id
	var result = await Network.http_get(endpoint)
	
	if result.success:
		var orders = result.data
		if typeof(orders) == TYPE_DICTIONARY and orders.has("data"):
			orders = orders.data # Unwrap if needed
			
		if typeof(orders) == TYPE_ARRAY:
			return {"success": true, "orders": orders}
			
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
