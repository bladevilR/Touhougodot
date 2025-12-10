extends Node2D
class_name WeaponSystem

# WeaponSystem - 完整的武器管理和发射系统
# 与WeaponData.gd集成，支持所有武器类型和升级系统

# 预加载子弹场景
var bullet_scene = preload("res://Bullet.tscn")

# 当前装备的武器列表
var weapons = {}  # {weapon_id: {config, timer, level}}

# 引用玩家
var player: Node2D = null

func _ready():
	# 获取父节点（应该是Player）
	player = get_parent()

	# 监听武器添加信号
	SignalBus.weapon_added.connect(add_weapon)
	SignalBus.weapon_upgraded.connect(upgrade_weapon)

	# 初始化武器数据
	WeaponData.initialize()

func _process(delta):
	if not player:
		return

	# 更新所有武器的冷却计时器
	for weapon_id in weapons.keys():
		var weapon_data = weapons[weapon_id]
		weapon_data.timer -= delta

		# 冷却完成，发射！
		if weapon_data.timer <= 0:
			fire_weapon(weapon_id)
			# 重置冷却，应用角色的cooldown属性
			var stats = _get_player_stats()
			weapon_data.timer = weapon_data.config.cooldown_max * stats.cooldown

func add_weapon(weapon_id: String):
	if weapon_id in weapons:
		print("武器已存在: ", weapon_id)
		return

	var config = WeaponData.get_weapon(weapon_id)
	if not config:
		print("武器不存在: ", weapon_id)
		return

	weapons[weapon_id] = {
		"config": config,
		"timer": 0.0,  # 立即发射一次
		"level": 1      # 武器等级
	}
	print("获得武器: ", config.weapon_name)

func upgrade_weapon(weapon_id: String):
	if not weapon_id in weapons:
		print("武器未装备，无法升级: ", weapon_id)
		return

	var weapon_data = weapons[weapon_id]
	if weapon_data.level >= weapon_data.config.max_level:
		print("武器已达到最大等级: ", weapon_id)
		return

	weapon_data.level += 1
	print("武器升级: ", weapon_data.config.weapon_name, " -> Lv.", weapon_data.level)

func fire_weapon(weapon_id: String):
	if not weapon_id in weapons:
		return

	var weapon_data = weapons[weapon_id]
	var config = weapon_data.config
	var weapon_level = weapon_data.level

	# 获取角色属性（用于计算最终伤害等）
	var stats = _get_player_stats()

	# 根据武器类型发射
	match config.weapon_type:
		GameConstants.WeaponType.PROJECTILE:
			_fire_projectile(config, stats, weapon_level)
		GameConstants.WeaponType.ORBITAL:
			_fire_orbital(config, stats, weapon_level)
		GameConstants.WeaponType.LASER:
			_fire_laser(config, stats, weapon_level)
		GameConstants.WeaponType.SPECIAL:
			_fire_special(config, stats, weapon_level)
		_:
			print("未实现的武器类型: ", config.weapon_type)

