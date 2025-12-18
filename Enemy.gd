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

# Shooting system
var shoot_timer: float = 0.0

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

# ==================== KEDAMA CHARGE ATTACK SYSTEM ====================
# 毛玉撞击攻击系统
var is_charging: bool = false  # 是否正在蓄力
var is_dashing_attack: bool = false  # 是否正在冲刺攻击
var charge_timer: float = 0.0  # 蓄力计时器
var dash_timer: float = 0.0  # 冲刺计时器
var attack_cooldown: float = 0.0  # 攻击冷却
const CHARGE_DURATION: float = 0.3  # 蓄力时间（前摇）
const DASH_DURATION: float = 0.4  # 冲刺时间
const ATTACK_COOLDOWN: float = 2.0  # 攻击冷却2秒
const DASH_SPEED_MULTIPLIER: float = 2.0  # 冲刺速度倍数（降低速度）
var charge_direction: Vector2 = Vector2.ZERO  # 蓄力方向
var dash_hit_players: Array = []  # 记录已击中的玩家（避免重复伤害）

# ==================== VISUAL EFFECTS ====================
var shadow_sprite: Sprite2D = null  # 地面影子

# 螺旋线特效系统
var spiral_trail: Line2D = null  # 螺旋线
var spiral_trail_active: bool = false  # 螺旋线是否激活
var spiral_trail_duration: float = 0.0  # 螺旋线持续时间
var spiral_trail_timer: float = 0.0  # 螺旋线计时器
var spiral_trail_points: Array = []  # 记录轨迹点
const SPIRAL_TRAIL_MAX_POINTS: int = 30  # 最大轨迹点数

# ==================== BOSS ATTACK SYSTEM ====================
var boss_attack_timer: float = 0.0
var current_attack_index: int = 0
const BOSS_ATTACK_INTERVAL: float = 3.0 # Attack every 3 seconds

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
	
	# 毛玉特殊处理：使用简单影子防止反转问题
	if enemy_type == GameConstants.EnemyType.KEDAMA:
		_create_enemy_shadow()
	elif map_system and map_system.has_method("create_shadow_for_entity"):
		# 根据敌人缩放调整阴影大小
		var enemy_scale = sprite.scale.x if sprite else 1.0
		var shadow_size = Vector2(40 * enemy_scale, 10 * enemy_scale)
		
		# 根据敌人类型判断是否悬空
		# 调整偏移：往里吃进一些 (负Y) - 用户要求更激进的偏移
		var shadow_offset = Vector2(0, -15) # 激进吃进
		var shadow_alpha = 0.5
		
		# 飞行单位
		if enemy_type in [GameConstants.EnemyType.ELF, GameConstants.EnemyType.FAIRY, GameConstants.EnemyType.GHOST]:
			shadow_offset = Vector2(0, 30 * enemy_scale) # 悬空还是在下方，但稍微拉近
			shadow_alpha = 0.3 
			
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
	var boss_scale = boss_config.scale
	if sprite:
		sprite.scale = Vector2(boss_scale, boss_scale)
	if collision_shape and collision_shape.shape:
		# 碰撞箱也相应缩放 (注意：碰撞箱通常不需要像纹理那样缩放那么大，或者基于radius设置)
		# EnemyData.gd 中 BossConfig 有 radius (25.0)。
		# 如果这里直接缩放 collision_shape，可能会导致判定过大。
		# 既然 HealthComp/Setup 使用了 radius，这里可能不需要再次缩放 Shape，或者应该重置 Scale?
		# 但为了安全起见，我们假设 collision_shape 初始是 1.0，我们只设置 radius。
		# 不过 setup_as_boss 前面已经设置了 radius (通过 EnemyData 逻辑?) 
		# 不，setup_as_boss 并没有设置 radius! 只有 hp/speed/mass.
		# 我们需要手动设置 radius.
		
		collision_shape.scale = Vector2(1.0, 1.0) # 重置缩放，使用半径控制
		if collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = boss_config.radius
		elif collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size = Vector2(boss_config.radius * 2, boss_config.radius * 2)

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

	# ==================== KEDAMA CHARGE ATTACK SYSTEM ====================
	# 毛玉撞击攻击（带前摇）
	if enemy_type == GameConstants.EnemyType.KEDAMA:
		_process_kedama_charge_attack(delta)

	# ==================== GENERAL SHOOTING LOGIC ====================
	if enemy_data and enemy_data.can_shoot and is_instance_valid(target):
		# 简单的视距检查
		if global_position.distance_to(target.global_position) < 600.0:
			shoot_timer -= delta
			if shoot_timer <= 0:
				print("[Enemy] Pew! Shooting at target.")
				shoot_timer = enemy_data.shoot_interval
				_shoot_at_target()

	# ==================== BOSS LOGIC ====================
	if enemy_type == GameConstants.EnemyType.BOSS:
		_process_boss_attacks(delta)

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

