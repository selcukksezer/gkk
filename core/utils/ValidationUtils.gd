class_name ValidationUtils
extends RefCounted
## Validation Utilities
## Input validation and sanitation helpers

## Validation result
class ValidationResult:
	var is_valid: bool = false
	var error_message: String = ""
	var error_code: String = ""
	
	func _init(valid: bool = false, message: String = "", code: String = "") -> void:
		is_valid = valid
		error_message = message
		error_code = code
	
	static func success() -> ValidationResult:
		return ValidationResult.new(true)
	
	static func error(message: String, code: String = "") -> ValidationResult:
		return ValidationResult.new(false, message, code)

## Validate username
static func validate_username(username: String) -> ValidationResult:
	if username.is_empty():
		return ValidationResult.error("Kullanıcı adı boş olamaz", "EMPTY_USERNAME")
	
	if username.length() < 3:
		return ValidationResult.error("Kullanıcı adı en az 3 karakter olmalı", "USERNAME_TOO_SHORT")
    
	if username.length() > 40:
		return ValidationResult.error("Kullanıcı adı en fazla 40 karakter olabilir", "USERNAME_TOO_LONG")
	
	if not StringUtils.is_valid_username(username):
		return ValidationResult.error("Kullanıcı adı sadece harf, rakam ve alt çizgi içerebilir", "INVALID_USERNAME_FORMAT")
	
	return ValidationResult.success()

## Validate email
static func validate_email(email: String) -> ValidationResult:
	if email.is_empty():
		return ValidationResult.error("E-posta adresi boş olamaz", "EMPTY_EMAIL")
	
	if not StringUtils.is_valid_email(email):
		return ValidationResult.error("Geçersiz e-posta formatı", "INVALID_EMAIL_FORMAT")
	
	return ValidationResult.success()

## Validate password
static func validate_password(password: String) -> ValidationResult:
	if password.is_empty():
		return ValidationResult.error("Şifre boş olamaz", "EMPTY_PASSWORD")
	
	if password.length() < 8:
		return ValidationResult.error("Şifre en az 8 karakter olmalı", "PASSWORD_TOO_SHORT")
	
	if password.length() > 128:
		return ValidationResult.error("Şifre en fazla 128 karakter olabilir", "PASSWORD_TOO_LONG")
	
	# Check for at least one letter
	var has_letter = false
	var has_digit = false
	
	for c in password:
		if c.is_valid_int():
			has_digit = true
		else:
			has_letter = true
	
	if not has_letter or not has_digit:
		return ValidationResult.error("Şifre en az bir harf ve bir rakam içermelidir", "PASSWORD_TOO_WEAK")
	
	return ValidationResult.success()

## Validate integer range
static func validate_int_range(value: int, min_val: int, max_val: int, field_name: String = "Değer") -> ValidationResult:
	if value < min_val:
		return ValidationResult.error("%s en az %d olmalı" % [field_name, min_val], "VALUE_TOO_LOW")
	
	if value > max_val:
		return ValidationResult.error("%s en fazla %d olabilir" % [field_name, max_val], "VALUE_TOO_HIGH")
	
	return ValidationResult.success()

## Validate float range
static func validate_float_range(value: float, min_val: float, max_val: float, field_name: String = "Değer") -> ValidationResult:
	if value < min_val:
		return ValidationResult.error("%s en az %.2f olmalı" % [field_name, min_val], "VALUE_TOO_LOW")
	
	if value > max_val:
		return ValidationResult.error("%s en fazla %.2f olabilir" % [field_name, max_val], "VALUE_TOO_HIGH")
	
	return ValidationResult.success()

## Validate string length
static func validate_string_length(text: String, min_length: int, max_length: int, field_name: String = "Metin") -> ValidationResult:
	if text.length() < min_length:
		return ValidationResult.error("%s en az %d karakter olmalı" % [field_name, min_length], "TEXT_TOO_SHORT")
	
	if text.length() > max_length:
		return ValidationResult.error("%s en fazla %d karakter olabilir" % [field_name, max_length], "TEXT_TOO_LONG")
	
	return ValidationResult.success()

