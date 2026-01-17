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
# Returns individual orders from market_listings_view (joined with seller profile)
func fetch_active_listings(region_id: int) -> Dictionary:
	# Query the View instead of the Table
	var result = await Network.http_get("/rest/v1/market_listings_view?order=price.asc")
	
	if result.success:
		var orders = result.data
		if typeof(orders) == TYPE_DICTIONARY and orders.has("data"): orders = orders.data # Unwrap
		
		if typeof(orders) == TYPE_ARRAY:
			return {"success": true, "listings": orders}
	
	return {"success": false, "error": result.get("error", "Failed to fetch listings")}

# Old order book logic removed as per refactor plan
# Old buy order logic removed as per refactor plan


## Purchase Listing (RPC)
## Directly buy a specific listing
func purchase_listing(order_id: String, quantity: int = 1, price_hint: int = -1, is_stackable: bool = false) -> Dictionary:
	var payload = { 
		"p_order_id": order_id,
		"p_quantity": quantity,
		"p_is_stackable": is_stackable
	}
	
	print("PazarManager: Purchasing Listing ", order_id, " Qty: ", quantity, " Stackable: ", is_stackable)
	
	var result = await Network.http_post("/rest/v1/rpc/purchase_market_listing", payload)
	
	print("PazarManager: Raw RPC Result -> ", result)
	
	if result.success:
		var data = result.data
		print("PazarManager: RPC Data Raw -> ", data)
		if typeof(data) == TYPE_STRING: # Handle stringified JSON
			var json = JSON.new()
			if json.parse(data) == OK: data = json.data
			
		if data is Dictionary and data.get("success") == true:
			order_filled.emit(data)
			
			# Refresh inventory as we bought something
			var inv_manager = get_node_or_null("/root/Inventory")
			if inv_manager:
				await inv_manager.fetch_inventory()
				
			# Optimistic / Authoritative Gold Sync
			if data.has("new_buyer_gold"):
				# Server returned new balance (Best)
				State.update_gold(int(data.new_buyer_gold))
				print("PazarManager: Updated gold authoritative to ", data.new_buyer_gold)
			elif price_hint >= 0:
				# Optimistic update (Fallback)
				var new_gold = max(0, State.gold - price_hint)
				State.update_gold(new_gold)
				print("PazarManager: Updated gold optimistically to ", new_gold)
				# Still trigger refresh to ensure consistency later
				if Session: Session.refresh_profile()
			elif Session:
				# No hint, no return -> Full fetch
				await Session.refresh_profile()
				
			return {"success": true}
			
		return {"success": false, "error": data.get("error", "Purchase failed")}
		
	return {"success": false, "error": result.get("error", "Network Error")}

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
			var inv_manager = get_node_or_null("/root/Inventory")
			if inv_manager:
				await inv_manager.fetch_inventory()
			return {"success": true, "data": data}
		
		# If RPC returned specific error in JSON
		return {"success": false, "error": data.get("error", "Unknown DB Error")}
		
	return {"success": false, "error": result.get("error", "Network/DB Error")}

## Cancel order (RPC)
func cancel_order(order_id: String, is_stackable: bool = false) -> Dictionary:
	var payload = {
		"p_order_id": order_id,
		"p_is_stackable": is_stackable
	}
	
	var result = await Network.http_post("/rest/v1/rpc/cancel_sell_order", payload)
	
	if result.success:
		var data = result.data
		if typeof(data) == TYPE_STRING:
			var json = JSON.new()
			if json.parse(data) == OK: data = json.data
			
		if data is Dictionary and data.get("success") == true:
			order_cancelled.emit(order_id)
			order_cancelled.emit(order_id)
			var inv_manager = get_node_or_null("/root/Inventory")
			if inv_manager:
				print("[PazarManager] Fetching inventory after cancel...")
				await inv_manager.fetch_inventory()
			else:
				print("[PazarManager] Inventory manager not found at /root/Inventory")
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
