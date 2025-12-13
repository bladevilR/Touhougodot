extends Node2D
class_name WeaponSystem

# WeaponSystem - 完整的武器管理和发射系统
# 与WeaponData.gd集成，支持所有武器类型和升级系统

# 预加载子弹场景
var bullet_scene = preload("res://Bullet.tscn")

# 当前装备的武器列表
var weapons = {}  # {weapon_id: {config, timer, level}}

# 引用
var player: Node2D = null
var aim_system: Node = null  # 瞄准系统

func _ready():
	# 获取父节点（应该是Player）
	player = get_parent()
	aim_system = player.get_node_or_null("AimSystem")

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
			# Auto-fire for most weapons
			fire_weapon(weapon_id)
			# 重置冷却，应用角色的cooldown属性和等级加成
			var stats = _get_player_stats()
			var level_cooldown_mult = weapon_data.level_bonuses.get("cooldown_mult", 1.0) if weapon_data.has("level_bonuses") else 1.0
			weapon_data.timer = weapon_data.config.cooldown_max * stats.cooldown * level_cooldown_mult

func add_weapon(weapon_id: String):
	if weapon_id in weapons:
		print("武器已存在，执行升级: ", weapon_id)
		upgrade_weapon(weapon_id)
		return

	var config = WeaponData.get_weapon(weapon_id)
	if not config:
		print("武器不存在: ", weapon_id)
		return

	weapons[weapon_id] = {
		"config": config,
		"timer": 0.0,  # 立即发射一次
		"level": 1,      # 武器等级
		"applied_upgrades": []  # 已应用的升级ID列表
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
	var new_level = weapon_data.level

	# 应用等级加成
	_apply_level_bonuses(weapon_id, weapon_data, new_level)

	# Lv.3 MAX 质变效果
	if new_level == 3:
		_apply_qualitative_change(weapon_id, weapon_data)

	print("武器升级: ", weapon_data.config.weapon_name, " -> Lv.", new_level)

func apply_weapon_upgrade(weapon_id: String, upgrade_id: String):
	"""应用武器升级"""
	if not weapon_id in weapons:
		print("武器未装备，无法应用升级: ", weapon_id)
		return

	var weapon_data = weapons[weapon_id]
	var applied_upgrades = weapon_data.get("applied_upgrades", [])

	# 检查是否已应用
	if upgrade_id in applied_upgrades:
		print("升级已应用: ", upgrade_id)
		return

	# 记录升级
	applied_upgrades.append(upgrade_id)
	weapon_data["applied_upgrades"] = applied_upgrades

	# 应用升级效果
	_apply_upgrade_effect(weapon_id, weapon_data, upgrade_id)

	print("应用武器升级: ", weapon_id, " - ", upgrade_id)

func _apply_upgrade_effect(weapon_id: String, weapon_data: Dictionary, upgrade_id: String):
	"""应用升级效果的具体逻辑"""
	var config = weapon_data.config

	# 初始化升级加成字典
	if not weapon_data.has("upgrade_bonuses"):
		weapon_data["upgrade_bonuses"] = {}

	# 根据升级ID应用效果
	match upgrade_id:
		# === Phoenix Wings (凤凰羽衣) ===
		"wings_count":
			config.projectile_count += 2
			print("  → 火焰羽翼数量 +2")
		"wings_damage":
			if not weapon_data.upgrade_bonuses.has("damage_mult"):
				weapon_data.upgrade_bonuses["damage_mult"] = 1.0
			weapon_data.upgrade_bonuses["damage_mult"] *= 1.5
			print("  → 伤害 +50%")
		"wings_range":
			config.orbit_radius *= 1.5
			print("  → 旋转范围 +50%")
		"wings_burn":
			config.on_hit_effect = "burn"
			print("  → 接触施加燃烧效果")
		"wings_double":
			weapon_data["second_layer"] = true
			print("  → 添加反向旋转的第二层")
		"wings_explode":
			weapon_data["kill_explosion"] = true
			print("  → 击杀触发爆炸")

		# 其他武器的升级可以继续添加...
		_:
			print("  → 未实现的升级效果: ", upgrade_id)

func _apply_level_bonuses(weapon_id: String, weapon_data: Dictionary, level: int):
	"""应用等级加成 (策划稿数值)"""
	# 存储等级加成到weapon_data
	if not weapon_data.has("level_bonuses"):
		weapon_data["level_bonuses"] = {}

	match level:
		2:
			# Lv.2: +30%伤害, +15%攻速
			weapon_data.level_bonuses["damage_mult"] = 1.3
			weapon_data.level_bonuses["cooldown_mult"] = 0.85
			print("  → 伤害+30%, 攻速+15%")
		3:
			# Lv.3 MAX: +60%伤害, +30%攻速
			weapon_data.level_bonuses["damage_mult"] = 1.6
			weapon_data.level_bonuses["cooldown_mult"] = 0.7
			print("  → 伤害+60%, 攻速+30% (MAX)")

func _apply_qualitative_change(weapon_id: String, weapon_data: Dictionary):
	"""应用Lv.3 MAX质变效果"""
	var config = weapon_data.config

	# 存储质变状态
	weapon_data["has_qualitative_change"] = true

	print("  ★ 质变解锁!")

	# 根据武器ID应用不同的质变效果
	match weapon_id:
		"molotov":
			# 鸡尾酒瓶 → Zone范围扩大50% / 附带减速效果
			weapon_data["qualitative_effect"] = "expanded_zone"
			weapon_data["zone_size_mult"] = 1.5
			weapon_data["has_slow"] = true
			print("  → 火焰区域+50%, 附带减速")

		"laser":
			# 恋符·激光 → 双射线 / 判定频率翻倍
			weapon_data["qualitative_effect"] = "double_beam"
			weapon_data["beam_count"] = 2
			weapon_data["hit_rate_mult"] = 2.0
			print("  → 双射线, 判定频率×2")

		"yin_yang_orb":
			# 阴阳玉 → 永动机制（不消失）/ 分裂成两个小球
			weapon_data["qualitative_effect"] = "eternal_split"
			weapon_data["no_despawn"] = true
			weapon_data["split_on_hit"] = true
			print("  → 永动机制, 命中时分裂")

		"shanghai_doll":
			# 上海人形 → 数量增加至5个 / 死亡时自爆
			weapon_data["qualitative_effect"] = "explosive_dolls"
			weapon_data["projectile_bonus"] = 2
			weapon_data["explode_on_death"] = true
			print("  → 人偶数量+2, 死亡自爆")

		"homing_amulet":
			# 博丽符纸 → 散弹扇形 + 回旋特性
			weapon_data["qualitative_effect"] = "scatter_return"
			weapon_data["scatter_angle"] = 0.6
			weapon_data["return_to_player"] = true
			print("  → 扇形散射, 回旋效果")

		"star_dust":
			# 星符 → 全屏发射 / 留下星尘轨迹
			weapon_data["qualitative_effect"] = "stardust_trail"
			weapon_data["all_directions"] = true
			weapon_data["trail_damage"] = true
			print("  → 全向发射, 星尘轨迹")

		"phoenix_wings":
			# 凤凰羽衣 → 双层旋转 / 击杀爆炸
			weapon_data["qualitative_effect"] = "double_rotation"
			weapon_data["second_layer"] = true
			weapon_data["kill_explosion"] = true
			print("  → 双层旋转, 击杀爆炸")

		"knives":
			# 银制飞刀 → 弹幕密度 / 时停飞刀
			weapon_data["qualitative_effect"] = "knife_barrage"
			weapon_data["barrage_mode"] = true
			weapon_data["suspend_delay"] = 0.3
			print("  → 弹幕模式, 悬停后射出")

		"spoon":
			# 刚欲汤勺 → 吞噬小型敌人 / 爆裂回收
			weapon_data["qualitative_effect"] = "devour_explode"
			weapon_data["devour_small"] = true
			weapon_data["explode_on_return"] = true
			print("  → 吞噬小怪, 爆裂回收")

		"mines":
			# 本我地雷 → 连锁爆炸 / 超大范围
			weapon_data["qualitative_effect"] = "chain_nuclear"
			weapon_data["chain_explode"] = true
			weapon_data["radius_mult"] = 2.0
			print("  → 连锁爆炸, 范围×2")

func get_weapon_level_multipliers(weapon_id: String) -> Dictionary:
	"""获取武器等级加成"""
	if not weapon_id in weapons:
		return {"damage_mult": 1.0, "cooldown_mult": 1.0}

	var weapon_data = weapons[weapon_id]
	if weapon_data.has("level_bonuses"):
		return {
			"damage_mult": weapon_data.level_bonuses.get("damage_mult", 1.0),
			"cooldown_mult": weapon_data.level_bonuses.get("cooldown_mult", 1.0)
		}

	return {"damage_mult": 1.0, "cooldown_mult": 1.0}

func has_qualitative_change(weapon_id: String) -> bool:
	"""检查武器是否有质变"""
	if not weapon_id in weapons:
		return false
	return weapons[weapon_id].get("has_qualitative_change", false)

func get_qualitative_effect(weapon_id: String) -> String:
	"""获取质变效果类型"""
	if not weapon_id in weapons:
		return ""
	return weapons[weapon_id].get("qualitative_effect", "")

func get_owned_weapon_ids() -> Array:
	"""返回当前拥有的所有武器ID列表"""
	return weapons.keys()

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
			_fire_projectile(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.ORBITAL:
			_fire_orbital(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.LASER:
			_fire_laser(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.SPECIAL:
			_fire_special(weapon_id, config, stats, weapon_level)
		_:
			print("未实现的武器类型: ", config.weapon_type)

func _fire_projectile(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 使用瞄准系统的方向
	var direction: Vector2
	if aim_system:
		direction = aim_system.get_aim_direction()
	else:
		# 备用：瞄准最近的敌人
		var target = get_nearest_enemy()
		if target:
			direction = (target.global_position - player.global_position).normalized()
		else:
			direction = Vector2.RIGHT

	_fire_projectile_in_direction(weapon_id, config, stats, weapon_level, direction)

func _fire_projectile_in_direction(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int, direction: Vector2):
	# 获取武器数据（包含质变效果）
	var weapon_data = weapons.get(weapon_id, {})
	var has_qualitative = weapon_data.get("has_qualitative_change", false)

	# 获取等级加成
	var level_bonuses = weapon_data.get("level_bonuses", {})
	var damage_mult = level_bonuses.get("damage_mult", 1.0)

	# 获取升级加成并合并
	var upgrade_bonuses = weapon_data.get("upgrade_bonuses", {})
	damage_mult *= upgrade_bonuses.get("damage_mult", 1.0)

	# 根据武器配置生成多个子弹（等级提升增加子弹数量）
	var projectile_count = config.projectile_count + max(0, weapon_level - 1)

	# 质变效果：额外弹幕
	if has_qualitative:
		projectile_count += weapon_data.get("projectile_bonus", 0)

	# 质变效果：全向发射（star_dust）
	var all_directions = weapon_data.get("all_directions", false)
	if all_directions:
		projectile_count = 8  # 8方向

	# 计算扇形角度
	var base_spread = config.projectile_spread  # 使用武器配置的散射角度
	if has_qualitative:
		base_spread = weapon_data.get("scatter_angle", base_spread)

	# 特殊处理：火鸟拳横向排列（不是扇形）
	var is_horizontal_sweep = (weapon_id == "phoenix_claws")

	for i in range(projectile_count):
		var bullet = bullet_scene.instantiate()

		# 计算发射角度和位置
		var angle_offset = 0.0
		var position_offset = Vector2.ZERO

		if all_directions:
			# 全向发射（8方向）
			angle_offset = (i * TAU / projectile_count)
		elif is_horizontal_sweep:
			# 横向一字排列（火鸟拳）
			# 计算垂直于射击方向的横向偏移
			var perpendicular = Vector2(-direction.y, direction.x)  # 逆时针旋转90度
			var spacing = 35.0  # 每个子弹之间的间距
			var total_width = spacing * (projectile_count - 1)
			var offset_distance = -total_width / 2.0 + spacing * i
			position_offset = perpendicular * offset_distance
		elif projectile_count > 1:
			# 正常扇形
			angle_offset = -base_spread + (base_spread * 2.0 * i / (projectile_count - 1))

		var final_angle = direction.angle() + angle_offset
		var final_direction = Vector2(cos(final_angle), sin(final_angle))

		# 计算等级加成（使用存储的乘数）
		var level_penetration = config.penetration + int((weapon_level - 1) * 0.5)  # 每2级+1穿透

		# 基础子弹配置
		var bullet_config = {
			"weapon_id": weapon_id,
			"bullet_color": _get_weapon_color(weapon_id, config),
			"damage": config.base_damage * stats.might * damage_mult,
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
		}

		# 应用质变效果
		if has_qualitative:
			# 回旋效果（homing_amulet）
			if weapon_data.get("return_to_player", false):
				bullet_config["return_to_player"] = true

			# 永动机制（yin_yang_orb）- 超长生命周期
			if weapon_data.get("no_despawn", false):
				bullet_config["lifetime"] = 999.0

			# 命中分裂（yin_yang_orb）
			if weapon_data.get("split_on_hit", false):
				bullet_config["split_count"] = 2
				bullet_config["split_angle_spread"] = 0.8

			# 弹幕模式悬停（knives）
			if weapon_data.get("barrage_mode", false):
				# 初始速度为0，延迟后加速
				bullet_config["speed"] = 0.0
				# 使用自定义延迟发射逻辑
				_schedule_delayed_bullet(bullet, config.projectile_speed, weapon_data.get("suspend_delay", 0.3))

			# 星尘轨迹（star_dust）
			if weapon_data.get("trail_damage", false):
				bullet_config["is_barrier_field"] = true
				bullet_config["damage_interval"] = 0.3

			# 减速效果（molotov）
			if weapon_data.get("has_slow", false):
				bullet_config["on_hit_effect"] = "slow"
				bullet_config["slow_amount"] = 0.5
				bullet_config["slow_duration"] = 2.0

			# 范围扩大（molotov）
			if weapon_data.has("zone_size_mult"):
				bullet_config["explosion_radius"] *= weapon_data.zone_size_mult

		bullet.setup(bullet_config)

		# 设置子弹位置（加上横向偏移）
		bullet.global_position = player.global_position + position_offset

		# 添加到场景
		get_tree().current_scene.call_deferred("add_child", bullet)

func _fire_orbital(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 环绕武器（如凤凰羽衣）
	# 这类武器应该持续存在，每次发射刷新环绕弹幕

	# 特殊处理：phoenix_wings 光环武器只生成一次，持续存在
	if weapon_id == "phoenix_wings":
		# 清理所有旧的光环（防止重复生成）
		var existing_auras = get_tree().get_nodes_in_group("phoenix_aura")
		for aura in existing_auras:
			aura.queue_free()

		# 生成持续存在的光环
		var bullet = bullet_scene.instantiate()
		bullet.add_to_group("phoenix_aura")  # 添加到组方便查找

		var bullet_config = {
			"weapon_id": weapon_id,
			"bullet_color": Color(1.0, 0.5, 0.1),  # 橙黄色
			"damage": config.base_damage * stats.might,
			"speed": 0.0,
			"lifetime": 999999.0,  # 超长生命周期，基本不会消失
			"direction": Vector2.ZERO,
			"penetration": config.penetration,
			"orbit_radius": 0.01,  # 设置为接近0的值，避免完全为0导致逻辑不触发
			"orbit_angle": 0.0,
			"orbit_speed": 0.0,
			"element": _element_type_to_string(config.element_type),
			"knockback": config.knockback,
			"on_hit_effect": config.on_hit_effect
		}

		bullet.setup(bullet_config)
		bullet.global_position = player.global_position
		get_tree().current_scene.call_deferred("add_child", bullet)
		return

	# 原有的环绕弹幕逻辑（用于其他武器）
	# 获取武器数据（包含质变效果）
	var weapon_data = weapons.get(weapon_id, {})
	var has_qualitative = weapon_data.get("has_qualitative_change", false)

	# 获取等级加成
	var level_bonuses = weapon_data.get("level_bonuses", {})
	var damage_mult = level_bonuses.get("damage_mult", 1.0)

	# 获取升级加成并合并
	var upgrade_bonuses = weapon_data.get("upgrade_bonuses", {})
	damage_mult *= upgrade_bonuses.get("damage_mult", 1.0)

	var time = Time.get_ticks_msec() / 1000.0
	var projectile_count = config.projectile_count + int((weapon_level - 1) * 0.5)  # 每2级+1环绕

	# 质变效果：双层旋转（phoenix_wings）
	var layer_count = 1
	if has_qualitative and weapon_data.get("second_layer", false):
		layer_count = 2

	for layer in range(layer_count):
		var layer_radius = config.orbit_radius * stats.area
		var layer_speed = config.orbit_speed
		var layer_offset = 0.0

		if layer == 1:
			# 第二层：更大半径，反向旋转
			layer_radius *= 1.5
			layer_speed *= -0.7
			layer_offset = PI / projectile_count  # 交错排列

		for i in range(projectile_count):
			var bullet = bullet_scene.instantiate()

			# 计算环绕角度
			var angle = (i * TAU / projectile_count) + (time * layer_speed) + layer_offset

			# 计算初始位置（围绕玩家）
			var offset = Vector2(cos(angle), sin(angle)) * layer_radius
			var start_pos = player.global_position + offset

			var bullet_config = {
				"weapon_id": weapon_id,
				"bullet_color": _get_weapon_color(weapon_id, config),
				"damage": config.base_damage * stats.might * damage_mult,
				"speed": 0.0,  # 环绕弹幕不需要速度，位��跟随玩家
				"lifetime": config.cooldown_max,  # 生命周期等于冷却时间，保持连续
				"direction": Vector2.ZERO,
				"penetration": config.penetration,
				"orbit_radius": layer_radius,
				"orbit_angle": angle,
				"orbit_speed": layer_speed,
				"element": _element_type_to_string(config.element_type),
				"knockback": config.knockback,
				"on_hit_effect": config.on_hit_effect
			}

			# 质变效果：击杀爆炸
			if has_qualitative and weapon_data.get("kill_explosion", false):
				bullet_config["explosion_radius"] = 50.0 * stats.area
				bullet_config["explosion_damage"] = config.base_damage * 0.5

			bullet.setup(bullet_config)
			bullet.global_position = start_pos  # 使用计算出的环绕位置
			get_tree().current_scene.call_deferred("add_child", bullet)

func _fire_laser(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 激光武器
	var target = get_nearest_enemy()
	if not target:
		return

	# 获取武器数据（包含质变效果）
	var weapon_data = weapons.get(weapon_id, {})
	var has_qualitative = weapon_data.get("has_qualitative_change", false)

	# 获取等级加成
	var level_bonuses = weapon_data.get("level_bonuses", {})
	var damage_mult = level_bonuses.get("damage_mult", 1.0)

	# 获取升级加成并合并
	var upgrade_bonuses = weapon_data.get("upgrade_bonuses", {})
	damage_mult *= upgrade_bonuses.get("damage_mult", 1.0)

	var direction = (target.global_position - player.global_position).normalized()

	# 计算等级加成
	var level_penetration = config.penetration + weapon_level - 1  # 每级+1穿透

	# 质变效果：双射线（laser）
	var beam_count = 1
	if has_qualitative:
		beam_count = weapon_data.get("beam_count", 1)

	# 质变效果：判定频率翻倍
	var damage_interval = 0.2
	if has_qualitative and weapon_data.get("hit_rate_mult", 1.0) > 1.0:
		damage_interval /= weapon_data.hit_rate_mult

	for beam in range(beam_count):
		var bullet = bullet_scene.instantiate()

		# 双射线时，第二道偏移角度
		var beam_direction = direction
		if beam_count > 1 and beam == 1:
			var offset_angle = 0.15  # 约8.6度偏移
			beam_direction = direction.rotated(offset_angle if randf() > 0.5 else -offset_angle)

		var bullet_config = {
			"weapon_id": weapon_id,
			"bullet_color": _get_weapon_color(weapon_id, config),
			"damage": config.base_damage * stats.might * damage_mult,
			"speed": config.projectile_speed,
			"lifetime": config.projectile_lifetime * (1.0 + (weapon_level - 1) * 0.1),  # 每级+10%持续时间
			"direction": beam_direction,
			"penetration": level_penetration,
			"is_laser": config.is_laser,
			"element": _element_type_to_string(config.element_type),
			"knockback": config.knockback
		}

		# 应用判定频率
		if has_qualitative:
			bullet_config["is_barrier_field"] = true
			bullet_config["damage_interval"] = damage_interval

		bullet.setup(bullet_config)
		bullet.global_position = player.global_position
		get_tree().current_scene.call_deferred("add_child", bullet)

func _fire_special(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 特殊武器（如地雷）

	# 获取武器数据（包含质变效果）
	var weapon_data = weapons.get(weapon_id, {})
	var has_qualitative = weapon_data.get("has_qualitative_change", false)

	# 获取等级加成
	var level_bonuses = weapon_data.get("level_bonuses", {})
	var damage_mult = level_bonuses.get("damage_mult", 1.0)

	# 获取升级加成并合并
	var upgrade_bonuses = weapon_data.get("upgrade_bonuses", {})
	damage_mult *= upgrade_bonuses.get("damage_mult", 1.0)

	var projectile_count = config.projectile_count + max(0, int((weapon_level - 1) * 0.5))

	# 质变效果：范围倍率（mines）
	var radius_mult = 1.0
	if has_qualitative:
		radius_mult = weapon_data.get("radius_mult", 1.0)

	for i in range(projectile_count):
		var bullet = bullet_scene.instantiate()

		# 在玩家周围随机位置放置
		var random_offset = Vector2(
			randf_range(-200, 200),
			randf_range(-200, 200)
		)

		var bullet_config = {
			"weapon_id": weapon_id,
			"bullet_color": _get_weapon_color(weapon_id, config),
			"damage": config.base_damage * stats.might * damage_mult,
			"speed": 0.0,  # 地雷静止
			"lifetime": config.projectile_lifetime,
			"direction": Vector2.ZERO,
			"penetration": config.penetration,
			"explosion_radius": config.explosion_radius * stats.area * radius_mult,
			"element": _element_type_to_string(config.element_type),
			"on_hit_effect": config.on_hit_effect
		}

		# 质变效果：连锁爆炸（mines）
		if has_qualitative and weapon_data.get("chain_explode", false):
			bullet_config["chain_count"] = 3
			bullet_config["chain_range"] = 150.0

		# 质变效果：吞噬小怪（spoon）
		if has_qualitative and weapon_data.get("devour_small", false):
			bullet_config["gravity_pull_strength"] = 200.0
			bullet_config["gravity_pull_range"] = 100.0

		# 质变效果：爆裂回收（spoon）
		if has_qualitative and weapon_data.get("explode_on_return", false):
			bullet_config["return_to_player"] = true
			bullet_config["explosion_radius"] = 80.0 * stats.area

		bullet.setup(bullet_config)
		bullet.global_position = player.global_position + random_offset
		get_tree().current_scene.call_deferred("add_child", bullet)

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

func _get_weapon_color(weapon_id: String, config: WeaponData.WeaponConfig) -> Color:
	"""根据weapon_id和元素类型返回弹幕颜色"""
	# 优先根据武器特性设置颜色
	match weapon_id:
		"homing_amulet":
			return Color("#e74c3c")  # 红色符札（灵梦）
		"star_dust":
			return Color("#f1c40f")  # 黄色星星（魔理沙）
		"phoenix_wings":
			return Color("#ff9500")  # 橙黄色火焰光环（妹红）
		"phoenix_claws":
			return Color("#ff3300")  # 鲜艳的橙红色利爪（妹红）
		"knives":
			return Color("#bdc3c7")  # 银白色飞刀（咲夜）
		"yin_yang_orb":
			return Color("#e74c3c")  # 红色阴阳玉（灵梦）
		"spoon":
			return Color("#8e44ad")  # 紫色汤勺（尤魔）
		"mines":
			return Color("#2ecc71")  # 绿色地雷（恋）
		"laser":
			return Color("#f1c40f")  # 黄色激光（魔理沙）

	# 其次根据元素类型设置颜色
	match config.element_type:
		GameConstants.ElementType.FIRE:
			return Color("#ff4500")  # 橙红色
		GameConstants.ElementType.ICE:
			return Color("#00ffff")  # 青色
		GameConstants.ElementType.LIGHTNING:
			return Color("#ffff00")  # 黄色
		GameConstants.ElementType.POISON:
			return Color("#00ff00")  # 绿色
		_:
			return Color.WHITE  # 默认白色

# ==================== HELPER FUNCTIONS ====================

func _schedule_delayed_bullet(bullet: Node, final_speed: float, delay: float):
	"""延迟发射子弹（用于咲夜飞刀的时停效果）"""
	# 创建一个计时器来延迟加速
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(func():
		if is_instance_valid(bullet):
			# 使用保存的方向加速
			bullet.velocity = bullet.direction * final_speed
			bullet.speed = final_speed
	)

func get_weapon_data(weapon_id: String) -> Dictionary:
	"""获取武器的完整数据（包括质变效果）"""
	if weapon_id in weapons:
		return weapons[weapon_id]
	return {}

func get_all_weapons() -> Dictionary:
	"""获取所有已装备武器"""
	return weapons