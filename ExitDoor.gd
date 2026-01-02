extends Area2D
class_name ExitDoor

# ExitDoor - 房间出口传送门
# 使用竹林封印效果，位于地图边缘的自然门口

signal door_entered(from_direction: int)  # 传递进入方向

var player_in_range: bool = false
var is_active: bool = false  # 初始关闭状态

# 视觉效果
var fog_seal_rect: ColorRect = null # 雾门封印
var fog_tween: Tween = null # 雾门呼吸动画Tween

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

	# 创建竹林封印（初始状态：封闭）
	_create_bamboo_seal()
	_create_fog_seal() # 添加雾门效果

	# 添加碰撞形状 (Deferred to avoid physics state errors)
	call_deferred("_create_collision_shape")

func set_door_direction(dir: DoorDirection):
	"""设置门的方向"""
	direction = dir

func _create_fog_seal():
	"""创建雾门封印视觉效果"""
	fog_seal_rect = ColorRect.new()
	fog_seal_rect.name = "FogSeal"
	
	# 根据方向设置雾门大小和位置
	var size = Vector2(120, 120)
	var offset = Vector2(-60, -60)
	
	match direction:
		DoorDirection.NORTH, DoorDirection.SOUTH:
			size = Vector2(160, 60)
			offset = Vector2(-80, -30)
		DoorDirection.EAST, DoorDirection.WEST:
			size = Vector2(60, 160)
			offset = Vector2(-30, -80)
			
	fog_seal_rect.size = size
	fog_seal_rect.position = offset
	fog_seal_rect.color = Color(0.8, 0.8, 0.9, 0.4) # 蓝白色半透明雾
	fog_seal_rect.z_index = 8 # 在竹子后面，地面上面
	
	add_child(fog_seal_rect)
	
	# 简单的呼吸动画
	_start_fog_animation(fog_seal_rect)

func _start_fog_animation(fog_seal: ColorRect):
	if not is_instance_valid(fog_seal) or not is_instance_valid(self) or not is_inside_tree():
		return
	if fog_tween and is_instance_valid(fog_tween):
		fog_tween.kill()
	# [修复] 使用 fog_seal.create_tween() 绑定 tween 到 fog_seal 的生命周期
	fog_tween = fog_seal.create_tween()
	fog_tween.tween_property(fog_seal, "modulate:a", 0.6, 1.5).set_trans(Tween.TRANS_SINE)
	fog_tween.tween_property(fog_seal, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE)
	# [修复] Lambda 捕获错误：添加弱引用检查
	fog_tween.tween_callback(func():
		# 检查 ExitDoor (self) 是否仍然有效且未被标记为删除
		if not is_instance_valid(self) or is_queued_for_deletion():
			return
		if is_instance_valid(fog_seal) and is_inside_tree():
			_start_fog_animation(fog_seal)
	)

func _create_collision_shape():
	"""创建碰撞区域"""
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	
	# 根据方向调整碰撞箱形状，覆盖整个通道宽度
	match direction:
		DoorDirection.NORTH, DoorDirection.SOUTH:
			shape.size = Vector2(400, 100) # 横向宽，纵向窄
		DoorDirection.EAST, DoorDirection.WEST:
			shape.size = Vector2(100, 400) # 纵向高，横向窄
			
	collision.shape = shape
	add_child(collision)

func _process(_delta):
	# 自动检测进入（如果玩家已经在范围内且门刚打开）
	if is_active and player_in_range:
		_enter_door()

func _create_bamboo_seal():
	"""创建竹林封印视觉效果"""
	# 根据门的方向创建封印竹子
	var bamboo_count = 5
	var spacing = 60.0

	# 加载竹子纹理
	var bamboo_textures = [
		"res://bamboo/bamboo_single_straight_1.png",
		"res://bamboo/bamboo_single_straight_2.png",
		"res://bamboo/bamboo_cluster_medium_1.png",
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

		# [修复] 使用 sprite.create_tween() 绑定 tween 到 sprite 的生命周期
		var tween = sprite.create_tween()
		tween.set_parallel(true)

		# 竹子向两侧移动并淡出
		var move_direction = Vector2.ZERO
		match direction:
			DoorDirection.NORTH, DoorDirection.SOUTH:
				move_direction = Vector2(1 if i >= seal_sprites.size() / 2.0 else -1, 0)
			DoorDirection.EAST, DoorDirection.WEST:
				move_direction = Vector2(0, 1 if i >= seal_sprites.size() / 2.0 else -1)

		tween.tween_property(sprite, "position", sprite.position + move_direction * 100, 0.8)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.8)
		tween.tween_property(sprite, "rotation", sprite.rotation + randf_range(-0.5, 0.5), 0.8)
		# [修复] Lambda 捕获错误：添加 self 有效性检查
		tween.tween_callback(func():
			# 如果 ExitDoor (self) 已被标记删除，sprite 会自动随父节点清理，无需手动 queue_free
			if not is_instance_valid(self) or is_queued_for_deletion():
				return
			if is_instance_valid(sprite):
				sprite.queue_free()
		)

	# 停止并删除封印粒子（异步删除，不阻塞）
	if seal_particles:
		seal_particles.emitting = false
		var particles_ref = seal_particles  # 保存引用
		seal_particles = null
		# [修复] 使用 Timer 节点而非 SceneTreeTimer 避免 Lambda 捕获错误
		var cleanup_timer = Timer.new()
		cleanup_timer.wait_time = particles_ref.lifetime
		cleanup_timer.one_shot = true
		cleanup_timer.autostart = true
		add_child(cleanup_timer)
		cleanup_timer.timeout.connect(func():
			if is_instance_valid(particles_ref):
				particles_ref.queue_free()
			if is_instance_valid(cleanup_timer):
				cleanup_timer.queue_free()
		)
		
	# 淡出雾门
	if fog_seal_rect:
		if fog_tween: fog_tween.kill() # 停止呼吸动画
		# [修复] 使用 fog_seal_rect.create_tween() 绑定 tween 到 fog_seal_rect 的生命周期
		var fade_tween = fog_seal_rect.create_tween()
		fade_tween.tween_property(fog_seal_rect, "modulate:a", 0.0, 0.8)
		# [修复] Lambda 捕获错误：添加 self 有效性检查
		fade_tween.tween_callback(func():
			# 如果 ExitDoor (self) 已被标记删除，fog_seal_rect 会自动随父节点清理
			if not is_instance_valid(self) or is_queued_for_deletion():
				return
			if is_instance_valid(fog_seal_rect):
				fog_seal_rect.queue_free()
		)
		fog_seal_rect = null

	# 延迟激活门
	await get_tree().create_timer(0.5).timeout
	is_active = true
	is_opening = false

func close_door():
	"""关闭门（重新封印）"""
	# 测试模式：禁用门关闭，保持所有门打开
	return

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		if is_active:
			_enter_door()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false

func _enter_door():
	"""进入传送门"""
	if not is_active:
		return

	is_active = false

	# 发送信号，传递进入方向
	door_entered.emit(direction)

	# 延迟销毁
	await get_tree().create_timer(0.5).timeout
	queue_free()
