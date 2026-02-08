extends Control

## Prison Screen
## Displays prison status and allows release via bail.

@onready var reason_label: Label = %ReasonLabel
@onready var timer_label: Label = %TimerLabel
@onready var bail_button: Button = %BailButton
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton
@onready var description_label: Label = %DescriptionLabel
@onready var gems_label: Label = %GemsLabel
@onready var icon_label: Label = %IconLabel
@onready var progress_bar: ProgressBar = %ProgressBar

var timer: Timer
var initial_prison_time: int = 0

func _ready() -> void:
	# Setup Timer for updating countdown
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Connect signals
	if bail_button:
		bail_button.pressed.connect(_on_bail_button_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	if PrisonManager:
		PrisonManager.prison_released.connect(_on_prison_released)
	if State:
		State.player_updated.connect(_on_player_updated)
		State.state_changed.connect(_on_state_changed)
	
	# Initial update
	_update_ui()
	
	# Start timer after UI is ready
	timer.start()
	print("[PrisonScreen] Timer started, in_prison: ", State.in_prison)

func _on_timer_timeout() -> void:
	# Only update if visible
	if not visible:
		return
		
	_update_ui()
	# Check if released automatically
	State.check_prison_status()

func _update_ui() -> void:
	if not State.in_prison:
		if status_label:
			status_label.text = "✅ Şu anda özgürsünüz!"
			status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		if reason_label:
			reason_label.text = "Burada işiniz yok."
		if timer_label:
			timer_label.text = ""
		if description_label:
			description_label.text = "Gölge Ekonomi'de hukuk ve düzen sağlanıyor. Yasalara uyduğunuz sürece özgürsünüz!"
		if bail_button:
			bail_button.text = "Kefalet (Gerekmiyor)"
			bail_button.disabled = true
		if icon_label:
			icon_label.text = "👍"
		if progress_bar:
			progress_bar.value = 0
			progress_bar.visible = false
		visible = true
		return
	
	visible = true
	
	# In prison
	if icon_label:
		icon_label.text = "👮"
	
	if status_label:
		status_label.text = "⛓️ HAPİSHANESİNİZ!"
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	
	if reason_label:
		reason_label.text = "📄 Gerekçe: " + State.prison_reason
	
	# Update initial_prison_time if not set or if prison time changed
	if initial_prison_time == 0 or not State.in_prison:
		initial_prison_time = int(State.prison_release_time - Time.get_unix_time_from_system())
	
	var remaining_sec = State.get_prison_remaining_seconds()
	var mins = remaining_sec / 60
	var secs = remaining_sec % 60
	
	if timer_label:
		timer_label.text = "⏱️ Kalan Süre: %02d:%02d" % [mins, secs]
	
	# Update progress bar
	if progress_bar and initial_prison_time > 0:
		progress_bar.visible = true
		var progress = 1.0 - (float(remaining_sec) / float(initial_prison_time))
		progress_bar.value = progress * 100
	
	# Update Bail Cost
	var gems_needed = max(1, ceil(remaining_sec / 60.0))
	
	if gems_label:
		gems_label.text = "💎 Mevcut: %d Elmas" % State.gems
	
	if description_label:
		description_label.text = "Yasalara aykırı davranışlar nedeniyle hapishanedesiniz. Kefalet ödeyerek erken çıkabilir veya sürenizi tamamlayabilirsiniz."
	
	if bail_button:
		bail_button.text = "💰 Kefalet Öde (%d Elmas)" % gems_needed
		
		if State.gems < gems_needed:
			bail_button.disabled = true
			bail_button.tooltip_text = "Yeterli elmasınız yok! (%d / %d)" % [State.gems, gems_needed]
		else:
			bail_button.disabled = false
			bail_button.tooltip_text = "Kefalet ödeyerek hemen serbest kalın"

func _on_bail_button_pressed() -> void:
	if bail_button:
		bail_button.disabled = true
	if status_label:
		status_label.text = "⏳ İşlem yapılıyor..."
	if PrisonManager:
		PrisonManager.pay_bail()

func _on_back_button_pressed() -> void:
	if get_tree() and get_tree().root:
		var main = get_tree().root.get_node_or_null("Main")
		if main and main.has_method("go_back"):
			main.go_back()

func _on_prison_released(success: bool, message: String) -> void:
	if success:
		if status_label:
			status_label.text = "✅ Tahliye Edildiniz!"
			status_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5))
		if description_label:
			description_label.text = "Kefalet ödendiniz. Artık özgürsünüz!"
		await get_tree().create_timer(2.0).timeout
		_update_ui()
	else:
		if status_label:
			status_label.text = "❌ Hata: " + message
			status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		if bail_button:
			bail_button.disabled = false

func _on_player_updated() -> void:
	# Player data updated, refresh UI
	_update_ui()

func _on_state_changed(key: String, value: Variant) -> void:
	# React immediately to prison state changes
	if key == "prison":
		print("[PrisonScreen] Prison state changed: %s" % value)
		_update_ui()
