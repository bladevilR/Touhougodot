extends Area2D
class_name Bullet

# Bullet - Complete bullet/projectile system implementing ALL combat mechanics
# from the original touhou-phantom game (constants.ts weapon definitions)
#
# Supported Mechanics:
# - Homing/Tracking (homingStrength)
# - Bouncing (bounceCount, wallBounces)
# - Penetration (penetration)
# - Orbital weapons (orbitRadius, orbitAngle, orbitSpeed)
# - Gravity effects (hasGravity)
# - Explosions (explosionRadius, explosionDamage)
# - Knockback (knockback)
# - Status effects (onHitEffect: burn, freeze, poison, heal, explode, stun, slow)
# - Laser mechanics (isLaser)
# - Barrier fields (isBarrierField, damageInterval)
# - Chain lightning (chainCount, chainRange)
# - Boomerang return (returnToPlayer)

# ==================== CORE PROPERTIES ====================
# Basic attributes
@export var damage: float = 10.0
@export var speed: float = 300.0
@export var lifetime: float = 5.0  # Duration in seconds
var direction: Vector2 = Vector2.RIGHT
var velocity: Vector2 = Vector2.ZERO  # Actual velocity vector

# Visual properties
var weapon_id: String = ""  # Weapon ID for texture selection
var bullet_color: Color = Color.WHITE  # Color for tinting

# ==================== PROJECTILE MECHANICS ====================
# Penetration & Knockback
@export var penetration: int = 1  # Number of enemies to pierce through
@export var knockback: float = 2.0

# Homing/Tracking
@export var homing_strength: float = 0.0  # 0-1, tracking strength (0.1-0.15 typical)
@export var has_homing_after_bounce: bool = false  # Enable homing after bouncing

# Bouncing
@export var bounce_count: int = 0  # Remaining bounces off walls/enemies
@export var wall_bounces: int = 0  # Wall-specific bounce count (separate from bounce_count)

# Explosion
@export var explosion_radius: float = 0.0
@export var explosion_damage: float = 0.0

# ==================== ORBITAL MECHANICS ====================
@export var orbit_radius: float = 0.0  # Distance from player (e.g., 150px)
@export var orbit_angle: float = 0.0  # Current angle in radians
@export var orbit_speed: float = 0.0  # Rotation speed (e.g., 0.03)
var player_reference: Node2D = null  # Reference to player for orbital weapons

# ==================== SPECIAL MECHANICS ====================
# Gravity (物理重力 - 让子弹往下掉)
@export var has_gravity: bool = false
var gravity_strength: float = 400.0  # Gravity acceleration

# Gravity Pull (引力拉扯 - 吸引周围敌人)
@export var gravity_pull_strength: float = 0.0  # Pull force (黑洞效果)
@export var gravity_pull_range: float = 300.0  # Pull range in pixels

# Laser
@export var is_laser: bool = false  # Instant raycast laser

# Barrier Field
@export var is_barrier_field: bool = false
@export var damage_interval: float = 0.2  # Damage tick interval in seconds
@export var slow_effect: float = 1.0  # Speed multiplier for enemies (0.5 = half speed)
var damage_timer: float = 0.0

# Boomerang
@export var return_to_player: bool = false
var return_phase: bool = false  # Whether boomerang is returning

# Chain Lightning
@export var chain_count: int = 0  # Number of enemies to chain to
@export var chain_range: float = 0.0  # Range for chaining
var chained_enemies: Array = []  # Track chained enemy IDs

# Split projectiles
@export var split_count: int = 0  # Number of projectiles to split into on hit
@export var split_angle_spread: float = 0.5  # Angle spread for split projectiles

# ==================== STATUS EFFECTS ====================
@export_enum("none", "burn", "freeze", "poison", "heal", "explode", "stun", "slow", "split")
var on_hit_effect: String = "none"

# Burn
@export var burn_duration: float = 3.0  # Duration in seconds (180 frames @ 60fps)
@export var burn_damage: float = 5.0  # Damage per tick

# Poison
@export var poison_duration: float = 3.0
@export var poison_damage: float = 3.0

# Stun
@export var stun_duration: float = 1.0

# Slow
@export var slow_duration: float = 2.0
@export var slow_amount: float = 0.5  # Speed reduction (0.5 = 50% slower)

# Heal
@export var heal_amount: float = 5.0

# Freeze
@export var freeze_duration: float = 2.0

# ==================== ELEMENT SYSTEM ====================
@export_enum("none", "fire", "ice", "lightning", "poison", "holy")
var element: String = "none"

# ==================== VISUAL ====================
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape = $CollisionShape2D

# ==================== INTERNAL STATE ====================
var hit_enemies: Array = []  # Track hit enemy IDs to prevent duplicate damage
var lifetime_timer: float = 0.0
var bounced_enemies: Array = []  # Track enemies already bounced to
var is_initialized: bool = false
var is_enemy_bullet: bool = false

