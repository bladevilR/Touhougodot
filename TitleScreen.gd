extends Control

# TitleScreen.gd - 游戏标题画面/主菜单入口
# 提供游戏开始、设置、局外升级的入口

@onready var title_label = $VBoxContainer/TitleContainer/TitleLabel
@onready var subtitle_label = $VBoxContainer/TitleContainer/SubtitleLabel
@onready var menu_container = $VBoxContainer/MenuContainer
@onready var version_label = $VersionLabel
@onready var background = $Background
@onready var particles_container = $ParticlesContainer

var buttons: Array[Button] = []
var selected_index: int = 0
var particle_nodes: Array = []

func _ready():
	_setup_background()
	_setup_ui()
	_create_menu_buttons()
	_create_floating_particles()
	_animate_intro()

	# 默认选中第一个按钮
	if buttons.size() > 0:
		await get_tree().create_timer(0.5).timeout
		buttons[0].grab_focus()

func _exit_tree():
	# 清理所有粒子动画的tweens
	for particle in particle_nodes:
		if is_instance_valid(particle):
			if particle.has_meta("particle_tween"):
				var tween = particle.get_meta("particle_tween")
				if is_instance_valid(tween):
					tween.kill()
			particle.queue_free()

func _setup_background():
	# 创建渐变背景效果
	pass

func _setup_ui():
	# 应用标题样式
	if title_label:
		UITheme.apply_title_style(title_label, 56)
		title_label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

	if subtitle_label:
		UITheme.apply_label_style(subtitle_label, 22, UITheme.TEXT_SECONDARY)

	# 版本号
	if version_label:
		version_label.text = "v0.1.0 Alpha"
		UITheme.apply_label_style(version_label, 14, UITheme.TEXT_MUTED)

func _create_menu_buttons():
	# 确保 menu_container 存在
	if not menu_container:
		push_error("[TitleScreen] menu_container 节点未找到！")
		return

	var menu_items = [
		{"text": "开始游戏", "callback": _on_start_game, "icon": "play"},
		{"text": "局外升级", "callback": _on_meta_upgrade, "icon": "upgrade"},
		{"text": "设置", "callback": _on_settings, "icon": "settings"},
		{"text": "退出游戏", "callback": _on_quit, "icon": "exit"}
	]

	for i in range(menu_items.size()):
		var item = menu_items[i]
		var button = _create_menu_button(item.text, i)
		button.pressed.connect(item.callback)
		menu_container.add_child(button)
		buttons.append(button)

	# 连接按钮焦点以支持键盘导航
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.focus_neighbor_top = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		btn.focus_neighbor_bottom = buttons[(i + 1) % buttons.size()].get_path()

func _create_menu_button(text: String, index: int) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(320, 65)
	button.focus_mode = Control.FOCUS_ALL

	# 应用主题样式
	UITheme.apply_button_style(button, 22)

	# 增强按钮样式
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.08, 0.18, 0.85)
	normal_style.border_width_left = 0
	normal_style.border_width_right = 0
	normal_style.border_width_top = 2
	normal_style.border_width_bottom = 2
	normal_style.border_color = UITheme.PRIMARY_DARK
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.corner_radius_bottom_left = 8
	normal_style.corner_radius_bottom_right = 8
	normal_style.shadow_color = Color(0, 0, 0, 0.3)
	normal_style.shadow_size = 4
	normal_style.shadow_offset = Vector2(0, 2)
	button.add_theme_stylebox_override("normal", normal_style)

	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.18, 0.14, 0.3, 0.95)
	hover_style.border_color = UITheme.PRIMARY
	hover_style.border_width_left = 4
	hover_style.shadow_size = 8
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)

	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = Color(0.22, 0.18, 0.35, 1.0)
	pressed_style.border_color = UITheme.PRIMARY_LIGHT
	pressed_style.border_width_left = 6
	button.add_theme_stylebox_override("pressed", pressed_style)

	# 悬停动画
	button.mouse_entered.connect(func():
		if is_instance_valid(self) and is_instance_valid(button):
			_on_button_hover(button, true)
	)
	button.mouse_exited.connect(func():
		if is_instance_valid(self) and is_instance_valid(button):
			_on_button_hover(button, false)
	)
	button.focus_entered.connect(func():
		if is_instance_valid(self) and is_instance_valid(button):
			_on_button_hover(button, true)
	)
	button.focus_exited.connect(func():
		if is_instance_valid(self) and is_instance_valid(button):
			_on_button_hover(button, false)
	)

	return button

