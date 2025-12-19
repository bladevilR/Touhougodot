extends Control
class_name VictoryScreen

var visible_state: bool = false

func _ready():
	# 连接到Boss被击败信号
	SignalBus.boss_defeated.connect(_on_boss_defeated)
	visible = false

func _on_boss_defeated():
	"""显示胜利界面"""
	print("VictoryScreen: 显示胜利界面")
	visible = true
	visible_state = true

	# 创建胜利文字
	var victory_label = Label.new()
	victory_label.text = "胜利！\n感谢参与测试"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_label.add_theme_font_size_override("font_size", 48)
	victory_label.add_theme_color_override("font_color", Color("#ffd700"))
	add_child(victory_label)

	# 添加背景遮罩
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)

	# 3秒后自动隐藏（可选）
	await get_tree().create_timer(3.0).timeout
	if visible_state:
		visible = false