# ==================== INITIALIZATION ====================
func _ready():
	add_to_group("bullet") # 确保能被清理
	
	# Setup collision detection
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# Initialize velocity from direction and speed
	if velocity == Vector2.ZERO and direction != Vector2.ZERO:
		velocity = direction.normalized() * speed

	# Find player reference for orbital weapons
	if orbit_radius > 0.0 or return_to_player:
		player_reference = get_tree().get_first_node_in_group("player")

	# Setup visual appearance
	_setup_bullet_visual()

	is_initialized = true

func _setup_bullet_visual():
	"""根据weapon_id加载正确的纹理并设置混合模式"""
	if not sprite:
		return

	# 根据weapon_id选择纹理
	var texture_path = ""
	var base_radius = 10.0
	var should_rotate = false

	match weapon_id:
		"homing_amulet":
			texture_path = "res://assets/bullets/amulet.png"
			base_radius = 180.0
			should_rotate = true
		"star_dust":
			texture_path = "res://assets/bullets/star.png"
			base_radius = 240.0
			should_rotate = true
		"rice_grain":  # 米粒弹 - 敌人射击用
			var tex = load("res://assets/bullets/rice_bullet.png")
			if tex:
				sprite.texture = tex
				# 强制缩小：米粒弹应该很小
				# 假设原图可能是64x64或更大，给一个0.1的缩放
				sprite.scale = Vector2(0.1, 0.1) 
				sprite.material = CanvasItemMaterial.new()
				sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
				sprite.modulate = bullet_color
				if velocity.length() > 0:
					sprite.rotation = velocity.angle() + PI/2 # 恢复旋转修正
				return # 直接返回，避免后续逻辑覆盖
			else:
				# Fallback
				texture_path = "res://assets/bullets/rice_bullet.png"
				base_radius = 120.0
				should_rotate = true
		"phoenix_wings":
			# 为光环创建高级感半透明纹理（火焰能量场效果）
			var aura_texture = _create_premium_aura_texture(120.0, Color(1.0, 0.5, 0.1, 0.6))
			sprite.texture = aura_texture
			sprite.scale = Vector2(1.0, 1.0)
			# 不使用ADD混合模式，避免闪烁
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # 固定不变
			should_rotate = false
			# 设置z_index让光环在玩家下层，不影响玩家颜色
			z_index = -5
			# 增大碰撞半径形成光环区域
			if collision_shape and collision_shape.shape:
				collision_shape.shape.radius = 120.0  # 光环伤害范围
			return  # 直接返回，不执行后续通用纹理加载
		"phoenix_claws":
			# 火鸟拳：扇形横扫效果，使用拉长的矩形
			var sweep_texture = _create_sweep_texture(60.0, 20.0, Color(1.0, 0.3, 0.0, 0.8))  # 橙红色拉长矩形
			sprite.texture = sweep_texture
			sprite.scale = Vector2(1.0, 1.0)
			sprite.material = CanvasItemMaterial.new()
			sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			should_rotate = true
			# 横扫碰撞使用胶囊形状
			if collision_shape and collision_shape.shape:
				collision_shape.shape.radius = 20.0  # 近战横扫范围
			return  # 直接返回，使用自定义纹理
		"knives":
			texture_path = "res://assets/bullets/knife.png"
			base_radius = 200.0
			should_rotate = true
		"yin_yang_orb":
			texture_path = "res://assets/bullets/yinyang.png"
			base_radius = 150.0
			should_rotate = false
			# 阴阳玉是大体积子弹，确保碰撞箱够大
			if collision_shape and collision_shape.shape:
				if collision_shape.shape is CircleShape2D:
					collision_shape.shape.radius = 60.0 # 150 * 0.4 = 60
				elif collision_shape.shape is RectangleShape2D:
					collision_shape.shape.size = Vector2(120, 120)
		_:
			# 根据半径选择通用弹幕
			var radius = collision_shape.shape.radius if collision_shape and collision_shape.shape else 10.0
			if radius > 15:
				texture_path = "res://assets/bullets/big_bullet.png"
				base_radius = 200.0
			else:
				texture_path = "res://assets/bullets/rice_bullet.png"
				base_radius = 150.0
			should_rotate = true

	# 激光特殊处理：动态生成光束纹理
	if is_laser:
		var gradient = Gradient.new()
		gradient.set_color(0, Color(1, 1, 1, 0)) # 两端透明
		gradient.set_color(1, Color(1, 1, 1, 0))
		gradient.add_point(0.2, Color(1, 1, 1, 0.8)) # 中间亮
		gradient.add_point(0.8, Color(1, 1, 1, 0.8))
		
		var texture = GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 64
		texture.height = 16 # 细长
		texture.fill = GradientTexture2D.FILL_LINEAR
		texture.fill_from = Vector2(0, 0)
		texture.fill_to = Vector2(0, 1) # 纵向渐变（如果是横向激光则改横向，这里假设激光沿Y轴拉伸或旋转）
		# 实际上激光通常是横向的。
		# 让我们做一个横向的激光纹理：左透明 -> 中白 -> 右透明
		texture.fill_from = Vector2(0, 0)
		texture.fill_to = Vector2(1, 0) 
		
		sprite.texture = texture
		# 激光通常不需要CanvasItemMaterial.BLEND_MODE_ADD，或者需要看效果。保持ADD通常比较亮。
		sprite.material = CanvasItemMaterial.new()
		sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		sprite.modulate = bullet_color
		
		# 激光不需要太大缩放，长度由Lifetime或逻辑决定，这里只负责宽度
		sprite.scale = Vector2(2.0, 0.5) # 长一点，细一点
		
		if velocity.length() > 0:
			sprite.rotation = velocity.angle()
			
		return # 激光设置完毕，直接返回

	# 加载纹理
	if texture_path != "" and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)

		# 设置混合模式为ADD（发光效果）
		sprite.material = CanvasItemMaterial.new()
		sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

		# 使用modulate着色（tint效果）
		sprite.modulate = bullet_color

		# 根据半径缩放
		var radius = collision_shape.shape.radius if collision_shape and collision_shape.shape else 10.0
		var target_scale = radius / base_radius
		
		# 特殊处理
		if weapon_id == "yin_yang_orb":
			sprite.scale = Vector2(0.4, 0.4) # 阴阳玉缩小，从0.8降到0.4
		else:
			sprite.scale = Vector2(target_scale * 1.8, target_scale * 1.8) # 全局缩放从2.5降到1.8

		# 旋转朝向运动方向
		if should_rotate and velocity.length() > 0:
			sprite.rotation = velocity.angle() + PI/2  # +90度因为贴图默认朝上

