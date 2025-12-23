extends Area2D
class_name EnchantShop

# EnchantShop - 附魔商店
# 玩家可以花费転流购买元素附魔

var player_in_range: bool = false
var shop_ui: Control = null

# 附魔价格配置
const ENCHANT_PRICES = {
	GameConstants.ElementType.FIRE: 50,
	GameConstants.ElementType.ICE: 50,
	GameConstants.ElementType.POISON: 60,
	GameConstants.ElementType.OIL: 55,
	GameConstants.ElementType.LIGHTNING: 70,
	GameConstants.ElementType.GRAVITY: 80,
}

# 附魔持续时间
const ENCHANT_DURATION: float = 45.0

# 元素名称映射
const ELEMENT_NAMES = {
	GameConstants.ElementType.FIRE: "火焰附魔",
	GameConstants.ElementType.ICE: "冰霜附魔",
	GameConstants.ElementType.POISON: "剧毒附魔",
	GameConstants.ElementType.OIL: "油脂附魔",
	GameConstants.ElementType.LIGHTNING: "雷电附魔",
	GameConstants.ElementType.GRAVITY: "重力附魔",
}

# 元素颜色
const ELEMENT_COLORS = {
	GameConstants.ElementType.FIRE: Color("#ff4500"),
	GameConstants.ElementType.ICE: Color("#00bfff"),
	GameConstants.ElementType.POISON: Color("#9370db"),
	GameConstants.ElementType.OIL: Color("#8b4513"),
	GameConstants.ElementType.LIGHTNING: Color("#ffd700"),
	GameConstants.ElementType.GRAVITY: Color("#9932cc"),
}

func _ready():
	add_to_group("enchant_shop")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 设置碰撞层
	collision_layer = 0
	collision_mask = 1  # 只检测玩家

	# 创建碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 100.0  # 交互范围
	collision.shape = shape
	add_child(collision)

	# 创建视觉提示
	_create_visual()

func _create_visual():
	"""创建视觉提示"""
	var sprite = Sprite2D.new()
	sprite.name = "ShopSprite"

	# 使用魔理沙地图形象
	var texture = load("res://assets/characters/marisa3.png")
	if texture:
		sprite.texture = texture
		sprite.scale = Vector2(0.05, 0.05) # 调小一点 (was 0.08)
	else:
		# Fallback if texture missing
		var size = 64
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		image.fill(Color("#cc66ff"))
		sprite.texture = ImageTexture.create_from_image(image)

	add_child(sprite)

	# 添加文字提示
	var label = Label.new()
	label.text = "魔理沙的附魔店"
	label.position = Vector2(-60, 60)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#ffd700")) # 金色
	add_child(label)
	
	# 添加影子
	var map_system = get_tree().get_first_node_in_group("map_system")
	if map_system and map_system.has_method("create_shadow_for_entity"):
		# 手动调整大小
		var shadow_size = Vector2(60, 20)
		map_system.create_shadow_for_entity(self, shadow_size, Vector2(0, -10))

var is_dialogue_active: bool = false
var dialogue_ui: Control = null

func _process(delta):
	# 检测E键打开商店
	if player_in_range and Input.is_action_just_pressed("interact"):
		if not shop_ui and not is_dialogue_active:
			_start_interaction()

func _start_interaction():
	"""开始交互 - 完整对话版本"""
	is_dialogue_active = true

	var dialogue_data = [
		{
			"speaker": "妹红",
			"text": "今天也来采蘑菇吗？",
			"portrait": "res://assets/characters/1C.png"
		},
		{
			"speaker": "魔理沙",
			"text": "没错！要不要试试我新研制的魔法药剂？可以附魔'元素'属性，多种元素之间可以触发奇妙的效果哦 ze~",
			"portrait": "res://assets/characters/3C.png"
		}
	]

	await _play_dialogue(dialogue_data)
	is_dialogue_active = false
	_open_shop()

