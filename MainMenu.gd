extends Control

# MainMenu.gd - 角色选择界面
# 美化版 - 支持自适应布局和动画效果

var selected_character_id: int = -1
var character_cards: Array = []

@onready var character_grid = $MarginContainer/VBoxContainer/ContentContainer/CharacterGrid
@onready var start_button = $MarginContainer/VBoxContainer/BottomPanel/ButtonContainer/StartButton
@onready var back_button = $MarginContainer/VBoxContainer/BottomPanel/ButtonContainer/BackButton
@onready var title_label = $MarginContainer/VBoxContainer/HeaderContainer/TitleLabel
@onready var subtitle_label = $MarginContainer/VBoxContainer/HeaderContainer/SubtitleLabel
@onready var character_info_panel = $MarginContainer/VBoxContainer/ContentContainer/CharacterInfoPanel
@onready var info_name = $MarginContainer/VBoxContainer/ContentContainer/CharacterInfoPanel/VBoxContainer/NameLabel
@onready var info_title = $MarginContainer/VBoxContainer/ContentContainer/CharacterInfoPanel/VBoxContainer/TitleLabel
@onready var info_desc = $MarginContainer/VBoxContainer/ContentContainer/CharacterInfoPanel/VBoxContainer/DescLabel
@onready var info_stats = $MarginContainer/VBoxContainer/ContentContainer/CharacterInfoPanel/VBoxContainer/StatsContainer

