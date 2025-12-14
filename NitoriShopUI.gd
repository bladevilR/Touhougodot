extends Control

# NitoriShopUI - 河童商店界面

var shop_system: NitoriShop = null
var nitori_portrait: TextureRect = null  # 河童立绘

@onready var background = $Background
@onready var title_label = $TitleLabel
@onready var coins_label = $CoinsLabel
@onready var item_container = $ItemContainer
@onready var close_button = $CloseButton

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时也能响应

	# 创建河童立绘
	_create_nitori_portrait()

	# 监听商店信号
	SignalBus.shop_opened.connect(_on_shop_opened)
	SignalBus.shop_closed.connect(_on_shop_closed)
	SignalBus.coins_changed.connect(_on_coins_changed)

	# 查找商店系统
	await get_tree().process_frame
	shop_system = get_tree().get_first_node_in_group("shop_system")
	if not shop_system:
		# 尝试从场景树查找
		var shops = get_tree().get_nodes_in_group("shop")
		if shops.size() > 0:
			shop_system = shops[0]

func _create_nitori_portrait():
	"""创建河童立绘"""
	nitori_portrait = TextureRect.new()
	nitori_portrait.name = "NitoriPortrait"

	# 加载河童立绘 - 使用2C.png（对话版）
	var portrait_path = "res://assets/characters/2C.png"
	if ResourceLoader.exists(portrait_path):
		var texture = load(portrait_path)
		nitori_portrait.texture = texture

		# 计算缩放：目标宽度120像素
		var original_size = texture.get_size()
		var target_width = 120.0
		var scale_factor = target_width / original_size.x
		nitori_portrait.scale = Vector2(scale_factor, scale_factor)

		print("[NitoriShopUI] 河童立绘已创建, scale=", scale_factor)
	else:
		print("警告: 找不到河童立绘: ", portrait_path)
		return

	# 设置立绘位置（左侧）
	nitori_portrait.position = Vector2(50, 150)

	# 添加到界面
	add_child(nitori_portrait)

	# 初始隐藏
	nitori_portrait.visible = false

func _on_shop_opened():
	"""商店打开"""
	visible = true
	if nitori_portrait:
		nitori_portrait.visible = true
	_refresh_ui()

func _on_shop_closed():
	"""商店关闭"""
	visible = false
	if nitori_portrait:
		nitori_portrait.visible = false

func _on_coins_changed(amount: int):
	"""金币变化"""
	if coins_label:
		coins_label.text = "金币: " + str(amount)

func _refresh_ui():
	"""刷新商店UI"""
	if not shop_system:
		# 再次尝试查找
		var player = get_tree().get_first_node_in_group("player")
		if player:
			shop_system = player.get_node_or_null("NitoriShop")

	if not shop_system:
		print("警告: 找不到商店系统")
		return

	# 更新金币显示
	if coins_label:
		coins_label.text = "金币: " + str(shop_system.coins)

	# 清空之前的商品
	if item_container:
		for child in item_container.get_children():
			child.queue_free()

	# 显示商品
	var stock = shop_system.get_stock()
	for item in stock:
		_create_item_button(item)

func _create_item_button(item: NitoriShop.ShopItem):
	"""创建商品按钮"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(180, 120)

	# 设置按钮文本
	var price_text = "[" + str(item.price) + "金]"
	button.text = item.item_name + "\n" + price_text + "\n" + item.description

	# 设置字体大小
	button.add_theme_font_size_override("font_size", 16)

	# 根据商品类型设置颜色
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.9)
	style.border_color = item.icon_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.3, 0.3, 0.4, 0.95)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	button.add_theme_stylebox_override("pressed", pressed_style)

	# 如果金币不足，禁用按钮
	if shop_system and shop_system.coins < item.price:
		button.disabled = true
		button.modulate = Color(0.5, 0.5, 0.5, 1.0)

	# 连接点击事件
	button.pressed.connect(_on_item_clicked.bind(item))

	item_container.add_child(button)

func _on_item_clicked(item: NitoriShop.ShopItem):
	"""点击商品"""
	if shop_system and shop_system.purchase_item(item):
		_refresh_ui()

func _on_close_pressed():
	"""关闭按钮"""
	if shop_system:
		shop_system.close_shop()

func _input(event):
	if not visible:
		return

	# ESC或N键关闭商店
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_N:
			if shop_system:
				shop_system.close_shop()
