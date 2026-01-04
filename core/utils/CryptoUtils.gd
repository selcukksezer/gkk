class_name CryptoUtils
extends RefCounted
## Crypto Utilities
## Encryption, hashing, and security helpers

## Simple XOR encryption (for basic obfuscation, not secure for sensitive data)
static func xor_encrypt(data: String, key: String) -> String:
	if key.is_empty():
		push_error("[CryptoUtils] XOR key cannot be empty")
		return data
	
	var result = ""
	var key_length = key.length()
	
	for i in data.length():
		var data_char = data[i]
		var key_char = key[i % key_length]
		var xor_char = char(data_char.unicode_at(0) ^ key_char.unicode_at(0))
		result += xor_char
	
	return result

## XOR decrypt (same as encrypt for XOR)
static func xor_decrypt(data: String, key: String) -> String:
	return xor_encrypt(data, key)

## Generate SHA-256 hash
static func sha256(data: String) -> String:
	var crypto = HashingContext.new()
	crypto.start(HashingContext.HASH_SHA256)
	crypto.update(data.to_utf8_buffer())
	var hash_result = crypto.finish()
	return hash_result.hex_encode()

## Generate MD5 hash
static func md5(data: String) -> String:
	var crypto = HashingContext.new()
	crypto.start(HashingContext.HASH_MD5)
	crypto.update(data.to_utf8_buffer())
	var hash_result = crypto.finish()
	return hash_result.hex_encode()

## Generate SHA-1 hash
static func sha1(data: String) -> String:
	var crypto = HashingContext.new()
	crypto.start(HashingContext.HASH_SHA1)
	crypto.update(data.to_utf8_buffer())
	var hash_result = crypto.finish()
	return hash_result.hex_encode()

## Generate random bytes
static func random_bytes(count: int) -> PackedByteArray:
	var bytes = PackedByteArray()
	for i in range(count):
		bytes.append(randi() % 256)
	return bytes

## Generate random hex string
static func random_hex(length: int) -> String:
	var bytes = random_bytes(int(ceil(length / 2.0)))
	var hex = bytes.hex_encode()
	return hex.substr(0, length)

## Generate UUID v4
static func generate_uuid() -> String:
	var bytes = random_bytes(16)
	
	# Set version to 4
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	
	# Set variant to RFC 4122
	bytes[8] = (bytes[8] & 0x3F) | 0x80
	
	var hex = bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12)
	]

## Base64 encode
static func base64_encode(data: String) -> String:
	return Marshalls.utf8_to_base64(data)

## Base64 decode
static func base64_decode(data: String) -> String:
	return Marshalls.base64_to_utf8(data)

## URL-safe base64 encode
static func base64url_encode(data: String) -> String:
	var encoded = base64_encode(data)
	encoded = encoded.replace("+", "-")
	encoded = encoded.replace("/", "_")
	encoded = encoded.replace("=", "")
	return encoded

## URL-safe base64 decode
static func base64url_decode(data: String) -> String:
	var decoded = data.replace("-", "+").replace("_", "/")
	# Add padding
	while decoded.length() % 4 != 0:
		decoded += "="
	return base64_decode(decoded)

## Simple obfuscation for save data (Base64 + XOR)
static func obfuscate_save_data(data: String, key: String) -> String:
	var xored = xor_encrypt(data, key)
	return base64_encode(xored)

## Deobfuscate save data
static func deobfuscate_save_data(data: String, key: String) -> String:
	var decoded = base64_decode(data)
	return xor_decrypt(decoded, key)

## Generate device ID
static func generate_device_id() -> String:
	# Combine system info for unique ID
	var os_name = OS.get_name()
	var unique_id = OS.get_unique_id()
	var model_name = OS.get_model_name()
	
	var combined = "%s_%s_%s_%d" % [os_name, unique_id, model_name, Time.get_ticks_msec()]
	return sha256(combined)

## HMAC-SHA256 (for API request signing)
static func hmac_sha256(data: String, key: String) -> String:
	var crypto = HMACContext.new()
	crypto.start(HashingContext.HASH_SHA256, key.to_utf8_buffer())
	crypto.update(data.to_utf8_buffer())
	var signature = crypto.finish()
	return signature.hex_encode()

## Verify HMAC signature
static func verify_hmac(data: String, signature: String, key: String) -> bool:
	var calculated = hmac_sha256(data, key)
	return calculated == signature

## Generate random token
static func generate_token(length: int = 32) -> String:
	var chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var token = ""
	for i in range(length):
		token += chars[randi() % chars.length()]
	return token

## Hash password with salt (simple implementation)
static func hash_password(password: String, salt: String) -> String:
	return sha256(password + salt)

## Verify password hash
static func verify_password(password: String, password_hash: String, salt: String) -> bool:
	return hash_password(password, salt) == password_hash

## Generate salt
static func generate_salt(length: int = 16) -> String:
	return random_hex(length)

## Constant-time string comparison (prevents timing attacks)
static func constant_time_compare(str1: String, str2: String) -> bool:
	if str1.length() != str2.length():
		return false
	
	var result = 0
	for i in str1.length():
		result |= str1.unicode_at(i) ^ str2.unicode_at(i)
	
	return result == 0

## Checksum validation (simple)
static func calculate_checksum(data: String) -> int:
	var sum = 0
	for c in data:
		sum += c.unicode_at(0)
	return sum % 256

## Verify checksum
static func verify_checksum(data: String, checksum: int) -> bool:
	return calculate_checksum(data) == checksum
