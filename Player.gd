extends CharacterBody2D

# Player - 玩家角色控制器（使用角色数据）

@export var speed = 200.0
@export var character_id: int = 0  # 默认使用灵梦

var health_comp = null
var sprite = null
var weapon_system = null
var collision_shape = null
var character_skills = null

# 角色数据
var character_data = null

# 无敌状态
var invulnerable_timer: float = 0.0
var is_invulnerable: bool = false

# ==================== PHYSICS SYSTEM ====================
# Physics properties from CharacterData
var mass: float = 10.0
var friction: float = 0.1
var hitbox_scale: float = 1.0
var can_pass_through_enemies: bool = false
var immune_to_knockback: bool = false

# Movement state
var current_velocity: Vector2 = Vector2.ZERO
var target_velocity: Vector2 = Vector2.ZERO
var base_speed: float = 200.0

# Collision avoidance
const ENEMY_AVOIDANCE_RADIUS: float = 60.0
const ENEMY_AVOIDANCE_STRENGTH: float = 100.0
const WALL_AVOIDANCE_DISTANCE: float = 50.0

func _ready():
	add_to_group("player")

	# 获取子节点引用
	health_comp = get_node_or_null("HealthComponent")
	sprite = get_node_or_null("Sprite2D")
	weapon_system = get_node_or_null("WeaponSystem")
	collision_shape = get_node_or_null("CollisionShape2D")
	character_skills = get_node_or_null("CharacterSkills")

	# 初始化角色数据
	CharacterData.initialize()

	# 加载角色配置
	character_data = CharacterData.CHARACTERS.get(character_id)
	if character_data and health_comp:
		# 应用角色属性
		health_comp.max_hp = character_data.stats.max_hp
		health_comp.current_hp = character_data.stats.max_hp
		base_speed = character_data.stats.speed * 50.0  # 调整速度比例
		speed = base_speed

		# 应用物理属性
		mass = character_data.physics.mass
		friction = character_data.physics.friction
		hitbox_scale = character_data.physics.hitbox_scale
		can_pass_through_enemies = character_data.physics.can_pass_through_enemies
		immune_to_knockback = character_data.physics.immune_to_knockback

		# 应用碰撞箱缩放
		if collision_shape and collision_shape.shape:
			if collision_shape.shape is CircleShape2D:
				collision_shape.shape.radius *= hitbox_scale
			elif collision_shape.shape is RectangleShape2D:
				collision_shape.shape.size *= hitbox_scale

		print("玩家角色: ", character_data.char_name)
		print("初始武器: ", character_data.starting_weapon_id)
		print("物理属性 - 质量: ", mass, ", 摩擦力: ", friction, ", 判定倍率: ", hitbox_scale)

		# 装备初始武器
		SignalBus.weapon_added.emit(character_data.starting_weapon_id)

	# 设置碰撞层
	_setup_collision_layers()

	# 连接生命值组件信号
	if health_comp:
		health_comp.died.connect(on_player_died)

	# 监听升级事件
	SignalBus.level_up.connect(on_level_up)

func _setup_collision_layers():
	# Layer 1: Player
	# Layer 2: Walls
	# Layer 3: Enemy
	# Layer 4: Bullet (Player)
	# Layer 5: Bullet (Enemy)
	# Layer 6: Pickup

	collision_layer = 1  # 玩家在第1层

	if can_pass_through_enemies:
		# 可以穿过敌人 (Koishi)
		collision_mask = 2 + 16 + 32  # 墙壁(Layer 2) + 敌人子弹(Layer 5) + 拾取物(Layer 6)
	else:
		# 普通碰撞
		collision_mask = 2 + 4 + 16 + 32  # 墙壁(Layer 2) + 敌人(Layer 3) + 敌人子弹(Layer 5) + 拾取物(Layer 6)

