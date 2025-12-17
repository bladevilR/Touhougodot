extends CharacterBody2D

# Enemy - 敌人AI（使用敌人数据）

@export var speed = 100.0
@export var xp_value = 10
@export var enemy_type: int = 0  # GameConstants.EnemyType

var health_comp = null
var sprite = null
var collision_shape = null
var health_bar = null  # 血量条引用

var target: Node2D = null
var enemy_data = null

# ==================== PHYSICS SYSTEM ====================
# Physics properties
var mass: float = 10.0
var base_speed: float = 100.0

# Knockback state
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_target_velocity: Vector2 = Vector2.ZERO  # 目标击退速度
var knockback_progress: float = 0.0  # 击退加速进度 0-1
var knockback_immunity: bool = false
const KNOCKBACK_DECAY: float = 0.8  # 降低衰减速度，让击飞持续更久
const KNOCKBACK_ACCELERATION_TIME: float = 0.15  # 加速到最大速度的时间（秒）

# Collision avoidance
const ENEMY_SEPARATION_RADIUS: float = 80.0  # 增加检测范围
const ENEMY_SEPARATION_STRENGTH: float = 150.0  # 增加分离力度
const MAX_SEPARATION_FORCE: float = 400.0  # 增加最大分离力

# 性能优化：分离力计算缓存
var _separation_force_cache: Vector2 = Vector2.ZERO
var _separation_calc_timer: float = 0.0
const SEPARATION_CALC_INTERVAL: float = 0.1  # 每0.1秒计算一次分离力，而非每帧

# ==================== JUMP SYSTEM ====================
var can_jump: bool = false  # 是否可以跳跃（毛玉特性）
var jump_interval: float = 1.0  # 跳跃间隔
var jump_timer: float = 0.0  # 跳跃计时器
var jump_height: float = 0.0  # 当前跳跃高度（视觉用）
var jump_progress: float = 0.0  # 跳跃进度 0-1
const JUMP_MAX_HEIGHT: float = 30.0  # 跳跃最大高度（像素）
const JUMP_DURATION: float = 0.5  # 跳跃持续时间（秒）

# ==================== VISUAL EFFECTS ====================
var shadow_sprite: Sprite2D = null  # 地面影子

# 螺旋线特效系统
var spiral_trail: Line2D = null  # 螺旋线
var spiral_trail_active: bool = false  # 螺旋线是否激活
var spiral_trail_duration: float = 0.0  # 螺旋线持续时间
var spiral_trail_timer: float = 0.0  # 螺旋线计时器
var spiral_trail_points: Array = []  # 记录轨迹点
const SPIRAL_TRAIL_MAX_POINTS: int = 30  # 最大轨迹点数

# ==================== STATUS EFFECT SYSTEM ====================
# Status effect tracking structures
var active_status_effects = {
	"burns": [],        # Array of {damage: float, duration: float, timer: float}
	"poisons": [],      # Array of {damage: float, duration: float, timer: float}
	"freeze": null,     # {duration: float, timer: float} or null
	"stun": null,       # {duration: float, timer: float} or null
	"slow": null,       # {amount: float, duration: float, timer: float} or null
}

# ==================== ELEMENT SYSTEM ====================
# 元素叠加追踪
var element_stacks = {}  # {ElementType: stack_count}
var frost_stacks: int = 0  # 冰元素寒冷叠层
const FROST_FREEZE_THRESHOLD: int = 3  # 3层冻结
var vulnerability_stacks: int = 0  # 毒元素易伤叠层
const VULNERABILITY_DAMAGE_PER_STACK: float = 5.0  # 每层+5固定伤害
var armor_reduction: float = 0.0  # 护甲降低百分比
var armor_reduction_timer: float = 0.0

# Status effect timers (for damage ticks)
var burn_tick_timer: float = 0.0
var poison_tick_timer: float = 0.0
const STATUS_TICK_INTERVAL: float = 1.0  # Damage every 1 second

# Visual feedback
var status_color_timer: float = 0.0
var original_color: Color = Color.RED

