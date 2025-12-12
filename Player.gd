extends CharacterBody2D

# Player - 玩家角色控制器（使用角色数据）

@export var speed = 200.0
@export var character_id: int = 0  # 默认使用灵梦

var health_comp = null
var sprite = null
var weapon_system = null
var collision_shape = null
var character_skills = null
var bond_system = null

# 角色数据
var character_data = null

# 无敌状态
var invulnerable_timer: float = 0.0
var is_invulnerable: bool = false

# 接触伤害冷却
var contact_damage_cooldown: float = 0.0
const CONTACT_DAMAGE_INTERVAL: float = 0.5  # 每0.5秒受一次伤害

# ==================== DASH SYSTEM ====================
var can_dash: bool = true
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
const DASH_DURATION: float = 0.2
const DASH_COOLDOWN: float = 1.0
const DASH_SPEED_MULTIPLIER: float = 3.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_damage: float = 30.0  # 飞踢伤害
var dash_hit_enemies: Array = []  # 记录已经伤害过的敌人

# 妹红动画系统
var mokou_textures = {
	"sprite": [],  # 水平移动帧
	"up": [],      # 向上移动帧
	"down": [],    # 向下移动帧
	"stand": null, # 站立
	"kick": null   # 飞踢
}
var animation_frame: int = 0
var animation_timer: float = 0.0
const ANIMATION_SPEED: float = 0.08  # 每帧持续时间

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

	# 获取子节点���用
	health_comp = get_node_or_null("HealthComponent")
	sprite = get_node_or_null("Sprite2D")
	weapon_system = get_node_or_null("WeaponSystem")
	collision_shape = get_node_or_null("CollisionShape2D")
	character_skills = get_node_or_null("CharacterSkills")
	bond_system = get_node_or_null("BondSystem")

	# 初始化角色数据
	CharacterData.initialize()

	# 监听角色选择信号（用于游戏运行时切换角色）
	SignalBus.character_selected.connect(_on_character_selected)

	# 从MainMenu获取选择的角色ID
	if SignalBus.selected_character_id >= 0:
		character_id = SignalBus.selected_character_id

	# 加载角色配置（使用选择的角色或默认角色）
	_load_character_data(character_id)

	# 设置碰撞层
	_setup_collision_layers()

	# 连接生命值组件信号
	if health_comp:
		health_comp.died.connect(on_player_died)

	# 监听升级事件
	SignalBus.level_up.connect(on_level_up)

func _on_character_selected(selected_id: int):
	"""角色选择信号回调"""
	print("收到角色选择信号: ", selected_id)
	character_id = selected_id
	# 重新加载角色数据（如果在游戏运行时）
	# _load_character_data(character_id)

func _load_character_data(char_id: int):
	"""加载并应用角色数据"""
	character_data = CharacterData.CHARACTERS.get(char_id)
	if character_data and health_comp:
		# 应用角色属性
		health_comp.max_hp = character_data.stats.max_hp
		health_comp.current_hp = character_data.stats.max_hp
		base_speed = character_data.stats.speed * 100.0  # 调整速度比例 (Increased from 50.0 to 100.0)
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

		# 应用视觉缩放
		if sprite:
			if "scale" in character_data:
				var s = character_data.scale
				sprite.scale = Vector2(s, s)
			else:
				sprite.scale = Vector2(0.08, 0.08) # Default if not found

		print("玩家角色: ", character_data.char_name)
		print("初始武器: ", character_data.starting_weapon_id)
		print("物理属性 - 质量: ", mass, ", 摩擦力: ", friction, ", 判定倍率: ", hitbox_scale)

		# 加载妹红动画（如果是妹红）
		if char_id == GameConstants.CharacterId.MOKOU:
			_load_mokou_textures()
			# Give her a secondary active weapon since wings are passive
			SignalBus.weapon_added.emit("phoenix_claws")

		# 装备初始武器
		SignalBus.weapon_added.emit(character_data.starting_weapon_id)

	# Adjust Camera Zoom (适当的视野大小)
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.zoom = Vector2(1.5, 1.5)  # 适中的zoom值，人物清晰可见
		camera.make_current() # Ensure camera follows player

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

	# 更新接触伤害冷却
	if contact_damage_cooldown > 0:
		contact_damage_cooldown -= delta

	# ==================== DASH LOGIC ====================
	_update_dash_timers(delta)

	# 使用"dash"输入动作触发冲刺（Shift键或空格键）
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

	if is_dashing:
		velocity = dash_direction * (base_speed * DASH_SPEED_MULTIPLIER)
		move_and_slide()

		# 飞踢伤害判定（妹红专属）
		if character_id == GameConstants.CharacterId.MOKOU:
			_check_dash_damage()
		else:
			_check_enemy_contact_damage() # 其他角色dash时仍然可能受伤

		# 更新妹红飞踢动画（如果是妹红）
		if character_id == GameConstants.CharacterId.MOKOU:
			_update_mokou_animation(delta, dash_direction)

		return

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

	# Check for collisions with enemies and apply contact damage
	_check_enemy_contact_damage()

	# 更新妹红动画（如果是妹红）
	if character_id == GameConstants.CharacterId.MOKOU:
		_update_mokou_animation(delta, input_dir)

	# 翻转精灵（面向移动方向）
	# 妹红的翻转由_update_mokou_animation处理
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
			sprite.modulate = Color.RED
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color.WHITE