func _physics_process(delta):
	# 更新无敌计时器
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		is_invulnerable = invulnerable_timer > 0

	# 如果正在执行技能，跳过普通移动逻辑
	if character_skills and character_skills.is_skill_active():
		return

	# 获取输入方向
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# ==================== FRICTION-BASED MOVEMENT ====================
	# Calculate target velocity based on input
	target_velocity = input_dir.normalized() * speed

	# Apply friction-based acceleration/deceleration
	# Higher friction = more responsive (less inertia)
	# Lower friction = more sliding (more inertia)
	var friction_factor = friction * 60.0  # Scale for frame-independent behavior

	if input_dir.length() > 0.1:
		# Accelerating towards target velocity
		current_velocity = current_velocity.lerp(target_velocity, friction_factor * delta)
	else:
		# Decelerating to stop
		current_velocity = current_velocity.lerp(Vector2.ZERO, friction_factor * delta * 2.0)

	# Apply final velocity
	velocity = current_velocity

	# ==================== COLLISION AVOIDANCE ====================
	if not can_pass_through_enemies:
		var avoidance_force = _calculate_enemy_avoidance()
		velocity += avoidance_force

	# ==================== WALL AVOIDANCE ====================
	var wall_avoidance = _calculate_wall_avoidance()
	velocity += wall_avoidance

	# Move with collision
	move_and_slide()

	# 翻转精灵（面向移动方向）
	# ColorRect不支持flip_h，暂时跳过
	# if input_dir.x != 0:
	# 	sprite.flip_h = input_dir.x < 0

# ==================== COLLISION AVOIDANCE METHODS ====================

# Calculate avoidance force to prevent overlapping with enemies
func _calculate_enemy_avoidance() -> Vector2:
	var avoidance = Vector2.ZERO
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)

		# Only apply avoidance within radius
		if distance < ENEMY_AVOIDANCE_RADIUS and distance > 0.1:
			var direction = (global_position - enemy.global_position).normalized()
			var strength = (1.0 - distance / ENEMY_AVOIDANCE_RADIUS) * ENEMY_AVOIDANCE_STRENGTH
			avoidance += direction * strength

	return avoidance

# Calculate wall avoidance to prevent getting stuck at edges
func _calculate_wall_avoidance() -> Vector2:
	var avoidance = Vector2.ZERO
	var viewport_rect = get_viewport_rect()

	# Get camera offset if exists
	var camera = get_viewport().get_camera_2d()
	var camera_pos = camera.global_position if camera else Vector2.ZERO

	# Check distance to each edge
	var left_dist = global_position.x - (camera_pos.x - viewport_rect.size.x / 2)
	var right_dist = (camera_pos.x + viewport_rect.size.x / 2) - global_position.x
	var top_dist = global_position.y - (camera_pos.y - viewport_rect.size.y / 2)
	var bottom_dist = (camera_pos.y + viewport_rect.size.y / 2) - global_position.y

	# Apply avoidance force near edges
	if left_dist < WALL_AVOIDANCE_DISTANCE:
		avoidance.x += (1.0 - left_dist / WALL_AVOIDANCE_DISTANCE) * 200.0
	if right_dist < WALL_AVOIDANCE_DISTANCE:
		avoidance.x -= (1.0 - right_dist / WALL_AVOIDANCE_DISTANCE) * 200.0
	if top_dist < WALL_AVOIDANCE_DISTANCE:
		avoidance.y += (1.0 - top_dist / WALL_AVOIDANCE_DISTANCE) * 200.0
	if bottom_dist < WALL_AVOIDANCE_DISTANCE:
		avoidance.y -= (1.0 - bottom_dist / WALL_AVOIDANCE_DISTANCE) * 200.0

	return avoidance

# Apply knockback from external sources (e.g., enemy collision)
func apply_knockback(direction: Vector2, force: float):
	if immune_to_knockback:
		return

	# Apply knockback inversely proportional to mass
	# Heavier characters resist knockback more
	var knockback_resistance = mass / 10.0  # Normalize to base mass
	var actual_force = force / knockback_resistance

	current_velocity += direction.normalized() * actual_force

func take_damage(amount: float):
	# 无敌时不受伤害
	if is_invulnerable:
		return

	if health_comp:
		health_comp.damage(amount)

		# 播放受击效果
		if sprite:
			sprite.color = Color.RED
			await get_tree().create_timer(0.1).timeout
			sprite.color = Color(0, 1, 0, 1)

func on_player_died():
	print("玩家死亡！")
	SignalBus.player_died.emit()
	SignalBus.game_over.emit()
	# TODO: 显示游戏结束界面

func on_level_up(new_level):
	# 升级时回满血
	if health_comp:
		health_comp.current_hp = health_comp.max_hp
		SignalBus.player_health_changed.emit(health_comp.current_hp, health_comp.max_hp)
		print("玩家升级到 Lv.", new_level, "，生命值已回复！")

# ==================== SKILL SUPPORT METHODS ====================

func set_invulnerable(duration: float):
	"""设置玩家无敌状态"""
	invulnerable_timer = duration
	is_invulnerable = true
	print("无敌时间: %.2f秒" % duration)
