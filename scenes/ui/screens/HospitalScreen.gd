extends Control
## Hospital Screen - Hastanelik yönetimi
## Geri sayım, elmas ile tedavi, doğal iyileşme

@onready var title_label: Label = %TitleLabel
@onready var release_time_label: Label = %ReleaseTimeLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var countdown_timer: Timer = Timer.new()
@onready var release_gems_button: Button = %ReleaseGemsButton
@onready var gem_cost_label: Label = %GemCostLabel
@onready var reason_label: Label = %ReasonLabel
@onready var back_button: Button = %BackButton
@onready var energy_label: Label = get_node_or_null("%EnergyLabel")

var hospital_release_time: int = 0  # Unix timestamp
var hospitalized_reason: String = "Zindan başarısızlığı"

func _ready() -> void:
	print("[HospitalScreen] Ready")
	
	# Geri sayım timer'ı
	countdown_timer.timeout.connect(_on_countdown_tick)
	add_child(countdown_timer)
	countdown_timer.wait_time = 1.0  # Her saniye güncelle
	
	# Button bağlantıları
	if release_gems_button:
		release_gems_button.pressed.connect(_on_release_with_gems_pressed)
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)
	
	# State sinyali
	if State:
		State.player_updated.connect(_on_player_updated)
		State.energy_updated.connect(_on_energy_updated)
	
	# İlk yükleme (AWAIT ZORUNLU - asynchronous işlem)
	await _load_hospital_status()
	
	# Yükleme bittikten sonra enerji gösterimini güncelle
	call_deferred("_update_energy_display")
	_start_countdown()

func _load_hospital_status() -> void:
	if not State:
		push_error("[HospitalScreen] State not available")
		return
	
	# Fetch fresh data from server instead of using State cache
	var hospital_mgr = HospitalManager.new()
	var status_result = await hospital_mgr.fetch_hospital_status()
	
	print("[HospitalScreen] Status result: %s" % status_result)
	
	if status_result.success and status_result.in_hospital:
		hospital_release_time = status_result.release_time
		hospitalized_reason = status_result.get("reason", "Zindan başarısızlığı")
		title_label.text = "Hastanede"
		print("[HospitalScreen] Loaded - in hospital until %d, reason: %s" % [hospital_release_time, hospitalized_reason])
	else:
		print("[HospitalScreen] Loaded - not in hospital (success=%s, in_hospital=%s)" % [status_result.success, status_result.get("in_hospital", false)])
		title_label.text = "Hastane"
		reason_label.text = "Sağlıksınız!"
		release_time_label.text = ""
		countdown_label.text = ""
		release_gems_button.disabled = true

func _start_countdown() -> void:
	if State.in_hospital and hospital_release_time > 0:
		countdown_timer.start()
		_on_countdown_tick()  # İlk güncelleme
	else:
		countdown_timer.stop()

func _on_countdown_tick() -> void:
	if not State.in_hospital or hospital_release_time <= 0:
		countdown_timer.stop()
		return
	
	var current_time = int(Time.get_unix_time_from_system())
	var remaining_seconds = hospital_release_time - current_time
	
	if remaining_seconds <= 0:
		# Hastaneden çıkmış
		countdown_timer.stop()
		State.set_hospital_status(false, 0)
		title_label.text = "Hastaneden Çıktınız!"
		reason_label.text = "Iyileştiniz ve artık aktivitelere katılabilirsiniz."
		countdown_label.text = ""
		release_time_label.text = ""
		release_gems_button.disabled = true
		return
	
	# Geri sayımı göster
	var hours = int(remaining_seconds / 3600.0)
	var minutes = int((remaining_seconds % 3600) / 60.0)
	var seconds = int(remaining_seconds % 60)
	
	countdown_label.text = "Kalan Süre: %dh %dm %ds" % [hours, minutes, seconds]
	reason_label.text = "Neden: %s" % hospitalized_reason
	
	# Elmas maliyeti: saat + dakika sayısı kadar elmas
	var gem_hours = int(remaining_seconds / 3600.0)
	var gem_minutes = ceil(fmod(float(remaining_seconds), 3600.0) / 60.0)
	var gem_cost = gem_hours + int(gem_minutes)
	gem_cost_label.text = "Elmas ile Çık: %d💎" % gem_cost
	
	# Release time label
	var release_datetime = Time.get_datetime_dict_from_unix_time(hospital_release_time)
	release_time_label.text = "Taburcu Tarihi: %04d-%02d-%02d %02d:%02d:%02d" % [
		release_datetime.year, release_datetime.month, release_datetime.day,
		release_datetime.hour, release_datetime.minute, release_datetime.second
	]

func _on_release_with_gems_pressed() -> void:
	if not State.in_hospital:
		push_warning("[HospitalScreen] Not in hospital")
		return
	
	# Önce emin misiniz dialogu göster
	_show_confirm_release_dialog()