func _ready():
	add_to_group("enemy")

	# 获取子节点引用
	health_comp = get_node_or_null("HealthComponent")
	sprite = get_node_or_null("Sprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	health_bar = get_node_or_null("HealthBar")

	# 初始化敌人数据
	EnemyData.initialize()

	# 加载敌人配置
	enemy_data = EnemyData.ENEMIES.get(enemy_type)
	if enemy_data and health_comp:
		# 应用敌人属性
		health_comp.max_hp = enemy_data.hp
		health_comp.current_hp = enemy_data.hp
		speed = enemy_data.speed * 100.0
		xp_value = enemy_data.exp
		mass = enemy_data.mass  # 应用质量

		if sprite:
			sprite.modulate = enemy_data.color
			if "scale" in enemy_data:
				var s = enemy_data.scale
				sprite.scale = Vector2(s, s)

		# 初始化血量条
		_update_health_bar()

	# Store base speed for status effect calculations
	base_speed = speed

	# 设置碰撞层
	_setup_collision_layers()

	# 寻找目标（不再强绑定 Player 变量，而是去组里找）
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

	# 连接组件信号：当组件说"我死了"，我就执行 die()
	if health_comp:
		health_comp.died.connect(die)

	# 添加阴影（下午斜阳的长影子）
	var map_system = get_tree().get_first_node_in_group("map_system")
	if map_system and map_system.has_method("create_shadow_for_entity"):
		# 根据敌人缩放调整阴影大小
		var enemy_scale = sprite.scale.x if sprite else 1.0
		var shadow_size = Vector2(40 * enemy_scale, 10 * enemy_scale)
		
		# 根据敌人类型判断是否悬空
		var shadow_offset = Vector2(0, 5) # 默认地面
		var shadow_alpha = 0.5
		
		# 飞行单位
		if enemy_type in [GameConstants.EnemyType.ELF, GameConstants.EnemyType.FAIRY, GameConstants.EnemyType.GHOST]:
			shadow_offset = Vector2(0, 40 * enemy_scale) # 悬空偏移
			shadow_alpha = 0.3 # 离地更远，影子更淡
			
		var shadow = map_system.create_shadow_for_entity(self, shadow_size, shadow_offset)
		if shadow:
			shadow.modulate.a = shadow_alpha
	else:
		# 备用：直接创建阴影
		_create_enemy_shadow()

func _setup_collision_layers():
	# Layer 1: Player
	# Layer 2: Walls
	# Layer 3: Enemy
	# Layer 4: Bullet (Player)
	# Layer 5: Bullet (Enemy)
	# Layer 6: Pickup

	collision_layer = 4  # 敌人在第3层
	collision_mask = 1 + 2 + 4 + 8  # 检测玩家(Layer 1) + 墙壁(Layer 2) + 其他敌人(Layer 3) + 玩家子弹(Layer 4)

func setup_as_boss(boss_config):
	"""设置为Boss"""
	print("[Enemy] 设置为Boss: ", boss_config.enemy_name)

	# 0. 先获取节点引用（防止在add_child之前调用导致组件为空）
	if not health_comp:
		health_comp = get_node_or_null("HealthComponent")
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")

	# 保存boss配置
	enemy_data = boss_config
	enemy_type = GameConstants.EnemyType.BOSS

	# 设置Boss属性
	var current_hp = boss_config.hp
	var max_hp = boss_config.hp

	if health_comp:
		health_comp.max_hp = boss_config.hp
		health_comp.current_hp = boss_config.hp
	else:
		push_error("[Enemy] Boss missing HealthComponent!")

	speed = boss_config.speed * 100.0
	base_speed = boss_config.speed * 100.0
	xp_value = boss_config.exp
	mass = 30.0  # Boss质量更大，抗击退

	# 设置sprite颜色（如果有）
	if sprite:
		sprite.modulate = boss_config.color

	# 设置缩放（Boss更大）
	var boss_scale = 3.0  # Boss是普通敌人的3倍大
	if sprite:
		sprite.scale = Vector2(boss_scale, boss_scale)
	if collision_shape and collision_shape.shape:
		collision_shape.scale = Vector2(boss_scale, boss_scale)

	# 发送Boss生成信号
	SignalBus.boss_spawned.emit(boss_config.enemy_name, current_hp, max_hp)

	print("[Enemy] Boss设置完成: ", boss_config.enemy_name, " HP=", max_hp)

func _physics_process(delta):
	# ==================== STATUS EFFECT UPDATES ====================
	_update_status_effects(delta)
	_update_status_visuals(delta)

	# Check if enemy can move (not frozen or stunned)
	if _is_movement_disabled():
		# Still apply knockback decay even when disabled
		if knockback_target_velocity.length() == 0:
			knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		return

	# Calculate current movement speed with status modifiers
	var current_speed = _get_modified_speed()

	# ==================== JUMP SYSTEM (上下弹跳动画) ====================
	if can_jump:
		jump_timer += delta

		# 更新跳跃动画（连续弹跳）
		jump_progress += delta / JUMP_DURATION
		if jump_progress >= 1.0:
			jump_progress = 0.0  # 重置，继续弹跳

		# 使用sin函数创建平滑的上下弹跳
		jump_height = sin(jump_progress * PI) * JUMP_MAX_HEIGHT

		# 更新sprite的视觉位置（向上偏移）
		if sprite:
			sprite.position.y = -jump_height

		# 更新影子的缩放（跳得越高，影子越小）
		if shadow_sprite:
			var shadow_scale = 1.0 - (jump_height / JUMP_MAX_HEIGHT) * 0.5  # 最多缩小50%
			shadow_sprite.scale = Vector2(shadow_scale, shadow_scale * 0.5)  # 椭圆形影子

	# ==================== PHYSICS-BASED MOVEMENT ====================
	var desired_velocity = Vector2.ZERO

	if is_instance_valid(target):
		var direction = global_position.direction_to(target.global_position)
		desired_velocity = direction * current_speed

	# ==================== ENEMY-ENEMY COLLISION AVOIDANCE ====================
	# 性能优化：每0.1秒计算一次，而非每帧
	_separation_calc_timer += delta
	if _separation_calc_timer >= SEPARATION_CALC_INTERVAL:
		_separation_calc_timer = 0.0
		_separation_force_cache = _calculate_enemy_separation()

	desired_velocity += _separation_force_cache

	# ==================== KNOCKBACK ACCELERATION SYSTEM ====================
	# 击退加速：前半段慢，后半段快（慢镜头效果）
	if knockback_target_velocity.length() > 0:
		# 更新加速进度
		knockback_progress += delta / KNOCKBACK_ACCELERATION_TIME
		knockback_progress = clamp(knockback_progress, 0.0, 1.0)

		# 使用缓入曲线（ease-in quad）：慢→快
		var ease_factor = knockback_progress * knockback_progress

		# 根据进度插值到目标速度
		knockback_velocity = knockback_target_velocity * ease_factor

		# 加速完成后，清空目标速度，开始衰减
		if knockback_progress >= 1.0:
			knockback_target_velocity = Vector2.ZERO

	# Combine desired velocity with knockback
	velocity = desired_velocity + knockback_velocity

	# Apply knockback decay (仅在无目标速度时衰减)
	if knockback_target_velocity.length() == 0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)

	# Move with collision
	move_and_slide()

	# 简单的翻转逻辑
	# ColorRect不支持flip_h，暂时跳过
	# if velocity.x != 0:
	# 	sprite.flip_h = velocity.x < 0

	# ==================== SPIRAL TRAIL UPDATE ====================
	# 更新螺旋线特效
	if spiral_trail_active:
		spiral_trail_timer += delta

		# 每帧记录sprite的全局位置，形成螺旋轨迹
		if sprite and spiral_trail:
			var trail_point = sprite.global_position
			spiral_trail_points.append(trail_point)

			# 限制轨迹点数量，避免性能问题
			if spiral_trail_points.size() > SPIRAL_TRAIL_MAX_POINTS:
				spiral_trail_points.pop_front()

			# 更新Line2D的点
			spiral_trail.clear_points()
			for point in spiral_trail_points:
				# 转换为相对于Line2D的局部坐标
				var local_point = spiral_trail.to_local(point)
				spiral_trail.add_point(local_point)

		# 淡出效果
		if spiral_trail and spiral_trail_duration > 0:
			var fade_progress = spiral_trail_timer / spiral_trail_duration
			spiral_trail.modulate.a = 1.0 - fade_progress

		# 时间到，停止特效
		if spiral_trail_timer >= spiral_trail_duration:
			_stop_spiral_trail()