func _create_circle_texture(radius: float, color: Color) -> ImageTexture:
	"""创建圆形渐变纹理用于光环效果"""
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var center = Vector2(radius, radius)

	# 绘制柔和的圆形光环（模拟火焰）
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var normalized_dist = dist / radius

			var alpha = 0.0
			var brightness = 1.0

			# 创建多层渐变效果
			if normalized_dist < 1.0:
				# 中心到边缘的渐变
				# 0.0-0.3: 中心较暗
				# 0.3-0.7: 中间亮
				# 0.7-1.0: 边缘柔和衰减
				if normalized_dist < 0.3:
					alpha = normalized_dist * 0.2
					brightness = 0.8
				elif normalized_dist < 0.7:
					alpha = 0.06 + (normalized_dist - 0.3) * 1.5
					brightness = 1.0
				elif normalized_dist < 0.95:
					var edge_factor = (normalized_dist - 0.7) / 0.25
					alpha = 0.66 - edge_factor * 0.4
					brightness = 1.0 - edge_factor * 0.3
				else:
					# 最外层快速衰减，制造柔和边缘
					var fade = (1.0 - normalized_dist) / 0.05
					alpha = 0.26 * fade
					brightness = 0.7

				alpha *= color.a

			var pixel_color = Color(color.r * brightness, color.g * brightness, color.b * brightness, alpha)
			image.set_pixel(x, y, pixel_color)

	return ImageTexture.create_from_image(image)

func _create_solid_circle_texture(radius: float, color: Color) -> ImageTexture:
	"""创建固定颜色的圆形纹理（无渐变，防止闪烁）"""
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var center = Vector2(radius, radius)

	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var normalized_dist = dist / radius

			if normalized_dist < 1.0:
				# 简单的圆形，边缘稍微柔和
				var alpha = color.a
				if normalized_dist > 0.85:
					# 边缘柔和过渡
					alpha = color.a * (1.0 - (normalized_dist - 0.85) / 0.15)
				image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)