func _shoot_at_target():
	if not is_instance_valid(target): return
	
	var dir = global_position.direction_to(target.global_position)
	var bullet_scene = load("res://Bullet.tscn")
	if bullet_scene:
		var bullet = bullet_scene.instantiate()
		
		var color = enemy_data.color if enemy_data else Color.RED
		# 米粒弹外观配置
		var config = {
			"weapon_id": "rice_grain", # 假设有这个ID或默认
			"color": color,
			"damage": enemy_data.damage,
			"speed": 300.0,
			"direction": dir,
			"lifetime": 4.0,
			"is_enemy_bullet": true
		}
		
		if bullet.has_method("setup"):
			bullet.setup(config)
			
		bullet.global_position = global_position
		get_parent().add_child(bullet)

# ==================== BOSS ATTACK LOGIC ====================
func _process_boss_attacks(delta: float):
	if not enemy_data or not enemy_data is EnemyData.BossConfig:
		return

	boss_attack_timer -= delta
	if boss_attack_timer <= 0:
		boss_attack_timer = BOSS_ATTACK_INTERVAL
		_execute_next_boss_attack()

# ==================== KEDAMA CHARGE ATTACK ====================
func _process_kedama_charge_attack(delta: float):
	"""处理毛玉的撞击攻击系统"""
	# 更新攻击冷却
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# 如果正在蓄力
	if is_charging:
		charge_timer += delta

		# 蓄力视觉效果：变大+变红
		if sprite:
			var charge_progress = charge_timer / CHARGE_DURATION
			var scale_mult = 1.0 + charge_progress * 0.3  # 最多放大30%
			sprite.scale = Vector2(enemy_data.scale, enemy_data.scale) * scale_mult
			sprite.modulate = Color.WHITE.lerp(Color.RED, charge_progress)

		# 蓄力完成，开始冲刺
		if charge_timer >= CHARGE_DURATION:
			is_charging = false
			is_dashing_attack = true
			dash_timer = 0.0
			dash_hit_players.clear()

			# 恢复颜色
			if sprite:
				sprite.modulate = Color.WHITE
		return

	# 如果正在冲刺攻击
	if is_dashing_attack:
		dash_timer += delta

		# 冲刺移动
		velocity = charge_direction * base_speed * DASH_SPEED_MULTIPLIER
		move_and_slide()

		# 检测击中玩家
		_check_dash_hit_player()

		# 冲刺结束
		if dash_timer >= DASH_DURATION:
			is_dashing_attack = false
			attack_cooldown = ATTACK_COOLDOWN

			# 恢复正常大小
			if sprite:
				sprite.scale = Vector2(enemy_data.scale, enemy_data.scale)
		return

	# 正常状态：检测是否应该开始蓄力
	if attack_cooldown <= 0 and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		# 在150像素范围内触发撞击攻击
		if distance < 150.0 and distance > 30.0:
			_start_charge_attack()

func _start_charge_attack():
	"""开始蓄力攻击"""
	if not is_instance_valid(target):
		return

	is_charging = true
	charge_timer = 0.0
	charge_direction = global_position.direction_to(target.global_position)
	print("[Kedama] 开始蓄力撞击！")

func _check_dash_hit_player():
	"""检查冲刺攻击是否击中玩家"""
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if not is_instance_valid(player):
			continue

		# 避免重复伤害
		var player_id = player.get_instance_id()
		if player_id in dash_hit_players:
			continue

		var distance = global_position.distance_to(player.global_position)
		if distance < 40.0:  # 撞击判定范围
			dash_hit_players.append(player_id)

			# 造成伤害
			if player.has_method("take_damage"):
				var damage = enemy_data.damage if enemy_data else 10.0
				player.take_damage(damage)
				print("[Kedama] 撞击命中！造成", damage, "点伤害")

			# 击退玩家
			if player.has_method("apply_knockback"):
				player.apply_knockback(charge_direction, 600.0)

# ==================== BOSS ATTACK LOGIC (continued) ====================

func _execute_next_boss_attack():
	var patterns = enemy_data.attack_patterns
	if patterns.size() == 0: return
	
	var pattern_name = patterns[current_attack_index % patterns.size()]
	current_attack_index += 1
	
	print("[Boss] Executing attack: ", pattern_name)
	
	match pattern_name:
		"ice_spread": _attack_ice_spread()
		"freeze_circle": _attack_freeze_circle()
		"sword_dash": _attack_sword_dash()
		"spirit_split": _attack_spirit_split()
		"impossible_bullet_hell": _attack_impossible_bullet_hell()
		"time_stop": _attack_time_stop()