func _check_enemy_contact_damage():
	"""检查与敌人的接触并造成伤害"""
	# 如果在冷却中，跳过
	if contact_damage_cooldown > 0:
		return

	# 检查与敌��的碰撞
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider and collider.is_in_group("enemy"):
			# 获取敌人的伤害值
			var damage = 10.0  # 默认伤害
			if collider.enemy_data and "damage" in collider.enemy_data:
				damage = collider.enemy_data.damage

			# 造成伤害
			take_damage(damage)

			# 设置冷却时间
			contact_damage_cooldown = CONTACT_DAMAGE_INTERVAL

			# 击退
			var knockback_dir = (global_position - collider.global_position).normalized()
			apply_knockback(knockback_dir, 300.0)

			break  # 一次只处理一个敌人碰撞

func _check_dash_damage():
	"""检查飞踢伤害（妹红专属）- 增强版"""
	# 使用区域检测而不是碰撞检测
	var dash_detection_radius = 80.0
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance > dash_detection_radius:
			continue

		var enemy_id = enemy.get_instance_id()
		# 避免重复伤害同一个敌人
		if enemy_id in dash_hit_enemies:
			continue

		dash_hit_enemies.append(enemy_id)

		# 计算敌人相对于冲刺方向的位置
		var to_enemy = (enemy.global_position - global_position).normalized()
		var dot = dash_direction.dot(to_enemy)

		# 前方的敌人（dot > 0.7，约45度内）
		if dot > 0.7:
			# 向前击飞
			if enemy.has_method("take_damage"):
				enemy.take_damage(dash_damage * 1.5)  # 前方敌人受到更高伤害

			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(dash_direction, 800.0)  # 强力前冲击飞

			# 火焰特效
			SignalBus.spawn_death_particles.emit(enemy.global_position, Color("#ff4500"), 15)

		# 两侧的敌人
		elif dot > 0:
			# 向两侧击退
			if enemy.has_method("take_damage"):
				enemy.take_damage(dash_damage)

			if enemy.has_method("apply_knockback"):
				# 计算垂直于冲刺方向的击退
				var perpendicular = Vector2(-dash_direction.y, dash_direction.x)
				var side = sign(perpendicular.dot(to_enemy))
				var knockback_dir = perpendicular * side + dash_direction * 0.3
				enemy.apply_knockback(knockback_dir.normalized(), 600.0)

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

# ==================== DASH METHODS ====================

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	dash_hit_enemies.clear()  # 清空已击中敌人列表

	# Determine dash direction
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length() > 0:
		dash_direction = input_dir.normalized()
	else:
		# If no input, dash in facing direction or right by default
		if sprite and sprite.flip_h:
			dash_direction = Vector2.LEFT
		else:
			dash_direction = Vector2.RIGHT

	# Optional: Visual effect
	if sprite:
		sprite.modulate.a = 0.5 # Ghost effect transparency

	# Optional: Invulnerability during dash
	set_invulnerable(DASH_DURATION)
	print("Dash started! Direction: ", dash_direction)

func _update_dash_timers(delta: float):
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			if sprite:
				sprite.modulate.a = 1.0 # Restore opacity
			velocity = Vector2.ZERO # Stop momentum after dash

			# 飞踢落地视觉效果（妹红专属）
			if character_id == GameConstants.CharacterId.MOKOU:
				_spawn_dash_landing_effect()

	if not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true
			print("Dash ready!")

# ==================== SKILL SUPPORT METHODS ====================

func set_invulnerable(duration: float):
	"""设置玩家无敌状态"""
	invulnerable_timer = duration
	is_invulnerable = true
	print("无敌时间: %.2f秒" % duration)

func _spawn_dash_landing_effect():
	"""生成飞踢落地视觉效果（火焰爆炸） + 范围伤害"""
	# 发射橙红色火焰粒子
	SignalBus.spawn_death_particles.emit(global_position, Color("#ff4500"), 30)

	# 触发轻微屏幕震动
	SignalBus.screen_shake.emit(0.1, 8.0)  # 0.1秒，8像素

	# 范围伤害
	var landing_damage = dash_damage * 0.8
	var landing_radius = 100.0
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= landing_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(landing_damage)

			# 向外击退
			if enemy.has_method("apply_knockback"):
				var knockback_dir = (enemy.global_position - global_position).normalized()
				enemy.apply_knockback(knockback_dir, 400.0)

			# 应用燃烧效果
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(5.0, 3.0)  # 5伤害/秒，持续3秒

	print("飞踢落地！范围伤害: %.0f" % landing_damage)

# ==================== MOKOU ANIMATION SYSTEM ====================