func _create_premium_aura_texture(radius: float, color: Color) -> ImageTexture:
	"""创建高级感的能量场光环纹理 - 多层渐变+光晕环+能量纹理"""
	var size = int(radius * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	var center = Vector2(radius, radius)

	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var normalized_dist = dist / radius

			if normalized_dist >= 1.0:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			# 基础alpha - 从中心向外渐变
			var base_alpha = 0.0

			# 层1: 内核光晕（中心微亮）
			if normalized_dist < 0.25:
				base_alpha = 0.15 + (0.25 - normalized_dist) * 0.3

			# 层2: 中间能量层（主要可见区域）
			elif normalized_dist < 0.6:
				var t = (normalized_dist - 0.25) / 0.35
				base_alpha = 0.2 + sin(t * PI) * 0.25

			# 层3: 外围光晕环
			elif normalized_dist < 0.85:
				var t = (normalized_dist - 0.6) / 0.25
				base_alpha = 0.35 - t * 0.15

			# 层4: 边缘柔和衰减
			else:
				var t = (normalized_dist - 0.85) / 0.15
				base_alpha = 0.2 * (1.0 - t * t)

			# 添加环形纹理（同心圆波纹效果）
			var ring_factor = sin(normalized_dist * 12.0) * 0.5 + 0.5
			var ring_intensity = ring_factor * 0.08

			# 添加径向纹理（射线效果）
			var angle = atan2(pos.y - center.y, pos.x - center.x)
			var ray_factor = sin(angle * 8.0) * 0.5 + 0.5
			var ray_intensity = ray_factor * 0.05 * (1.0 - normalized_dist)

			# 合并所有效果
			var final_alpha = (base_alpha + ring_intensity + ray_intensity) * color.a

			# 颜色渐变：中心偏黄，外围偏橙红
			var color_blend = normalized_dist * 0.4
			var r = lerp(1.0, color.r, color_blend)
			var g = lerp(0.8, color.g, color_blend + 0.2)
			var b = lerp(0.3, color.b, color_blend)

			image.set_pixel(x, y, Color(r, g, b, clamp(final_alpha, 0.0, 0.7)))

	return ImageTexture.create_from_image(image)

func _create_sweep_texture(length: float, width: float, color: Color) -> ImageTexture:
	"""创建横扫效果���理（拉长的矩形带渐变）"""
	var w = int(length)
	var h = int(width)
	var image = Image.create(w, h, false, Image.FORMAT_RGBA8)

	var center_y = h / 2.0

	# 绘制横扫火焰效果
	for x in range(w):
		for y in range(h):
			var normalized_x = float(x) / float(w)  # 0-1，从左到右
			var dist_y = abs(y - center_y) / center_y  # 0-1，距离中心线的距离

			var alpha = 0.0

			# 横向渐变：中间亮，两端衰减
			var horizontal_fade = 1.0
			if normalized_x < 0.2:
				horizontal_fade = normalized_x / 0.2  # 起始淡入
			elif normalized_x > 0.8:
				horizontal_fade = (1.0 - normalized_x) / 0.2  # 末尾淡出

			# 纵向渐变：中心亮，边缘衰减
			var vertical_fade = 1.0 - dist_y

			# 合并渐变
			alpha = horizontal_fade * vertical_fade * color.a

			var pixel_color = Color(color.r, color.g, color.b, alpha)
			image.set_pixel(x, y, pixel_color)

	return ImageTexture.create_from_image(image)

# ==================== PHYSICS PROCESS ====================
func _physics_process(delta):
	if not is_initialized:
		return

	lifetime_timer += delta

	# Check lifetime expiration
	if lifetime_timer >= lifetime:
		_on_lifetime_end()
		return

	# ===== ORBITAL MECHANICS =====
	if orbit_radius > 0.0 and player_reference:
		_update_orbital_movement(delta)
		return  # Skip normal movement for orbital weapons

	# ===== BARRIER FIELD MECHANICS =====
	if is_barrier_field:
		_update_barrier_field(delta)
		return  # Barrier stays in place

	# ===== BOOMERANG MECHANICS =====
	if return_to_player:
		_update_boomerang_movement(delta)

	# ===== HOMING/TRACKING MECHANICS =====
	if homing_strength > 0.0 and not return_phase:
		var target = _find_nearest_enemy()
		if target:
			var to_target = (target.global_position - global_position).normalized()
			velocity = velocity.normalized().lerp(to_target, homing_strength * delta * 60.0).normalized() * speed

	# ===== GRAVITY MECHANICS (物理重力) =====
	if has_gravity:
		velocity.y += gravity_strength * delta
		# Cap falling speed
		velocity.y = min(velocity.y, 800.0)

	# ===== GRAVITY PULL MECHANICS (引力拉扯) =====
	if gravity_pull_strength > 0.0:
		_apply_gravity_pull()

	# ===== MOVEMENT =====
	global_position += velocity * delta

	# ===== WALL BOUNCE MECHANICS =====
	if bounce_count > 0 or wall_bounces > 0:
		_check_wall_bounce()

	# ===== OFF-SCREEN CLEANUP =====
	_check_out_of_bounds()

	# ===== VISUAL ROTATION =====
	if sprite and velocity.length() > 0:
		sprite.rotation = velocity.angle()

# ==================== ORBITAL MOVEMENT ====================
func _update_orbital_movement(delta: float):
	if not player_reference:
		queue_free()
		return

	# Update orbit angle
	orbit_angle += orbit_speed * delta * 60.0  # Convert to frame-based timing

	# Calculate position around player
	var offset = Vector2(
		cos(orbit_angle) * orbit_radius,
		sin(orbit_angle) * orbit_radius
	)

	global_position = player_reference.global_position + offset

	# Rotate sprite to face outward
	if sprite:
		# 光环特殊效果：完全静止，不旋转，不改变任何视觉属性
		if weapon_id == "phoenix_wings":
			pass  # 不做任何操作，保持纹理完全静止
		else:
			sprite.rotation = orbit_angle

	# 主动检测并伤害重叠的敌人（修复光环不造成伤害的问题）
	var overlapping_bodies = get_overlapping_bodies()
	var overlapping_areas = get_overlapping_areas()

	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			_hit_enemy(body)

	for area in overlapping_areas:
		var parent = area.get_parent()
		if parent and parent.is_in_group("enemy"):
			_hit_enemy(parent)

# ==================== BARRIER FIELD ====================
func _update_barrier_field(delta: float):
	damage_timer += delta

	# Damage tick
	if damage_timer >= damage_interval:
		damage_timer = 0.0

		# Get all overlapping enemies
		var overlapping_bodies = get_overlapping_bodies()
		var overlapping_areas = get_overlapping_areas()

		for body in overlapping_bodies:
			if body.is_in_group("enemy"):
				_apply_barrier_damage(body)

		for area in overlapping_areas:
			var parent = area.get_parent()
			if parent and parent.is_in_group("enemy"):
				_apply_barrier_damage(parent)

func _apply_barrier_damage(enemy):
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, weapon_id)

	# Apply slow effect
	if slow_effect < 1.0 and enemy.has_method("apply_slow"):
		enemy.apply_slow(slow_effect, damage_interval)

