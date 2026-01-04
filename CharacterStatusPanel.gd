extends CanvasLayer

# CharacterStatusPanel - 角色状态面板 (Tab键打开)
# 显示左侧大立绘 + 右侧角色信息

var panel_visible: bool = false
var player: CharacterBody2D = null  # 玩家引用

# UI节点
var overlay: ColorRect = null
var portrait: TextureRect = null
var info_container: VBoxContainer = null

# 角色信息标签
var name_label: Label = null
var level_label: Label = null
var hp_label: Label = null
var stats_label: Label = null
var skills_label: Label = null
var weapons_label: Label = null
var mission_label: Label = null

func _ready():
	# 关键修复：确保在暂停时也能接收输入，防止卡死
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 创建UI
	_create_ui()

	# 默认隐藏
	overlay.visible = false

func _unhandled_input(event):
	# Tab键切换显示/隐藏
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		print("[StatusPanel] Tab pressed, toggling...")
		get_viewport().set_input_as_handled() # 消耗事件
		toggle_panel()

func toggle_panel():
	"""切换面板显示状态"""
	panel_visible = !panel_visible
	overlay.visible = panel_visible

	if panel_visible:
		# 打开时暂停游戏
		get_tree().paused = true
		_update_info()
	else:
		# 关闭时恢复游戏
		get_tree().paused = false

func _create_ui():
	"""创建UI界面"""
	# 整体白色背景（全屏）
	overlay = ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = Color(1.0, 1.0, 1.0, 0.98)  # 整体白色背景
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止点击穿透
	add_child(overlay)

	# 左侧立绘（放大到300x450）
	portrait = TextureRect.new()
	portrait.name = "Portrait"
	var portrait_path = "res://assets/characters/1.png"
	if ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
		portrait.position = Vector2(20, 50)
		portrait.custom_minimum_size = Vector2(675, 1012) 
		portrait.size = Vector2(675, 1012)      
		portrait.set_size(Vector2(675, 1012))   
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE 
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		overlay.add_child(portrait)

	# 右侧信息容器（不需要单独背景，因为整体已经是白色）
	info_container = VBoxContainer.new()
	info_container.name = "InfoContainer"
	info_container.position = Vector2(700, 100)  # 向右移动避开超大立绘
	info_container.size = Vector2(650, 700)
	info_container.add_theme_constant_override("separation", 15)
	overlay.add_child(info_container)

	# 创建标题
	var title = Label.new()
	title.text = "角色状态"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.1, 0.1, 0.2))  # 深色标题
	info_container.add_child(title)

	# 分隔线
	var separator1 = HSeparator.new()
	separator1.add_theme_constant_override("separation", 2)
	info_container.add_child(separator1)

	# 角色名称和等级
	name_label = Label.new()
	name_label.text = "藤原妹红"
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.0))  # 橙红色（适配妹红）
	info_container.add_child(name_label)

	level_label = Label.new()
	level_label.text = "Lv. 1"
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))  # 深色
	info_container.add_child(level_label)

	hp_label = Label.new()
	hp_label.text = "HP: 100 / 100"
	hp_label.add_theme_font_size_override("font_size", 20)
	hp_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))  # 深色
	info_container.add_child(hp_label)

	# 分隔线
	var separator2 = HSeparator.new()
	info_container.add_child(separator2)

	# 角色属性
	var stats_title = Label.new()
	stats_title.text = "◆ 角色属性"
	stats_title.add_theme_font_size_override("font_size", 22)
	stats_title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.6))  # 深蓝色
	info_container.add_child(stats_title)

	stats_label = Label.new()
	stats_label.text = "力量: 1.0\n范围: 1.0\n冷却: 1.0\n速度: 1.0"
	stats_label.add_theme_font_size_override("font_size", 18)
	stats_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))  # 深色
	info_container.add_child(stats_label)

	# 分隔线
	var separator3 = HSeparator.new()
	info_container.add_child(separator3)

	# 已习得技能
	var skills_title = Label.new()
	skills_title.text = "◆ 已习得技能"
	skills_title.add_theme_font_size_override("font_size", 22)
	skills_title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.6))  # 深蓝色
	info_container.add_child(skills_title)

	skills_label = Label.new()
	skills_label.text = "[SPACE] 不死凤凰 - 重生技能"
	skills_label.add_theme_font_size_override("font_size", 18)
	skills_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))  # 深色
	info_container.add_child(skills_label)

	# 分隔线
	var separator4 = HSeparator.new()
	info_container.add_child(separator4)

	# 装备武器
	var weapons_title = Label.new()
	weapons_title.text = "◆ 装备武器"
	weapons_title.add_theme_font_size_override("font_size", 22)
	weapons_title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.6))  # 深蓝色
	info_container.add_child(weapons_title)

	weapons_label = Label.new()
	weapons_label.text = "无"
	weapons_label.add_theme_font_size_override("font_size", 18)
	weapons_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))  # 深色
	info_container.add_child(weapons_label)

	# 分隔线
	var separator5 = HSeparator.new()
	info_container.add_child(separator5)

	# 当前任务
	var mission_title = Label.new()
	mission_title.text = "◆ ��前任务"
	mission_title.add_theme_font_size_override("font_size", 22)
	mission_title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.6))  # 深蓝色
	info_container.add_child(mission_title)

	mission_label = Label.new()
	mission_label.text = "探索迷途竹林，寻找出路"
	mission_label.add_theme_font_size_override("font_size", 18)
	mission_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.3))  # 深色
	info_container.add_child(mission_label)

	# 关闭提示
	var close_hint = Label.new()
	close_hint.text = "\n[按 Tab 键关闭]"
	close_hint.add_theme_font_size_override("font_size", 20)
	close_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))  # 灰色提示
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_container.add_child(close_hint)

