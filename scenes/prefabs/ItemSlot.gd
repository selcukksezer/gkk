extends PanelContainer

## Envanter Izgarası için Eşya Slotu
signal slot_clicked(item: ItemData)

# @onready değişkenlerini "Unique Name" (%) yapısına göre güncelledik
@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var quantity_label: Label = %QuantityLabel
@onready var enhancement_label: Label = %EnhancementLabel
@onready var rarity_border: ColorRect = %RarityBorder
@onready var equipped_indicator: TextureRect = %EquippedIndicator

var _item: ItemData

func _ready() -> void:
	# Sinyal bağlantısını editörden yapmadıysan kodla bağlamak iyidir
	gui_input.connect(_on_gui_input)
	
	# Başlangıçta boş görünmesi için temizle
	clear_slot()

## Slota bir eşya yerleştirir ve görselleri günceller
func set_item(item: ItemData) -> void:
	if not item:
		clear_slot()
		return
		
	_item = item
	
	# İkon yükleme (ItemData içinde 'icon' özelliği path olarak var)
	if icon_rect:
		if item.icon and not item.icon.is_empty() and ResourceLoader.exists(item.icon):
			icon_rect.texture = load(item.icon)
		else:
			icon_rect.texture = null
	else:
		# icon_rect not found in scene, skip icon assignment
		pass
	
	# İsim güncelleme
	if name_label:
		name_label.text = item.name
		if item.pending_sync:
			name_label.text += " (syncing...)"

	# Miktar gösterimi
	if quantity_label:
		if item.quantity > 1:
			quantity_label.text = "x%d" % item.quantity
			quantity_label.visible = true
		else:
			quantity_label.visible = false

	# Geliştirme seviyesi gösterimi
	if enhancement_label:
		if item.enhancement_level > 0:
			enhancement_label.text = "+%d" % item.enhancement_level
			enhancement_label.visible = true
		else:
			enhancement_label.visible = false

	# Nadirlik rengi
	if rarity_border:
		rarity_border.color = item.get_rarity_color()

	# Kuşanılmış durumu (bu inventory'den gelmeli, şimdilik gizli)
	if equipped_indicator:
		equipped_indicator.visible = false

## Slotu boşaltır (Reset)
func clear_slot() -> void:
	_item = null
	if icon_rect:
		icon_rect.texture = null
	if name_label:
		name_label.text = ""
	if quantity_label:
		quantity_label.visible = false
	if enhancement_label:
		enhancement_label.visible = false
	if equipped_indicator:
		equipped_indicator.visible = false
	if rarity_border:
		rarity_border.color = Color(1, 1, 1, 0.1) # Varsayılan şeffaf renk

## Ekipman slotu olarak ayarla (Kask, Zırh vb. için placeholder)
func set_equipment_slot(slot_name: String) -> void:
	# Defer clearing until node is ready to avoid accessing @onready nodes before they're initialized
	call_deferred("clear_slot")
	if name_label:
		name_label.text = slot_name
	# İsteğe bağlı: Buraya o slotun gölge ikonunu koyabilirsin (kask resmi vs.)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Eğer slot boşsa null döner, doluysa eşyayı döner
			slot_clicked.emit(_item)