func _play_dialogue(data: Array):
	var dm = _get_dialogue_manager()
	if dm:
		dm.show_sequence(data)
		await dm.dialogue_finished
	else:
		await get_tree().create_timer(1.0).timeout

func _get_dialogue_manager() -> Node:
	# 检查是否存在 DialogueLayer/DialogueManager
	var existing_layer = get_tree().root.get_node_or_null("DialogueLayer")
	if existing_layer:
		return existing_layer.get_node_or_null("DialogueManager")

	# 创建新的 Layer 和 Manager
	var layer = CanvasLayer.new()
	layer.layer = 128 # 确保在最上层
	layer.name = "DialogueLayer"
	get_tree().root.add_child(layer)

	var DialoguePortraitScript = load("res://DialoguePortrait.gd")
	var dm = DialoguePortraitScript.new()
	dm.name = "DialogueManager"
	layer.add_child(dm)

	return dm
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		_show_interaction_hint(true)

		# 显示简短对话（简化版本）
		print("Enchantress: 欢迎来到附魔商店！")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		_show_interaction_hint(false)

func _show_interaction_hint(show: bool):
	"""显示/隐藏交互提示"""
	var hint = get_node_or_null("InteractionHint")

	if show and not hint:
		hint = Label.new()
		hint.name = "InteractionHint"
		hint.text = "按 E 对话"
		hint.position = Vector2(-60, -40)
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color("#ffff00"))
		add_child(hint)
	elif not show and hint:
		hint.queue_free()

func _open_shop():
	"""打开附魔商店UI"""
	if shop_ui:
		return  # 已经打开

	# 获取经验管理器以获取転流数量
	var exp_manager = get_tree().get_first_node_in_group("experience_manager")
	if not exp_manager:
		print("错误：找不到ExperienceManager")
		return

	# 创建商店UI
	shop_ui = Control.new()
	shop_ui.name = "EnchantShopUI"
	shop_ui.process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时也能响应输入
	shop_ui.set_anchors_preset(Control.PRESET_FULL_RECT) # 确保覆盖全屏以便居中

	# 获取画布层
	var canvas_layer = get_tree().get_first_node_in_group("ui")
	if not canvas_layer:
		print("错误：找不到UI层")
		return

	canvas_layer.add_child(shop_ui)

	# 全屏半透明遮罩
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_ui.add_child(overlay)
	
	# 魔理沙立绘 (大立绘，放在最底层背景上)
	# 参考 NitoriShopUI: position(50, 100), width=500
	var portrait = TextureRect.new()
	var portrait_tex = load("res://assets/characters/3C.png")
	if portrait_tex:
		portrait.texture = portrait_tex
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# 自动计算高度以保持比例
		var aspect = portrait_tex.get_width() / float(portrait_tex.get_height())
		var h = 1080 * 0.5 # 占屏幕高度的50% (从60%减少)
		var w = h * aspect
		
		portrait.size = Vector2(w, h)
		portrait.position = Vector2(50, 1080 - h) # 左下角对齐
		
		# 稍微半透明
		portrait.modulate.a = 0.95
		shop_ui.add_child(portrait)

	# 商店面板 - 居中显示 (稍微右移以避开立绘)
	var panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -300  # 稍微右移
	panel.offset_top = -300
	panel.offset_right = 500
	panel.offset_bottom = 300
	panel.size = Vector2(800, 600)
	shop_ui.add_child(panel)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 0.95)
	bg.size = Vector2(800, 600)
	panel.add_child(bg)

	# 标题
	var title = Label.new()
	title.text = "魔理沙的魔法店"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#ffd700"))
	panel.add_child(title)

	# 显示当前転流
	var tenryu_label = Label.new()
	tenryu_label.text = "拥有転流: " + str(exp_manager.tenryu)
	tenryu_label.position = Vector2(20, 60)
	tenryu_label.add_theme_font_size_override("font_size", 20)
	tenryu_label.add_theme_color_override("font_color", Color("#ff8800"))
	panel.add_child(tenryu_label)

	# 创建附魔选项
	var y_offset = 120
	var element_types = [
		GameConstants.ElementType.FIRE,
		GameConstants.ElementType.ICE,
		GameConstants.ElementType.LIGHTNING,
		GameConstants.ElementType.POISON,
		GameConstants.ElementType.OIL,
		GameConstants.ElementType.GRAVITY,
	]

	for element_type in element_types:
		_create_enchant_button(panel, element_type, y_offset, exp_manager.tenryu)
		y_offset += 70

	# 关闭按钮
	var close_btn = Button.new()
	close_btn.text = "关闭 [ESC]"
	close_btn.position = Vector2(650, 540)
	close_btn.size = Vector2(130, 40)
	close_btn.pressed.connect(_close_shop)
	panel.add_child(close_btn)

	# 暂停游戏
	get_tree().paused = true

