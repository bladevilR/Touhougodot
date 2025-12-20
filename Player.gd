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
var shadow_sprite: Sprite2D = null # 影子引用

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
var is_attacking: bool = false # 是否正在播放攻击动画
var current_attack_id: int = 0 # 攻击动画实例ID
var animation_frame: int = 0
var animation_timer: float = 0.0
const ANIMATION_SPEED: float = 0.08  # 每帧持续时间

# 蓄力攻击变量
var charge_start_time: float = 0.0
var is_weapon_charging: bool = false # 是否正在蓄力

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

	# 确保精灵可见
	if sprite:
		sprite.visible = true

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

	# [修复] 延迟添加影子，确保 MapSystem 已就绪
	call_deferred("_initialize_shadow")

	# 创建蓄力条
	_create_charge_bar()

	# 显示精灵（角色数据已加载）
	if sprite:
		sprite.visible = true
		# 复位 Sprite，不再尝试上移
		sprite.position = Vector2.ZERO

	# 阴影位置在_try_add_shadow中已经设置，无需重复调整

	# 碰撞箱下移找脚
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = 15.0
			collision_shape.position = Vector2(0, 45)
		elif collision_shape.shape is RectangleShape2D:
			collision_shape.shape.size = Vector2(30, 20)
			collision_shape.position = Vector2(0, 45)

func _initialize_shadow():
	# 使用 MapSystem 的高级投影影子
	var map_system = get_tree().get_first_node_in_group("map_system")
	if map_system and map_system.has_method("create_shadow_for_entity"):
		# 强制清理旧影子
		if has_node("Shadow"):
			get_node("Shadow").queue_free()
			
		# 创建新影子，偏移量设为 (0, -10) 以贴合脚底
		# 60x20 的尺寸是根据角色比例预估的
		shadow_sprite = map_system.create_shadow_for_entity(self, Vector2(60, 20), Vector2(0, -10))
		if shadow_sprite:
			print("Player Shadow Created Successfully via MapSystem")
	else:
		print("Warning: MapSystem not found, player shadow creation skipped.")

func _sync_shadow_visuals():
	"""每一帧同步影子的纹理和状态"""
	if not shadow_sprite or not is_instance_valid(shadow_sprite):
		shadow_sprite = get_node_or_null("Shadow")
		if not shadow_sprite: return
		
	if not sprite or not sprite.texture: return
	
	# 同步纹理属性
	if shadow_sprite.texture != sprite.texture:
		shadow_sprite.texture = sprite.texture
	
	shadow_sprite.hframes = sprite.hframes
	shadow_sprite.vframes = sprite.vframes
	shadow_sprite.frame = sprite.frame
	
	# 计算尺寸
	var frame_height = sprite.texture.get_height() / sprite.vframes
	var frame_width = sprite.texture.get_width() / sprite.hframes
	
	# 关键修正：将锚点设为底部中心，确保翻转后从脚底延伸
	shadow_sprite.centered = false
	shadow_sprite.offset = Vector2(-frame_width / 2.0, -frame_height)
	
	# 计算脚底位置 (假设Sprite中心在0,0)
	var player_scale_y = abs(sprite.scale.y)
	# [修复] 之前减去的是纹理像素，乘缩放后几乎为0。
	# 现在改为减去 15.0 屏幕像素，强行向上提，消除缝隙。
	var feet_y = (frame_height * player_scale_y) / 2.0 - 15.0
	
	# 将影子节点定位到脚底
	shadow_sprite.position = Vector2(0, feet_y)
	
	# 垂直翻转缩放 (向下投影)
	shadow_sprite.scale = Vector2(abs(sprite.scale.x), -player_scale_y * 0.5)
	
	# 同步水平翻转
	shadow_sprite.flip_h = sprite.flip_h or (sprite.scale.x < 0)
	
	# 获取环境倾斜值
	var map_skew = 0.5
	var map_system = get_tree().get_first_node_in_group("map_system")
	if map_system and "SHADOW_SKEW" in map_system:
		map_skew = map_system.SHADOW_SKEW
		
	# 应用倾斜 (与环境保持一致，不再取反)
	shadow_sprite.skew = map_skew