# ==================== BOOMERANG MECHANICS ====================
func _update_boomerang_movement(delta: float):
	if not player_reference:
		queue_free()
		return

	# Check distance to player
	var distance_to_player = global_position.distance_to(player_reference.global_position)

	# Switch to return phase after traveling some distance
	if not return_phase and lifetime_timer > lifetime * 0.4:
		return_phase = true

	if return_phase:
		# Return to player
		var to_player = (player_reference.global_position - global_position).normalized()
		velocity = to_player * speed * 1.5  # Return faster

		# Collect when reaching player
		if distance_to_player < 30.0:
			queue_free()

# ==================== COLLISION DETECTION ====================
func _on_area_entered(area):
	var parent = area.get_parent()
	if parent and parent.is_in_group("enemy"):
		_hit_enemy(parent)

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		_hit_enemy(body)
	else:
		# 碰到墙壁/竹子等环境物体时反弹
		if bounce_count > 0 or wall_bounces > 0:
			_bounce_off_body(body)

# ==================== HIT DETECTION & DAMAGE ====================
func _hit_enemy(enemy):
	# Prevent duplicate damage (except for barrier fields)
	if not is_barrier_field:
		var enemy_id = enemy.get_instance_id()
		if enemy_id in hit_enemies:
			return
		hit_enemies.append(enemy_id)

	# Apply damage
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, weapon_id)

	# Apply knockback
	if knockback > 0:
		var knock_dir = (enemy.global_position - global_position).normalized()
		if enemy.has_method("apply_knockback"):
			enemy.apply_knockback(knock_dir, knockback)
		elif enemy.has_method("velocity"):
			enemy.velocity += knock_dir * knockback * 100

	# Apply status effects
	_apply_status_effect(enemy)

	# Handle chain lightning
	if chain_count > 0:
		_chain_to_nearby_enemies(enemy)

	# Handle split projectiles
	if split_count > 0:
		_split_projectile()

	# Reduce penetration
	if not is_barrier_field and penetration > 0:
		penetration -= 1
		
		# 特殊效果：高穿透且可反弹的子弹（如阴阳玉），在击中敌人时轻微偏转，增加混乱感
		if penetration > 10 and (bounce_count > 0 or wall_bounces > 0):
			var deflection = deg_to_rad(randf_range(-10, 10))
			velocity = velocity.rotated(deflection)
			direction = velocity.normalized()
			if sprite:
				sprite.rotation = velocity.angle() + PI/2
		
		if penetration <= 0:
			_on_penetration_depleted()

# ==================== STATUS EFFECTS ====================
func _apply_status_effect(enemy):
	# 首先应用明确指定的on_hit_effect
	match on_hit_effect:
		"burn":
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(burn_damage, burn_duration)

		"freeze":
			if enemy.has_method("apply_freeze"):
				enemy.apply_freeze(freeze_duration)

		"poison":
			if enemy.has_method("apply_poison"):
				enemy.apply_poison(poison_damage, poison_duration)

		"stun":
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(stun_duration)

		"slow":
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(slow_amount, slow_duration)

		"heal":
			if player_reference and player_reference.has_method("heal"):
				player_reference.heal(heal_amount)

		"explode":
			_explode()

		"split":
			_split_projectile()

	# 然后根据元素类型应用额外效果
	_apply_element_effect(enemy)

	# 检查元素反应
	_check_element_reaction(enemy)