func _create_enchant_button(parent: Control, element_type: int, y_pos: float, current_tenryu: int):
	"""创建附魔购买按钮"""
	var price = ENCHANT_PRICES.get(element_type, 50)
	var name = ELEMENT_NAMES.get(element_type, "未知附魔")
	var color = ELEMENT_COLORS.get(element_type, Color.WHITE)

	# 按钮容器
	var btn_container = Control.new()
	btn_container.position = Vector2(20, y_pos)
	btn_container.size = Vector2(760, 60)
	parent.add_child(btn_container)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.2, 0.2, 0.25, 0.8)
	bg.size = Vector2(760, 60)
	btn_container.add_child(bg)

	# 元素颜色标记
	var color_mark = ColorRect.new()
	color_mark.color = color
	color_mark.position = Vector2(10, 10)
	color_mark.size = Vector2(40, 40)
	btn_container.add_child(color_mark)

	# 附魔名称
	var name_label = Label.new()
	name_label.text = name
	name_label.position = Vector2(60, 10)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", color)
	btn_container.add_child(name_label)

	# 持续时间
	var duration_label = Label.new()
	duration_label.text = "持续: " + str(int(ENCHANT_DURATION)) + "秒"
	duration_label.position = Vector2(60, 35)
	duration_label.add_theme_font_size_override("font_size", 14)
	duration_label.add_theme_color_override("font_color", Color("#aaaaaa"))
	btn_container.add_child(duration_label)

	# 价格和购买按钮
	var can_afford = current_tenryu >= price

	var buy_btn = Button.new()
	buy_btn.text = str(price) + " 転流"
	buy_btn.position = Vector2(620, 10)
	buy_btn.size = Vector2(130, 40)
	buy_btn.disabled = not can_afford

	if can_afford:
		buy_btn.pressed.connect(_purchase_enchant.bind(element_type, price))
	else:
		buy_btn.add_theme_color_override("font_color", Color("#666666"))

	btn_container.add_child(buy_btn)

func _purchase_enchant(element_type: int, price: int):
	"""购买附魔"""
	var exp_manager = get_tree().get_first_node_in_group("experience_manager")
	if not exp_manager:
		return

	# 扣除転流
	if exp_manager.tenryu >= price:
		exp_manager.tenryu -= price
		SignalBus.tenryu_changed.emit(exp_manager.tenryu)

		# 应用附魔
		SignalBus.element_enchant_applied.emit(element_type, ENCHANT_DURATION)

		var name = ELEMENT_NAMES.get(element_type, "未知附魔")
		print("购买附魔: ", name, " - 花费 ", price, " 転流")

		# 关闭商店
		_close_shop()

func _close_shop():
	"""关闭商店"""
	if shop_ui:
		shop_ui.queue_free()
		shop_ui = null

	# 恢复游戏
	get_tree().paused = false

func _input(event):
	# ESC关闭商店
	if shop_ui and event.is_action_pressed("ui_cancel"):
		_close_shop()
		# 阻止事件继续传播到暂停菜单
		get_viewport().set_input_as_handled()