func _spawn_boss_bullet(pos: Vector2, dir: Vector2, speed_val: float, weapon_id: String, color: Color, props: Dictionary = {}):
	var bullet_scene = load("res://Bullet.tscn")
	if not bullet_scene: return
	
	var bullet = bullet_scene.instantiate()
	# Configure bullet
	var config = {
		"weapon_id": weapon_id,
		"color": color,
		"damage": enemy_data.damage,
		"speed": speed_val,
		"direction": dir,
		"lifetime": 5.0,
		"knockback": 0.0, # Boss bullets usually don't knockback player too much
		"is_enemy_bullet": true # Mark as enemy bullet for collision detection
	}
	config.merge(props)
	
	if bullet.has_method("setup"):
		bullet.setup(config)
	
	bullet.global_position = pos
	
	# Add to bullet layer (usually parent of enemy)
	get_parent().add_child(bullet)

# --- Cirno Attacks ---
func _attack_ice_spread():
	# 360 degree spread of ice crystals
	var count = 36
	for i in range(count):
		var angle = i * (TAU / count)
		var dir = Vector2(cos(angle), sin(angle))
		_spawn_boss_bullet(global_position, dir, 300.0, "star_dust", Color.CYAN, {"element": "ice", "freeze_duration": 1.0})

func _attack_freeze_circle():
	# Barrier field that freezes
	var bullet_scene = load("res://Bullet.tscn")
	if bullet_scene:
		var barrier = bullet_scene.instantiate()
		barrier.setup({
			"weapon_id": "phoenix_wings", # Use aura visual
			"color": Color(0.5, 0.8, 1.0, 0.5),
			"damage": 5.0,
			"is_barrier_field": true,
			"damage_interval": 0.5,
			"slow_effect": 0.2, # Extreme slow
			"lifetime": 3.0,
			"orbit_radius": 0.0, # Center on boss
			"element": "ice"
		})
		barrier.global_position = global_position
		# Attach to boss? No, create at position.
		get_parent().add_child(barrier)

# --- Youmu Attacks ---
func _attack_sword_dash():
	# Dash towards player
	if is_instance_valid(target):
		var dash_dir = global_position.direction_to(target.global_position)
		knockback_target_velocity = dash_dir * 800.0 # Use knockback system for dash movement
		
		# Spawn sword projectiles along the path (delayed)
		for i in range(5):
			await get_tree().create_timer(0.1 * i).timeout
			_spawn_boss_bullet(global_position, dash_dir, 500.0, "knives", Color.WHITE, {"penetration": 5})

func _attack_spirit_split():
	# Spawn phantom bullets
	var count = 8
	for i in range(count):
		var angle = randf() * TAU
		var dir = Vector2(cos(angle), sin(angle))
		_spawn_boss_bullet(global_position + dir * 50, dir, 200.0, "homing_amulet", Color.WHITE, {"homing_strength": 0.05})

# --- Kaguya Attacks ---
func _attack_impossible_bullet_hell():
	# 东方风格：七彩扩散弹幕
	# 从Boss位置向四周发射彩虹色弹幕
	var wave_count = 5  # 5波弹幕
	var bullets_per_wave = 36  # 每波36颗子弹（10度间隔）

	for wave in range(wave_count):
		# 彩虹色渐变
		var colors = [
			Color("#ff0000"),  # 红
			Color("#ff7f00"),  # 橙
			Color("#ffff00"),  # 黄
			Color("#00ff00"),  # 绿
			Color("#0000ff"),  # 蓝
			Color("#4b0082"),  # 靛
			Color("#9400d3")   # 紫
		]

		for i in range(bullets_per_wave):
			var angle = i * (TAU / bullets_per_wave) + wave * 0.1  # 每波稍微旋转
			var dir = Vector2(cos(angle), sin(angle))
			var color = colors[i % colors.size()]

			_spawn_boss_bullet(
				global_position,
				dir,
				200.0 + wave * 20.0,  # 速度逐波递增
				"yin_yang_orb",
				color,
				{"bounce_count": 1}
			)

		# 波次间隔
		await get_tree().create_timer(0.3).timeout

