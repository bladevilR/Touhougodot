extends Control
class_name VictoryScreen

var visible_state: bool = false
var game_stats: Dictionary = {}

func _ready():
	# 连接到Boss被击败信号
	SignalBus.boss_defeated.connect(_on_boss_defeated)
	visible = false

func _on_boss_defeated():
	"""显示胜利界面 - 完整的结算信息"""
	print("VictoryScreen: 显示胜利界面")
	visible = true
	visible_state = true

	# 获取游戏统计数据
	_collect_game_stats()

	# 创建背景遮罩
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 主容器
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.size = Vector2(600, 500)
	main_container.add_theme_constant_override("separation", 20)
	add_child(main_container)

	# 胜利标题
	var title = Label.new()
	title.text = "胜利！"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("#ffd700"))
	main_container.add_child(title)

	# 分隔线
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 10)
	main_container.add_child(separator)

	# 战斗统计
	var stats_label = Label.new()
	stats_label.text = _format_stats()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 20)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	main_container.add_child(stats_label)

	# 奖励展示
	var reward_label = Label.new()
	reward_label.text = "获得奖励：\n★ 经验值大幅提升\n★ 解锁新技能\n★ 特殊成就达成"
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 18)
	reward_label.add_theme_color_override("font_color", Color("#90ee90"))
	main_container.add_child(reward_label)

	# 操作提示
	var tip_label = Label.new()
	tip_label.text = "按 R 键重新开始\n按 M 键返回主菜单"
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 16)
	tip_label.add_theme_color_override("font_color", Color("#cccccc"))
	main_container.add_child(tip_label)

func _process(_delta):
	"""处理按键输入"""
	if visible_state:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			# 重新开始
			visible = false
			visible_state = false
			get_tree().change_scene_to_file("res://world.tscn")
		elif Input.is_action_just_pressed("ui_cancel") or Input.is_key_pressed(KEY_M):
			# 返回主菜单
			visible = false
			visible_state = false
			get_tree().change_scene_to_file("res://MainMenu.tscn")

func _collect_game_stats():
	"""收集游戏统计信息"""
	game_stats.clear()

	# 从ExperienceManager获取经验值
	var exp_manager = get_tree().get_first_node_in_group("experience_manager")
	if exp_manager:
		if "current_level" in exp_manager:
			game_stats["current_level"] = exp_manager["current_level"]
		else:
			game_stats["current_level"] = 1

		if "current_xp" in exp_manager:
			game_stats["current_xp"] = exp_manager["current_xp"]
		else:
			game_stats["current_xp"] = 0

		if "xp_to_next" in exp_manager:
			game_stats["xp_to_next"] = exp_manager["xp_to_next"]
		else:
			game_stats["xp_to_next"] = 100

	# 从RoomManager获取房间信息
	var room_manager = get_tree().get_first_node_in_group("room_manager")
	if room_manager:
		if room_manager.has_method("get"):
			game_stats["rooms_cleared"] = room_manager.current_room_index + 1

	# 从SignalBus获取击杀数
	# 这里简化处理，实际可能需要从游戏状态中获取

func _format_stats() -> String:
	"""格式化统计信息显示"""
	var stats_text = "战斗统计：\n"
	stats_text += "----------------------------------------\n"
	stats_text += "当前等级：Lv.%d\n" % game_stats.get("current_level", 1)
	stats_text += "经验值：%d / %d\n" % [game_stats.get("current_xp", 0), game_stats.get("xp_to_next", 100)]
	stats_text += "清理房间：%d 个\n" % game_stats.get("rooms_cleared", 0)
	stats_text += "----------------------------------------\n"
	return stats_text
