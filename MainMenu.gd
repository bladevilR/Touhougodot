extends Control

# MainMenu.gd - Character Selection Screen
# UI for selecting your playable character

var selected_character_id: int = -1
var character_cards = []

@onready var character_grid = $MarginContainer/VBoxContainer/CharacterGrid
@onready var start_button = $MarginContainer/VBoxContainer/BottomPanel/StartButton
@onready var title_label = $MarginContainer/VBoxContainer/TitleLabel

func _ready():
	# Initialize character data
	CharacterData.initialize()

	# Create character cards
	create_character_cards()

	# Disable start button until character is selected
	start_button.disabled = true
	start_button.pressed.connect(_on_start_button_pressed)

func create_character_cards():
	var character_ids = [
		GameConstants.CharacterId.REIMU,
		GameConstants.CharacterId.MARISA,
		GameConstants.CharacterId.MOKOU,
		GameConstants.CharacterId.SAKUYA,
		GameConstants.CharacterId.YUMA,
		GameConstants.CharacterId.KOISHI
	]

	for char_id in character_ids:
		var character_data = CharacterData.CHARACTERS.get(char_id)
		if character_data:
			var card = create_character_card(character_data)
			character_grid.add_child(card)
			character_cards.append(card)

func create_character_card(character_data: CharacterData.Character) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 400)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	# Add style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = character_data.color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	card.add_child(vbox)

	# Character Portrait
	var portrait_container = CenterContainer.new()
	portrait_container.custom_minimum_size = Vector2(0, 180)
	vbox.add_child(portrait_container)

	var portrait = ColorRect.new()
	portrait.custom_minimum_size = Vector2(150, 150)
	portrait.color = character_data.color
	portrait_container.add_child(portrait)

	# Try to load character sprite
	var sprite_paths = [
		"res://assets/characters/leimu.png",
		"res://assets/characters/marisa.png",
		"res://assets/characters/mokuo.png",
		"res://assets/characters/xiaoye.png",
		"res://assets/characters/taotie.png",
		"res://assets/characters/koyi.png"
	]
	if character_data.id < sprite_paths.size():
		var texture_rect = TextureRect.new()
		texture_rect.texture = load(sprite_paths[character_data.id])
		texture_rect.custom_minimum_size = Vector2(150, 150)
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait_container.add_child(texture_rect)
		portrait.visible = false

	# Character Name
	var name_label = Label.new()
	name_label.text = character_data.char_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", character_data.color)
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)

	# Character Title
	var title_label = Label.new()
	title_label.text = character_data.title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(title_label)

	# Stats Panel
	var stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 4)
	vbox.add_child(stats_container)

	# HP Bar
	stats_container.add_child(create_stat_bar("HP", character_data.stats.max_hp, 150, Color(0.8, 0.2, 0.2)))

	# Speed Bar
	stats_container.add_child(create_stat_bar("Speed", character_data.stats.speed, 5, Color(0.2, 0.8, 0.8)))

	# ATK Bar (Might)
	stats_container.add_child(create_stat_bar("ATK", character_data.stats.might, 1.5, Color(0.8, 0.6, 0.2)))

	# Description
	var desc_label = Label.new()
	desc_label.text = character_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(desc_label)

	# Store character ID
	card.set_meta("character_id", character_data.id)

	# Connect hover effects
	card.mouse_entered.connect(_on_card_hover.bind(card, character_data))
	card.mouse_exited.connect(_on_card_unhover.bind(card, character_data))
	card.gui_input.connect(_on_card_clicked.bind(card, character_data))

	return card

func create_stat_bar(label_text: String, value: float, max_value: float, bar_color: Color) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label = Label.new()
	label.text = label_text + ":"
	label.custom_minimum_size = Vector2(50, 0)
	label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(label)

	var bar_container = PanelContainer.new()
	bar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.2, 0.2, 0.2)
	bar_container.add_theme_stylebox_override("panel", bar_bg)

	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(150, 16)

	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = bar_color
	bar.add_theme_stylebox_override("fill", bar_style)

	bar_container.add_child(bar)
	hbox.add_child(bar_container)

	var value_label = Label.new()
	value_label.text = str(int(value))
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.add_theme_font_size_override("font_size", 12)
	hbox.add_child(value_label)

	return hbox

func _on_card_hover(card: PanelContainer, character_data: CharacterData.Character):
	var style = card.get_theme_stylebox("panel").duplicate()
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_width_top = 5
	style.border_width_bottom = 5
	style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	card.add_theme_stylebox_override("panel", style)

func _on_card_unhover(card: PanelContainer, character_data: CharacterData.Character):
	if card.get_meta("character_id") != selected_character_id:
		var style = card.get_theme_stylebox("panel").duplicate()
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		card.add_theme_stylebox_override("panel", style)

func _on_card_clicked(event: InputEvent, card: PanelContainer, character_data: CharacterData.Character):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		select_character(card, character_data)

func select_character(card: PanelContainer, character_data: CharacterData.Character):
	# Deselect previous
	for c in character_cards:
		var style = c.get_theme_stylebox("panel").duplicate()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		c.add_theme_stylebox_override("panel", style)

	# Select new
	selected_character_id = character_data.id
	var style = card.get_theme_stylebox("panel").duplicate()
	style.bg_color = Color(0.25, 0.3, 0.35, 1.0)
	card.add_theme_stylebox_override("panel", style)

	# Enable start button
	start_button.disabled = false

	print("Selected character: ", character_data.char_name)

func _on_start_button_pressed():
	if selected_character_id >= 0:
		SignalBus.character_selected.emit(selected_character_id)
		print("Starting with character ID: ", selected_character_id)
		# Load bond selection screen
		get_tree().change_scene_to_file("res://BondSelectionScreen.tscn")
