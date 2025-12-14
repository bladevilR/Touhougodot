extends Area2D
class_name TreasureChest

# TreasureChest - 精英怪掉落的宝箱
# 拾取后触发升级选择界面，可获得武器/强化

@export var attract_radius: float = 80.0  # 吸引范围（比经验球小）
@export var attract_speed: float = 200.0   # 吸引速度（比经验球慢）

var is_attracted: bool = false
var player: Node2D = null
var sprite: Sprite2D = null
var glow_timer: float = 0.0

func _ready():
	add_to_group("pickup")
	add_to_group("treasure_chest")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# 设置碰撞层
	collision_layer = 32  # Layer 6: Pickup
	collision_mask = 1     # 只检测玩家 (Layer 1)

	# 找到玩家
	player = get_tree().get_first_node_in_group("player")

	# 创建视觉效果
	_create_visual()

func _create_visual():
	"""创建宝箱视觉效果"""
	# 创建Sprite2D显示宝箱
	sprite = Sprite2D.new()

	# 尝试加载宝箱纹理，如果没有则创建一个简单的矩形
	var texture_path = "res://assets/chest.png"
	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)
		sprite.scale = Vector2(0.1, 0.1)  # 根据实际纹理调整
	else:
		# 创建简单的宝箱纹理（金色方块）
		var chest_size = 32
		var image = Image.create(chest_size, chest_size, false, Image.FORMAT_RGBA8)

		# 画一个金色的宝箱形状
		for x in range(chest_size):
			for y in range(chest_size):
				var color: Color
				# 顶部（盖子）- 深金色
				if y < chest_size * 0.3:
					color = Color(0.8, 0.6, 0.1, 1.0)
				# 底部（箱体）- 亮金色
				else:
					color = Color(1.0, 0.8, 0.2, 1.0)

				# 边框
				if x < 2 or x >= chest_size - 2 or y < 2 or y >= chest_size - 2:
					color = Color(0.6, 0.4, 0.0, 1.0)

				# 中间的锁
				var center_x = chest_size / 2.0
				var lock_y = chest_size * 0.35
				if abs(x - center_x) < 4 and abs(y - lock_y) < 5:
					color = Color(0.9, 0.7, 0.1, 1.0)

				image.set_pixel(x, y, color)

		var texture = ImageTexture.create_from_image(image)
		sprite.texture = texture

	add_child(sprite)

	# 添加发光效果（加法混合）
	var glow_mat = CanvasItemMaterial.new()
	glow_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = glow_mat

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

	# 更新发光动画
	_update_glow(delta)

func _update_glow(delta):
	"""更新发光脉冲动画"""
	glow_timer += delta

	if sprite:
		# 脉冲发光效果
		var pulse = sin(glow_timer * 3.0) * 0.3 + 0.7
		sprite.modulate = Color(1.0, 0.9, 0.5, pulse)

		# 轻微上下浮动
		sprite.position.y = sin(glow_timer * 2.0) * 3.0

func _on_area_entered(area):
	if area.get_parent() and area.get_parent().is_in_group("player"):
		_pickup()

func _on_body_entered(body):
	if body.is_in_group("player"):
		_pickup()

func _pickup():
	"""拾取宝箱，触发升级选择"""
	# 播放拾取特效
	SignalBus.spawn_death_particles.emit(global_position, Color("#ffd700"), 25)
	SignalBus.screen_shake.emit(0.1, 5.0)

	# 触发升级选择界面（与升级相同的机制）
	_trigger_upgrade_selection()

	# 销毁宝箱
	queue_free()

func _trigger_upgrade_selection():
	"""触发升级选择界面"""
	# 获取WeaponData生成随机升级选项
	var upgrade_choices = _generate_upgrade_choices()

	# 发送显示升级界面的信号
	SignalBus.show_level_up_screen.emit(upgrade_choices)

	print("宝箱开启！获得升级选择机会！")

func _generate_upgrade_choices() -> Array:
	"""生成3个随机升级选项"""
	var choices = []

	# 确保WeaponData已初始化
	WeaponData.initialize()

	# 获取WeaponData中的所有武器
	if not WeaponData.WEAPONS.is_empty():
		var weapon_ids = WeaponData.WEAPONS.keys()

		# 随机选择3个不同的武器/升级
		var selected_count = 0
		var attempts = 0
		var max_attempts = 20

		while selected_count < 3 and attempts < max_attempts:
			attempts += 1
			var random_id = weapon_ids[randi() % weapon_ids.size()]
			var weapon_config = WeaponData.WEAPONS[random_id]

			# 避免重复选择
			var already_selected = false
			for choice in choices:
				if choice.id == random_id:
					already_selected = true
					break

			if not already_selected:
				choices.append({
					"id": random_id,
					"name": weapon_config.weapon_name,
					"description": weapon_config.description,
					"type": "weapon"
				})
				selected_count += 1

	# 如果武器不足，添加通用强化选项
	var generic_upgrades = [
		{"id": "hp_boost", "name": "生命强化", "description": "最大生命值+20%", "type": "stat"},
		{"id": "speed_boost", "name": "速度强化", "description": "移动速度+15%", "type": "stat"},
		{"id": "damage_boost", "name": "伤害强化", "description": "所有伤害+10%", "type": "stat"},
		{"id": "pickup_range", "name": "拾取范围", "description": "拾取范围+25%", "type": "stat"},
	]

	while choices.size() < 3:
		var upgrade = generic_upgrades[randi() % generic_upgrades.size()]
		var already_selected = false
		for choice in choices:
			if choice.id == upgrade.id:
				already_selected = true
				break
		if not already_selected:
			choices.append(upgrade)

	return choices
