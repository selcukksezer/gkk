class_name DateTimeUtils
extends RefCounted
## DateTime Utilities
## Helper functions for date/time operations

## Get current Unix timestamp
static func now() -> int:
	return Time.get_unix_time_from_system()

## Format Unix timestamp to readable string
static func format_timestamp(timestamp: int, format: String = "%Y-%m-%d %H:%M:%S") -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return format.format(datetime)

## Get time difference in seconds
static func time_diff(timestamp1: int, timestamp2: int) -> int:
	return abs(timestamp1 - timestamp2)

## Check if timestamp is in the past
static func is_past(timestamp: int) -> bool:
	return timestamp < now()

## Check if timestamp is in the future
static func is_future(timestamp: int) -> bool:
	return timestamp > now()

## Get seconds until timestamp
static func seconds_until(timestamp: int) -> int:
	var diff = timestamp - now()
	return max(0, diff)

## Get seconds since timestamp
static func seconds_since(timestamp: int) -> int:
	return now() - timestamp

## Format duration in seconds to human readable
static func format_duration(seconds: int) -> String:
	if seconds < 60:
		return "%d saniye" % seconds
	elif seconds < 3600:
		var minutes = seconds / 60
		var secs = seconds % 60
		if secs > 0:
			return "%d dakika %d saniye" % [minutes, secs]
		return "%d dakika" % minutes
	elif seconds < 86400:
		var hours = seconds / 3600
		var minutes = (seconds % 3600) / 60
		if minutes > 0:
			return "%d saat %d dakika" % [hours, minutes]
		return "%d saat" % hours
	else:
		var days = seconds / 86400
		var hours = (seconds % 86400) / 3600
		if hours > 0:
			return "%d gün %d saat" % [days, hours]
		return "%d gün" % days

## Format duration (short version)
static func format_duration_short(seconds: int) -> String:
	if seconds < 60:
		return "%ds" % seconds
	elif seconds < 3600:
		return "%dm" % (seconds / 60)
	elif seconds < 86400:
		return "%dh" % (seconds / 3600)
	else:
		return "%dd" % (seconds / 86400)

## Get time ago string (e.g., "5 minutes ago")
static func time_ago(timestamp: int) -> String:
	var diff = seconds_since(timestamp)
	
	if diff < 60:
		return "%d saniye önce" % diff
	elif diff < 3600:
		return "%d dakika önce" % (diff / 60)
	elif diff < 86400:
		return "%d saat önce" % (diff / 3600)
	elif diff < 604800:  # 7 days
		return "%d gün önce" % (diff / 86400)
	else:
		return format_timestamp(timestamp, "%d/%m/%Y")

## Check if two timestamps are on the same day
static func is_same_day(timestamp1: int, timestamp2: int) -> bool:
	var dt1 = Time.get_datetime_dict_from_unix_time(timestamp1)
	var dt2 = Time.get_datetime_dict_from_unix_time(timestamp2)
	return dt1.year == dt2.year and dt1.month == dt2.month and dt1.day == dt2.day

## Check if timestamp is today
static func is_today(timestamp: int) -> bool:
	return is_same_day(timestamp, now())

## Get start of day timestamp
static func start_of_day(timestamp: int) -> int:
	var dt = Time.get_datetime_dict_from_unix_time(timestamp)
	dt.hour = 0
	dt.minute = 0
	dt.second = 0
	return Time.get_unix_time_from_datetime_dict(dt)

## Get end of day timestamp
static func end_of_day(timestamp: int) -> int:
	var dt = Time.get_datetime_dict_from_unix_time(timestamp)
	dt.hour = 23
	dt.minute = 59
	dt.second = 59
	return Time.get_unix_time_from_datetime_dict(dt)

## Get days between two timestamps
static func days_between(timestamp1: int, timestamp2: int) -> int:
	return int(abs(timestamp1 - timestamp2) / 86400)

## Add days to timestamp
static func add_days(timestamp: int, days: int) -> int:
	return timestamp + (days * 86400)

## Add hours to timestamp
static func add_hours(timestamp: int, hours: int) -> int:
	return timestamp + (hours * 3600)

## Add minutes to timestamp
static func add_minutes(timestamp: int, minutes: int) -> int:
	return timestamp + (minutes * 60)

## Check if cooldown has expired
static func is_cooldown_ready(last_use: int, cooldown_seconds: int) -> bool:
	return seconds_since(last_use) >= cooldown_seconds

## Get remaining cooldown time
static func remaining_cooldown(last_use: int, cooldown_seconds: int) -> int:
	var elapsed = seconds_since(last_use)
	return max(0, cooldown_seconds - elapsed)

## Format cooldown remaining
static func format_cooldown(last_use: int, cooldown_seconds: int) -> String:
	var remaining = remaining_cooldown(last_use, cooldown_seconds)
	if remaining == 0:
		return "Hazır"
	return format_duration(remaining)

## Get UTC offset in seconds
static func get_utc_offset() -> int:
	var local = Time.get_unix_time_from_system()
	var utc = Time.get_unix_time_from_datetime_string(Time.get_datetime_string_from_system(true))
	return local - utc

## Convert timestamp to ISO 8601 string
static func to_iso8601(timestamp: int) -> String:
	return Time.get_datetime_string_from_unix_time(timestamp, true)

## Parse ISO 8601 string to timestamp
static func from_iso8601(iso_string: String) -> int:
	return Time.get_unix_time_from_datetime_string(iso_string)