func _ready():
	# 初始化角色数据
	CharacterData.initialize()

	# 设置UI样式
	_setup_ui_style()

	# 创建角色卡片
	_create_character_cards()

	# 初始化按钮状态
	start_button.disabled = true
	start_button.pressed.connect(_on_start_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

	# 隐藏角色信息面板
	character_info_panel.modulate.a = 0

	# 播放入场动画
	_animate_intro()

func _setup_ui_style():
	# 标题样式
	UITheme.apply_title_style(title_label, 42)
	UITheme.apply_label_style(subtitle_label, 18, UITheme.TEXT_SECONDARY)

	# 按钮样式
	UITheme.apply_button_style(start_button, 20)
	UITheme.apply_button_style(back_button, 18)

	# 信息面板样式
	UITheme.apply_panel_style(character_info_panel, UITheme.BG_PANEL)

func _create_character_cards():
	# 按照GameConstants.CharacterId枚举顺序排列
	var character_ids = [
		GameConstants.CharacterId.REIMU,
		GameConstants.CharacterId.MOKOU,
		GameConstants.CharacterId.MARISA,
		GameConstants.CharacterId.SAKUYA,
		GameConstants.CharacterId.YUMA,
		GameConstants.CharacterId.KOISHI
	]

	# 本版本只开放藤原妹红
	var unlocked_characters = [
		GameConstants.CharacterId.MOKOU
	]

	for i in range(character_ids.size()):
		var char_id = character_ids[i]
		var character_data = CharacterData.CHARACTERS.get(char_id)
		if character_data:
			var is_unlocked = char_id in unlocked_characters
			var card = _create_character_card(character_data, i, is_unlocked)
			character_grid.add_child(card)
			character_cards.append(card)

func _create_character_card(character_data: CharacterData.Character, index: int, is_unlocked: bool = true) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 260)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP if is_unlocked else Control.MOUSE_FILTER_IGNORE

	# 卡片样式
	var style = UITheme.create_card_style(character_data.color, false)
	card.add_theme_stylebox_override("panel", style)

	# 如果未解锁，添加灰色遮罩
	if not is_unlocked:
		card.modulate = Color(0.4, 0.4, 0.4, 0.7)

	# 内容容器
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# 角色头像区域
	var portrait_container = CenterContainer.new()
	portrait_container.custom_minimum_size = Vector2(0, 130)
	vbox.add_child(portrait_container)

	# 头像背景
	var portrait_bg = ColorRect.new()
	portrait_bg.custom_minimum_size = Vector2(110, 110)
	portrait_bg.color = character_data.color.darkened(0.6)
	portrait_bg.color.a = 0.4
	portrait_container.add_child(portrait_bg)

	# 尝试加载角色图片（使用新的立绘）
	var sprite_paths = [
		"res://assets/leimuF.png",              # Reimu
		"res://assets/characters/1.png",        # Mokou - 新立绘
		"res://assets/marisaF.png",             # Marisa
		"res://assets/sakuyaF.png",             # Sakuya
		"res://assets/taotie.png",              # Yuma
		"res://assets/koyiF.png"                # Koishi
	]

	if character_data.id < sprite_paths.size():
		var texture_rect = TextureRect.new()
		var tex_path = sprite_paths[character_data.id]
		if ResourceLoader.exists(tex_path):
			var tex = load(tex_path)
			if tex:
				texture_rect.texture = tex
				texture_rect.custom_minimum_size = Vector2(110, 110)
				texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				portrait_container.add_child(texture_rect)
				portrait_bg.visible = false

	# 角色名称
	var name_label = Label.new()
	name_label.text = character_data.char_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", character_data.color.lightened(0.2))
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)

	# 角色称号
	var title_label = Label.new()
	title_label.text = character_data.title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title_label)

	# 如果未解锁，添加锁定标记
	if not is_unlocked:
		var lock_overlay = CenterContainer.new()
		lock_overlay.position = Vector2(0, 0)
		lock_overlay.size = card.custom_minimum_size
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock_overlay)

		var lock_bg = PanelContainer.new()
		var lock_bg_style = StyleBoxFlat.new()
		lock_bg_style.bg_color = Color(0, 0, 0, 0.7)
		lock_bg_style.corner_radius_top_left = 8
		lock_bg_style.corner_radius_top_right = 8
		lock_bg_style.corner_radius_bottom_left = 8
		lock_bg_style.corner_radius_bottom_right = 8
		lock_bg.add_theme_stylebox_override("panel", lock_bg_style)
		lock_overlay.add_child(lock_bg)

		var lock_vbox = VBoxContainer.new()
		lock_vbox.add_theme_constant_override("separation", 8)
		lock_bg.add_child(lock_vbox)

		# 锁定图标（使用文字代替）
		var lock_icon = Label.new()
		lock_icon.text = "🔒"
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_icon.add_theme_font_size_override("font_size", 48)
		lock_vbox.add_child(lock_icon)

		var lock_text = Label.new()
		lock_text.text = "敬请期待"
		lock_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_text.add_theme_font_size_override("font_size", 14)
		lock_text.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		lock_vbox.add_child(lock_text)

	# 属性预览条
	var stats_preview = HBoxContainer.new()
	stats_preview.add_theme_constant_override("separation", 8)
	stats_preview.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stats_preview)

	# HP图标
	var hp_indicator = _create_stat_indicator("HP", character_data.stats.max_hp / 200.0, UITheme.SUCCESS)
	stats_preview.add_child(hp_indicator)

	# 速度图标
	var spd_indicator = _create_stat_indicator("SPD", character_data.stats.speed / 300.0, UITheme.INFO)
	stats_preview.add_child(spd_indicator)

	# 攻击图标
	var atk_indicator = _create_stat_indicator("ATK", character_data.stats.might / 2.0, UITheme.DANGER)
	stats_preview.add_child(atk_indicator)

	# 存储角色ID和解锁状态
	card.set_meta("character_id", character_data.id)
	card.set_meta("character_data", character_data)
	card.set_meta("is_unlocked", is_unlocked)

	# 只为解锁的角色连接交互事件
	if is_unlocked:
		card.mouse_entered.connect(_on_card_hover.bind(card, true))
		card.mouse_exited.connect(_on_card_hover.bind(card, false))
		card.gui_input.connect(_on_card_input.bind(card))

	return card

func _create_stat_indicator(label: String, value: float, color: Color) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var bar_bg = ColorRect.new()
	bar_bg.custom_minimum_size = Vector2(35, 4)
	bar_bg.color = Color(0.2, 0.2, 0.25, 0.8)
	container.add_child(bar_bg)

	var bar_fill = ColorRect.new()
	bar_fill.custom_minimum_size = Vector2(35 * clamp(value, 0, 1), 4)
	bar_fill.color = color
	bar_fill.position = Vector2.ZERO
	bar_bg.add_child(bar_fill)

	var stat_label = Label.new()
	stat_label.text = label
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_label.add_theme_font_size_override("font_size", 9)
	stat_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	container.add_child(stat_label)

	return container