# ==================== PHYSICS METHODS ====================

# Calculate separation force to prevent enemy stacking
func _calculate_enemy_separation() -> Vector2:
	var separation = Vector2.ZERO
	var neighbor_count = 0
	var enemies = get_tree().get_nodes_in_group("enemy")

	# 性能优化：使用距离平方避免开方，限制最大邻居数
	var radius_sq = ENEMY_SEPARATION_RADIUS * ENEMY_SEPARATION_RADIUS
	const MAX_NEIGHBORS = 8  # 最多检查8个最近邻居

	for enemy in enemies:
		if neighbor_count >= MAX_NEIGHBORS:
			break  # 已经检查足够多邻居了

		if not is_instance_valid(enemy) or enemy == self:
			continue

		var diff = global_position - enemy.global_position
		var dist_sq = diff.length_squared()

		# 使用距离平方比较，避免开方
		if dist_sq < radius_sq and dist_sq > 1.0:
			var distance = sqrt(dist_sq)  # 只在需要时才开方
			var direction = diff / distance
			var strength = (1.0 - distance / ENEMY_SEPARATION_RADIUS) * ENEMY_SEPARATION_STRENGTH
			separation += direction * strength
			neighbor_count += 1

	# Cap the separation force to prevent extreme values
	var sep_len_sq = separation.length_squared()
	if sep_len_sq > MAX_SEPARATION_FORCE * MAX_SEPARATION_FORCE:
		separation = separation.normalized() * MAX_SEPARATION_FORCE

	return separation

