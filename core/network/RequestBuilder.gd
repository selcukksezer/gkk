class_name RequestBuilder
extends RefCounted
## Request Builder - Helper for building API requests
## Provides a fluent interface for constructing requests

var _method: HTTPClient.Method = HTTPClient.METHOD_GET
var _endpoint: String = ""
var _headers: Dictionary = {}
var _body: Dictionary = {}
var _query_params: Dictionary = {}
var _timeout: float = 30.0

## Set HTTP method
func method(m: HTTPClient.Method) -> RequestBuilder:
	_method = m
	return self

## Set endpoint
func endpoint(ep: String) -> RequestBuilder:
	_endpoint = ep
	return self

## Add header
func header(key: String, value: String) -> RequestBuilder:
	_headers[key] = value
	return self

## Add multiple headers
func headers(h: Dictionary) -> RequestBuilder:
	_headers.merge(h)
	return self

## Set body
func body(b: Dictionary) -> RequestBuilder:
	_body = b
	return self

## Add body parameter
func param(key: String, value: Variant) -> RequestBuilder:
	_body[key] = value
	return self

## Add query parameter
func query(key: String, value: Variant) -> RequestBuilder:
	_query_params[key] = value
	return self

## Add multiple query parameters
func queries(q: Dictionary) -> RequestBuilder:
	_query_params.merge(q)
	return self

## Set timeout
func timeout(t: float) -> RequestBuilder:
	_timeout = t
	return self

## Build the request dictionary
func build() -> Dictionary:
	var full_endpoint = _endpoint
	
	# Add query parameters
	if not _query_params.is_empty():
		full_endpoint += APIEndpoints.build_query_string(_query_params)
	
	return {
		"method": _method,
		"endpoint": full_endpoint,
		"headers": _headers,
		"body": _body,
		"timeout": _timeout
	}

## Execute the request (DEPRECATED - use Network directly)
## Note: NetworkManager methods return void, not Dictionary
func execute() -> Dictionary:
	push_warning("[RequestBuilder] execute() is deprecated - NetworkManager uses callbacks")
	return {"success": false, "error": "Use Network methods directly with callbacks"}

## Factory methods for common request types

## Create GET request
static func create_get(url_endpoint: String) -> RequestBuilder:
	var builder = RequestBuilder.new()
	return builder.method(HTTPClient.METHOD_GET).endpoint(url_endpoint)

## Create POST request
static func post(url_endpoint: String) -> RequestBuilder:
	var builder = RequestBuilder.new()
	return builder.method(HTTPClient.METHOD_POST).endpoint(url_endpoint)

## Create PUT request
static func put(url_endpoint: String) -> RequestBuilder:
	var builder = RequestBuilder.new()
	return builder.method(HTTPClient.METHOD_PUT).endpoint(url_endpoint)

## Create DELETE request
static func delete(url_endpoint: String) -> RequestBuilder:
	var builder = RequestBuilder.new()
	return builder.method(HTTPClient.METHOD_DELETE).endpoint(url_endpoint)

## Example usage:
## var result = await RequestBuilder.get(APIEndpoints.PLAYER_PROFILE)
##     .query("player_id", "123")
##     .header("X-Custom-Header", "value")
##     .execute()
