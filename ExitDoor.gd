extends Area2D
class_name ExitDoor

# ExitDoor - 房间出口传送门
# 使用竹林封印效果，位于地图边缘的自然门口

signal door_entered(from_direction: int)  # 传递进入方向

var player_in_range: bool = false
var is_active: bool = false  # 初始关闭状态
var prompt_label: Label = null

# 视觉效果
var portal_sprite: Sprite2D = null
var glow_timer: float = 0.0

# 竹林封印效果
var seal_sprites: Array[Sprite2D] = []  # 封印竹子精灵
var seal_particles: CPUParticles2D = null  # 封印粒子
var is_opening: bool = false
var is_closing: bool = false

# 门的方向 (用于确定封印形式)
enum DoorDirection {
	NORTH,
	SOUTH,
	EAST,
	WEST
}
var direction: DoorDirection = DoorDirection.NORTH

func _ready():
	add_to_group("exit_door")

	# 设置碰撞
	collision_layer = 0
	collision_mask = 1  # 检测玩家

	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 创建传送门视觉
	_create_portal_visual()

	# 创建竹林封印（初始状态：封闭）
	_create_bamboo_seal()

	# 创建提示标签
	_create_prompt_label()

	# 添加碰撞形状
	_create_collision_shape()

func set_door_direction(dir: DoorDirection):
	"""设置门的方向"""
	direction = dir

func _create_portal_visual():
	"""创建传送门视觉效果"""
	portal_sprite = Sprite2D.new()
	portal_sprite.name = "PortalSprite"

	# 创建传送门纹理（发光圆环）
	var texture = _create_portal_texture(60)
	portal_sprite.texture = texture
	portal_sprite.z_index = 10

	# 加法混合发光效果
	var material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	portal_sprite.material = material

	add_child(portal_sprite)

func _create_portal_texture(radius: int) -> ImageTexture:
	"""创建传送门纹理 - 蓝紫色发光圆环"""
	var size = radius * 2
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(radius, radius)

	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var normalized_dist = dist / float(radius)

			var alpha = 0.0
			var r = 0.3
			var g = 0.5
			var b = 1.0

			# 外环（主要发光区域）
			if normalized_dist > 0.6 and normalized_dist < 0.95:
				var ring_center = 0.775
				var ring_width = 0.175
				var ring_dist = abs(normalized_dist - ring_center) / ring_width
				alpha = (1.0 - ring_dist * ring_dist) * 0.9

				# 颜色渐变
				var color_t = (normalized_dist - 0.6) / 0.35
				r = lerp(0.4, 0.6, color_t)
				g = lerp(0.3, 0.4, color_t)
				b = lerp(1.0, 0.9, color_t)

			# 内部微光
			elif normalized_dist < 0.6:
				alpha = 0.1 + (0.6 - normalized_dist) * 0.15
				r = 0.5
				g = 0.6
				b = 1.0

			# 外部柔和边缘
			elif normalized_dist < 1.0:
				var edge_t = (normalized_dist - 0.95) / 0.05
				alpha = 0.3 * (1.0 - edge_t)

			if alpha > 0:
				image.set_pixel(x, y, Color(r, g, b, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)

func _create_prompt_label():
	"""创建交互提示"""
	prompt_label = Label.new()
	prompt_label.text = "按 E 进入下一个房间"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-80, -100)
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	prompt_label.visible = false
	add_child(prompt_label)

func _create_collision_shape():
	"""创建碰撞区域"""
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 50.0
	collision.shape = shape
	add_child(collision)

func _process(delta):
	# 传送门动画效果（只在激活时显示）
	if is_active:
		glow_timer += delta
		if portal_sprite:
			portal_sprite.visible = true
			# 缩放脉动
			var pulse = 1.0 + sin(glow_timer * 3.0) * 0.05
			portal_sprite.scale = Vector2(pulse, pulse)

			# 旋转
			portal_sprite.rotation += delta * 0.5

		# 检测E键交互
		if player_in_range and Input.is_action_just_pressed("interact"):
			_enter_door()
	else:
		if portal_sprite:
			portal_sprite.visible = false