func _update_info():
	"""更新角色信息显示"""
	# 获取玩家引用
	if not player:
		player = get_tree().get_first_node_in_group("player")

	# 强制重置立绘大小（防止布局系统覆盖）
	if portrait:
		portrait.custom_minimum_size = Vector2(675, 1012) 
		portrait.size = Vector2(675, 1012)
		portrait.position = Vector2(20, 50)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		print("DEBUG: Portrait size forced to ", portrait.size)

	# 固定使用妹红（已移除多角色系统）
	var char_id = GameConstants.CharacterId.MOKOU
	if SignalBus.selected_character_id >= 0:
		char_id = SignalBus.selected_character_id

	var char_data = CharacterData.CHARACTERS.get(char_id)
	if char_data:
		if name_label:
			name_label.text = char_data.char_name
			name_label.add_theme_color_override("font_color", char_data.color.lightened(0.2))
		
		# 更新立绘
		var sprite_paths = [
			"res://assets/leimuF.png",              # Reimu
			"res://assets/characters/1.png",        # Mokou
			"res://assets/marisaF.png",             # Marisa
			"res://assets/sakuyaF.png",             # Sakuya
			"res://assets/taotie.png",              # Yuma
			"res://assets/koyiF.png"                # Koishi
		]
		if char_id < sprite_paths.size() and portrait:
			var portrait_path = sprite_paths[char_id]
			if ResourceLoader.exists(portrait_path):
				portrait.texture = load(portrait_path)
				print("[StatusPanel] Portrait updated to: ", portrait_path)

	if not player:
		return

	# 更新等级和血量
	if player.has_method("get_character_stats"):
		var stats = player.get_character_stats()

		if level_label:
			level_label.text = "Lv. " + str(player.level if "level" in player else 1)

		if stats_label:
			stats_label.text = "力量: %.1f\n范围: %.1f\n冷却: %.1f\n速度: %.1f" % [
				stats.get("might", 1.0),
				stats.get("area", 1.0),
				stats.get("cooldown", 1.0),
				stats.get("speed", 1.0)
			]

	# 更新血量
	var health_comp = player.get_node_or_null("HealthComponent")
	if health_comp and hp_label:
		hp_label.text = "HP: %d / %d" % [int(health_comp.current_hp), int(health_comp.max_hp)]

	# 更新武器
	var weapon_system = player.get_node_or_null("WeaponSystem")
	if weapon_system and weapons_label:
		var weapons = weapon_system.get_owned_weapon_ids() if weapon_system.has_method("get_owned_weapon_ids") else []
		if weapons.size() > 0:
			var weapon_text = ""
			for weapon_id in weapons:
				var weapon_data = weapon_system.get_weapon_data(weapon_id) if weapon_system.has_method("get_weapon_data") else {}
				var weapon_name = weapon_id  # 默认使用ID
				var weapon_level = weapon_data.get("level", 1)

				# WeaponConfig是类对象，需要访问属性而不是用get
				if weapon_data.has("config") and weapon_data.config != null:
					weapon_name = weapon_data.config.weapon_name

				weapon_text += "• " + weapon_name + " Lv." + str(weapon_level) + "\n"
			weapons_label.text = weapon_text
		else:
			weapons_label.text = "无装备武器"

	# 更新房间信息（作为任务描述）
	var room_manager = get_tree().get_first_node_in_group("room_manager")
	if room_manager and mission_label:
		var current_room = room_manager.current_room_index if "current_room_index" in room_manager else 0
		mission_label.text = "当前房间: %d\n探索迷途竹林，寻找出路" % [current_room + 1]