func _on_button_hover(button: Button, hovered: bool):
	var tween = button.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	if hovered:
		tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
	else:
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)

func _create_floating_particles():
	# 检查 particles_container 是否存在
	if not particles_container:
		push_warning("[TitleScreen] particles_container 节点未找到，跳过粒子创建")
		return

	# 创建浮动粒子效果
	for i in range(15):
		var particle = ColorRect.new()
		particle.color = UITheme.PRIMARY.lightened(0.3)
		particle.color.a = randf_range(0.1, 0.3)
		var size = randf_range(3, 8)
		particle.custom_minimum_size = Vector2(size, size)
		particle.size = Vector2(size, size)
		particle.position = Vector2(
			randf_range(0, get_viewport_rect().size.x),
			randf_range(0, get_viewport_rect().size.y)
		)
		particles_container.add_child(particle)
		particle_nodes.append(particle)
		_animate_particle(particle)

func _animate_particle(particle: ColorRect):
	if not is_instance_valid(particle) or not is_instance_valid(self):
		return

	# 如果已有tween在运行，先停止它
	if particle.has_meta("particle_tween"):
		var old_tween = particle.get_meta("particle_tween")
		if is_instance_valid(old_tween):
			old_tween.kill()

	var tween = particle.create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	particle.set_meta("particle_tween", tween)

	var start_y = particle.position.y
	var end_y = start_y - randf_range(100, 300)
	var duration = randf_range(4, 8)

	tween.tween_property(particle, "position:y", end_y, duration)
	tween.parallel().tween_property(particle, "modulate:a", 0.0, duration)
	tween.tween_callback(func():
		if is_instance_valid(particle) and is_instance_valid(self) and is_inside_tree():
			particle.position.y = get_viewport_rect().size.y + 50
			particle.position.x = randf_range(0, get_viewport_rect().size.x)
			particle.modulate.a = 1.0
			_animate_particle(particle)
	)

func _animate_intro():
	# 标题淡入动画
	if title_label:
		title_label.modulate.a = 0
	if subtitle_label:
		subtitle_label.modulate.a = 0

	if title_label and subtitle_label:
		var tween = create_tween()
		tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
		tween.parallel().tween_property(title_label, "position:y", title_label.position.y, 0.8).from(title_label.position.y - 30)
		tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)

	# 按钮逐个淡入和缩放
	for i in range(buttons.size()):
		var button = buttons[i]
		button.modulate.a = 0
		button.scale = Vector2(0.8, 0.8)

		await get_tree().create_timer(0.1).timeout

		var btn_tween = button.create_tween()
		btn_tween.set_ease(Tween.EASE_OUT)
		btn_tween.set_trans(Tween.TRANS_BACK)
		btn_tween.set_parallel(true)
		btn_tween.tween_property(button, "modulate:a", 1.0, 0.25)
		btn_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.35)

func _input(event):
	# 支持键盘导航
	if event.is_action_pressed("ui_up"):
		_navigate_menu(-1)
	elif event.is_action_pressed("ui_down"):
		_navigate_menu(1)
	elif event.is_action_pressed("ui_accept"):
		if selected_index >= 0 and selected_index < buttons.size():
			buttons[selected_index].emit_signal("pressed")

func _navigate_menu(direction: int):
	selected_index = (selected_index + direction + buttons.size()) % buttons.size()
	buttons[selected_index].grab_focus()

# --- 菜单回调 ---

func _on_start_game():
	_transition_to_scene("res://MainMenu.tscn")

func _on_meta_upgrade():
	_transition_to_scene("res://MetaUpgradeMenu.tscn")

func _on_settings():
	_transition_to_scene("res://SettingsMenu.tscn")

func _on_quit():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(self):
			get_tree().quit()
	)

func _transition_to_scene(scene_path: String):
	# 淡出过渡效果
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(self):
			get_tree().change_scene_to_file(scene_path)
	)
