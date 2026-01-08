extends Control
class_name SettingsMenu

# SettingsMenu - 设置菜单
# 显示和修改游戏设置（纯代码创建，不依赖.tscn）

signal back_to_pause

var background: ColorRect = null
var menu_container: VBoxContainer = null

# 设置控件
var dps_checkbox: CheckBox = null
var map_checkbox: CheckBox = null
var ui_sound_checkbox: CheckBox = null
var damage_numbers_checkbox: CheckBox = null
var master_volume_slider: HSlider = null
var master_volume_label: Label = null

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	_create_ui()
	_load_settings()

func _create_ui():
	"""创建设置菜单UI"""
	# 半透明黑色背景
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.85)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# 菜单容器（居中）
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	panel_style.set_corner_radius_all(12)
	panel_style.set_border_width_all(2)
	panel_style.border_color = Color(0.6, 0.6, 0.7, 0.8)
	panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(panel)

	# 内容容器
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	menu_container = VBoxContainer.new()
	menu_container.add_theme_constant_override("separation", 15)
	menu_container.custom_minimum_size = Vector2(500, 0)
	margin.add_child(menu_container)

	# 标题
	var title = Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	menu_container.add_child(title)

	# 分隔线
	var separator1 = HSeparator.new()
	menu_container.add_child(separator1)

	# === 显示设置 ===
	var display_section = Label.new()
	display_section.text = "显示设置"
	display_section.add_theme_font_size_override("font_size", 22)
	display_section.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	menu_container.add_child(display_section)

	# DPS显示
	dps_checkbox = _create_checkbox("显示DPS统计")
	dps_checkbox.toggled.connect(_on_dps_display_toggled)
	menu_container.add_child(dps_checkbox)

	# 地图显示
	map_checkbox = _create_checkbox("显示房间地图")
	map_checkbox.toggled.connect(_on_map_display_toggled)
	menu_container.add_child(map_checkbox)

	# 伤害数字显示
	damage_numbers_checkbox = _create_checkbox("显示伤害数字（暴击感叹号）")
	damage_numbers_checkbox.toggled.connect(_on_damage_numbers_toggled)
	menu_container.add_child(damage_numbers_checkbox)

	# 分隔线
	var separator2 = HSeparator.new()
	menu_container.add_child(separator2)

	# === 音频设置 ===
	var audio_section = Label.new()
	audio_section.text = "音频设置"
	audio_section.add_theme_font_size_override("font_size", 22)
	audio_section.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
	menu_container.add_child(audio_section)

	# UI音效
	ui_sound_checkbox = _create_checkbox("UI按键音效")
	ui_sound_checkbox.toggled.connect(_on_ui_sound_toggled)
	menu_container.add_child(ui_sound_checkbox)

	# 主音量滑块
	var volume_container = HBoxContainer.new()
	volume_container.add_theme_constant_override("separation", 10)
	menu_container.add_child(volume_container)

	var volume_title = Label.new()
	volume_title.text = "主音量："
	volume_title.custom_minimum_size = Vector2(100, 0)
	volume_title.add_theme_font_size_override("font_size", 16)
	volume_container.add_child(volume_title)

	master_volume_slider = HSlider.new()
	master_volume_slider.min_value = 0.0
	master_volume_slider.max_value = 1.0
	master_volume_slider.step = 0.05
	master_volume_slider.custom_minimum_size = Vector2(250, 0)
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	volume_container.add_child(master_volume_slider)

	master_volume_label = Label.new()
	master_volume_label.text = "100%"
	master_volume_label.custom_minimum_size = Vector2(50, 0)
	master_volume_label.add_theme_font_size_override("font_size", 16)
	volume_container.add_child(master_volume_label)

	# 分隔线
	var separator3 = HSeparator.new()
	menu_container.add_child(separator3)

	# 返回按钮
	var back_button = Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.add_theme_font_size_override("font_size", 20)
	back_button.pressed.connect(_on_back_pressed)

	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color(0.25, 0.25, 0.3, 0.9)
	back_style.set_corner_radius_all(8)
	back_style.set_border_width_all(2)
	back_style.border_color = Color(0.7, 0.7, 0.8)
	back_button.add_theme_stylebox_override("normal", back_style)

	var back_container = CenterContainer.new()
	back_container.add_child(back_button)
	menu_container.add_child(back_container)

func _create_checkbox(label_text: String) -> CheckBox:
	"""创建复选框"""
	var checkbox = CheckBox.new()
	checkbox.text = label_text
	checkbox.add_theme_font_size_override("font_size", 18)
	checkbox.add_theme_color_override("font_color", Color.WHITE)
	return checkbox

func _load_settings():
	"""从GameSettings加载当前设置"""
	if not GameSettings:
		print("[SettingsMenu] 警告: GameSettings未加载")
		return

	dps_checkbox.button_pressed = GameSettings.show_dps
	map_checkbox.button_pressed = GameSettings.show_room_map
	ui_sound_checkbox.button_pressed = GameSettings.ui_sound_enabled
	damage_numbers_checkbox.button_pressed = GameSettings.show_damage_numbers
	master_volume_slider.value = GameSettings.master_volume
	master_volume_label.text = str(int(GameSettings.master_volume * 100)) + "%"

func _on_dps_display_toggled(pressed: bool):
	"""切换DPS显示"""
	GameSettings.show_dps = pressed
	GameSettings.save_settings()
	SignalBus.settings_changed.emit()
	print("[SettingsMenu] DPS显示: ", pressed)

func _on_map_display_toggled(pressed: bool):
	"""切换地图显示"""
	GameSettings.show_room_map = pressed
	GameSettings.save_settings()
	SignalBus.settings_changed.emit()
	print("[SettingsMenu] 地图显示: ", pressed)

func _on_ui_sound_toggled(pressed: bool):
	"""切换UI音效"""
	GameSettings.ui_sound_enabled = pressed
	GameSettings.save_settings()
	print("[SettingsMenu] UI音效: ", pressed)

func _on_damage_numbers_toggled(pressed: bool):
	"""切换伤害数字显示"""
	GameSettings.show_damage_numbers = pressed
	GameSettings.save_settings()
	SignalBus.settings_changed.emit()
	print("[SettingsMenu] 伤害数字显示: ", pressed)

func _on_master_volume_changed(value: float):
	"""主音量改变"""
	GameSettings.set_master_volume(value)
	master_volume_label.text = str(int(value * 100)) + "%"

func _on_back_pressed():
	"""返回暂停菜单"""
	back_to_pause.emit()
	visible = false
