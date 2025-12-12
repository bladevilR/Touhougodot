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
var knockback_immunity: bool = false
const KNOCKBACK_DECAY: float = 5.0  # How fast knockback decays

# Collision avoidance
const ENEMY_SEPARATION_RADIUS: float = 80.0  # 增加检测范围
const ENEMY_SEPARATION_STRENGTH: float = 150.0  # 增加分离力度
const MAX_SEPARATION_FORCE: float = 400.0  # 增加最大分离力

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

	# 创建地面影子（椭圆形）
	_create_shadow()

func _setup_collision_layers():
	# Layer 1: Player
	# Layer 2: Walls
	# Layer 3: Enemy
	# Layer 4: Bullet (Player)
	# Layer 5: Bullet (Enemy)
	# Layer 6: Pickup

	collision_layer = 4  # 敌人在第3层
	collision_mask = 1 + 2 + 4 + 8  # 检测玩家(Layer 1) + 墙壁(Layer 2) + 其他敌人(Layer 3) + 玩家子弹(Layer 4)

func _physics_process(delta):
	# ==================== STATUS EFFECT UPDATES ====================
	_update_status_effects(delta)
	_update_status_visuals(delta)

	# Check if enemy can move (not frozen or stunned)
	if _is_movement_disabled():
		# Still apply knockback decay even when disabled
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
	var separation_force = _calculate_enemy_separation()
	desired_velocity += separation_force

	# Combine desired velocity with knockback
	velocity = desired_velocity + knockback_velocity

	# Apply knockback decay
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)

	# Move with collision
	move_and_slide()

	# 简单的翻转逻辑
	# ColorRect不支持flip_h，暂时跳过
	# if velocity.x != 0:
	# 	sprite.flip_h = velocity.x < 0

# ==================== PHYSICS METHODS ====================

# Calculate separation force to prevent enemy stacking
func _calculate_enemy_separation() -> Vector2:
	var separation = Vector2.ZERO
	var neighbor_count = 0
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy == self:
			continue

		var distance = global_position.distance_to(enemy.global_position)

		# Only apply separation within radius
		if distance < ENEMY_SEPARATION_RADIUS and distance > 0.1:
			var direction = (global_position - enemy.global_position).normalized()
			var strength = (1.0 - distance / ENEMY_SEPARATION_RADIUS) * ENEMY_SEPARATION_STRENGTH
			separation += direction * strength
			neighbor_count += 1

	# Cap the separation force to prevent extreme values
	if separation.length() > MAX_SEPARATION_FORCE:
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

	# Apply knockback velocity
	knockback_velocity += direction.normalized() * actual_force * 100.0

	# Cap maximum knockback velocity to prevent extreme speeds
	var max_knockback = 500.0
	if knockback_velocity.length() > max_knockback:
		knockback_velocity = knockback_velocity.normalized() * max_knockback

# ==================== VISUAL EFFECTS ====================
func _create_shadow():
	"""创建地面影子（椭圆形）"""
	# 创建影子sprite
	shadow_sprite = Sprite2D.new()

	# 创建一个简单的椭圆形纹理（使用圆形纹理压扁）
	# 如果有专门的影子纹理更好，这里先用代码生成
	var shadow_size = 20
	var shadow_image = Image.create(shadow_size, shadow_size, false, Image.FORMAT_RGBA8)

	# 画一个黑色半透明圆形
	for x in range(shadow_size):
		for y in range(shadow_size):
			var dx = x - shadow_size / 2.0
			var dy = y - shadow_size / 2.0
			var dist = sqrt(dx * dx + dy * dy)
			if dist < shadow_size / 2.0:
				var alpha = (1.0 - dist / (shadow_size / 2.0)) * 0.3  # 半透明
				shadow_image.set_pixel(x, y, Color(0, 0, 0, alpha))

	var shadow_texture = ImageTexture.create_from_image(shadow_image)
	shadow_sprite.texture = shadow_texture
	shadow_sprite.scale = Vector2(1.5, 0.75)  # 椭圆形（扁的）
	shadow_sprite.z_index = -1  # 在敌人下方
	shadow_sprite.position = Vector2(0, 5)  # 稍微往下偏移

	add_child(shadow_sprite)

# 子弹打中敌人时，调用这个函数
func take_damage(amount):
	# 应用易伤加成
	var final_damage = amount + get_vulnerability_bonus()

	# 应用护甲降低（如果有）
	if armor_reduction > 0:
		final_damage *= (1.0 + armor_reduction)

	if health_comp:
		health_comp.damage(final_damage)
		# 发射伤害数字
		SignalBus.damage_dealt.emit(final_damage, global_position, false)

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

	# 触发轻微屏幕震动
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

	print("setup_from_wave 被调用: ", wave_config.enemy_type)

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
			print("尝试加载纹理: ", texture_path)
			print("纹理文件存在? ", ResourceLoader.exists(texture_path))

			if ResourceLoader.exists(texture_path):
				sprite.texture = load(texture_path)
				print("✓ 纹理已加载: ", texture_path)
			else:
				print("✗ 纹理文件不存在: ", texture_path)

			sprite.modulate = wave_config.color

			# 应用缩放
			if "scale" in enemy_data:
				var s = enemy_data.scale
				sprite.scale = Vector2(s, s)
			else:
				sprite.scale = Vector2(0.015, 0.015)  # 默认缩放
		else:
			print("✗ sprite 为 null，无法设置纹理")

		# 5. 应用碰撞半径
		if collision_shape and collision_shape.shape:
			collision_shape.shape.radius = enemy_data.radius

		# 6. 应用特殊行为属性（跳跃、射击等）
		if "can_jump" in enemy_data:
			can_jump = enemy_data.can_jump
			if "jump_interval" in enemy_data:
				jump_interval = enemy_data.jump_interval
			print("✓ 跳跃能力已启用，间隔: ", jump_interval, "秒")

		# 更新血量条
		_update_health_bar()

		print("生成敌人: ", enemy_data.enemy_name, " (", wave_config.enemy_type, ") HP:", wave_config.hp, " 半径:", enemy_data.radius, " 颜色:", wave_config.color)

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
		xp_value = int(enemy_data.exp * difficulty_multiplier)
		mass = enemy_data.mass  # 应用质量

		if sprite:
			sprite.modulate = enemy_data.color

		# 更新血量条
		_update_health_bar()

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

# 应用护甲降低效果
func apply_armor_reduction(amount: float, duration: float):
	armor_reduction = amount
	armor_reduction_timer = duration

# 获取易伤加成伤害
func get_vulnerability_bonus() -> float:
	return vulnerability_stacks * VULNERABILITY_DAMAGE_PER_STACK