func _load_mokou_textures():
	"""加载妹红的雪碧图动画纹理"""
	# sprite.png - 8帧水平移动动画（水平排列）
	var sprite_texture = load("res://assets/sprite.png")
	if sprite_texture:
		var frame_width = sprite_texture.get_width() / 8
		var frame_height = sprite_texture.get_height()
		mokou_textures.sprite = []
		for i in range(8):
			var atlas = AtlasTexture.new()
			atlas.atlas = sprite_texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			mokou_textures.sprite.append(atlas)
		print("妹红水平动画加载完成：8帧")

	# up.png - 4帧向上移动动画（水平排列）
	var up_texture = load("res://assets/up.png")
	if up_texture:
		var frame_width = up_texture.get_width() / 4
		var frame_height = up_texture.get_height()
		mokou_textures.up = []
		for i in range(4):
			var atlas = AtlasTexture.new()
			atlas.atlas = up_texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			mokou_textures.up.append(atlas)
		print("妹红向上动画加载完成：4帧")

	# down.png - 17帧向下移动动画（检测垂直/水平排列）
	var down_texture = load("res://assets/down.png")
	if down_texture:
		var is_vertical_layout = down_texture.get_height() > down_texture.get_width()
		mokou_textures.down = []

		if is_vertical_layout:
			# 垂直排列（上下堆叠）
			var frame_width = down_texture.get_width()
			var frame_height = down_texture.get_height() / 17
			for i in range(17):
				var atlas = AtlasTexture.new()
				atlas.atlas = down_texture
				atlas.region = Rect2(0, i * frame_height, frame_width, frame_height)
				mokou_textures.down.append(atlas)
			print("妹红向下动画加载完成：17帧（垂直排列）")
		else:
			# 水平排列（左右排列）
			var frame_width = down_texture.get_width() / 17
			var frame_height = down_texture.get_height()
			for i in range(17):
				var atlas = AtlasTexture.new()
				atlas.atlas = down_texture
				atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
				mokou_textures.down.append(atlas)
			print("妹红向下动画加载完成：17帧（水平排列）")

	# stand.png - 站立
	mokou_textures.stand = load("res://assets/stand.png")
	if mokou_textures.stand:
		print("妹红站立纹理加载完成")

	# mokuokick.png - 飞踢
	mokou_textures.kick = load("res://assets/mokuokick.png")
	if mokou_textures.kick:
		print("妹红飞踢纹理加载完成")

func _update_mokou_animation(delta: float, input_dir: Vector2):
	"""更新妹红的动画帧"""
	if not sprite or mokou_textures.sprite.size() == 0:
		return

	# 目标视觉高度：约100像素
	const TARGET_HEIGHT = 100.0

	# 优先处理冲刺动画（飞踢）
	if is_dashing and mokou_textures.kick:
		sprite.texture = mokou_textures.kick
		# mokuokick.png: 2496x1696，计算缩放 = 100/1696 = 0.059
		sprite.scale = Vector2(TARGET_HEIGHT / 1696.0, TARGET_HEIGHT / 1696.0)
		# 根据dash方向翻转（如果图片默认朝左，向右时需要翻转）
		sprite.flip_h = dash_direction.x > 0
		return  # 冲刺时不处理其他动画

	var is_moving = input_dir.length() > 0.1

	# 更新动画计时器
	if is_moving:
		animation_timer += delta
		# 60帧=1秒动画周期
		var animation_cycle = 1.0  # 1秒一个完整循环
		var progress = fmod(animation_timer, animation_cycle) / animation_cycle

		# 根据方向选择动画
		var is_moving_up = input_dir.y < -0.5
		var is_moving_down = input_dir.y > 0.5

		if is_moving_up and mokou_textures.up.size() > 0:
			# 向上移动（4帧）
			var frame_index = int(progress * 4) % 4
			# 原项目使用倒序播放：spriteUp[3 - frame]
			sprite.texture = mokou_textures.up[3 - frame_index]
		elif is_moving_down and mokou_textures.down.size() > 0:
			# 向下移动（17帧）
			var frame_index = int(progress * 17) % 17
			# 原项目使用倒序播放：spriteDown[16 - frame]
			sprite.texture = mokou_textures.down[16 - frame_index]
		else:
			# 水平移动（8帧）
			var frame_index = int(progress * 8) % 8
			# 原项目使用倒序播放：sprite[(8-1) - frame]
			sprite.texture = mokou_textures.sprite[7 - frame_index]

		# 水平翻转（朝向移动方向）
		if input_dir.x != 0:
			sprite.flip_h = input_dir.x < 0

		# 运动帧：sprite.png, up.png, down.png都是720px高，计算缩放 = 100/720 = 0.139
		sprite.scale = Vector2(TARGET_HEIGHT / 720.0, TARGET_HEIGHT / 720.0)
	else:
		# 停止移动，显示站立
		animation_timer = 0.0
		if mokou_textures.stand:
			sprite.texture = mokou_textures.stand
			# stand.png: 2048x2048，计算缩放 = 100/2048 = 0.049
			sprite.scale = Vector2(TARGET_HEIGHT / 2048.0, TARGET_HEIGHT / 2048.0)
