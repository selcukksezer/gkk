class_name StringUtils
extends RefCounted
## String Utilities
## Helper functions for string operations

## Truncate string to max length with ellipsis
static func truncate(text: String, max_length: int, ellipsis: String = "...") -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length - ellipsis.length()) + ellipsis

## Capitalize first letter
static func capitalize_first(text: String) -> String:
	if text.is_empty():
		return text
	return text[0].to_upper() + text.substr(1)

## Title case (capitalize each word)
static func title_case(text: String) -> String:
	var words = text.split(" ")
	var result: Array[String] = []
	
	for word in words:
		if not word.is_empty():
			result.append(capitalize_first(word.to_lower()))
	
	return " ".join(result)

## Snake case to title case (e.g., "hello_world" -> "Hello World")
static func snake_to_title(text: String) -> String:
	var words = text.split("_")
	var result: Array[String] = []
	
	for word in words:
		if not word.is_empty():
			result.append(capitalize_first(word))
	
	return " ".join(result)

## Camel case to title case (e.g., "helloWorld" -> "Hello World")
static func camel_to_title(text: String) -> String:
	var result = ""
	for i in text.length():
		var c = text[i]
		if c == c.to_upper() and i > 0:
			result += " "
		result += c
	return title_case(result)

## Format number with commas (e.g., 1000 -> "1,000")
static func format_number(value: int) -> String:
	var string = str(value)
	var mod = string.length() % 3
	var res = ""
	
	for i in range(0, string.length()):
		if i != 0 and i % 3 == mod:
			res += ","
		res += string[i]
	
	return res

## Format number with K/M/B suffixes (e.g., 1500 -> "1.5K")
static func format_number_short(value: int) -> String:
	if value >= 1_000_000_000:
		return str(snapped(value / 1_000_000_000.0, 0.1)) + "B"
	elif value >= 1_000_000:
		return str(snapped(value / 1_000_000.0, 0.1)) + "M"
	elif value >= 1_000:
		return str(snapped(value / 1_000.0, 0.1)) + "K"
	else:
		return str(value)

## Remove whitespace from both ends
static func trim(text: String) -> String:
	return text.strip_edges()

## Remove all whitespace
static func remove_whitespace(text: String) -> String:
	return text.replace(" ", "").replace("\t", "").replace("\n", "").replace("\r", "")

## Pad string to length with character
static func pad_left(text: String, length: int, pad_char: String = " ") -> String:
	while text.length() < length:
		text = pad_char + text
	return text

static func pad_right(text: String, length: int, pad_char: String = " ") -> String:
	while text.length() < length:
		text = text + pad_char
	return text

## Count occurrences of substring
static func count_substring(text: String, substring: String) -> int:
	var count = 0
	var pos = 0
	while true:
		pos = text.find(substring, pos)
		if pos == -1:
			break
		count += 1
		pos += substring.length()
	return count

## Replace all occurrences (case-sensitive)
static func replace_all(text: String, from: String, to: String) -> String:
	return text.replace(from, to)

## Check if string contains only digits
static func is_numeric(text: String) -> bool:
	if text.is_empty():
		return false
	for c in text:
		if not c.is_valid_int():
			return false
	return true

## Check if string contains only letters
static func is_alpha(text: String) -> bool:
	if text.is_empty():
		return false
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z]+$")
	return regex.search(text) != null

## Check if string contains only alphanumeric characters
static func is_alphanumeric(text: String) -> bool:
	if text.is_empty():
		return false
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9]+$")
	return regex.search(text) != null

## Validate email format
static func is_valid_email(email: String) -> bool:
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")
	return regex.search(email) != null

## Validate username format (alphanumeric, underscore, 3-20 chars)
static func is_valid_username(username: String) -> bool:
	if username.length() < 3 or username.length() > 20:
		return false
	var regex = RegEx.new()
	regex.compile("^[a-zA-Z0-9_]+$")
	return regex.search(username) != null

## Generate random string
static func random_string(length: int, chars: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String:
	var result = ""
	for i in range(length):
		result += chars[randi() % chars.length()]
	return result

## Generate UUID-like string
static func generate_id() -> String:
	return "%08x-%04x-%04x-%04x-%012x" % [
		randi(),
		randi() % 0xFFFF,
		randi() % 0xFFFF,
		randi() % 0xFFFF,
		randi()
	]

## Sanitize string for filename
static func sanitize_filename(text: String) -> String:
	var invalid_chars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|']
	var result = text
	for c in invalid_chars:
		result = result.replace(c, "_")
	return result

## Word wrap text to max line length
static func word_wrap(text: String, max_line_length: int) -> String:
	var words = text.split(" ")
	var lines: Array[String] = []
	var current_line = ""
	
	for word in words:
		if current_line.length() + word.length() + 1 > max_line_length:
			if not current_line.is_empty():
				lines.append(current_line)
			current_line = word
		else:
			if not current_line.is_empty():
				current_line += " "
			current_line += word
	
	if not current_line.is_empty():
		lines.append(current_line)
	
	return "\n".join(lines)

## Extract numbers from string
static func extract_numbers(text: String) -> Array[int]:
	var numbers: Array[int] = []
	var regex = RegEx.new()
	regex.compile("\\d+")
	
	var matches = regex.search_all(text)
	for match in matches:
		numbers.append(int(match.get_string()))
	
	return numbers

## Compare strings (case-insensitive)
static func equals_ignore_case(str1: String, str2: String) -> bool:
	return str1.to_lower() == str2.to_lower()

## Get similarity score between two strings (0.0 to 1.0)
static func similarity(str1: String, str2: String) -> float:
	if str1 == str2:
		return 1.0
	
	if str1.is_empty() or str2.is_empty():
		return 0.0
	
	# Simple similarity using Levenshtein distance
	var len1 = str1.length()
	var len2 = str2.length()
	var max_dist = max(len1, len2)
	var distance = levenshtein_distance(str1, str2)
	
	return 1.0 - (float(distance) / float(max_dist))

## Levenshtein distance (edit distance)
static func levenshtein_distance(str1: String, str2: String) -> int:
	var len1 = str1.length()
	var len2 = str2.length()
	
	var matrix = []
	for i in range(len1 + 1):
		matrix.append([])
		for j in range(len2 + 1):
			matrix[i].append(0)
	
	for i in range(len1 + 1):
		matrix[i][0] = i
	for j in range(len2 + 1):
		matrix[0][j] = j
	
	for i in range(1, len1 + 1):
		for j in range(1, len2 + 1):
			var cost = 0 if str1[i - 1] == str2[j - 1] else 1
			matrix[i][j] = min(
				matrix[i - 1][j] + 1,      # deletion
				matrix[i][j - 1] + 1,      # insertion
				matrix[i - 1][j - 1] + cost  # substitution
			)
	
	return matrix[len1][len2]