func _apply_element_effect(enemy):
	"""根据子弹的element类型应用对应的元素效果"""
	match element:
		"fire":
			# 火元素：点燃效果 (DOT 5dmg/s，持续3s)
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(5.0, 3.0)
			if enemy.has_method("add_element_stack"):
				enemy.add_element_stack(GameConstants.ElementType.FIRE)

		"ice":
			# 冰元素：叠加寒冷值，3层冻结
			if enemy.has_method("add_frost_stack"):
				enemy.add_frost_stack()
			elif enemy.has_method("add_element_stack"):
				enemy.add_element_stack(GameConstants.ElementType.ICE)

		"lightning":
			# 雷元素：连锁闪电 (已经在chain_count处理)
			if enemy.has_method("add_element_stack"):
				enemy.add_element_stack(GameConstants.ElementType.LIGHTNING)

		"poison":
			# 毒元素：易伤效果 (每层+5固定伤害)
			if enemy.has_method("add_vulnerability_stack"):
				enemy.add_vulnerability_stack()
			elif enemy.has_method("add_element_stack"):
				enemy.add_element_stack(GameConstants.ElementType.POISON)

func _check_element_reaction(enemy):
	"""检查并触发元素反应"""
	if element == "none" or element == "":
		return

	# 获取敌人当前的元素状态
	if not enemy.has_method("get_active_elements"):
		return

	var enemy_elements = enemy.get_active_elements()

	# 转换当前元素为ElementType
	var current_element = _string_to_element_type(element)
	if current_element == -1:
		return

	# 检查每个敌人身上的元素
	for enemy_element in enemy_elements:
		if enemy_element == current_element:
			continue  # 跳过相同元素

		# 检查反应
		var reaction = ElementData.check_reaction(current_element, enemy_element)
		if reaction:
			_trigger_element_reaction(enemy, reaction)
			break  # 只触发一次反应

func _trigger_element_reaction(enemy, reaction):
	"""触发元素反应效果"""
	print("触发元素反应: ", reaction.reaction_name)

	match reaction.effect_type:
		"explosion":
			# 地狱火：大范围爆炸
			_create_reaction_explosion(enemy.global_position, reaction.radius, damage * reaction.damage_multiplier)

		"freeze_shatter":
			# 碎冰：对冻结敌人暴击
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage * reaction.damage_multiplier, weapon_id)
			# 清除冻结状态
			if enemy.has_method("clear_freeze"):
				enemy.clear_freeze()

		"corrosion":
			# 腐蚀：降低防御
			if enemy.has_method("apply_armor_reduction"):
				enemy.apply_armor_reduction(0.5, 5.0)  # 50%护甲降低，5秒

		"steam":
			# 蒸汽：范围伤害+遮蔽
			_create_reaction_explosion(enemy.global_position, reaction.radius, 120.0)

		"thunder_field":
			# 雷暴领域：持续电击区域
			_create_thunder_field(enemy.global_position, reaction.radius, damage * reaction.damage_multiplier)

	# 清除参与反应的元素
	if enemy.has_method("clear_element_stacks"):
		enemy.clear_element_stacks()

func _create_reaction_explosion(pos: Vector2, radius: float, dmg: float):
	"""创建元素反应爆炸"""
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var distance = pos.distance_to(enemy.global_position)
		if distance <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(dmg, weapon_id)

func _create_thunder_field(pos: Vector2, radius: float, dmg: float):
	"""创建雷暴领域（持续电击区域）"""
	# 简化实现：直接对范围内敌人造成伤害
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var distance = pos.distance_to(enemy.global_position)
		if distance <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(dmg, weapon_id)
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(0.5)

func _string_to_element_type(elem_str: String) -> int:
	"""将元素字符串转换为ElementType枚举"""
	match elem_str:
		"fire":
			return GameConstants.ElementType.FIRE
		"ice":
			return GameConstants.ElementType.ICE
		"lightning":
			return GameConstants.ElementType.LIGHTNING
		"poison":
			return GameConstants.ElementType.POISON
		_:
			return -1

# ==================== CHAIN LIGHTNING ====================
func _chain_to_nearby_enemies(source_enemy):
	if chain_count <= 0 or chain_range <= 0:
		return

	var enemy_id = source_enemy.get_instance_id()
	chained_enemies.append(enemy_id)

	var enemies = get_tree().get_nodes_in_group("enemy")
	var chained = 0

	for enemy in enemies:
		if chained >= chain_count:
			break

		var eid = enemy.get_instance_id()
		if eid in chained_enemies:
			continue

		var distance = source_enemy.global_position.distance_to(enemy.global_position)
		if distance <= chain_range:
			# Chain damage (reduced)
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage * 0.7, weapon_id)

			chained_enemies.append(eid)
			chained += 1

			# Visual: spawn chain effect (TODO: implement visual)
			# _spawn_chain_visual(source_enemy.global_position, enemy.global_position)