func _on_character_selected(selected_id: int):
	"""角色选择信号回调"""
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
				sprite.scale = Vector2(0.08, 0.08)

		# 加载妹红动画（如果是妹红）
		if char_id == GameConstants.CharacterId.MOKOU:
			_load_mokou_textures()
			# 立即应用站立纹理，防止首帧隐身
			if mokou_textures.stand:
				sprite.texture = mokou_textures.stand
				# 预设一个合理的 Scale
				sprite.scale = Vector2(0.05, 0.05) 
			
			# Give her weapons: Light Kick (LMB) and Heavy Kick (RMB)
			SignalBus.weapon_added.emit("mokou_kick_light")
			SignalBus.weapon_added.emit("mokou_kick_heavy")

		# 装备初始武器
		SignalBus.weapon_added.emit(character_data.starting_weapon_id)
		
		# 同步ID到技能组件（解决初始化时序问题）
		if character_skills:
			character_skills.character_id = char_id

	# Adjust Camera Zoom (适当的视野大小)
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.zoom = Vector2(1.5, 1.5)  # 适中的zoom值，人物清晰可见
		camera.make_current() # Ensure camera follows player
		
		# 动态添加屏幕震动组件
		var camera_shake = Node.new()
		camera_shake.name = "CameraShake"
		camera_shake.set_script(load("res://CameraShake.gd"))
		camera.add_child(camera_shake)

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

func _input(event):
	# 妹红攻击输入处理
	if character_id == GameConstants.CharacterId.MOKOU and weapon_system:
		# 鼠标输入
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					# 开始蓄力
					if not is_weapon_charging:
						charge_start_time = Time.get_ticks_msec() / 1000.0
						is_weapon_charging = true
				else:
					# 释放蓄力攻击
					if is_weapon_charging:
						var current_time = Time.get_ticks_msec() / 1000.0
						var charge_duration = current_time - charge_start_time
						
						# 只要蓄力超过 0.1 秒，就触发效果
						if charge_duration > 0.1:
							var intensity = clamp(charge_duration / 1.5, 0.2, 1.0)
							# 触发释放爆发特效
							_spawn_release_burst(intensity)

						# 根据输入方式决定方向
						var fire_dir = Vector2.ZERO
						fire_dir = (get_global_mouse_position() - global_position).normalized()

						weapon_system.fire_charged_flame_ring(charge_duration, fire_dir)

						is_weapon_charging = false
						if sprite: sprite.modulate = Color.WHITE # 复位颜色
			elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				# 右键重击
				weapon_system.try_fire_weapon("mokou_kick_heavy")

		# 键盘输入 (J/K)
		if event is InputEventKey:
			if event.keycode == KEY_J:
				if event.pressed:
					if not is_weapon_charging:
						charge_start_time = Time.get_ticks_msec() / 1000.0
						is_weapon_charging = true
				else:
					if is_weapon_charging:
						var current_time = Time.get_ticks_msec() / 1000.0
						var charge_duration = current_time - charge_start_time
						
						# 键盘释放逻辑同上
						if charge_duration > 0.1:
							var intensity = clamp(charge_duration / 1.5, 0.2, 1.0)
							_spawn_release_burst(intensity)
						
						# 键盘释放，使用键盘方向
						var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
						if input_dir.length() < 0.1:
							if sprite and sprite.flip_h: input_dir = Vector2.LEFT
							else: input_dir = Vector2.RIGHT
						else:
							input_dir = input_dir.normalized()
							
						weapon_system.fire_charged_flame_ring(charge_duration, input_dir)
						
						is_weapon_charging = false
						if sprite: sprite.modulate = Color.WHITE
						
			elif event.keycode == KEY_K and event.pressed:
				# 键盘右键映射
				weapon_system.try_fire_weapon("mokou_kick_heavy")