func _show_confirm_release_dialog() -> void:
	print("[HospitalScreen] Showing confirm release dialog")
	var confirm_dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
	if confirm_dialog_scene:
		print("[HospitalScreen] ConfirmDialog scene loaded")
		var main = get_tree().root.get_node_or_null("Main")
		if main and main.has_method("show_dialog"):
			print("[HospitalScreen] Using Main.show_dialog")
			var current_time = int(Time.get_unix_time_from_system())
			var remaining_seconds = hospital_release_time - current_time
			var gem_hours = int(remaining_seconds / 3600.0)
			var gem_minutes = ceil(fmod(float(remaining_seconds), 3600.0) / 60.0)
			var gem_cost = gem_hours + int(gem_minutes)
			
			main.show_dialog(confirm_dialog_scene, {
				"title": "Emin misiniz?",
				"message": "Hastaneden çıkmak için %d elmas harcayacak. Devam etmek istiyor musunuz?" % gem_cost,
				"confirm_text": "Evet, Çık",
				"cancel_text": "İptal",
				"on_confirm": Callable(self, "_on_confirm_release_with_gems"),
				"on_cancel": Callable(self, "_on_cancel_release")
			})
		else:
			print("[HospitalScreen] Main.show_dialog not available")
	else:
		print("[HospitalScreen] Failed to load ConfirmDialog scene")

func _on_confirm_release_with_gems() -> void:
	print("[HospitalScreen] Confirmed release with gems")
	
	# Button'u hemen devre dışı bırak - çoklu tıklamayı engelle
	release_gems_button.disabled = true
	
	var current_time = int(Time.get_unix_time_from_system())
	var remaining_seconds = hospital_release_time - current_time
	var gem_hours = int(remaining_seconds / 3600.0)
	var gem_minutes = ceil(fmod(float(remaining_seconds), 3600.0) / 60.0)
	var gem_cost = gem_hours + int(gem_minutes)
	
	var player_gems = State.gems
	if player_gems < gem_cost:
		release_gems_button.disabled = false
		_show_insufficient_gems_dialog("Hastaneden çıkmak için %d elmas gerekli. Şu anki: %d" % [gem_cost, player_gems])
		return
	
	print("[HospitalScreen] Releasing with gems - cost: %d" % gem_cost)
	
	# Server'a istek gönder
	var hospital_mgr = HospitalManager.new()
	var result = await hospital_mgr.release_with_gems()
	
	if result.success:
		State.set_hospital_status(false, 0)
		countdown_timer.stop()
		title_label.text = "Başarıyla Çıktınız!"
		reason_label.text = "Elmas harcayarak hastaneden erken çıktınız."
		countdown_label.text = "Gem Harcandı: %d💎" % gem_cost
		_show_success("Başarılı", "Hastaneden çıktınız!")
	else:
		release_gems_button.disabled = false
		_show_error("Hata", result.get("error", "Bilinmeyen hata"))

func _on_cancel_release() -> void:
	print("[HospitalScreen] Cancelled release with gems")

func _on_energy_updated() -> void:
	_update_energy_display()

func _update_energy_display() -> void:
	if energy_label and State:
		energy_label.text = "Enerji: %d/%d" % [State.current_energy, State.max_energy]

func _on_player_updated() -> void:
	_load_hospital_status()
	_start_countdown()

func _on_back_button_pressed() -> void:
	print("[HospitalScreen] Back button pressed")
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		main.show_screen("home", true)

func _show_error(title: String, message: String) -> void:
	push_error("[HospitalScreen] %s: %s" % [title, message])
	
	# Elmas yetersiz uyarısı için özel dialog göster
	if title == "Yetersiz Elmas":
		_show_insufficient_gems_dialog(message)
	else:
		# Diğer hatalar için basit dialog
		var error_dialog_scene = load("res://scenes/ui/dialogs/ErrorDialog.tscn")
		if error_dialog_scene:
			var dialog = error_dialog_scene.instantiate()
			if dialog.has_method("setup"):
				dialog.setup({
					"title": title,
					"message": message
				})
			_add_dialog_to_container(dialog)

func _show_insufficient_gems_dialog(message: String) -> void:
	print("[HospitalScreen] Showing insufficient gems dialog")
	var confirm_dialog_scene = load("res://scenes/ui/dialogs/ConfirmDialog.tscn")
	if confirm_dialog_scene:
		print("[HospitalScreen] ConfirmDialog scene loaded")
		var main = get_tree().root.get_node_or_null("Main")
		if main and main.has_method("show_dialog"):
			print("[HospitalScreen] Using Main.show_dialog for insufficient gems")
			main.show_dialog(confirm_dialog_scene, {
				"title": "Yetersiz Elmas",
				"message": message,
				"confirm_text": "Dükkana Git",
				"cancel_text": "Kapat",
				"on_confirm": Callable(self, "_on_go_to_shop"),
				"on_cancel": Callable(self, "_on_close_insufficient_gems_dialog")
			})
		else:
			print("[HospitalScreen] Main.show_dialog not available")
	else:
		print("[HospitalScreen] Failed to load ConfirmDialog scene")

func _add_dialog_to_container(dialog: Control) -> void:
	print("[HospitalScreen] Adding dialog to container")
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_node("DialogContainer"):
		print("[HospitalScreen] Found DialogContainer in Main")
		main.get_node("DialogContainer").add_child(dialog)
	else:
		print("[HospitalScreen] DialogContainer not found, adding to HospitalScreen")
		# Fallback: add to current scene
		add_child(dialog)

func _on_go_to_shop() -> void:
	print("[HospitalScreen] Going to shop from insufficient gems dialog")
	var main = get_tree().root.get_node_or_null("Main")
	if main and main.has_method("show_screen"):
		main.show_screen("shop", true)

func _on_close_insufficient_gems_dialog() -> void:
	print("[HospitalScreen] Closed insufficient gems dialog")

func _show_success(title: String, message: String) -> void:
	print("[HospitalScreen] %s: %s" % [title, message])
