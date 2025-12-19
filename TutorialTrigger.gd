extends Area2D
class_name TutorialTrigger

var has_shown: bool = false

func _ready():
	add_to_group("tutorial_trigger")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not has_shown:
		has_shown = true
		print("触发教程！")
		_show_tutorial()

func _show_tutorial():
	"""显示教程UI"""
	var tutorial_ui = Control.new()
	tutorial_ui.name = "TutorialUI"
	tutorial_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(tutorial_ui)

	# 添加背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_ui.add_child(bg)

	# 教程文字
	var text = Label.new()
	text.text = "操作指引\n\nWASD - 移动\n空格 - 火焰飞踢（消耗10%HP）\n鼠标左键 - 轻击\n鼠标右键 - 重击（击飞敌人）\nE - 互动\n\n消灭敌人获得经验升级\n击败Boss通关！"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.add_theme_font_size_override("font_size", 24)
	text.add_theme_color_override("font_color", Color.WHITE)
	tutorial_ui.add_child(text)

	# 按E关闭提示
	var hint = Label.new()
	hint.text = "按 E 键继续"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position.y = 400
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color("#ffff00"))
	tutorial_ui.add_child(hint)

	# 监听E键
	var dialog_closed = false
	while not dialog_closed:
		await get_tree().process_frame
		if Input.is_action_just_pressed("interact"):
			dialog_closed = true

	tutorial_ui.queue_free()
	print("教程结束")