func _fire_projectile(config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 获取最近的敌人作为目标
	var target = get_nearest_enemy()
	var target_pos = target.global_position if target else player.global_position + Vector2(100, 0)

	# 计算方向
	var direction = (target_pos - player.global_position).normalized()

	# 根据武器配置生成多个子弹（等级提升增加子弹数量）
	var projectile_count = config.projectile_count + max(0, weapon_level - 1)

	for i in range(projectile_count):
		var bullet = bullet_scene.instantiate()

		# 计算扇形发射角度
		var angle_offset = 0.0
		if projectile_count > 1:
			var spread = 0.3  # 扇形角度
			angle_offset = -spread + (spread * 2.0 * i / (projectile_count - 1))

		var final_angle = direction.angle() + angle_offset
		var final_direction = Vector2(cos(final_angle), sin(final_angle))

		# 计算等级加成
		var level_damage_bonus = 1.0 + (weapon_level - 1) * 0.15  # 每级+15%伤害
		var level_penetration = config.penetration + int((weapon_level - 1) * 0.5)  # 每2级+1穿透

		# 配置子弹属性 - 使用Bullet.setup()方法
		bullet.setup({
			"damage": config.base_damage * stats.might * level_damage_bonus,
			"speed": config.projectile_speed,
			"lifetime": config.projectile_lifetime,
			"direction": final_direction,
			"penetration": level_penetration,
			"homing_strength": config.homing_strength,
			"bounce_count": config.bounce_count,
			"explosion_radius": config.explosion_radius * stats.area,
			"element": _element_type_to_string(config.element_type),
			"knockback": config.knockback,
			"on_hit_effect": config.on_hit_effect,
			"has_gravity": config.has_gravity
		})

		# 设置子弹位置
		bullet.global_position = player.global_position

		# 添加到场景
		get_tree().root.add_child(bullet)

func _fire_orbital(config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 环绕武器（如凤凰羽衣）
	# 这类武器应该持续存在，每次发射刷新环绕弹幕

	var time = Time.get_ticks_msec() / 1000.0
	var projectile_count = config.projectile_count + int((weapon_level - 1) * 0.5)  # 每2级+1环绕

	for i in range(projectile_count):
		var bullet = bullet_scene.instantiate()

		# 计算环绕角度
		var angle = (i * TAU / projectile_count) + (time * config.orbit_speed)

		# 计算等级加成
		var level_damage_bonus = 1.0 + (weapon_level - 1) * 0.15

		bullet.setup({
			"damage": config.base_damage * stats.might * level_damage_bonus,
			"speed": 0.0,  # 环绕弹幕不需要速度，位置跟随玩家
			"lifetime": 0.2,  # 短生命周期，持续重新生成
			"direction": Vector2.ZERO,
			"penetration": config.penetration,
			"orbit_radius": config.orbit_radius * stats.area,
			"orbit_angle": angle,
			"orbit_speed": config.orbit_speed,
			"element": _element_type_to_string(config.element_type),
			"knockback": config.knockback,
			"on_hit_effect": config.on_hit_effect
		})

		bullet.global_position = player.global_position
		get_tree().root.add_child(bullet)

func _fire_laser(config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 激光武器
	var target = get_nearest_enemy()
	if not target:
		return

	var direction = (target.global_position - player.global_position).normalized()

	# 计算等级加成
	var level_damage_bonus = 1.0 + (weapon_level - 1) * 0.2  # 激光每级+20%伤害
	var level_penetration = config.penetration + weapon_level - 1  # 每级+1穿透

	var bullet = bullet_scene.instantiate()
	bullet.setup({
		"damage": config.base_damage * stats.might * level_damage_bonus,
		"speed": config.projectile_speed,
		"lifetime": config.projectile_lifetime * (1.0 + (weapon_level - 1) * 0.1),  # 每级+10%持续时间
		"direction": direction,
		"penetration": level_penetration,
		"is_laser": config.is_laser,
		"element": _element_type_to_string(config.element_type),
		"knockback": config.knockback
	})

	bullet.global_position = player.global_position
	get_tree().root.add_child(bullet)

func _fire_special(config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 特殊武器（如地雷）
	var level_damage_bonus = 1.0 + (weapon_level - 1) * 0.15
	var projectile_count = config.projectile_count + max(0, int((weapon_level - 1) * 0.5))

	for i in range(projectile_count):
		var bullet = bullet_scene.instantiate()

		# 在玩家周围随机位置放置
		var random_offset = Vector2(
			randf_range(-200, 200),
			randf_range(-200, 200)
		)

		bullet.setup({
			"damage": config.base_damage * stats.might * level_damage_bonus,
			"speed": 0.0,  # 地雷静止
			"lifetime": config.projectile_lifetime,
			"direction": Vector2.ZERO,
			"penetration": config.penetration,
			"explosion_radius": config.explosion_radius * stats.area,
			"element": _element_type_to_string(config.element_type),
			"on_hit_effect": config.on_hit_effect
		})

		bullet.global_position = player.global_position + random_offset
		get_tree().root.add_child(bullet)

func get_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return null

	var nearest = null
	var min_distance = INF

	for enemy in enemies:
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = enemy

	return nearest

func _get_player_stats() -> Dictionary:
	# 从Player节点获取角色属性
	if player and player.has_method("get_character_stats"):
		return player.get_character_stats()

	# 如果Player有character_data，使用它
	if player and player.get("character_data"):
		var char_data = player.character_data
		if char_data and char_data.stats:
			return {
				"might": char_data.stats.might,
				"area": char_data.stats.area,
				"cooldown": char_data.stats.cooldown,
				"speed": char_data.stats.speed
			}

	# 默认属性
	return {
		"might": 1.0,
		"area": 1.0,
		"cooldown": 1.0,
		"speed": 1.0
	}

func _element_type_to_string(element_type: int) -> String:
	# 将GameConstants.ElementType转换为Bullet.element字符串
	match element_type:
		GameConstants.ElementType.FIRE:
			return "fire"
		GameConstants.ElementType.ICE:
			return "ice"
		GameConstants.ElementType.LIGHTNING:
			return "lightning"
		GameConstants.ElementType.POISON:
			return "poison"
		_:
			return "none"
