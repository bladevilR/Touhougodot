extends Area2D
class_name ElementEnchant

# ElementEnchant - 元素附魔道具
# 拾取后为玩家的所有武器附加元素效果，持续30秒

@export var element_type: int = GameConstants.ElementType.FIRE
@export var enchant_duration: float = 30.0  # 附魔持续时间
@export var attract_radius: float = 150.0  # 吸引范围
@export var attract_speed: float = 300.0   # 吸引速度

var is_attracted: bool = false
var player: Node2D = null
var sprite: Sprite2D = null
var glow_timer: float = 0.0
var float_offset: float = 0.0

# 元素颜色映射
const ELEMENT_COLORS = {
	GameConstants.ElementType.FIRE: Color("#ff4500"),
	GameConstants.ElementType.ICE: Color("#00bfff"),
	GameConstants.ElementType.POISON: Color("#9370db"),
	GameConstants.ElementType.OIL: Color("#8b4513"),
	GameConstants.ElementType.LIGHTNING: Color("#ffd700"),
	GameConstants.ElementType.GRAVITY: Color("#9932cc"),
}

# 元素符号映射
const ELEMENT_SYMBOLS = {
	GameConstants.ElementType.FIRE: "fire",
	GameConstants.ElementType.ICE: "ice",
	GameConstants.ElementType.POISON: "poison",
	GameConstants.ElementType.OIL: "oil",
	GameConstants.ElementType.LIGHTNING: "lightning",
	GameConstants.ElementType.GRAVITY: "gravity",
}

func _ready():
	add_to_group("pickup")
	add_to_group("element_enchant")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# 设置碰撞层
	collision_layer = 32  # Layer 6: Pickup
	collision_mask = 1     # 只检测玩家 (Layer 1)

	# 找到玩家
	player = get_tree().get_first_node_in_group("player")

	# 创建视觉效果
	_create_visual()

	# 随机浮动相位
	float_offset = randf() * TAU

func _create_visual():
	"""创建元素附魔道具视觉效果"""
	var element_color = ELEMENT_COLORS.get(element_type, Color.WHITE)

	# 创建外圈光环
	var outer_glow = Sprite2D.new()
	outer_glow.name = "OuterGlow"
	var glow_size = 48
	var glow_image = Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(glow_size / 2.0, glow_size / 2.0)

	for x in range(glow_size):
		for y in range(glow_size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(dist / (glow_size / 2.0), 0.0, 1.0)
			var alpha = pow(1.0 - t, 2.0) * 0.6
			glow_image.set_pixel(x, y, Color(element_color.r, element_color.g, element_color.b, alpha))

	outer_glow.texture = ImageTexture.create_from_image(glow_image)
	outer_glow.material = CanvasItemMaterial.new()
	outer_glow.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add_child(outer_glow)

	# 创建核心图标
	sprite = Sprite2D.new()
	sprite.name = "CoreSprite"

	# 创建元素符号纹理
	var icon_size = 24
	var icon_image = Image.create(icon_size, icon_size, false, Image.FORMAT_RGBA8)
	var icon_center = Vector2(icon_size / 2.0, icon_size / 2.0)

	# 绘制元素符号（简化的几何形状）
	for x in range(icon_size):
		for y in range(icon_size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(icon_center)
			var normalized_dist = dist / (icon_size / 2.0)

			var alpha = 0.0
			var brightness = 1.0

			# 内圈实心
			if normalized_dist < 0.6:
				alpha = 1.0
				brightness = 1.2
			# 外圈渐变
			elif normalized_dist < 1.0:
				alpha = 1.0 - (normalized_dist - 0.6) / 0.4
				brightness = 1.0

			if alpha > 0:
				icon_image.set_pixel(x, y, Color(
					min(element_color.r * brightness, 1.0),
					min(element_color.g * brightness, 1.0),
					min(element_color.b * brightness, 1.0),
					alpha
				))

	sprite.texture = ImageTexture.create_from_image(icon_image)
	sprite.material = CanvasItemMaterial.new()
	sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add_child(sprite)

	# 创建碰撞形状
	var collision = get_node_or_null("CollisionShape2D")
	if not collision:
		collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 20.0
		collision.shape = shape
		add_child(collision)

func _physics_process(delta):
	if not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)

	# 进入吸引范围
	if distance < attract_radius:
		is_attracted = true

	# 吸引向玩家
	if is_attracted:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * attract_speed * delta

		# 如果非常接近玩家，自动拾取
		if distance < 25.0:
			_pickup()

	# 更新视觉动画
	_update_visual(delta)

func _update_visual(delta):
	"""更新发光和浮动动画"""
	glow_timer += delta

	if sprite:
		# 脉冲发光效果
		var pulse = sin(glow_timer * 4.0) * 0.3 + 0.7
		var element_color = ELEMENT_COLORS.get(element_type, Color.WHITE)
		sprite.modulate = Color(element_color.r, element_color.g, element_color.b, pulse)

		# 缓慢旋转
		sprite.rotation += delta * 1.5

	# 上下浮动
	var float_y = sin(glow_timer * 2.5 + float_offset) * 5.0
	if sprite:
		sprite.position.y = float_y

func _on_area_entered(area):
	if area.get_parent() and area.get_parent().is_in_group("player"):
		_pickup()

func _on_body_entered(body):
	if body.is_in_group("player"):
		_pickup()

func _pickup():
	"""拾取元素附魔道具"""
	# 获取元素信息
	var element_item = ElementData.get_element_item(element_type)
	var element_name = element_item.item_name if element_item else "未知元素"

	# 播放拾取特效
	var element_color = ELEMENT_COLORS.get(element_type, Color.WHITE)
	SignalBus.spawn_death_particles.emit(global_position, element_color, 30)
	SignalBus.screen_shake.emit(0.1, 5.0)

	# 发送元素附魔应用信号
	SignalBus.element_enchant_applied.emit(element_type, enchant_duration)

	print("拾取元素附魔: ", element_name, " - 持续 ", enchant_duration, " 秒")

	# 销毁道具
	queue_free()

# 静态方法：创建随机元素附魔道具
static func create_random(pos: Vector2) -> ElementEnchant:
	var enchant = ElementEnchant.new()
	var element_types = ElementData.get_all_element_types()
	enchant.element_type = element_types[randi() % element_types.size()]
	enchant.global_position = pos
	return enchant