func _physics_process(delta):
	# 同步影子视觉 (每帧更新)
	_sync_shadow_visuals()

	# 更新无敌计时器
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		is_invulnerable = invulnerable_timer > 0

	# 更新接触伤害冷却
	if contact_damage_cooldown > 0:
		contact_damage_cooldown -= delta

	# ==================== 蓄力视觉反馈 ====================
	var charge_bar = get_node_or_null("ChargeBar")
	
	if is_weapon_charging and sprite:
		var current_time = Time.get_ticks_msec() / 1000.0
		var duration = current_time - charge_start_time
		# 变红变亮：从白色渐变到高亮红
		var t = clamp(duration / 1.5, 0.0, 1.0)
		sprite.modulate = Color.WHITE.lerp(Color(3.0, 0.5, 0.2), t)
		
		# 更新蓄力条
		if charge_bar:
			charge_bar.visible = true
			# 直接赋值，配合 step=0.01 实现平滑
			charge_bar.value = duration
			
			# 蓄力快满时颤抖 (t > 0.7)
			if t > 0.7:
				var s = (t - 0.7) / 0.3 * 2.5 
				charge_bar.position = Vector2(35, -40) + Vector2(randf_range(-s, s), randf_range(-s, s))
			else:
				charge_bar.position = Vector2(35, -40)
			
			# 满蓄力时变红
			if duration >= 1.5:
				charge_bar.modulate = Color(2.0, 0.2, 0.2) # 发光红
			else:
				charge_bar.modulate = Color.WHITE
		
		# 聚气粒子 (每0.1秒生成一次)
		if Engine.get_physics_frames() % 6 == 0:
			_spawn_charging_particles(t)
	else:
		if charge_bar: 
			charge_bar.visible = false
			charge_bar.value = 0 # 重置

	# 如果正在执行技能，跳过普通移动逻辑 (包括Dash)
	if character_skills and character_skills.is_skill_active():
		# 修复：技能期间（如飞踢）也需要更新动画
		if character_id == GameConstants.CharacterId.MOKOU and character_skills.is_fire_kicking:
			_update_mokou_animation(delta, character_skills.fire_kick_direction)
		return

	# ==================== DASH LOGIC ====================
	_update_dash_timers(delta)

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

func take_damage(amount: float, should_shake: bool = true):
	"""造成伤害"""
	# 无敌时不受伤害
	if is_invulnerable:
		return

	if health_comp:
		health_comp.damage(amount)

		if should_shake:
			# 自机受击：高频、小幅度、极短 + 泛红
			SignalBus.screen_shake.emit(0.15, 5.0) 
			SignalBus.screen_flash.emit(Color(1.0, 0.0, 0.0, 0.3), 0.2)

		# 播放受击效果
		if sprite:
			sprite.modulate = Color.RED
			await get_tree().create_timer(0.1).timeout
			sprite.modulate = Color.WHITE

func hitstop(duration: float):
	"""顿帧效果"""
	Engine.time_scale = 0.05 # 极慢
	await get_tree().create_timer(duration * 0.05, true, false, true).timeout
	Engine.time_scale = 1.0

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
			# 毛玉（KEDAMA）不造成接触伤害，只有撞击攻击才会伤害
			if "enemy_type" in collider and collider.enemy_type == GameConstants.EnemyType.KEDAMA:
				continue

			# 获取敌人的伤害值
			var damage = 10.0  # 默认伤害
			if collider.enemy_data and "damage" in collider.enemy_data:
				damage = collider.enemy_data.damage

			# 造成伤害
			take_damage(damage)

			# 设置冷却时间
			contact_damage_cooldown = CONTACT_DAMAGE_INTERVAL

			# 击退 (增强力度)
			var knockback_dir = (global_position - collider.global_position).normalized()
			apply_knockback(knockback_dir, 800.0)

			break  # 一次只处理一个敌人碰撞

