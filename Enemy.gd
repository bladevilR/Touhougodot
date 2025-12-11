extends CharacterBody2D

# Enemy - 敌人AI（使用敌人数据）

@export var speed = 100.0
@export var xp_value = 10
@export var enemy_type: int = 0  # GameConstants.EnemyType

var health_comp = null
var sprite = null
var collision_shape = null

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

# ==================== STATUS EFFECT SYSTEM ====================
# Status effect tracking structures
var active_status_effects = {
	"burns": [],        # Array of {damage: float, duration: float, timer: float}
	"poisons": [],      # Array of {damage: float, duration: float, timer: float}
	"freeze": null,     # {duration: float, timer: float} or null
	"stun": null,       # {duration: float, timer: float} or null
	"slow": null,       # {amount: float, duration: float, timer: float} or null
}

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

	# 初始化敌人数据
	EnemyData.initialize()

	# 加载敌人配置
	enemy_data = EnemyData.ENEMIES.get(enemy_type)
	if enemy_data and health_comp:
		# 应用敌人属性
		health_comp.max_hp = enemy_data.hp
		health_comp.current_hp = enemy_data.hp
		speed = enemy_data.speed * 50.0
		xp_value = enemy_data.exp
		mass = enemy_data.mass  # 应用质量

		# 设置颜色（Sprite2D使用modulate而不是color）
		if sprite:
			sprite.modulate = enemy_data.color
			original_color = enemy_data.color

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

# 子弹打中敌人时，调用这个函数
func take_damage(amount):
	if health_comp:
		health_comp.damage(amount)
		# 发射伤害数字
		SignalBus.damage_dealt.emit(amount, global_position, false)

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

# 设置敌人类型和属性
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
		speed = enemy_data.speed * 50.0
		xp_value = int(enemy_data.exp * difficulty_multiplier)
		mass = enemy_data.mass  # 应用质量

		if sprite:
			sprite.modulate = enemy_data.color

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
