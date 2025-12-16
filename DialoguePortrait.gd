extends Control
class_name DialoguePortrait

# DialoguePortrait - 通用对话立绘系统
# 显示角色立绘和对话文本

enum CharacterPortrait {
	MOKOU,    # 妹红 - 1.png
	NITORI,   # 河童 - 2.png
	KAGUYA,   # 辉夜
	YOUMU,    # 妖梦
	CIRNO,    # 琪露诺
}

# 立绘路径映射 - 使用C版本（裁剪版，适合对话框）
const PORTRAIT_PATHS = {
	CharacterPortrait.MOKOU: "res://assets/characters/1C.png",   # 妹红 - 对话版
	CharacterPortrait.NITORI: "res://assets/characters/2C.png",  # 河童 - 对话版
	CharacterPortrait.KAGUYA: "res://assets/characters/huiye.png",
	CharacterPortrait.YOUMU: "res://assets/characters/yaomeng2.png",
	CharacterPortrait.CIRNO: "res://assets/characters/9.png",
}

# 角色名称
const CHARACTER_NAMES = {
	CharacterPortrait.MOKOU: "藤原妹红",
	CharacterPortrait.NITORI: "河城荷取",
	CharacterPortrait.KAGUYA: "蓬莱山辉夜",
	CharacterPortrait.YOUMU: "魂魄妖梦",
	CharacterPortrait.CIRNO: "琪露诺",
}

# UI节点
var portrait_texture: TextureRect = null
var name_label: Label = null
var dialogue_label: Label = null
var background: ColorRect = null
var close_button: Button = null

# 当前状态
var is_showing: bool = false
var current_character: CharacterPortrait = CharacterPortrait.MOKOU

signal dialogue_closed

func _ready():
	# 确保在暂停时也能运行
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 初始隐藏
	visible = false
	# 确保在最上层
	z_index = 200
	_create_ui()
	print("[DialoguePortrait] 对话系统初始化完成, z_index=200")

func _create_ui():
	"""创建对话UI"""
	# 设置为全屏覆盖 - 使用固定大小
	size = Vector2(1920, 1080)
	position = Vector2(0, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止点击穿透

	# 半透明黑色背景
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.7)
	background.size = Vector2(1920, 1080)
	background.position = Vector2(0, 0)
	add_child(background)

	# 对话框容器（屏幕底部）
	var dialogue_container = Control.new()
	dialogue_container.name = "DialogueContainer"
	dialogue_container.position = Vector2(0, 780)  # 屏幕底部往上300像素 (1080-300)
	dialogue_container.size = Vector2(1920, 280)  # 宽度1920，高度280
	add_child(dialogue_container)

	# 对话框背景
	var dialogue_bg = ColorRect.new()
	dialogue_bg.color = Color(0.1, 0.1, 0.15, 0.95)
	dialogue_bg.size = Vector2(1920, 280)
	dialogue_bg.position = Vector2(0, 0)
	dialogue_container.add_child(dialogue_bg)

	# 立绘纹理 - 直接添加到对话框容器
	portrait_texture = TextureRect.new()
	portrait_texture.name = "PortraitTexture"
	portrait_texture.position = Vector2(30, 20)  # 对话框内左侧
	portrait_texture.size = Vector2(150, 240)  # 固定显示区域
	portrait_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dialogue_container.add_child(portrait_texture)

	# 文字容器（右侧）- 立绘旁边
	var text_container = Control.new()
	text_container.name = "TextContainer"
	text_container.position = Vector2(300, 40)  # 往右移以避免重叠
	text_container.size = Vector2(1500, 220)
	dialogue_container.add_child(text_container)

	# 角色名称
	name_label = Label.new()
	name_label.text = "角色名"
	name_label.position = Vector2(0, 0)
	name_label.add_theme_font_size_override("font_size", 32) # 增大字体
	name_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	text_container.add_child(name_label)

	# 对话内容
	dialogue_label = Label.new()
	dialogue_label.text = "对话内容"
	dialogue_label.position = Vector2(0, 50)
	dialogue_label.size = Vector2(1400, 150)
	dialogue_label.add_theme_font_size_override("font_size", 28) # 增大字体
	dialogue_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_container.add_child(dialogue_label)

	# 关闭按钮 - 右下角
	close_button = Button.new()
	close_button.text = "继续 [SPACE / E]"
	close_button.position = Vector2(1700, 220)
	close_button.size = Vector2(180, 40)
	close_button.add_theme_font_size_override("font_size", 16)
	dialogue_container.add_child(close_button)
	close_button.pressed.connect(_on_close_button_pressed)

func show_dialogue(character: CharacterPortrait, dialogue_text: String):
	"""显示对话"""
	current_character = character

	# 加载立绘
	var portrait_path = PORTRAIT_PATHS.get(character, "")
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		var texture = load(portrait_path)
		portrait_texture.texture = texture
		portrait_texture.visible = true
		print("[DialoguePortrait] 立绘已加载: ", portrait_path)
	else:
		portrait_texture.visible = false
		print("[DialoguePortrait] 警告: 找不到立绘: ", portrait_path)

	# 设置角色名
	var character_name = CHARACTER_NAMES.get(character, "未知角色")
	name_label.text = character_name

	# 设置对话文本
	dialogue_label.text = dialogue_text

	# 显示对话框
	visible = true
	is_showing = true
	
	# 暂停游戏
	get_tree().paused = true

	print("[DialoguePortrait] 对话框已显示, visible=", visible)

func _input(event):
	if not is_showing:
		return

	# 按空格或E键关闭对话
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			close_dialogue()

	# 鼠标点击关闭对话
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			close_dialogue()

func _on_close_button_pressed():
	"""关闭按钮被点击"""
	close_dialogue()

func close_dialogue():
	"""关闭对话"""
	if not is_showing:
		return

	visible = false
	is_showing = false
	
	# 恢复游戏
	get_tree().paused = false
	
	dialogue_closed.emit()

func is_dialogue_showing() -> bool:
	"""检查对话是否正在显示"""
	return is_showing
