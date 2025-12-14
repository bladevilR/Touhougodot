extends Control
class_name PauseMenu

# PauseMenu - ESC暂停菜单
# 按ESC暂停游戏，显示菜单

var is_paused: bool = false
var settings_menu: Control = null

# UI节点
var background: ColorRect = null
var menu_container: VBoxContainer = null
var title_label: Label = null
var resume_button: Button = null
var settings_button: Button = null
var main_menu_button: Button = null
var quit_button: Button = null

func _ready():
	# 设置为全屏
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 初始隐藏
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时也能处理输入

	# 确保在最上层
	z_index = 100

	# 创建UI
	_create_ui()

	# 连接信号
	SignalBus.pause_menu_toggled.connect(_on_pause_toggled)

func _create_ui():
	"""创建暂停菜单UI"""
	# 半透明黑色背景
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
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
	margin.add_child(menu_container)

	# 标题
	title_label = Label.new()
	title_label.text = "暂停"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	menu_container.add_child(title_label)

	# 分隔线
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 20)
	menu_container.add_child(separator)

	# 继续游戏按钮
	resume_button = _create_menu_button("继续游戏", Color(0.5, 0.8, 0.5))
	resume_button.pressed.connect(_on_resume_pressed)
	menu_container.add_child(resume_button)

	# 设置按钮
	settings_button = _create_menu_button("设置", Color(0.6, 0.7, 0.9))
	settings_button.pressed.connect(_on_settings_pressed)
	menu_container.add_child(settings_button)

	# 返回主菜单按钮
	main_menu_button = _create_menu_button("返回主菜单", Color(0.9, 0.7, 0.4))
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	menu_container.add_child(main_menu_button)

	# 退出游戏按钮
	quit_button = _create_menu_button("退出游戏", Color(0.9, 0.5, 0.5))
	quit_button.pressed.connect(_on_quit_pressed)
	menu_container.add_child(quit_button)

func _create_menu_button(text: String, color: Color) -> Button:
	"""创建菜单按钮"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 50)
	button.add_theme_font_size_override("font_size", 20)

	# 按钮样式
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.25, 0.25, 0.3, 0.9)
	normal_style.set_corner_radius_all(8)
	normal_style.set_border_width_all(2)
	normal_style.border_color = color
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.35, 0.35, 0.4, 0.95)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	button.add_theme_stylebox_override("pressed", pressed_style)

	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color.lightened(0.2))

	return button

func _input(event):
	# 按ESC切换暂停
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause():
	"""切换暂停状态"""
	is_paused = !is_paused
	visible = is_paused
	get_tree().paused = is_paused
	SignalBus.pause_menu_toggled.emit(is_paused)

	if is_paused:
		print("[PauseMenu] 游戏暂停")
	else:
		print("[PauseMenu] 继续游戏")
		# 确保设置菜单也关闭
		if settings_menu and settings_menu.visible:
			settings_menu.visible = false

func _on_pause_toggled(paused: bool):
	"""响应暂停信号"""
	if paused != is_paused:
		is_paused = paused
		visible = paused
		get_tree().paused = paused

func _on_resume_pressed():
	"""继续游戏"""
	toggle_pause()

func _on_settings_pressed():
	"""打开设置菜单"""
	if not settings_menu:
		# 动态创建设置菜单
		var SettingsMenuScript = load("res://SettingsMenu.gd")
		if SettingsMenuScript:
			settings_menu = SettingsMenuScript.new()
			add_child(settings_menu)

	if settings_menu:
		settings_menu.visible = true
		menu_container.visible = false  # 隐藏主菜单
		background.visible = false  # 隐藏暂停菜单背景
		settings_menu.back_to_pause.connect(_on_settings_back)

func _on_settings_back():
	"""从设置菜单返回"""
	if settings_menu:
		settings_menu.visible = false
	menu_container.visible = true
	background.visible = true

func _on_main_menu_pressed():
	"""返回主菜单"""
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

func _on_quit_pressed():
	"""退出游戏"""
	get_tree().quit()
