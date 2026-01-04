extends HBoxContainer
## Production Queue Item

@onready var recipe_name = $RecipeName
@onready var progress_bar = $ProgressBar
@onready var time_remaining = $TimeRemaining

var _start_time: int = 0
var _duration: int = 0
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	add_child(_timer)
	_timer.timeout.connect(_update_progress)
	_timer.wait_time = 1.0
	_timer.autostart = true

func set_data(data: Dictionary) -> void:
	recipe_name.text = data.get("recipe_name", "Unknown Recipe")
	
	# Parse timestamps
	var started_at = data.get("started_at", "")
	var completes_at = data.get("completes_at", "")
	
	_start_time = _parse_timestamp(started_at)
	var complete_time = _parse_timestamp(completes_at)
	_duration = complete_time - _start_time
	
	_update_progress()

func _parse_timestamp(iso_string: String) -> int:
	var datetime = Time.get_datetime_dict_from_datetime_string(iso_string, true)
	return Time.get_unix_time_from_datetime_dict(datetime)

func _update_progress() -> void:
	var current_time = Time.get_unix_time_from_system()
	var elapsed = current_time - _start_time
	var remaining = _duration - elapsed
	
	if remaining <= 0:
		progress_bar.value = 100
		time_remaining.text = "Complete!"
		_timer.stop()
		return
	
	var progress_percent = (float(elapsed) / float(_duration)) * 100.0
	progress_bar.value = progress_percent
	
	# Format time remaining
	var minutes = int(remaining / 60)
	var seconds = int(remaining % 60)
	time_remaining.text = "%d:%02d" % [minutes, seconds]