func _check_dash_damage():
	"""检查飞踢伤害（妹红专属）- 增强版"""
	# 使用区域检测而不是碰撞检测
	var dash_detection_radius = 120.0 # 扩大判定范围 (原80)
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	# 妹红特效：生成火墙（简化版，不需要Area2D，只作为视觉或瞬时伤害）
	# 实际上，如果用 Dash CD，那么频率很高，不需要持久火墙，瞬时燃烧更好
	if Engine.get_physics_frames() % 3 == 0:
		_spawn_dash_fire_particles()

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance > dash_detection_radius:
			continue

		var enemy_id = enemy.get_instance_id()
		# 避免重复伤害同一个敌人 (但在一次Dash中，如果持续时间长，可以多次伤害？暂保持一次)
		if enemy_id in dash_hit_enemies:
			continue

		dash_hit_enemies.append(enemy_id)

		# 计算敌人相对于冲刺方向的位置
		var to_enemy = (enemy.global_position - global_position).normalized()
		var dot = dash_direction.dot(to_enemy)

		# 前方的敌人（dot > 0.5，范围扩大）
		if dot > 0.5:
			# 向前击飞
			if enemy.has_method("take_damage"):
				enemy.take_damage(dash_damage * 2.0)  # 伤害翻倍

			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(dash_direction, 1000.0)  # 超强力击飞
				
			# 施加燃烧
			if enemy.has_method("apply_burn"):
				enemy.apply_burn(10.0, 5.0) # 强力燃烧

			# 视觉反馈：猛烈偏移 + 顿帧
			hitstop(0.15) # 更长顿帧

			# 火焰特效
			SignalBus.spawn_death_particles.emit(enemy.global_position, Color("#ff4500"), 25)

		# 两侧的敌人
		elif dot > -0.2: # 稍微背后一点也能打到
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

# ==================== DASH METHODS ====================

func start_dash():
	# 统一逻辑：空格/Shift都触发技能
	if character_skills:
		character_skills.activate_skill()
		return

	# Fallback (如果没有技能组件，虽然不太可能)
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION
	dash_cooldown_timer = DASH_COOLDOWN
	
	# Determine dash direction
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length() > 0.1: 
		dash_direction = input_dir.normalized()
	else:
		if sprite and sprite.flip_h:
			dash_direction = Vector2.LEFT
		else:
			dash_direction = Vector2.RIGHT
	if sprite:
		sprite.modulate.a = 0.5

	# Optional: Invulnerability during dash
	set_invulnerable(DASH_DURATION)

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

# ==================== SKILL SUPPORT METHODS ====================

func set_invulnerable(duration: float):
	"""设置玩家无敌状态"""
	invulnerable_timer = duration
	is_invulnerable = true

func _spawn_dash_landing_effect():
	"""生成飞踢落地视觉效果（火焰爆炸） + 范围伤害"""
	# 发射橙红色火焰粒子
	SignalBus.spawn_death_particles.emit(global_position, Color("#ff4500"), 30)

	# 移除震动，保留打击感 (打击感由_check_dash_damage中的顿帧提供)
	# SignalBus.screen_shake.emit(0.1, 8.0) 

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
		else:
			# 水平排列（左右排列）
			var frame_width = down_texture.get_width() / 17
			var frame_height = down_texture.get_height()
			for i in range(17):
				var atlas = AtlasTexture.new()
				atlas.atlas = down_texture
				atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
				mokou_textures.down.append(atlas)

	# stand.png - 站立
	# 改用无特殊字符的文件名，防止加载失败
	var stand_path = "res://assets/characters/mokuo.png"
	if ResourceLoader.exists(stand_path):
		mokou_textures.stand = load(stand_path)
	else:
		# Fallback
		mokou_textures.stand = load("res://assets/characters/mokuo (4).png")

	# mokuokick.png - 飞踢
	var kick_path = "res://assets/mokuokick.png"
	print("Loading kick texture from: ", kick_path)
	if ResourceLoader.exists(kick_path):
		mokou_textures.kick = load(kick_path)
		print("Kick texture loaded successfully: ", mokou_textures.kick)
	else:
		print("错误：找不到飞踢图片文件！")
		mokou_textures.kick = null