# ==================== SPLIT PROJECTILES ====================
func _split_projectile():
	if split_count <= 0:
		return

	var bullet_scene = load("res://Bullet.tscn")
	if not bullet_scene:
		return

	for i in range(split_count):
		var split_bullet = bullet_scene.instantiate()
		get_parent().add_child(split_bullet)

		# Calculate split angle
		var angle_offset = (i - split_count / 2.0) * split_angle_spread
		var split_angle = velocity.angle() + angle_offset
		var split_velocity = Vector2(cos(split_angle), sin(split_angle)) * speed * 0.8

		# Copy properties
		split_bullet.global_position = global_position
		split_bullet.velocity = split_velocity
		split_bullet.damage = damage * 0.6
		split_bullet.penetration = 1
		split_bullet.lifetime = lifetime * 0.5
		split_bullet.element = element

# ==================== WALL BOUNCE ====================
func _bounce_off_body(body: Node2D):
	"""碰到墙壁/竹子时反弹"""
	# 计算反弹方向（基于碰撞点）
	var collision_normal = (global_position - body.global_position).normalized()

	# 如果无法计算有效法线，使用简单反向
	if collision_normal.length_squared() < 0.01:
		collision_normal = -velocity.normalized()

	# 反射速度向量
	velocity = velocity.bounce(collision_normal)
	direction = velocity.normalized()

	# 更新视觉旋转
	if sprite and velocity.length() > 0:
		sprite.rotation = velocity.angle() + PI/2

	# 减少反弹次数
	if wall_bounces > 0:
		wall_bounces -= 1
	elif bounce_count > 0:
		bounce_count -= 1

	# 启用导向（如果有）
	if has_homing_after_bounce and homing_strength == 0.0:
		homing_strength = 0.1

	# 无反弹次数时触发爆炸
	if bounce_count <= 0 and wall_bounces <= 0:
		if has_gravity:
			_explode()
		queue_free()

func _check_wall_bounce():
	var map_bounds = Rect2(0, 0, GameConstants.MAP_WIDTH, GameConstants.MAP_HEIGHT)
	var bounced = false

	# Check horizontal bounds
	if global_position.x <= map_bounds.position.x or global_position.x >= map_bounds.end.x:
		velocity.x *= -1
		bounced = true

		# Clamp position
		global_position.x = clamp(global_position.x, map_bounds.position.x + 10, map_bounds.end.x - 10)

	# Check vertical bounds
	if global_position.y <= map_bounds.position.y or global_position.y >= map_bounds.end.y:
		velocity.y *= -1
		bounced = true

		# Clamp position
		global_position.y = clamp(global_position.y, map_bounds.position.y + 10, map_bounds.end.y - 10)

	# Reduce bounce count
	if bounced:
		if wall_bounces > 0:
			wall_bounces -= 1
		elif bounce_count > 0:
			bounce_count -= 1

		# Enable homing after bounce (Reimu bond ability)
		if has_homing_after_bounce and homing_strength == 0.0:
			homing_strength = 0.1

		# Trigger explosion if no bounces left
		if bounce_count <= 0 and wall_bounces <= 0:
			if has_gravity:  # Ground impact explosion (molotov)
				_explode()
				queue_free()

# ==================== EXPLOSION ====================
func _explode():
	if explosion_radius <= 0:
		return

	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance <= explosion_radius:
			if enemy.has_method("take_damage"):
				var dmg = explosion_damage if explosion_damage > 0 else damage
				enemy.take_damage(dmg, weapon_id)

			# Apply knockback from explosion center
			if knockback > 0:
				var knock_dir = (enemy.global_position - global_position).normalized()
				if enemy.has_method("apply_knockback"):
					enemy.apply_knockback(knock_dir, knockback * 2.0)

	# TODO: Spawn explosion visual effect
	# SignalBus.emit_signal("spawn_explosion", global_position, explosion_radius)

# ==================== CLEANUP ====================
func _on_penetration_depleted():
	_explode()
	queue_free()

func _on_lifetime_end():
	# Trigger explosion on timeout (mines, etc.)
	if on_hit_effect == "explode" or explosion_radius > 0:
		_explode()
	queue_free()

func _check_out_of_bounds():
	# Despawn if too far from map (safety check)
	var map_bounds = Rect2(-200, -200, GameConstants.MAP_WIDTH + 400, GameConstants.MAP_HEIGHT + 400)
	if not map_bounds.has_point(global_position):
		queue_free()

# ==================== UTILITY ====================
func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return null

	var nearest = null
	var min_distance = INF

	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = enemy

	return nearest