func _on_card_hover(card: PanelContainer, hovered: bool):
	var character_data = card.get_meta("character_data")
	var is_selected = card.get_meta("character_id") == selected_character_id
	var is_unlocked = card.get_meta("is_unlocked", true)

	# 未解锁的角色不响应悬停
	if not is_unlocked:
		return

	# 更新卡片样式
	var style = UITheme.create_card_style(character_data.color, is_selected or hovered)
	card.add_theme_stylebox_override("panel", style)

	# 悬停动画
	UITheme.animate_hover(card, hovered and not is_selected)

	# 显示角色信息
	if hovered and not is_selected:
		_show_character_info(character_data)

func _on_card_input(event: InputEvent, card: PanelContainer):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_character(card)

func _select_character(card: PanelContainer):
	var character_data = card.get_meta("character_data")
	var char_id = card.get_meta("character_id")

	# 取消之前的选择
	for c in character_cards:
		var c_data = c.get_meta("character_data")
		var style = UITheme.create_card_style(c_data.color, false)
		c.add_theme_stylebox_override("panel", style)
		c.scale = Vector2(1, 1)

	# 选中当前卡片
	selected_character_id = char_id
	var style = UITheme.create_card_style(character_data.color, true)
	card.add_theme_stylebox_override("panel", style)

	# 选中动画
	var tween = card.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(card, "scale", Vector2(1.05, 1.05), 0.15)
	tween.tween_property(card, "scale", Vector2(1.02, 1.02), 0.1)

	# 启用开始按钮
	start_button.disabled = false

	# 显示角色详细信息
	_show_character_info(character_data)

	print("[MainMenu] 选择角色: ", character_data.char_name)

func _show_character_info(character_data: CharacterData.Character):
	# 更新信息面板
	info_name.text = character_data.char_name
	info_name.add_theme_color_override("font_color", character_data.color.lightened(0.2))

	info_title.text = character_data.title

	info_desc.text = character_data.description

	# 清空并重建属性显示
	for child in info_stats.get_children():
		child.queue_free()

	var stats = [
		{"name": "生命", "value": character_data.stats.max_hp, "max": 200, "color": UITheme.SUCCESS},
		{"name": "速度", "value": character_data.stats.speed, "max": 300, "color": UITheme.INFO},
		{"name": "攻击", "value": character_data.stats.might, "max": 2.0, "color": UITheme.DANGER},
	]

	for stat in stats:
		var stat_row = _create_stat_row(stat.name, stat.value, stat.max, stat.color)
		info_stats.add_child(stat_row)

	# 淡入动画
	var tween = character_info_panel.create_tween()
	tween.tween_property(character_info_panel, "modulate:a", 1.0, 0.2)

func _create_stat_row(stat_name: String, value: float, max_value: float, color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var name_label = Label.new()
	name_label.text = stat_name
	name_label.custom_minimum_size = Vector2(50, 0)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	row.add_child(name_label)

	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(120, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_custom_bar_style(bar, color)
	row.add_child(bar)

	var value_label = Label.new()
	value_label.text = str(int(value)) if value >= 1 else ("%.1f" % value)
	value_label.custom_minimum_size = Vector2(40, 0)
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	return row

func _animate_intro():
	# 标题动画
	title_label.modulate.a = 0
	subtitle_label.modulate.a = 0

	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.4)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.3)

	# 卡片依次淡入
	for i in range(character_cards.size()):
		var card = character_cards[i]
		var is_unlocked = card.get_meta("is_unlocked", true)
		var initial_modulate = Color(0.4, 0.4, 0.4, 0.7) if not is_unlocked else Color(1, 1, 1, 1)
		card.modulate.a = 0
		card.scale = Vector2(0.9, 0.9)

		await get_tree().create_timer(0.08).timeout

		var card_tween = card.create_tween()
		card_tween.set_ease(Tween.EASE_OUT)
		card_tween.set_trans(Tween.TRANS_BACK)
		card_tween.set_parallel(true)
		card_tween.tween_property(card, "modulate", initial_modulate, 0.25)
		card_tween.tween_property(card, "scale", Vector2(1, 1), 0.3)

func _on_start_button_pressed():
	if selected_character_id >= 0:
		# 保存选择的角色到全局变量
		SignalBus.selected_character_id = selected_character_id
		SignalBus.character_selected.emit(selected_character_id)
		print("[MainMenu] 开始游戏，角色ID: ", selected_character_id)

		# 过渡动画
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(func():
			if is_instance_valid(self):
				get_tree().change_scene_to_file("res://LoadingScreen.tscn")
		)

func _on_back_button_pressed():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(self):
			get_tree().change_scene_to_file("res://TitleScreen.tscn")
	)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_button_pressed()