func _update_mokou_animation(delta: float, input_dir: Vector2):
	"""更新妹红的动画帧"""
	# 状态 1: 攻击 (Attack) - 由 play_attack_animation 控制
	if is_attacking: 
		return 
		
	# 兜底重置：非攻击状态下，必须重置 Sprite 属性以支持 AtlasTexture
	if sprite:
		sprite.hframes = 1
		sprite.vframes = 1

	# 优先处理空格技能飞踢 (强制使用飞踢图)
	var is_skill_kicking = false
	if character_skills:
		is_skill_kicking = character_skills.is_fire_kicking

	if is_skill_kicking:
		print("显示飞踢图片！") # Debug

	if (is_skill_kicking or is_dashing) and mokou_textures.kick:
		sprite.texture = mokou_textures.kick
		# mokuokick.png: 2496x1696，保持与其他动画一致的高度
		var kick_height = 100.0
		sprite.scale = Vector2(kick_height / 1696.0, kick_height / 1696.0)

		# 冲刺时增加亮度效果
		if is_dashing:
			sprite.modulate = Color(1.2, 1.2, 1.2, 1.0)  # 稍微亮一点
		else:
			sprite.modulate = Color.WHITE

		# 翻转逻辑：优先考虑技能方向
		if is_skill_kicking:
			if character_skills.fire_kick_direction.x != 0:
				sprite.flip_h = character_skills.fire_kick_direction.x > 0
		else:
			sprite.flip_h = dash_direction.x > 0
		return

	# 状态 3: 正常移动 (Normal)
	if not sprite or mokou_textures.sprite.size() == 0:
		return

	var is_moving = input_dir.length() > 0.1
	const TARGET_HEIGHT = 100.0

	# 更新动画计时器
	if is_moving:
		animation_timer += delta
		var animation_cycle = 1.0
		var progress = fmod(animation_timer, animation_cycle) / animation_cycle

		var is_moving_up = input_dir.y < -0.5
		var is_moving_down = input_dir.y > 0.5

		if is_moving_up and mokou_textures.up.size() > 0:
			var frame_index = int(progress * 4) % 4
			sprite.texture = mokou_textures.up[3 - frame_index]
		elif is_moving_down and mokou_textures.down.size() > 0:
			var frame_index = int(progress * 17) % 17
			sprite.texture = mokou_textures.down[16 - frame_index]
		else:
			var frame_index = int(progress * 8) % 8
			sprite.texture = mokou_textures.sprite[7 - frame_index]

		if input_dir.x != 0:
			sprite.flip_h = input_dir.x < 0

		sprite.scale = Vector2(TARGET_HEIGHT / 720.0, TARGET_HEIGHT / 720.0)
	else:
		animation_timer = 0.0
		if mokou_textures.stand:
			sprite.texture = mokou_textures.stand
			sprite.scale = Vector2(TARGET_HEIGHT / 2048.0, TARGET_HEIGHT / 2048.0)

	# [实现] 动态阴影系统：妹红的影子根据跑步方向变化
	# _update_mokou_animation 不再调用 shadow 更新，避免冲突

func _create_charge_bar():
	var bar = TextureProgressBar.new()
	bar.name = "ChargeBar"
	# 使用垂直进度条
	bar.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP
	bar.value = 0
	bar.max_value = 1.5 # 满蓄力时间
	bar.step = 0.01 # 允许平滑的小数变化
	bar.visible = false
	
	# 创建纯色纹理 (竖向)
	var w = 12
	var h = 60
	var img_bg = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img_bg.fill(Color(0, 0, 0, 0.5))
	var img_fill = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img_fill.fill(Color(1.0, 0.5, 0.0)) # 橙色
	
	bar.texture_under = ImageTexture.create_from_image(img_bg)
	bar.texture_progress = ImageTexture.create_from_image(img_fill)
	
	# 位置：右侧身边
	bar.position = Vector2(35, -40)
	add_child(bar)