# Apply knockback effect with mass-based resistance
func apply_knockback(direction: Vector2, force: float):
	# Check for knockback immunity (from status effects or character traits)
	if knockback_immunity:
		return

	# Apply knockback inversely proportional to mass
	# Heavier enemies resist knockback more
	# Base mass is 10.0 for normal enemies
	var knockback_resistance = mass / 10.0
	var actual_force = force / knockback_resistance

	# 设置目标击退速度（将在_physics_process中逐渐加速）
	knockback_target_velocity = direction.normalized() * actual_force

	# 重置加速进度，开始慢镜头加速
	knockback_progress = 0.0

	# 初始速度设为很小（慢镜头开始）
	knockback_velocity = knockback_target_velocity * 0.1  # 从10%速度开始

	print("[Enemy] 击飞! 方向:", direction, " 力度:", force, " 目标速度:", knockback_target_velocity.length())

	# Cap maximum knockback velocity - 大幅提高上限以允许超级击飞
	var max_knockback = 20000.0  # 从15000提高到20000
	if knockback_target_velocity.length() > max_knockback:
		knockback_target_velocity = knockback_target_velocity.normalized() * max_knockback

# ==================== SPIRAL TRAIL EFFECT ====================
# 启动螺旋线特效
func start_spiral_trail(duration: float):
	"""启动螺旋线轨迹特效 - 透明破空效果"""
	if not sprite:
		return

	# 创建Line2D节点来绘制螺旋线
	if not spiral_trail:
		spiral_trail = Line2D.new()
		spiral_trail.name = "SpiralTrail"
		spiral_trail.width_curve = Curve.new()
		# 设置宽度曲线：头部宽尾部窄（破空感）
		spiral_trail.width_curve.add_point(Vector2(0.0, 5.0))  # 起点宽5px
		spiral_trail.width_curve.add_point(Vector2(1.0, 0.0))  # 终点消失
		spiral_trail.default_color = Color(0.9, 0.9, 1.0, 0.3)  # 浅蓝白色半透明
		spiral_trail.z_index = -1  # 在敌人下方绘制
		spiral_trail.top_level = true  # 使用全局坐标

		# 添加渐变透明效果
		var gradient = Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 0.6))  # 起点半透明白
		gradient.set_color(1, Color(0.9, 0.9, 1.0, 0.0))  # 终点完全透明
		spiral_trail.gradient = gradient

		add_child(spiral_trail)

	# 初始化螺旋线状态
	spiral_trail_active = true
	spiral_trail_duration = duration
	spiral_trail_timer = 0.0
	spiral_trail_points.clear()
	spiral_trail.modulate.a = 1.0

	print("[Enemy] 螺旋破空特效已启动, 持续时间:", duration, "秒")

# 停止螺旋线特效
func _stop_spiral_trail():
	"""停止并清理螺旋线特效"""
	spiral_trail_active = false
	spiral_trail_points.clear()

	if spiral_trail:
		spiral_trail.queue_free()
		spiral_trail = null

	print("[Enemy] 螺旋线特效已停止")

# ==================== VISUAL EFFECTS ====================
# 子弹打中敌人时，调用这个函数
func take_damage(amount, weapon_id: String = ""):
	# 应用易伤加成
	var final_damage = amount + get_vulnerability_bonus()

	# 应用护甲降低（如果有）
	if armor_reduction > 0:
		final_damage *= (1.0 + armor_reduction)

	if health_comp:
		health_comp.damage(final_damage)
		# 发射伤害数字，包含武器ID
		SignalBus.damage_dealt.emit(final_damage, global_position, false, weapon_id)
		
		# 受击震动反馈 (伤害较高时)
		if final_damage > 20:
			SignalBus.screen_shake.emit(0.05, 3.0)

		# 更新血量条
		_update_health_bar()

		# 播放受击闪白
		if sprite:
			sprite.modulate = Color.WHITE
			await get_tree().create_timer(0.1).timeout
			if enemy_data:
				sprite.modulate = enemy_data.color
			else:
				sprite.modulate = Color.RED