func _attack_time_stop():
	# 东方风格：延迟直线弹幕
	# 先生成静止的弹幕，然后同时激活向玩家射去
	var count = 24  # 24颗子弹围成一圈
	var bullets = []

	# 第一阶段：生成静止弹幕（圆形阵列）
	for i in range(count):
		var angle = i * (TAU / count)
		var offset = Vector2(cos(angle), sin(angle)) * 250  # 距离Boss 250像素
		var bullet_scene = load("res://Bullet.tscn")

		if bullet_scene:
			var bullet = bullet_scene.instantiate()
			bullet.setup({
				"weapon_id": "star_dust",
				"color": Color.MAGENTA,
				"damage": 25.0,
				"speed": 0.0,  # 初始静止
				"lifetime": 8.0,
				"is_enemy_bullet": true
			})
			bullet.global_position = global_position + offset
			get_parent().add_child(bullet)
			bullets.append(bullet)

	# 等待1.5秒（给玩家反应时间）
	await get_tree().create_timer(1.5).timeout

	# 第二阶段：同时激活，向玩家位置射去
	if is_instance_valid(target):
		var target_pos = target.global_position
		for bullet in bullets:
			if is_instance_valid(bullet):
				var dir = (target_pos - bullet.global_position).normalized()
				# 重新配置子弹，使其移动
				bullet.setup({
					"weapon_id": "star_dust",
					"color": Color.MAGENTA,
					"damage": 25.0,
					"speed": 350.0,  # 快速射出
					"direction": dir,
					"lifetime": 5.0,
					"is_enemy_bullet": true
				})

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
		
		# 受击震动反馈 (已移除)
		# if final_damage > 20:
		# 	SignalBus.screen_shake.emit(0.05, 3.0)

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
	# 发射死亡粒子效果 - 爆开效果
	var particle_color = original_color if original_color != Color.RED else Color.WHITE
	
	# 增加粒子数量和爆发感
	SignalBus.spawn_death_particles.emit(global_position, particle_color, 30) 
	
	# 额外的白色闪光粒子，模拟爆炸核心
	SignalBus.spawn_death_particles.emit(global_position, Color.WHITE, 10)

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

	# Boss死亡特殊处理：发出boss_defeated信号
	if enemy_type == GameConstants.EnemyType.BOSS:
		print("[Enemy] Boss defeated! Emitting boss_defeated signal...")
		SignalBus.boss_defeated.emit()

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

func setup_from_config(config: EnemyData.EnemyConfig):
	"""从EnemyConfig对象初始化敌人"""
	# 0. 获取节点引用
	if not health_comp: health_comp = get_node_or_null("HealthComponent")
	if not sprite: sprite = get_node_or_null("Sprite2D")
	if not collision_shape: collision_shape = get_node_or_null("CollisionShape2D")
	if not health_bar: health_bar = get_node_or_null("HealthBar")

	enemy_data = config
	enemy_type = config.enemy_type
	
	# 应用属性
	if health_comp:
		health_comp.max_hp = config.hp
		health_comp.current_hp = config.hp
		
	speed = config.speed * 100.0
	base_speed = speed
	xp_value = config.exp
	mass = config.mass
	original_color = config.color
	
	if sprite:
		sprite.modulate = config.color
		if config.scale > 0:
			sprite.scale = Vector2(config.scale, config.scale)
		
		# Y-Sort Fix: Sprite 上移半个身位，让 Position 代表脚底
		sprite.position.y = -40
		
		# 加载纹理
		var texture_path = ""
		if "boss_type" in config: # Check property existence
			texture_path = _get_boss_texture_path(config.boss_type)
		else:
			texture_path = _get_texture_path_for_type(enemy_type)
			
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
			
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = config.radius
			collision_shape.position = Vector2(0, 0) # 碰撞箱在脚底
			
	# 特殊属性
	can_jump = config.can_jump
	jump_interval = config.jump_interval
	
	_update_health_bar()
	print("[Enemy] Setup from config: ", config.enemy_name, " CanShoot:", config.can_shoot)

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
			return "res://assets/characters/9.png"
		GameConstants.BossType.YOUMU:
			return "res://assets/characters/yaomeng2.png"
		GameConstants.BossType.KAGUYA:
			return "res://assets/characters/huiye.png"
		_:
			return "res://assets/characters/9.png"

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
func setup(config_or_type, wave: int = 1):
	if typeof(config_or_type) == TYPE_OBJECT:
		setup_from_config(config_or_type)
		return

	var type = config_or_type
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
			
			# 加载正确的纹理
			var texture_path = _get_texture_path_for_type(enemy_type)
			if ResourceLoader.exists(texture_path):
				sprite.texture = load(texture_path)
				
			# 应用缩放
			if "scale" in enemy_data:
				var s = enemy_data.scale
				sprite.scale = Vector2(s, s)
			else:
				sprite.scale = Vector2(0.015, 0.015)

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