func _create_soft_circle_texture(size: int) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center) / (size / 2.0)
			# 使用平滑衰减公式，消除硬边缘
			var alpha = clamp(1.0 - pow(dist, 2.0), 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)

func _spawn_charging_particles(intensity: float):
	"""生成蓄力聚气粒子 - 强度随 intensity 增加"""
	var p = CPUParticles2D.new()
	# 设置材质为叠加模式，产生高亮发光感
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	# 设置平滑纹理，告别像素方块
	p.texture = _create_soft_circle_texture(32)
	
	p.emitting = true
	p.one_shot = true
	p.amount = int(8 + 25 * intensity)
	p.lifetime = 0.5
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 40.0
	p.gravity = Vector2(0, -20)
	p.radial_accel_min = -100.0 * (1.0 + intensity)
	p.radial_accel_max = -150.0 * (1.0 + intensity)
	
	# 动态大小
	p.scale_amount_min = 0.05 + (0.1 * intensity)
	p.scale_amount_max = 0.15 + (0.2 * intensity)
	
	var grad = Gradient.new()
	grad.add_point(0.0, Color(1.0, 0.9, 0.3, 0.8)) # 亮黄
	grad.add_point(1.0, Color(1.0, 0.2, 0.0, 0.0)) # 深红透明
	p.color_ramp = grad
	
	p.position = Vector2(0, -20)
	p.z_index = 1
	add_child(p)
	
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(p): p.queue_free()

func _spawn_release_burst(intensity: float):
	"""释放瞬间的巨大火焰冲击波"""
	var burst = CPUParticles2D.new()
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	burst.material = mat
	burst.texture = _create_soft_circle_texture(64) # 更大的爆发粒子纹理
	add_child(burst)
	
	burst.amount = int(30 + 70 * intensity)
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.lifetime = 0.6
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 150 * intensity
	burst.initial_velocity_max = 500 * intensity
	
	# 随蓄力变大
	burst.scale_amount_min = 0.2 * intensity
	burst.scale_amount_max = 0.6 * intensity
	
	var grad = Gradient.new()
	# 满蓄力时核心发白
	if intensity > 0.9:
		grad.add_point(0.0, Color(4.0, 4.0, 2.0, 1.0)) # HDR 强度白光
	else:
		grad.add_point(0.0, Color(1.5, 0.8, 0.2, 1.0))
	grad.add_point(1.0, Color(0.8, 0.1, 0.0, 0.0))
	burst.color_ramp = grad
	
	# 反馈：震动强度随时间增加
	SignalBus.screen_shake.emit(0.2 * intensity, 20.0 * intensity)
	
	await get_tree().create_timer(0.7).timeout
	if is_instance_valid(burst): burst.queue_free()



# ==================== 粒子屏障系统 ====================
func _create_particle_barrier():
	"""创建圆形粒子屏障 - 发光球形护盾效果"""
	var particles = GPUParticles2D.new()
	particles.name = "ParticleBarrier"
	particles.position = Vector2.ZERO  # 确保粒子在玩家中心
	particles.amount = 16  # 粒子数量减少，从48降到16，稀疏一些
	particles.lifetime = 3.0  # 粒子生命周期增加，让粒子运动更舒缓
	particles.preprocess = 0.5  # 预处理时间
	particles.speed_scale = 0.8  # 速度减慢
	particles.emitting = true
	particles.local_coords = true  # 使用本地坐标，跟随父节点
	particles.process_material = _create_barrier_particle_material()
	particles.texture = _create_particle_texture()
	particles.z_index = 10  # 在玩家上方显示

	# 使用加法混合创造发光效果
	var material = CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = material

	add_child(particles)

