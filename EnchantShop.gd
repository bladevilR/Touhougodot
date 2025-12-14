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

	# 创建祭坛图标
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)

	# 绘制紫色祭坛
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)

			if dist < 20:
				# 中心圆
				image.set_pixel(x, y, Color("#cc66ff"))
			elif dist < 28:
				# 外圈
				var alpha = 1.0 - (dist - 20) / 8.0
				image.set_pixel(x, y, Color(0.8, 0.4, 1.0, alpha))

	sprite.texture = ImageTexture.create_from_image(image)
	sprite.scale = Vector2(1.5, 1.5)
	add_child(sprite)

	# 添加文字提示
	var label = Label.new()
	label.text = "附魔祭坛"
	label.position = Vector2(-40, 60)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#cc66ff"))
	add_child(label)

func _process(delta):
	# 检测E键打开商店
	if player_in_range and Input.is_action_just_pressed("interact"):
		_open_shop()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		_show_interaction_hint(true)

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
		hint.text = "按 E 购买附魔"
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

	# 商店面板
	var panel = Control.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-400, -300)
	panel.size = Vector2(800, 600)
	shop_ui.add_child(panel)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 0.95)
	bg.size = Vector2(800, 600)
	panel.add_child(bg)

	# 标题
	var title = Label.new()
	title.text = "附魔祭坛 - 选择元素附魔"
	title.position = Vector2(20, 20)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#cc66ff"))
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
