extends Node
## Request Queue - Offline request queue with retry logic
## Singleton autoload: Queue

signal queue_processed(success_count: int, failure_count: int)

# const GameHTTPClient = preload("res://core/network/HTTPClient.gd")

const QUEUE_FILE = "user://request_queue.json"
const MAX_RETRIES = 3
const RETRY_DELAY = 2.0  # seconds

var _queue: Array = []
var _processing: bool = false
var _retry_timer: Timer

func _ready() -> void:
	print("[Queue] Initializing...")
	_load_queue()
	
	# Create retry timer
	_retry_timer = Timer.new()
	_retry_timer.wait_time = RETRY_DELAY
	_retry_timer.one_shot = true
	_retry_timer.timeout.connect(_on_retry_timer_timeout)
	add_child(_retry_timer)
	
	# Process queue on startup if online
	if has_node("/root/Network") and Network.is_online():
		process_queue()

## Enqueue new request
func enqueue(method: String, endpoint: String, body: Dictionary = {}, priority: int = 0) -> void:
	var request_data = {
		"id": _generate_id(),
		"method": method.to_upper(),
		"endpoint": endpoint,
		"body": body,
		"priority": priority,
		"retries": 0,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	_queue.append(request_data)
	_sort_queue()
	_save_queue()
	
	print("[Queue] Enqueued: %s %s (priority: %d)" % [method, endpoint, priority])
	
	# Try to process immediately if online and not already processing
	if has_node("/root/Network") and Network.is_online() and not _processing:
		process_queue()

## Process queued requests
func process_queue() -> void:
	if _processing:
		return
	
	if _queue.is_empty():
		print("[Queue] Queue is empty")
		return
	
	if not (has_node("/root/Network") and Network.is_online()):
		print("[Queue] Cannot process - offline")
		return
	
	_processing = true
	print("[Queue] Processing %d requests..." % _queue.size())
	
	var success_count = 0
	var failure_count = 0
	var failed_requests: Array = []
	
	for request in _queue:
		var success = await _execute_request(request)
		
		if success:
			success_count += 1
		else:
			failure_count += 1
			request.retries += 1
			
			if request.retries < MAX_RETRIES:
				failed_requests.append(request)
	
	# Update queue with only failed requests
	_queue = failed_requests
	_save_queue()
	
	_processing = false
	
	print("[Queue] Processed: %d success, %d failed" % [success_count, failure_count])
	queue_processed.emit(success_count, failure_count)
	
	# Retry after delay if there are failed requests
	if not _queue.is_empty():
		_retry_timer.start()

## Execute single request
func _execute_request(request: Dictionary) -> bool:
	print("[Queue] Executing: %s %s (retry %d)" % [request.method, request.endpoint, request.retries])
	
	var result: Dictionary = {}

	# Use GameHTTPClient instance so we can await the HTTP response
	var http_client = GameHTTPClient.new()
	http_client.initialize(self, Network.BASE_URL if has_node("/root/Network") == false else Network.BASE_URL)

	match request.method:
		"GET":
			result = await http_client.http_get(request.endpoint)
		"POST":
			result = await http_client.post(request.endpoint, request.body)
		"PUT":
			result = await http_client.put(request.endpoint, request.body)
		"DELETE":
			result = await http_client.delete(request.endpoint)
		_:
			print("[Queue] Unknown method: %s" % request.method)
			return false
	
	return result.get("success", false)

## Sort queue by priority (higher first) and timestamp (older first)
func _sort_queue() -> void:
	_queue.sort_custom(func(a, b):
		if a.priority != b.priority:
			return a.priority > b.priority
		return a.timestamp < b.timestamp
	)

## Generate unique ID
func _generate_id() -> String:
	return "%d_%s" % [Time.get_unix_time_from_system(), str(randi()).md5_text().substr(0, 8)]

## Save queue to disk
func _save_queue() -> void:
	var file = FileAccess.open(QUEUE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_queue, "\t"))
		file.close()

## Load queue from disk
func _load_queue() -> void:
	if not FileAccess.file_exists(QUEUE_FILE):
		return
	
	var file = FileAccess.open(QUEUE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			_queue = json.data
			print("[Queue] Loaded %d queued requests" % _queue.size())

## Clear queue
func clear_queue() -> void:
	_queue.clear()
	_save_queue()
	print("[Queue] Queue cleared")

## Get queue size
func size() -> int:
	return _queue.size()

## Check if queue is empty
func is_empty() -> bool:
	return _queue.is_empty()

## Retry timer timeout
func _on_retry_timer_timeout() -> void:
	if not _queue.is_empty():
		process_queue()
