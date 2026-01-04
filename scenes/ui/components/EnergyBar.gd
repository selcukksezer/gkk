extends Control
## Energy Bar Component
## Reusable energy display with regeneration indicator

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label
@onready var regen_timer_label: Label = $RegenTimerLabel

var show_timer: bool = true
var next_regen_time: int = 0

func _ready() -> void:
	State.energy_updated.connect(_update_display)
	_update_display()
	
	if show_timer:
		_start_timer_update()

func _update_display() -> void:
	if progress_bar:
		progress_bar.max_value = State.max_energy
		progress_bar.value = State.current_energy
		
		# Color gradient based on energy level
		var ratio = float(State.current_energy) / float(State.max_energy)
		if ratio >= 1.0:
			progress_bar.add_theme_stylebox_override("fill", _create_stylebox(Color.GOLD))
		elif ratio >= 0.75:
			progress_bar.add_theme_stylebox_override("fill", _create_stylebox(Color.GREEN))
		elif ratio >= 0.5:
			progress_bar.add_theme_stylebox_override("fill", _create_stylebox(Color.YELLOW))
		elif ratio >= 0.25:
			progress_bar.add_theme_stylebox_override("fill", _create_stylebox(Color.ORANGE))
		else:
			progress_bar.add_theme_stylebox_override("fill", _create_stylebox(Color.RED))
	
	if label:
		label.text = "%d / %d" % [State.current_energy, State.max_energy]

func _create_stylebox(color: Color) -> StyleBoxFlat:
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = color
	stylebox.corner_radius_top_left = 4
	stylebox.corner_radius_top_right = 4
	stylebox.corner_radius_bottom_left = 4
	stylebox.corner_radius_bottom_right = 4
	return stylebox

func _start_timer_update() -> void:
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_timer_display)
	add_child(timer)
	timer.start()

func _update_timer_display() -> void:
	if not show_timer or not regen_timer_label:
		return
	
	if State.current_energy >= State.max_energy:
		regen_timer_label.text = "Dolu"
		return
	
	# Calculate next regen time (180 seconds = 3 minutes)
	var regen_interval = GameConfig.get_config("energy", "regen_interval", 180)
	var elapsed_since_last = Time.get_unix_time_from_system() - State.player.last_energy_regen
	var remaining = regen_interval - (elapsed_since_last % regen_interval)
	
	var minutes = int(remaining / 60)
	var seconds = int(remaining % 60)
	
	regen_timer_label.text = "%d:%02d" % [minutes, seconds]

## Public methods
func set_show_timer(should_show: bool) -> void:
	show_timer = should_show
	if regen_timer_label:
		regen_timer_label.visible = should_show