func die():
	# 发射死亡粒子效果
	var particle_color = original_color if original_color != Color.RED else Color.WHITE
	SignalBus.spawn_death_particles.emit(global_position, particle_color, 20)

	# 精英怪特殊处理：更强的屏幕震动 + 掉落宝箱
	if enemy_data and enemy_data.is_elite:
		# 精英怪死亡震动更强
		SignalBus.screen_shake.emit(0.2, 12.0)  # 0.2秒，12像素
		# 额外的死亡粒子（橙色火焰效果）
		SignalBus.spawn_death_particles.emit(global_position, Color("#ff6600"), 40)
		# 掉落宝箱
		if enemy_data.drops_chest:
			SignalBus.treasure_chest_spawn.emit(global_position)
	else:
		# 普通敌人震动
		# 原项目：triggerScreenShake(5, 10) 用于普通敌人死亡
		SignalBus.screen_shake.emit(0.08, 5.0)  # 0.08秒，5像素

	# 通知全世界：这里死怪了，掉经验吧，播音效吧
	SignalBus.enemy_killed.emit(xp_value, global_position)
	queue_free()

# 从波次配置设置敌人（新接口，用于波次系统）
func setup_from_wave(wave_config: EnemyData.WaveConfig):
	# 0. 先获取节点引用（因为此函数在add_child之前调用，_ready还没执行）
	if not health_comp:
		health_comp = get_node_or_null("HealthComponent")
	if not sprite:
		sprite = get_node_or_null("Sprite2D")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape2D")
	if not health_bar:
		health_bar = get_node_or_null("HealthBar")

	# 1. 根据字符串类型找到对应的GameConstants枚举
	enemy_type = _get_enemy_type_from_string(wave_config.enemy_type)

	# 2. 应用波次配置的数值
	if health_comp:
		health_comp.max_hp = wave_config.hp
		health_comp.current_hp = wave_config.hp

	speed = wave_config.speed * 100.0
	base_speed = speed
	xp_value = wave_config.exp

	# 3. 从EnemyData获取对应类型的完整配置（用于获取mass、radius、scale等）
	enemy_data = EnemyData.ENEMIES.get(enemy_type)
	if enemy_data:
		mass = enemy_data.mass
		original_color = wave_config.color

		# 4. 应用视觉效果
		if sprite:
			# 根据敌人类型加载对应的纹理
			var texture_path = _get_texture_path_for_type(enemy_type)
			if ResourceLoader.exists(texture_path):
				sprite.texture = load(texture_path)

			sprite.modulate = wave_config.color

			# 应用缩放
			if "scale" in enemy_data:
				var s = enemy_data.scale
				sprite.scale = Vector2(s, s)
			else:
				sprite.scale = Vector2(0.015, 0.015)

		# 5. 应用碰撞半径
		if collision_shape and collision_shape.shape:
			collision_shape.shape.radius = enemy_data.radius

		# 6. 应用特殊行为属性（跳跃、射击等）
		if "can_jump" in enemy_data:
			can_jump = enemy_data.can_jump
			if "jump_interval" in enemy_data:
				jump_interval = enemy_data.jump_interval

		# 更新血量条
		_update_health_bar()

func _get_enemy_type_from_string(enemy_type_str: String) -> int:
	"""将字符串敌人类型转换为GameConstants枚举"""
	match enemy_type_str:
		"kedama":
			return GameConstants.EnemyType.KEDAMA
		"elf":
			return GameConstants.EnemyType.ELF
		"ghost":
			return GameConstants.EnemyType.GHOST
		"fairy":
			return GameConstants.EnemyType.FAIRY
		"elite":
			return GameConstants.EnemyType.ELITE
		_:
			return GameConstants.EnemyType.KEDAMA  # 默认毛玉

func _get_texture_path_for_type(type: int) -> String:
	"""根据敌人类型返回对应的纹理路径"""
	match type:
		GameConstants.EnemyType.KEDAMA:
			return "res://assets/maoyu.png"
		GameConstants.EnemyType.ELF:
			return "res://assets/elf.png"
		GameConstants.EnemyType.FAIRY:
			return "res://assets/elf.png"  # 妖精和精灵用同一个图
		GameConstants.EnemyType.GHOST:
			return "res://assets/elf.png"  # 暂时用elf，通过颜色区分
		GameConstants.EnemyType.ELITE:
			return "res://assets/maoyu.png"  # 精英怪用毛玉图，通过颜色和大小区分
		GameConstants.EnemyType.BOSS:
			return "res://assets/9.png"  # 默认Boss纹理
		_:
			return "res://assets/elf.png"

