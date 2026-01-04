extends HBoxContainer
## Chat Message

@onready var sender_label = $SenderLabel
@onready var message_label = $MessageLabel
@onready var timestamp_label = $TimestampLabel

func set_message(sender: String, message: String, timestamp: String) -> void:
	sender_label.text = sender + ":"
	message_label.text = message
	
	# Format timestamp (show only time)
	var time_str = timestamp.split("T")
	if time_str.size() > 1:
		var time_parts = time_str[1].split(":")
		if time_parts.size() >= 2:
			timestamp_label.text = "%s:%s" % [time_parts[0], time_parts[1]]
