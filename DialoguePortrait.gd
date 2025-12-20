extends Control
class_name DialoguePortrait

# DialoguePortrait - 通用对话管理器 (Unified Dialogue System)
# 支持播放对话序列，处理输入，管理暂停

signal dialogue_finished
# 兼容旧代码 (如 NitoriNPC)
signal dialogue_closed 
signal dialogue_sequence_started
signal dialogue_advanced

# 预设角色配置
enum CharacterPortrait {
	MOKOU, NITORI, KAGUYA, YOUMU, CIRNO
}

# 角色名称映射
const CHARACTER_NAMES = {
	CharacterPortrait.MOKOU: "藤原妹红",
	CharacterPortrait.NITORI: "河城荷取",
	CharacterPortrait.KAGUYA: "蓬莱山辉夜",
	CharacterPortrait.YOUMU: "魂魄妖梦",
	CharacterPortrait.CIRNO: "琪露诺",
}

# UI节点引用
var background: ColorRect
var portrait_texture: TextureRect
var dialogue_panel: Panel
var name_label: Label
var text_label: Label
var continue_indicator: Label

# 状态
var current_sequence: Array = []
var current_index: int = 0
var is_active: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # 始终运行
	z_index = 4096 # 确保最上层
	
	# 关键：设置自身为全屏，否则子节点的Anchor可能不生效
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 强制重建UI，防止残留或未初始化
	for child in get_children():
		child.queue_free()
	_create_ui()
	
	visible = false # 初始隐藏

func _process(delta):
	if visible and dialogue_panel:
		# 暴力强制布局 - 每一帧都重置位置，确保不被挤压
		var vp_size = get_viewport_rect().size
		
		# 1. 确保根节点填满屏幕
		size = vp_size
		position = Vector2.ZERO
		background.size = vp_size
		
		# 2. 面板：底部居中
		var panel_w = vp_size.x * 0.8
		var panel_h = 320.0
		dialogue_panel.size = Vector2(panel_w, panel_h)
		dialogue_panel.position = Vector2((vp_size.x - panel_w) / 2.0, vp_size.y - panel_h - 20.0)
		
		# 3. 立绘：左下角
		if portrait_texture.texture:
			var aspect = portrait_texture.texture.get_width() / float(portrait_texture.texture.get_height())
			var h = vp_size.y * 0.65
			var w = h * aspect
			portrait_texture.size = Vector2(w, h)
			portrait_texture.position = Vector2(vp_size.x * 0.05, vp_size.y - h)
			
		# 4. 文字：向右偏移避开立绘 (加大偏移)
		var text_offset_x = 550.0
		name_label.position = Vector2(text_offset_x, 30) # 名字稍微下移
		text_label.position = Vector2(text_offset_x, 100) # 正文下移，拉大间距
		text_label.size = Vector2(panel_w - text_offset_x - 40, panel_h - 120)
		continue_indicator.position = Vector2(panel_w - 180, panel_h - 40)

func _create_ui():
	# 1. 全屏背景
	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.4)
	add_child(background)
	
	# 2. 对话框面板 - 磨砂半透明，无边框
	dialogue_panel = Panel.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.7) # 黑色半透明
	style.set_corner_radius_all(12)
	# 去除边框
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	dialogue_panel.add_theme_stylebox_override("panel", style)
	add_child(dialogue_panel)
	
	# 3. 立绘
	portrait_texture = TextureRect.new()
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(portrait_texture)
	
	# 4. 文本内容
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 48)
	name_label.add_theme_color_override("font_color", Color("#ffd700"))
	dialogue_panel.add_child(name_label)
	
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 36)
	text_label.add_theme_color_override("font_color", Color.WHITE)
	dialogue_panel.add_child(text_label)
	
	continue_indicator = Label.new()
	continue_indicator.text = "点击继续..."
	continue_indicator.add_theme_font_size_override("font_size", 18)
	continue_indicator.add_theme_color_override("font_color", Color(1,1,1,0.6))
	dialogue_panel.add_child(continue_indicator)

func show_sequence(sequence: Array):
	print("[DialoguePortrait] show_sequence called with ", sequence.size(), " items")
	if sequence.is_empty(): return
		
	current_sequence = sequence
	current_index = 0
	is_active = true
	visible = true
	
	if not background: _create_ui()
	
	get_tree().paused = true
	dialogue_sequence_started.emit()
	_show_current_line()

func _show_current_line():
	if current_index >= current_sequence.size():
		_end_dialogue()
		return
		
	var data = current_sequence[current_index]
	name_label.text = data.get("speaker", "???")
	text_label.text = data.get("text", "...")
	
	var portrait_path = data.get("portrait")
	if portrait_path and ResourceLoader.exists(portrait_path):
		var tex = load(portrait_path)
		if tex:
			portrait_texture.texture = tex
			# 动态布局在 _process 中处理
			portrait_texture.visible = true
		else:
			portrait_texture.visible = false
	else:
		portrait_texture.visible = false

func _input(event):
	if not is_active: return
	
	if event.is_action_pressed("ui_accept") or \
	   event.is_action_pressed("interact") or \
	   (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE) or \
	   (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		
		get_viewport().set_input_as_handled()
		_advance()

func _advance():
	current_index += 1
	if current_index >= current_sequence.size():
		_end_dialogue()
	else:
		_show_current_line()
		dialogue_advanced.emit()

func _end_dialogue():
	is_active = false
	visible = false
	get_tree().paused = false
	dialogue_finished.emit()
	dialogue_closed.emit()

# 兼容旧接口
func show_dialogue(character: int, text: String):
	var name = CHARACTER_NAMES.get(character, "???")
	# 尝试映射旧版立绘路径
	var portrait = ""
	match character:
		CharacterPortrait.MOKOU: portrait = "res://assets/characters/1C.png"
		CharacterPortrait.NITORI: portrait = "res://assets/characters/2C.png"
		CharacterPortrait.KAGUYA: portrait = "res://assets/characters/4C.png"
		CharacterPortrait.YOUMU: portrait = "res://assets/characters/youmu_portrait.png"
		CharacterPortrait.CIRNO: portrait = "res://assets/characters/cirno_portrait.png"
	
	show_sequence([{"speaker": name, "text": text, "portrait": portrait}])