func _get_boss_texture_path(boss_type: int) -> String:
	"""根据Boss类型返回对应的纹理路径"""
	match boss_type:
		GameConstants.BossType.CIRNO:
			return "res://assets/9.png"
		GameConstants.BossType.YOUMU:
			return "res://assets/yaomeng.png"
		GameConstants.BossType.KAGUYA:
			return "res://assets/huiye2.png"
		_:
			return "res://assets/9.png"

func _create_enemy_shadow():
	"""备用阴影创建方法"""
	shadow_sprite = Sprite2D.new()
	shadow_sprite.name = "Shadow"

	var enemy_scale = sprite.scale.x if sprite else 1.0
	var width = int(40 * enemy_scale)
	var height = int(10 * enemy_scale)
	width = max(width, 2)
	height = max(height, 2)

	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center_x = width / 2.0
	var center_y = height / 2.0

	for x in range(width):
		for y in range(height):
			var dx = (x - center_x) / (width / 2.0)
			var dy = (y - center_y) / (height / 2.0)
			var dist_sq = dx * dx + dy * dy

			if dist_sq <= 1.0:
				var dist = sqrt(dist_sq)
				var alpha = (1.0 - dist) * 0.35
				alpha = pow(alpha, 1.5)
				image.set_pixel(x, y, Color(0, 0, 0, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	shadow_sprite.texture = ImageTexture.create_from_image(image)
	shadow_sprite.position = Vector2(12, 8)
	shadow_sprite.rotation = 0.8
	shadow_sprite.skew = 0.0
	shadow_sprite.z_index = -10
	shadow_sprite.centered = true

	add_child(shadow_sprite)

# 设置敌人类型和属性（旧接口，保留兼容性）
func setup(type: int, wave: int = 1):
	enemy_type = type

	# 重新加载配置
	if not EnemyData.ENEMIES.has(enemy_type):
		EnemyData.initialize()

	enemy_data = EnemyData.ENEMIES.get(enemy_type)
	if enemy_data and health_comp:
		# 根据波次调整难度
		var difficulty_multiplier = 1.0 + (wave - 1) * 0.1

		health_comp.max_hp = enemy_data.hp * difficulty_multiplier
		health_comp.current_hp = health_comp.max_hp
		speed = enemy_data.speed * 100.0
		base_speed = enemy_data.speed * 100.0  # 也要设置base_speed
		xp_value = int(enemy_data.exp * difficulty_multiplier)
		mass = enemy_data.mass  # 应用质量

		# 应用特殊行为属性
		can_jump = enemy_data.can_jump
		if can_jump:
			jump_interval = enemy_data.jump_interval

		# TODO: 应用射击属性（需要实现射击系统）
		# can_shoot = enemy_data.can_shoot
		# shoot_interval = enemy_data.shoot_interval

		if sprite:
			sprite.modulate = enemy_data.color
			# 敌人的sprite由Enemy.tscn控制，不在这里设置scale

		# 更新碰撞形状
		if collision_shape and collision_shape.shape:
			var enemy_radius = enemy_data.radius if "radius" in enemy_data else 10.0
			if collision_shape.shape is CircleShape2D:
				collision_shape.shape.radius = enemy_radius

		# 更新血量条
		_update_health_bar()

		print("[Enemy] 设置完成: ", enemy_data.enemy_name, " (类型:", type, ", 跳跃:", can_jump, ")")

# ==================== STATUS EFFECT APPLICATION METHODS ====================
# These methods are called by Bullet.gd when status effects are applied

# Apply burn status effect - DOT fire damage over time
func apply_burn(damage: float, duration: float):
	# Burns are stackable - multiple burns can be active at once
	var burn_effect = {
		"damage": damage,
		"duration": duration,
		"timer": 0.0
	}
	active_status_effects.burns.append(burn_effect)

# Apply freeze status effect - Completely stops movement
func apply_freeze(duration: float):
	# Freeze is not stackable - only apply if not already frozen
	if active_status_effects.freeze == null:
		active_status_effects.freeze = {
			"duration": duration,
			"timer": 0.0
		}

# Apply poison status effect - DOT poison damage over time
func apply_poison(damage: float, duration: float):
	# Poisons are stackable - multiple poisons can be active at once
	var poison_effect = {
		"damage": damage,
		"duration": duration,
		"timer": 0.0
	}
	active_status_effects.poisons.append(poison_effect)

# Apply stun status effect - Prevents all actions (movement and attacks)
func apply_stun(duration: float):
	# Stun is not stackable - refresh duration if already stunned
	if active_status_effects.stun == null:
		active_status_effects.stun = {
			"duration": duration,
			"timer": 0.0
		}
	else:
		# Extend stun duration
		active_status_effects.stun.duration = max(active_status_effects.stun.duration, duration)

# Apply slow status effect - Reduces movement speed by percentage
func apply_slow(amount: float, duration: float):
	# Slow is not stackable - only the strongest slow applies
	if active_status_effects.slow == null:
		active_status_effects.slow = {
			"amount": amount,
			"duration": duration,
			"timer": 0.0
		}
	else:
		# Apply stronger slow or extend duration
		if amount < active_status_effects.slow.amount:
			active_status_effects.slow.amount = amount
		active_status_effects.slow.duration = max(active_status_effects.slow.duration, duration)

# ==================== STATUS EFFECT UPDATE LOGIC ====================

# Update all active status effects each frame
func _update_status_effects(delta: float):
	# Update burn effects
	_update_burn_effects(delta)

	# Update poison effects
	_update_poison_effects(delta)

	# Update freeze effect
	if active_status_effects.freeze != null:
		active_status_effects.freeze.timer += delta
		if active_status_effects.freeze.timer >= active_status_effects.freeze.duration:
			active_status_effects.freeze = null

	# Update stun effect
	if active_status_effects.stun != null:
		active_status_effects.stun.timer += delta
		if active_status_effects.stun.timer >= active_status_effects.stun.duration:
			active_status_effects.stun = null

	# Update slow effect
	if active_status_effects.slow != null:
		active_status_effects.slow.timer += delta
		if active_status_effects.slow.timer >= active_status_effects.slow.duration:
			active_status_effects.slow = null

	# Update armor reduction timer
	if armor_reduction_timer > 0:
		armor_reduction_timer -= delta
		if armor_reduction_timer <= 0:
			armor_reduction = 0.0

# Update burn effects with DOT damage
func _update_burn_effects(delta: float):
	if active_status_effects.burns.size() == 0:
		return

	# Update tick timer
	burn_tick_timer += delta

	# Apply damage every tick interval
	if burn_tick_timer >= STATUS_TICK_INTERVAL:
		burn_tick_timer = 0.0

		# Calculate total burn damage from all active burns
		var total_burn_damage = 0.0
		for burn in active_status_effects.burns:
			total_burn_damage += burn.damage

		# Apply total burn damage
		if total_burn_damage > 0 and health_comp:
			health_comp.damage(total_burn_damage)

	# Update burn timers and remove expired burns
	var i = 0
	while i < active_status_effects.burns.size():
		active_status_effects.burns[i].timer += delta
		if active_status_effects.burns[i].timer >= active_status_effects.burns[i].duration:
			active_status_effects.burns.remove_at(i)
		else:
			i += 1

# Update poison effects with DOT damage
func _update_poison_effects(delta: float):
	if active_status_effects.poisons.size() == 0:
		return

	# Update tick timer
	poison_tick_timer += delta

	# Apply damage every tick interval
	if poison_tick_timer >= STATUS_TICK_INTERVAL:
		poison_tick_timer = 0.0

		# Calculate total poison damage from all active poisons
		var total_poison_damage = 0.0
		for poison in active_status_effects.poisons:
			total_poison_damage += poison.damage

		# Apply total poison damage
		if total_poison_damage > 0 and health_comp:
			health_comp.damage(total_poison_damage)

	# Update poison timers and remove expired poisons
	var i = 0
	while i < active_status_effects.poisons.size():
		active_status_effects.poisons[i].timer += delta
		if active_status_effects.poisons[i].timer >= active_status_effects.poisons[i].duration:
			active_status_effects.poisons.remove_at(i)
		else:
			i += 1

# Check if movement is disabled by status effects
func _is_movement_disabled() -> bool:
	# Freeze completely stops movement
	if active_status_effects.freeze != null:
		return true

	# Stun prevents all actions including movement
	if active_status_effects.stun != null:
		return true

	return false

# Calculate modified speed based on slow effects
func _get_modified_speed() -> float:
	var modified_speed = base_speed

	# Apply slow effect (multiplier reduction)
	if active_status_effects.slow != null:
		modified_speed *= active_status_effects.slow.amount

	return modified_speed

# ==================== STATUS EFFECT VISUAL FEEDBACK ====================

# Update visual indicators for active status effects
func _update_status_visuals(delta: float):
	if not sprite:
		return

	status_color_timer += delta

	# Determine which status colors to show
	var status_colors = []

	# Add colors for each active status
	if active_status_effects.burns.size() > 0:
		status_colors.append(Color.RED)  # Burn = Red

	if active_status_effects.freeze != null:
		status_colors.append(Color.CYAN)  # Freeze = Cyan/Blue

	if active_status_effects.poisons.size() > 0:
		status_colors.append(Color.GREEN)  # Poison = Green

	if active_status_effects.stun != null:
		status_colors.append(Color.YELLOW)  # Stun = Yellow

	if active_status_effects.slow != null:
		status_colors.append(Color.GRAY)  # Slow = Gray

	# Apply visual feedback
	if status_colors.size() > 0:
		# Create pulsing effect
		var pulse = abs(sin(status_color_timer * 5.0))
		var blend_factor = 0.3 + pulse * 0.4  # Oscillate between 0.3 and 0.7

		# Blend multiple status colors
		var blended_color = _blend_status_colors(status_colors)

		# Apply blended color with original color
		sprite.modulate = original_color.lerp(blended_color, blend_factor)
	else:
		# No active status effects - restore original color
		sprite.modulate = Color.WHITE

# Blend multiple status effect colors together
func _blend_status_colors(colors: Array) -> Color:
	if colors.size() == 0:
		return Color.WHITE

	if colors.size() == 1:
		return colors[0]

	# Average all colors together
	var result = Color.BLACK
	for color in colors:
		result += color

	result /= float(colors.size())
	return result

# ==================== HEALTH BAR UPDATE ====================

# 更新血量条显示
func _update_health_bar():
	if not health_bar or not health_comp:
		return

	# 更新血量条的值
	health_bar.max_value = health_comp.max_hp
	health_bar.value = health_comp.current_hp

	# 根据血量百分比改变颜色
	var health_percent = health_comp.current_hp / health_comp.max_hp
	if health_percent > 0.6:
		# 绿色：血量充足
		health_bar.modulate = Color(0.2, 1.0, 0.2)
	elif health_percent > 0.3:
		# 黄色：血量中等
		health_bar.modulate = Color(1.0, 1.0, 0.2)
	else:
		# 红色：血量危险
		health_bar.modulate = Color(1.0, 0.2, 0.2)

# ==================== ELEMENT SYSTEM METHODS ====================

# 添加元素叠层
func add_element_stack(element_type: int):
	if not element_stacks.has(element_type):
		element_stacks[element_type] = 0
	element_stacks[element_type] += 1

# 获取当前激活的元素列表
func get_active_elements() -> Array:
	var active = []
	for element_type in element_stacks.keys():
		if element_stacks[element_type] > 0:
			active.append(element_type)

	# 也包括通过状态效果激活的元素
	if active_status_effects.burns.size() > 0:
		if not GameConstants.ElementType.FIRE in active:
			active.append(GameConstants.ElementType.FIRE)
	if frost_stacks > 0 or active_status_effects.freeze != null:
		if not GameConstants.ElementType.ICE in active:
			active.append(GameConstants.ElementType.ICE)
	if active_status_effects.poisons.size() > 0 or vulnerability_stacks > 0:
		if not GameConstants.ElementType.POISON in active:
			active.append(GameConstants.ElementType.POISON)

	return active

# 清除所有元素叠层
func clear_element_stacks():
	element_stacks.clear()
	frost_stacks = 0

# 添加冰元素寒冷叠层
func add_frost_stack():
	frost_stacks += 1
	add_element_stack(GameConstants.ElementType.ICE)

	# 达到阈值时冻结
	if frost_stacks >= FROST_FREEZE_THRESHOLD:
		apply_freeze(2.0)  # 冻结2秒
		frost_stacks = 0  # 重置叠层

# 添加毒元素易伤叠层
func add_vulnerability_stack():
	vulnerability_stacks += 1
	add_element_stack(GameConstants.ElementType.POISON)

# 清除冻结状态
func clear_freeze():
	active_status_effects.freeze = null
	frost_stacks = 0

# 冻结敌人（CharacterSkills需要的接口）
func freeze(duration: float):
	apply_freeze(duration)
	# 添加视觉反馈
	if sprite:
		sprite.modulate = Color.CYAN

# 解除冻结（CharacterSkills需要的接口）
func unfreeze():
	clear_freeze()
	# 恢复原始颜色
	if sprite:
		if enemy_data:
			sprite.modulate = enemy_data.color
		else:
			sprite.modulate = original_color

# 应用护甲降低效果
func apply_armor_reduction(amount: float, duration: float):
	armor_reduction = amount
	armor_reduction_timer = duration

# 获取易伤加成伤害
func get_vulnerability_bonus() -> float:
	return vulnerability_stacks * VULNERABILITY_DAMAGE_PER_STACK