# Apply gravity pull effect to nearby enemies (黑洞效果)
func _apply_gravity_pull():
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var dx = global_position.x - enemy.global_position.x
		var dy = global_position.y - enemy.global_position.y
		var dist = sqrt(dx * dx + dy * dy)

		# Only pull enemies within range
		if dist < gravity_pull_range and dist > 0.1:
			# Pull force inversely proportional to distance squared
			# 原项目公式：pullForce = gravityStrength / (dist * dist + 1)
			var pull_force = gravity_pull_strength / (dist * dist + 1.0)

			# Normalize direction and apply pull
			var pull_x = (dx / dist) * pull_force
			var pull_y = (dy / dist) * pull_force

			# Apply to enemy velocity (if enemy has velocity property)
			if enemy.has_method("apply_knockback"):
				# Use knockback system to apply pull force
				var pull_direction = Vector2(pull_x, pull_y).normalized()
				enemy.apply_knockback(pull_direction, pull_force * 10.0)
			elif "velocity" in enemy:
				enemy.velocity.x += pull_x
				enemy.velocity.y += pull_y

# ==================== SETUP HELPER ====================
# Setup bullet from dictionary config (for WeaponSystem integration)
func setup(config: Dictionary):
	# Visual properties
	if config.has("weapon_id"):
		weapon_id = config.weapon_id
	if config.has("bullet_color"):
		bullet_color = config.bullet_color
	elif config.has("color"):
		# 支持Color对象或颜色字符串
		var color_value = config.color
		if color_value is Color:
			bullet_color = color_value
		elif color_value is String:
			bullet_color = Color(color_value)

	# Core properties
	if config.has("damage"):
		damage = config.damage
	if config.has("speed"):
		speed = config.speed
	if config.has("lifetime"):
		lifetime = config.lifetime
	if config.has("direction"):
		direction = config.direction.normalized()
		velocity = direction * speed
	if config.has("velocity"):
		velocity = config.velocity

	# Projectile mechanics
	if config.has("penetration"):
		penetration = config.penetration
	if config.has("knockback"):
		knockback = config.knockback
	if config.has("homing_strength"):
		homing_strength = config.homing_strength
	if config.has("bounce_count"):
		bounce_count = config.bounce_count
	if config.has("wall_bounces"):
		wall_bounces = config.wall_bounces
	if config.has("explosion_radius"):
		explosion_radius = config.explosion_radius
	if config.has("explosion_damage"):
		explosion_damage = config.explosion_damage

	# Orbital
	if config.has("orbit_radius"):
		orbit_radius = config.orbit_radius
	if config.has("orbit_angle"):
		orbit_angle = config.orbit_angle
	if config.has("orbit_speed"):
		orbit_speed = config.orbit_speed

	# Special mechanics
	if config.has("has_gravity"):
		has_gravity = config.has_gravity
	if config.has("gravity_pull_strength"):
		gravity_pull_strength = config.gravity_pull_strength
	if config.has("gravity_pull_range"):
		gravity_pull_range = config.gravity_pull_range
	if config.has("is_laser"):
		is_laser = config.is_laser
	if config.has("is_barrier_field"):
		is_barrier_field = config.is_barrier_field
	if config.has("damage_interval"):
		damage_interval = config.damage_interval
	if config.has("slow_effect"):
		slow_effect = config.slow_effect
	if config.has("return_to_player"):
		return_to_player = config.return_to_player
	if config.has("chain_count"):
		chain_count = config.chain_count
	if config.has("chain_range"):
		chain_range = config.chain_range
	if config.has("split_count"):
		split_count = config.split_count
	if config.has("split_angle_spread"):
		split_angle_spread = config.split_angle_spread
	if config.has("has_homing_after_bounce"):
		has_homing_after_bounce = config.has_homing_after_bounce

	# Status effects
	if config.has("on_hit_effect"):
		on_hit_effect = config.on_hit_effect
	if config.has("burn_duration"):
		burn_duration = config.burn_duration
	if config.has("burn_damage"):
		burn_damage = config.burn_damage
	if config.has("poison_duration"):
		poison_duration = config.poison_duration
	if config.has("poison_damage"):
		poison_damage = config.poison_damage
	if config.has("stun_duration"):
		stun_duration = config.stun_duration
	if config.has("slow_duration"):
		slow_duration = config.slow_duration
	if config.has("slow_amount"):
		slow_amount = config.slow_amount
	if config.has("heal_amount"):
		heal_amount = config.heal_amount
	if config.has("freeze_duration"):
		freeze_duration = config.freeze_duration

	# Element
	if config.has("element"):
		element = config.element

	# Enemy bullet config
	if config.has("is_enemy_bullet"):
		is_enemy_bullet = config.is_enemy_bullet
		if is_enemy_bullet:
			collision_layer = 16 # Layer 5
			collision_mask = 1 + 2 # Player + Walls
		else:
			collision_layer = 8 # Layer 4
			collision_mask = 4 + 2 # Enemy + Walls
