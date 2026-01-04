class_name MathUtils
extends RefCounted
## Math Utilities
## Helper functions for mathematical operations

## Clamp value between min and max
static func clamp_int(value: int, min_val: int, max_val: int) -> int:
	return clampi(value, min_val, max_val)

## Lerp between two values
static func lerp_int(from: int, to: int, weight: float) -> int:
	return int(lerp(float(from), float(to), weight))

## Calculate percentage
static func percentage(value: float, total: float) -> float:
	if total == 0:
		return 0.0
	return (value / total) * 100.0

## Calculate percentage (int version)
static func percentage_int(value: int, total: int) -> int:
	if total == 0:
		return 0
	return int((float(value) / float(total)) * 100.0)

## Random range (inclusive)
static func random_range(min_val: int, max_val: int) -> int:
	return randi_range(min_val, max_val)

## Random float range
static func random_float(min_val: float, max_val: float) -> float:
	return randf_range(min_val, max_val)

## Random chance (0.0 to 1.0)
static func random_chance(chance: float) -> bool:
	return randf() < chance

## Random weighted choice
static func weighted_random(weights: Array[float]) -> int:
	var total = 0.0
	for weight in weights:
		total += weight
	
	var rand = randf() * total
	var accumulated = 0.0
	
	for i in weights.size():
		accumulated += weights[i]
		if rand <= accumulated:
			return i
	
	return weights.size() - 1

## Calculate distance between two points
static func distance_2d(x1: float, y1: float, x2: float, y2: float) -> float:
	return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2))

## Calculate Manhattan distance
static func manhattan_distance(x1: int, y1: int, x2: int, y2: int) -> int:
	return abs(x2 - x1) + abs(y2 - y1)

## Round to nearest multiple
static func round_to_multiple(value: float, multiple: float) -> float:
	return round(value / multiple) * multiple

## Format number with separators (e.g., 1,000,000)
static func format_number(value: int, separator: String = ",") -> String:
	var str_value = str(value)
	var result = ""
	var count = 0
	
	for i in range(str_value.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = separator + result
		result = str_value[i] + result
		count += 1
	
	return result

## Format number with K/M/B suffixes
static func format_number_short(value: int) -> String:
	if value < 1000:
		return str(value)
	elif value < 1000000:
		return "%.1fK" % (value / 1000.0)
	elif value < 1000000000:
		return "%.1fM" % (value / 1000000.0)
	else:
		return "%.1fB" % (value / 1000000000.0)

## Calculate compound interest
static func compound_interest(principal: float, rate: float, time: float) -> float:
	return principal * pow(1.0 + rate, time)

## Calculate exponential growth
static func exp_growth(base: float, exponent: float) -> float:
	return base * exp(exponent)

## Calculate level from experience (common RPG formula)
static func level_from_exp(experience: int, base_exp: int = 100, growth_rate: float = 1.15) -> int:
	var level = 1
	var required_exp = base_exp
	var accumulated_exp = 0
	
	while accumulated_exp + required_exp <= experience:
		accumulated_exp += required_exp
		level += 1
		required_exp = int(base_exp * pow(growth_rate, level - 1))
	
	return level

## Calculate experience required for level
static func exp_for_level(level: int, base_exp: int = 100, growth_rate: float = 1.15) -> int:
	var total_exp = 0
	for i in range(1, level):
		total_exp += int(base_exp * pow(growth_rate, i - 1))
	return total_exp

## Ease in cubic
static func ease_in_cubic(t: float) -> float:
	return t * t * t

## Ease out cubic
static func ease_out_cubic(t: float) -> float:
	var f = t - 1.0
	return f * f * f + 1.0

## Ease in-out cubic
static func ease_in_out_cubic(t: float) -> float:
	if t < 0.5:
		return 4.0 * t * t * t
	else:
		var f = 2.0 * t - 2.0
		return 0.5 * f * f * f + 1.0

## Map value from one range to another
static func map_range(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
	return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min)

## Calculate Fibonacci number
static func fibonacci(n: int) -> int:
	if n <= 1:
		return n
	
	var a = 0
	var b = 1
	
	for i in range(2, n + 1):
		var temp = a + b
		a = b
		b = temp
	
	return b

## Calculate factorial
static func factorial(n: int) -> int:
	if n <= 1:
		return 1
	
	var result = 1
	for i in range(2, n + 1):
		result *= i
	
	return result

## Check if number is prime
static func is_prime(n: int) -> bool:
	if n <= 1:
		return false
	if n <= 3:
		return true
	if n % 2 == 0 or n % 3 == 0:
		return false
	
	var i = 5
	while i * i <= n:
		if n % i == 0 or n % (i + 2) == 0:
			return false
		i += 6
	
	return true

## Get sign of number (-1, 0, or 1)
static func sign_int(value: int) -> int:
	if value > 0:
		return 1
	elif value < 0:
		return -1
	else:
		return 0