func _create_barrier_particle_material() -> ParticleProcessMaterial:
	"""创建粒子屏障的材质 - 圆形轨道（外圈光环）"""
	var mat = ParticleProcessMaterial.new()

	# 发射形状：圆环（扩大半径到外圈）
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_axis = Vector3(0, 0, 1)  # Z轴（2D平面）
	mat.emission_ring_height = 1.0
	mat.emission_ring_radius = 70.0  # 外圈半径，从35增大到70
	mat.emission_ring_inner_radius = 68.0  # 内半径，保持2像素厚度

	# 粒子初始速度（轨道运动）
	mat.angle_min = 0.0
	mat.angle_max = 360.0
	mat.angular_velocity_min = 20.0  # 粒子更慢旋转
	mat.angular_velocity_max = 30.0

	# 轨道速度（绕圆周运动）
	mat.orbit_velocity_min = 0.2  # 更慢的轨道运动
	mat.orbit_velocity_max = 0.3

	# 粒子不向外扩散，保持在圆环上
	mat.initial_velocity_min = 0.0
	mat.initial_velocity_max = 0.0

	# 重力设为0，粒子不下坠
	mat.gravity = Vector3(0, 0, 0)

	# 粒子大小 - 更大一些让稀疏光环更明显
	mat.scale_min = 0.8
	mat.scale_max = 1.2

	# 粒子颜色 - 淡蓝色发光
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.6, 0.8, 1.0, 0.8))  # 起始：亮蓝色，较亮
	gradient.add_point(0.5, Color(0.7, 0.9, 1.0, 1.0))  # 中间：最亮
	gradient.add_point(1.0, Color(0.5, 0.7, 0.9, 0.0))  # 结束：淡出

	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	mat.color_ramp = gradient_tex

	# 启用衰减，粒子逐渐淡出
	mat.damping_min = 0.1
	mat.damping_max = 0.2

	return mat

func _create_particle_texture() -> ImageTexture:
	"""创建粒子纹理 - 柔和的圆形光点"""
	var size = 16
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_dist = size / 2.0
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(dist / max_dist, 0.0, 1.0)
			# 柔和的径向渐变
			var brightness = 1.0 - pow(t, 1.8)
			# 白色粒子，亮度由alpha控制
			image.set_pixel(x, y, Color(1, 1, 1, brightness))
	
	return ImageTexture.create_from_image(image)

func _spawn_dash_fire_particles():
	"""生成冲刺火焰粒子"""
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.5
	particles.direction = -dash_direction
	particles.spread = 30.0
	particles.gravity = Vector2(0, -50)
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color_ramp = Gradient.new()
	particles.color_ramp.add_point(0.0, Color(1.0, 0.8, 0.2))
	particles.color_ramp.add_point(1.0, Color(1.0, 0.2, 0.0, 0.0))
	particles.z_index = 5
	get_tree().current_scene.add_child(particles)
	
	# 自动清理
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func play_attack_animation(frame_index: int, duration: float):
	"""播放攻击动画（替换本体贴图）"""
	current_attack_id += 1
	var my_id = current_attack_id
	is_attacking = true
	
	# 备份当前缩放 (只在第一次进入攻击状态时备份，防止连续攻击时备份了错误的攻击缩放)
	# 实际上，只要我们确保恢复逻辑正确，每次备份 sprite.scale 也可以，因为上一帧可能已经被恢复了
	# 或者我们硬编码恢复值为 Vector2(0.05, 0.05)，这是最安全的
	var restore_scale = Vector2(0.05, 0.05)
	
	if sprite:
		var attack_tex = load("res://assets/attack.png")
		if attack_tex:
			sprite.texture = attack_tex
			sprite.hframes = 2
			sprite.vframes = 1
			sprite.frame = frame_index
			# 参考之前的 WeaponSystem 代码，攻击图缩放为 0.1
			sprite.scale = Vector2(0.1, 0.1)
			
			# 根据鼠标方向翻转
			var mouse_pos = get_global_mouse_position()
			if mouse_pos.x < global_position.x:
				sprite.flip_h = true
			else:
				sprite.flip_h = false
	
	# 动画结束后恢复状态
	await get_tree().create_timer(duration).timeout
	
	# 只有当这是最后一次攻击时才恢复
	if current_attack_id == my_id:
		is_attacking = false
		if sprite:
			sprite.hframes = 1
			sprite.vframes = 1
			sprite.scale = restore_scale # 恢复默认缩放