## Validate not empty
static func validate_not_empty(text: String, field_name: String = "Alan") -> ValidationResult:
	if text.is_empty() or text.strip_edges().is_empty():
		return ValidationResult.error("%s boş olamaz" % field_name, "EMPTY_FIELD")
	
	return ValidationResult.success()

## Validate price/amount
static func validate_amount(amount: int, min_amount: int = 1, max_amount: int = 999999999) -> ValidationResult:
	if amount < min_amount:
		return ValidationResult.error("Miktar en az %d olmalı" % min_amount, "AMOUNT_TOO_LOW")
	
	if amount > max_amount:
		return ValidationResult.error("Miktar en fazla %d olabilir" % max_amount, "AMOUNT_TOO_HIGH")
	
	return ValidationResult.success()

## Validate guild name
static func validate_guild_name(name: String) -> ValidationResult:
	if name.is_empty():
		return ValidationResult.error("Lonca adı boş olamaz", "EMPTY_GUILD_NAME")
	
	if name.length() < 3:
		return ValidationResult.error("Lonca adı en az 3 karakter olmalı", "GUILD_NAME_TOO_SHORT")
	
	if name.length() > 30:
		return ValidationResult.error("Lonca adı en fazla 30 karakter olabilir", "GUILD_NAME_TOO_LONG")
	
	return ValidationResult.success()

## Validate guild tag
static func validate_guild_tag(tag: String) -> ValidationResult:
	if tag.is_empty():
		return ValidationResult.error("Lonca etiketi boş olamaz", "EMPTY_GUILD_TAG")
	
	if tag.length() < 2:
		return ValidationResult.error("Lonca etiketi en az 2 karakter olmalı", "GUILD_TAG_TOO_SHORT")
	
	if tag.length() > 5:
		return ValidationResult.error("Lonca etiketi en fazla 5 karakter olabilir", "GUILD_TAG_TOO_LONG")
	
	if not StringUtils.is_alphanumeric(tag):
		return ValidationResult.error("Lonca etiketi sadece harf ve rakam içerebilir", "INVALID_GUILD_TAG")
	
	return ValidationResult.success()

## Sanitize text input
static func sanitize_text(text: String, max_length: int = 1000) -> String:
	# Remove control characters
	var sanitized = ""
	for c in text:
		var code = c.unicode_at(0)
		if code >= 32 and code != 127:  # Printable characters
			sanitized += c
	
	# Trim whitespace
	sanitized = sanitized.strip_edges()
	
	# Truncate to max length
	if sanitized.length() > max_length:
		sanitized = sanitized.substr(0, max_length)
	
	return sanitized

## Sanitize username
static func sanitize_username(username: String) -> String:
	var sanitized = ""
	for c in username:
		if c.is_valid_identifier() or c == "_":
			sanitized += c
	return sanitized.substr(0, 40)

## Check for profanity (basic implementation)
static func contains_profanity(text: String) -> bool:
	var profanity_list = [
		# Add Turkish/English profanity words here
		# This is a placeholder - implement proper filtering
	]
	
	var lower_text = text.to_lower()
	for word in profanity_list:
		if lower_text.contains(word):
			return true
	
	return false

## Validate JSON structure
static func validate_json(json_string: String) -> ValidationResult:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return ValidationResult.error("Geçersiz JSON formatı", "INVALID_JSON")
	
	return ValidationResult.success()

## Validate required fields in dictionary
static func validate_required_fields(data: Dictionary, required_fields: Array[String]) -> ValidationResult:
	for field in required_fields:
		if not data.has(field):
			return ValidationResult.error("Gerekli alan eksik: %s" % field, "MISSING_FIELD")
	
	return ValidationResult.success()

## Validate enum value
static func validate_enum(value: String, valid_values: Array[String], field_name: String = "Değer") -> ValidationResult:
	if value not in valid_values:
		return ValidationResult.error("%s geçersiz. Geçerli değerler: %s" % [field_name, ", ".join(valid_values)], "INVALID_ENUM")
	
	return ValidationResult.success()
