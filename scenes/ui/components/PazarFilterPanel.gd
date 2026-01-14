extends PanelContainer

signal filters_changed(filters: Dictionary)

@onready var search_input: LineEdit = $VBoxContainer/SearchSection/MarginContainer/SearchInput
@onready var category_filter: OptionButton = $VBoxContainer/CategorySection/MarginContainer/CategoryFilter
@onready var reset_button: Button = $VBoxContainer/MarginContainer2/ResetButton

var rarity_checks: Dictionary = {}

func _ready() -> void:
	search_input.text_changed.connect(_on_filter_changed)
	category_filter.item_selected.connect(_on_filter_changed)
	reset_button.pressed.connect(reset_filters)
	
	# Initialize rarity checks here to ensure ItemData is loaded
	# Initialize rarity checks using Integers to avoid potential Enum/Array access issues
	rarity_checks = {
		0: $VBoxContainer/RaritySection/MarginContainer/VBoxContainer/RarityCommon,     # COMMON
		1: $VBoxContainer/RaritySection/MarginContainer/VBoxContainer/RarityUncommon,   # UNCOMMON
		2: $VBoxContainer/RaritySection/MarginContainer/VBoxContainer/RarityRare,       # RARE
		3: $VBoxContainer/RaritySection/MarginContainer/VBoxContainer/RarityEpic,       # EPIC
		4: $VBoxContainer/RaritySection/MarginContainer/VBoxContainer/RarityLegendary   # LEGENDARY
	}
	
	for rarity in rarity_checks:
		var checkbox = rarity_checks[rarity]
		if checkbox:
			checkbox.toggled.connect(_on_filter_changed)

func _on_filter_changed(_arg = null) -> void:
	var filters = {
		"search": search_input.text,
		"category": category_filter.get_selected_id(),
		"rarities": []
	}
	
	for rarity in rarity_checks:
		if rarity_checks[rarity].button_pressed:
			filters.rarities.append(rarity)
			
	filters_changed.emit(filters)

func reset_filters() -> void:
	search_input.text = ""
	category_filter.selected = 0
	
	for rarity in rarity_checks:
		rarity_checks[rarity].button_pressed = true
		
	_on_filter_changed()
