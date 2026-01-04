extends Control
## Tolerance Bar Component
## Displays potion tolerance/addiction level

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label
@onready var status_label: Label = $StatusLabel
@onready var warning_icon: TextureRect = $WarningIcon

var max_tolerance: int = 100

func _ready() -> void:
	max_tolerance = GameConfig.get_config("potion", "max_tolerance", 100)
	_update_display()

func _update_display() -> void:
	var tolerance = State.tolerance
	
	if progress_bar:
		progress_bar.max_value = max_tolerance
		progress_bar.value = tolerance
		
		# Color based on tolerance level
		var stylebox: StyleBoxFlat
		if tolerance >= 80:
			stylebox = _create_stylebox(Color.RED)
		elif tolerance >= 60:
			stylebox = _create_stylebox(Color.ORANGE)
		elif tolerance >= 30:
			stylebox = _create_stylebox(Color.YELLOW)
		else:
			stylebox = _create_stylebox(Color.GREEN)
		
		progress_bar.add_theme_stylebox_override("fill", stylebox)
	
	if label:
		label.text = "%d / %d" % [tolerance, max_tolerance]
	
	if status_label:
		status_label.text = _get_status_text(tolerance)
		status_label.add_theme_color_override("font_color", _get_status_color(tolerance))
	
	if warning_icon:
		warning_icon.visible = tolerance >= 60

func _create_stylebox(color: Color) -> StyleBoxFlat:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = color
	stylebox.corner_radius_top_left = 4
	stylebox.corner_radius_top_right = 4
	stylebox.corner_radius_bottom_left = 4
	stylebox.corner_radius_bottom_right = 4
	return stylebox

func _get_status_text(tolerance: int) -> String:
	if tolerance >= 80:
		return "⚠️ Ağır Bağımlı"
	elif tolerance >= 60:
		return "⚠️ Bağımlı"
	elif tolerance >= 30:
		return "Hafif Tolerans"
	else:
		return "✓ Sağlıklı"

func _get_status_color(tolerance: int) -> Color:
	if tolerance >= 80:
		return Color.RED
	elif tolerance >= 60:
		return Color.ORANGE
	elif tolerance >= 30:
		return Color.YELLOW
	else:
		return Color.GREEN

func update_tolerance(new_tolerance: int) -> void:
	State.tolerance = new_tolerance
	_update_display()

## Show detailed info
func show_info() -> void:
	var tolerance = State.tolerance
	var overdose_risk = _calculate_overdose_risk(tolerance)
	var effectiveness = _calculate_effectiveness(tolerance)
	
	var info_text = """
	Tolerans: %d/%d
	
	Durum: %s
	İksir Etkisi: %%%d
	Overdose Riski: %%%d
	
	%s
	""" % [
		tolerance,
		max_tolerance,
		_get_status_text(tolerance),
		int(effectiveness * 100),
		int(overdose_risk * 100),
		_get_advice(tolerance)
	]
	
	# Show dialog
	var dialog_scene = load("res://scenes/ui/dialogs/InfoDialog.tscn")
	if dialog_scene:
		get_tree().root.get_node("Main").show_dialog(dialog_scene, {
			"title": "Bağımlılık Durumu",
			"message": info_text
		})

func _calculate_overdose_risk(tolerance: int) -> float:
	if tolerance < 60:
		return 0.0
	elif tolerance < 80:
		return 0.05 + (tolerance - 60) * 0.0075  # 5-20%
	else:
		return 0.20 + (tolerance - 80) * 0.01  # 20-40%

func _calculate_effectiveness(tolerance: int) -> float:
	if tolerance < 30:
		return 1.0  # 100%
	elif tolerance < 60:
		return 0.8  # 80%
	elif tolerance < 80:
		return 0.5  # 50%
	else:
		return 0.2  # 20%

func _get_advice(tolerance: int) -> String:
	if tolerance >= 80:
		return "⚠️ ÇOK TEHLİKELİ! Derhal iksir kullanmayı bırakın veya antidot alın."
	elif tolerance >= 60:
		return "⚠️ Dikkat! İksir bağımlılığınız yüksek. Antidot kullanmayı düşünün."
	elif tolerance >= 30:
		return "İksir kullanımınızı azaltmanız önerilir."
	else:
		return "İksir kullanımınız güvenli seviyelerde."