func _create_bamboo_seal():
	"""创建竹林封印视觉效果"""
	# 根据门的方向创建封印竹子
	var bamboo_count = 5
	var spacing = 60.0

	# 加载竹子纹理
	var bamboo_textures = [
		"res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_1.png",
		"res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_2.png",
		"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_1.png",
	]

	for i in range(bamboo_count):
		var seal_sprite = Sprite2D.new()
		seal_sprite.name = "SealBamboo" + str(i)

		# 随机选择竹子纹理
		var texture_path = bamboo_textures[randi() % bamboo_textures.size()]
		var texture = load(texture_path)
		if not texture:
			continue

		seal_sprite.texture = texture

		# 根据方向调整位置和旋转
		var offset_pos = Vector2.ZERO
		match direction:
			DoorDirection.NORTH, DoorDirection.SOUTH:
				# 水平排列
				offset_pos = Vector2((i - bamboo_count / 2.0) * spacing, 0)
				seal_sprite.scale = Vector2(0.15, 0.15)
			DoorDirection.EAST, DoorDirection.WEST:
				# 垂直排列
				offset_pos = Vector2(0, (i - bamboo_count / 2.0) * spacing)
				seal_sprite.scale = Vector2(0.15, 0.15)
				seal_sprite.rotation = PI / 2  # 旋转90度

		seal_sprite.position = offset_pos
		seal_sprite.centered = false
		seal_sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		seal_sprite.modulate = Color(0.6, 0.8, 0.6, 0.8)  # 略带绿色的半透明
		seal_sprite.z_index = 5

		add_child(seal_sprite)
		seal_sprites.append(seal_sprite)

	# 创建封印粒子效果
	seal_particles = CPUParticles2D.new()
	seal_particles.name = "SealParticles"
	seal_particles.emitting = true
	seal_particles.amount = 20
	seal_particles.lifetime = 1.5
	seal_particles.preprocess = 0.5
	seal_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	seal_particles.emission_sphere_radius = 40.0
	seal_particles.direction = Vector2(0, -1)
	seal_particles.spread = 45.0
	seal_particles.gravity = Vector2(0, -20)
	seal_particles.initial_velocity_min = 10.0
	seal_particles.initial_velocity_max = 30.0
	seal_particles.scale_amount_min = 0.5
	seal_particles.scale_amount_max = 1.0
	seal_particles.color = Color(0.4, 0.8, 0.4, 0.6)  # 绿色粒子
	seal_particles.z_index = 6

	add_child(seal_particles)

func open_door():
	"""打开门（移除竹林封印）"""
	if is_active or is_opening:
		return

	is_opening = true
	print("Opening door at direction: ", direction)

	# 播放封印破除动画
	for i in range(seal_sprites.size()):
		var sprite = seal_sprites[i]
		if not is_instance_valid(sprite):
			continue

		var tween = create_tween()
		tween.set_parallel(true)

		# 竹子向两侧移动并淡出
		var move_direction = Vector2.ZERO
		match direction:
			DoorDirection.NORTH, DoorDirection.SOUTH:
				move_direction = Vector2(1 if i >= seal_sprites.size() / 2 else -1, 0)
			DoorDirection.EAST, DoorDirection.WEST:
				move_direction = Vector2(0, 1 if i >= seal_sprites.size() / 2 else -1)

		tween.tween_property(sprite, "position", sprite.position + move_direction * 100, 0.8)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
		tween.tween_property(sprite, "rotation", sprite.rotation + randf_range(-0.5, 0.5), 0.8)

	# 停止封印粒子
	if seal_particles:
		seal_particles.emitting = false

	# 延迟激活门
	await get_tree().create_timer(0.5).timeout
	is_active = true
	is_opening = false

	# 显示传送门
	if portal_sprite:
		portal_sprite.modulate.a = 0.0
		portal_sprite.visible = true
		var tween = create_tween()
		tween.tween_property(portal_sprite, "modulate:a", 1.0, 0.5)

func close_door():
	"""关闭门（重新封印）"""
	if not is_active or is_closing:
		return

	is_closing = true
	is_active = false
	print("Closing door at direction: ", direction)

	# 隐藏传送门
	if portal_sprite:
		var tween = create_tween()
		tween.tween_property(portal_sprite, "modulate:a", 0.0, 0.3)
		await tween.finished
		portal_sprite.visible = false

	# 重新生成封印竹子
	for sprite in seal_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	seal_sprites.clear()

	_create_bamboo_seal()
	is_closing = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _enter_door():
	"""进入传送门"""
	if not is_active:
		return

	is_active = false

	# 播放进入效果
	if portal_sprite:
		var tween = create_tween()
		tween.tween_property(portal_sprite, "scale", Vector2(2.0, 2.0), 0.3)
		tween.parallel().tween_property(portal_sprite, "modulate:a", 0.0, 0.3)

	# 发送信号，传递进入方向
	door_entered.emit(direction)

	# 延迟销毁
	await get_tree().create_timer(0.5).timeout
	queue_free()
