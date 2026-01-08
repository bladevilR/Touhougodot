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

# 近战武器冷却追踪
var melee_cooldowns = {}  # {weapon_id: cooldown_remaining}
var melee_attack_frame = 0  # 交替显示第0帧或第1帧

# ==================== 元素附魔系统 ====================
var current_enchant_element: int = -1  # 当前附魔的元素类型 (-1 = 无)
var enchant_timer: float = 0.0  # 附魔剩余时间

# 元素附魔颜色叠加
const ENCHANT_COLORS = {
	GameConstants.ElementType.FIRE: Color("#ff4500"),
	GameConstants.ElementType.ICE: Color("#00bfff"),
	GameConstants.ElementType.POISON: Color("#9370db"),
	GameConstants.ElementType.OIL: Color("#8b4513"),
	GameConstants.ElementType.LIGHTNING: Color("#ffd700"),
	GameConstants.ElementType.GRAVITY: Color("#9932cc"),
}

func _ready():
	# 获取父节点（应该是Player）
	player = get_parent()
	aim_system = player.get_node_or_null("AimSystem")

	# 监听武器添加信号
	SignalBus.weapon_added.connect(add_weapon)
	SignalBus.weapon_upgraded.connect(upgrade_weapon)

	# 监听元素附魔信号
	SignalBus.element_enchant_applied.connect(_on_element_enchant_applied)

	# 初始化武器数据
	WeaponData.initialize()
	ElementData.initialize()

func try_fire_weapon(weapon_id: String, override_direction: Vector2 = Vector2.ZERO) -> bool:
	"""尝试发射指定武器（检查冷却）"""
	if not weapon_id in weapons:
		print("DEBUG: try_fire_weapon failed - weapon not found: ", weapon_id)
		return false
		
	var weapon_data = weapons[weapon_id]
	
	# 如果是近战武器，检查近战冷却
	if weapon_data.config.weapon_type == GameConstants.WeaponType.MELEE:
		var current_cd = melee_cooldowns.get(weapon_id, 0.0)
		if current_cd <= 0:
			fire_weapon(weapon_id, override_direction)
			# 设置冷却
			var stats = _get_player_stats()
			var level_cooldown_mult = weapon_data.get("level_bonuses", {}).get("cooldown_mult", 1.0)
			melee_cooldowns[weapon_id] = weapon_data.config.cooldown_max * stats.cooldown * level_cooldown_mult
			return true
		else:
			return false
	
	return false # 非近战武器由_process自动发射

func _process(delta):
	if not player:
		return

	# 更新元素附魔计时器
	_update_enchant_timer(delta)

	# 更新近战武器冷却
	for weapon_id in melee_cooldowns.keys():
		melee_cooldowns[weapon_id] -= delta

	# 更新所有武器的冷却计时器
	for weapon_id in weapons.keys():
		var weapon_data = weapons[weapon_id]

		# MELEE类型不自动发射，由鼠标点击触发
		if weapon_data.config.weapon_type == GameConstants.WeaponType.MELEE:
			continue

		weapon_data.timer -= delta

		# 冷却完成，发射！
		if weapon_data.timer <= 0:
			# Auto-fire for most weapons
			fire_weapon(weapon_id)
			# 重置冷却，应用角色的cooldown属性和等级加成
			var stats = _get_player_stats()
			var level_cooldown_mult = weapon_data.level_bonuses.get("cooldown_mult", 1.0) if weapon_data.has("level_bonuses") else 1.0
			weapon_data.timer = weapon_data.config.cooldown_max * stats.cooldown * level_cooldown_mult

# ==================== 元素附魔处理 ====================
func _on_element_enchant_applied(element_type: int, duration: float):
	"""应用元素附魔"""
	current_enchant_element = element_type
	enchant_timer = duration

	# 获取元素信息
	var element_item = ElementData.get_element_item(element_type)
	var element_name = element_item.item_name if element_item else "未知"

	print("元素附魔生效: ", element_name, " - ", duration, "秒")

	# 视觉反馈：玩家发光
	_apply_enchant_visual()

func _update_enchant_timer(delta: float):
	"""更新元素附魔计时器"""
	if current_enchant_element < 0:
		return

	enchant_timer -= delta

	# 附魔到期
	if enchant_timer <= 0:
		_expire_enchant()

func _expire_enchant():
	"""元素附魔到期"""
	var element_item = ElementData.get_element_item(current_enchant_element)
	var element_name = element_item.item_name if element_item else "未知"

	print("元素附魔结束: ", element_name)

	current_enchant_element = -1
	enchant_timer = 0.0

	# 移除视觉效果
	_remove_enchant_visual()

	# 发送信号
	SignalBus.element_enchant_expired.emit()

func _apply_enchant_visual():
	"""应用附魔视觉效果"""
	if not player:
		return

	var player_sprite = player.get_node_or_null("Sprite2D")
	if player_sprite:
		var enchant_color = ENCHANT_COLORS.get(current_enchant_element, Color.WHITE)
		# 混合原色和附魔色
		player_sprite.modulate = enchant_color.lightened(0.3)

func _remove_enchant_visual():
	"""移除附魔视觉效果"""
	if not player:
		return

	var player_sprite = player.get_node_or_null("Sprite2D")
	if player_sprite:
		player_sprite.modulate = Color.WHITE

func get_current_enchant_element() -> int:
	"""获取当前附魔元素"""
	return current_enchant_element

func get_enchant_time_remaining() -> float:
	"""获取附魔剩余时间"""
	return enchant_timer

func has_enchant() -> bool:
	"""是否有激活的附魔"""
	return current_enchant_element >= 0

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

	# 根据升ID应用效果
	match upgrade_id:
		# === Yin Yang Orb (阴阳玉) ===
		"orb_size":
			_apply_damage_mult(weapon_data, 2.5)
			config.penetration += 50
			print("  → 强化阴阳: 伤害 +150%，穿透 +50")
		"orb_gravity":
			weapon_data["gravity_control"] = true
			config.has_gravity = true
			print("  → 重力控制: 可手动控制抛物线")
		"orb_multi":
			config.projectile_count += 1
			print("  → 双子阴阳: 同时投掷两个")
		"orb_seeking":
			weapon_data["seek_on_land"] = true
			print("  → 寻敌阴阳: 落地时追踪最近敌人")
		"orb_crush":
			weapon_data["stun_on_hit"] = 3.0
			print("  → 碾压重击: 命中眩晕敌人 3 秒")
		"orb_bounce_ground":
			config.bounce_count += 5
			print("  → 地面弹跳: 落地后继续弹跳 5 次")
		"orb_meteor":
			weapon_data["meteor_rain"] = true
			weapon_data["meteor_count"] = 10
			print("  → 阴阳天降: 召唤 10 个小阴阳玉从天而降")
		"orb_vortex":
			weapon_data["create_vortex"] = true
			weapon_data["vortex_radius"] = 150.0
			print("  → 阴阳漩涡: 落地创造吸引敌人的旋涡")
		"orb_return":
			weapon_data["return_to_player"] = true
			print("  → 回旋阴阳: 落地后飞回玩家")

		# === Charged Fire Ring (左键蓄力) ===
		"cfr_quick":
			weapon_data["quick_charge"] = true # 蓄力速度+30%在 fire_charged_flame_ring 中实现
			_apply_damage_mult(weapon_data, 1.2)
			print("  → 快速蓄力")
		"cfr_burn":
			weapon_data["strong_burn"] = true
			print("  → 灼热气息")
		"cfr_big":
			weapon_data["big_fireball"] = true
			_apply_damage_mult(weapon_data, 1.3)
			print("  → 巨大火球")
		"cfr_trail":
			weapon_data["fire_trail"] = true
			print("  → 烈焰路径")
		"cfr_inferno":
			weapon_data["inferno_blast"] = true
			print("  → 炼狱爆裂")

		# === Mokou Kick Heavy (右键重击) ===
		"mkh_force":
			weapon_data["strong_kick"] = true
			_apply_damage_mult(weapon_data, 1.3)
			print("  → 强力踢击")
		"mkh_cd":
			_apply_cooldown_mult(weapon_data, 0.8) # 简单减少CD
			print("  → 冷却缩减")
		"mkh_shockwave":
			weapon_data["shockwave"] = true
			print("  → 震荡波")
		"mkh_stun":
			weapon_data["stun_kick"] = true
			print("  → 粉碎踢")
		"mkh_chain":
			weapon_data["chain_explode"] = true
			print("  → 连环爆破")

		# === Skill Mokou (空格技能) ===
		"skm_cost":
			if player and player.has_node("CharacterSkills"):
				player.get_node("CharacterSkills").cost_multiplier = 0.5
			print("  → 节能模式")
		"skm_dist":
			if player and player.has_node("CharacterSkills"):
				var skills = player.get_node("CharacterSkills")
				skills.fire_kick_distance *= 1.3
				skills.fire_kick_duration *= 0.8 # 更快
			print("  → 迅捷之鸟")
		"skm_wall":
			# 需要在CharacterSkills中实现
			weapon_data["wall_mastery"] = true 
			print("  → 烈焰之墙 (需逻辑支持)")
		"skm_invul":
			# 需要在CharacterSkills中实现
			weapon_data["long_invul"] = true
			print("  → 不死之身 (需逻辑支持)")
		"skm_rebirth":
			# 需要在CharacterSkills中实现
			weapon_data["phoenix_rebirth"] = true
			print("  → 凤凰涅槃 (需逻辑支持)")

		# 其他旧升级已移除
		_:
			print("  → 未实现的升级效果: ", upgrade_id)

# 辅助方法：应用伤害倍数
func _apply_damage_mult(weapon_data: Dictionary, mult: float):
	if not weapon_data.upgrade_bonuses.has("damage_mult"):
		weapon_data.upgrade_bonuses["damage_mult"] = 1.0
	weapon_data.upgrade_bonuses["damage_mult"] *= mult

# 辅助方法：应用冷却倍数
func _apply_cooldown_mult(weapon_data: Dictionary, mult: float):
	if not weapon_data.upgrade_bonuses.has("cooldown_mult"):
		weapon_data.upgrade_bonuses["cooldown_mult"] = 1.0
	weapon_data.upgrade_bonuses["cooldown_mult"] *= mult

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

func fire_weapon(weapon_id: String, override_direction: Vector2 = Vector2.ZERO):
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
		GameConstants.WeaponType.AURA:
			_fire_aura(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.ORBITAL:
			_fire_orbital(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.LASER:
			_fire_laser(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.SPECIAL:
			_fire_special(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.MELEE:
			_fire_melee(weapon_id, config, stats, weapon_level, override_direction)
		_:
			print("未实现的武器类型: ", config.weapon_type)

func _fire_projectile(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	# 确定攻击方向：优先使用角色移动方向（键盘控制），其次是瞄准系统/鼠标
	var direction: Vector2 = Vector2.RIGHT
	
	if player and "last_move_direction" in player:
		direction = player.last_move_direction
	elif aim_system:
		direction = aim_system.get_aim_direction()
	else:
		# 备用：瞄准最近的敌人
		var target = get_nearest_enemy()
		if target:
			direction = (target.global_position - player.global_position).normalized()

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

	# 特殊处理：火鸟重踢横向排列（不是扇形）
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
			# 横向一字排列（火鸟重踢）
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

		# 应用元素附魔（覆盖武器原有元素）
		if current_enchant_element >= 0:
			bullet_config["element"] = _element_type_to_string(current_enchant_element)
			# 混合附魔颜色
			var enchant_color = ENCHANT_COLORS.get(current_enchant_element, Color.WHITE)
			var base_color = bullet_config["bullet_color"]
			bullet_config["bullet_color"] = base_color.lerp(enchant_color, 0.6)

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
				"speed": 0.0,  # 环绕弹幕不需要速度，位跟随玩家
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

func _fire_aura(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	"""近战AURA武器 - 在玩家周围创建扇形判定区域"""
	# 获取武器数据
	var weapon_data = weapons.get(weapon_id, {})

	# 获取伤害倍数
	var level_bonuses = weapon_data.get("level_bonuses", {})
	var damage_mult = level_bonuses.get("damage_mult", 1.0)
	var upgrade_bonuses = weapon_data.get("upgrade_bonuses", {})
	damage_mult *= upgrade_bonuses.get("damage_mult", 1.0)

	# 计算最终伤害
	var final_damage = config.base_damage * stats.might * damage_mult

	# 获取瞄准方向
	var direction: Vector2
	if aim_system:
		direction = aim_system.get_aim_direction()
	else:
		var target = get_nearest_enemy()
		if target:
			direction = (target.global_position - player.global_position).normalized()
		else:
			direction = Vector2(cos(player.rotation), sin(player.rotation))

	# 创建近战判定区域
	var aura_area = Area2D.new()
	aura_area.name = "AuraSlash"
	aura_area.global_position = player.global_position

	# 创建扇形碰撞形状（使用多个圆形近似）
	var sweep_angle = config.projectile_spread  # 扇形角度
	var sweep_range = config.explosion_radius  # 扇形范围
	var segments = 5  # 扇形分段数

	for i in range(segments):
		var angle_offset = -sweep_angle / 2.0 + (sweep_angle * i / (segments - 1))
		var seg_direction = direction.rotated(angle_offset)

		var collision = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = sweep_range / segments
		collision.shape = shape
		collision.position = seg_direction * (sweep_range * 0.7)  # 偏移到扇形中部
		aura_area.add_child(collision)

	# 添加视觉效果（扇形）
	var fan = Polygon2D.new()
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)  # 扇形中心点

	# 生成扇形边缘的点
	var segments_visual = 16
	for i in range(segments_visual + 1):
		var angle_offset = -sweep_angle / 2.0 + (sweep_angle * i / segments_visual)
		var point_direction = direction.rotated(angle_offset)
		points.append(point_direction * sweep_range)

	fan.polygon = points
	fan.color = Color(1.0, 0.5, 0.0, 0.4)  # 橙红色半透明
	aura_area.add_child(fan)

	# 设置碰撞层
	aura_area.collision_layer = 0
	aura_area.collision_mask = 4  # 检测敌人

	# 添加到场景
	get_tree().current_scene.add_child(aura_area)

	# 立即检测并伤害范围内的敌人
	await get_tree().process_frame  # 等待一帧让碰撞生效

	var hit_enemies = aura_area.get_overlapping_bodies()
	for body in hit_enemies:
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			# 造成伤害
			body.take_damage(final_damage)

			# 击退
			if body.has_method("apply_knockback"):
				var knockback_dir = (body.global_position - player.global_position).normalized()
				body.apply_knockback(knockback_dir, config.knockback)

			# 燃烧效果
			if config.on_hit_effect == "burn" and body.has_method("apply_burn"):
				var burn_dmg = weapon_data.get("burn_damage", 5.0)
				var burn_dur = weapon_data.get("burn_duration", 2.0)
				body.apply_burn(burn_dmg, burn_dur)

	# 持续一段时间后消失
	await get_tree().create_timer(config.projectile_lifetime).timeout
	if is_instance_valid(aura_area):
		aura_area.queue_free()


func _fire_melee(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int, override_direction: Vector2 = Vector2.ZERO):
	"""近战攻击分发"""
	if weapon_id == "mokou_kick_light":
		_fire_melee_light(weapon_id, config, stats)
	else:
		_fire_melee_heavy(weapon_id, config, stats, override_direction)

func fire_charged_flame_ring(duration: float, override_direction: Vector2 = Vector2.ZERO):
	"""发射蓄力火焰圈 - 三段式逻辑"""
	# 获取玩家属性
	var stats = _get_player_stats()
	
	# 确定攻击方向
	var direction = Vector2.RIGHT
	if override_direction.length() > 0.1:
		direction = override_direction.normalized()
	elif aim_system:
		direction = aim_system.get_aim_direction()
	else:
		direction = (get_global_mouse_position() - player.global_position).normalized()

	# 播放通用攻击动画
	if player and player.has_method("play_attack_animation"):
		player.play_attack_animation(0, 0.3)

	# === 第一阶段：点按瞬发 (原轻攻击) ===
	if duration < 0.5:
		# 伤害: 基础
		var damage = 25.0 * stats.might
		
		# 视觉：火焰弧粒子
		_spawn_fire_arc_particles(direction, 0.6) # 0.6规模
		
		# 判定：扇形AOE (距离120, 角度宽)
		_apply_melee_arc_damage(direction, 120.0, 0.2, damage, 300.0, 0.3)
		return

	# === 第二阶段：半蓄力 (中程火焰弹) ===
	elif duration < 1.5:
		var charge_ratio = (duration - 0.5) / 1.0 # 0.0 ~ 1.0
		
		# 添加发射时的火焰视觉效果 (增强可见性)
		# 使用更高的 Z-index 和更多的粒子
		var burst = GPUParticles2D.new()
		var mat = ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		mat.emission_sphere_radius = 30.0
		mat.direction = Vector3(direction.x, direction.y, 0)
		mat.spread = 25.0
		mat.initial_velocity_min = 200.0
		mat.initial_velocity_max = 350.0
		mat.gravity = Vector3(0, 0, 0)
		mat.scale_min = 0.5
		mat.scale_max = 0.8 # 更大的粒子
		
		# [修复] 直接使用代码生成渐变，避免加载不存在的 .tres 文件导致报错
		var grad = Gradient.new()
		grad.colors = [Color(1, 0.8, 0.2), Color(1, 0.3, 0), Color(1, 0, 0, 0)]
		var tex = GradientTexture1D.new()
		tex.gradient = grad
		mat.color_ramp = tex
			
		burst.process_material = mat
		
		# 创建圆形纹理
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8) # 更大的纹理
		img.fill(Color.WHITE)
		burst.texture = ImageTexture.create_from_image(img)
		
		burst.emitting = true
		burst.one_shot = true
		burst.explosiveness = 1.0
		burst.amount = 60 # 更多粒子
		burst.lifetime = 0.6
		burst.global_position = player.global_position + direction * 40.0
		burst.z_index = 100 # 确保在最上层
		
		# 叠加模式
		var canvas_mat = CanvasItemMaterial.new()
		canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		burst.material = canvas_mat

		get_tree().current_scene.add_child(burst)
		# [修复] 使用 finished 信号自动清理，避免 Lambda 捕获失效导致的 C++ 错误
		burst.finished.connect(func():
			if is_instance_valid(burst):
				burst.queue_free()
		)
		
		var bullet = bullet_scene.instantiate()
		var bullet_config = {
			"weapon_id": "charged_fire_ring", 
			"damage": 50.0 * stats.might * (1.0 + charge_ratio * 0.5),
			"speed": 500.0,
			"lifetime": 0.6 + charge_ratio * 0.4, # 飞得稍远
			"direction": direction,
			"scale_mult": 1.2 + charge_ratio * 0.5,
			"penetration": 999,
			"knockback": 500.0,
			"element": "fire",
			"on_hit_effect": "burn",
			"burn_damage": 10.0,
			"bullet_color": Color(1.0, 0.5, 0.0)
		}
		bullet.setup(bullet_config)
		bullet.global_position = player.global_position + direction * 40.0
		get_tree().current_scene.call_deferred("add_child", bullet)
		
		SignalBus.screen_shake.emit(0.2, 5.0)
		return

	# === 第三阶段：满蓄力 (远程大火环) ===
	else:
		# 满蓄力固定属性
		var bullet = bullet_scene.instantiate()
		var bullet_config = {
			"weapon_id": "charged_fire_ring_full", # 满蓄力ID
			"damage": 120.0 * stats.might,
			"speed": 700.0, # 高速
			"lifetime": 1.5, # 远射程
			"direction": direction,
			"scale_mult": 2.5, # 巨大
			"penetration": 999,
			"knockback": 1000.0,
			"element": "fire",
			"on_hit_effect": "burn",
			"burn_damage": 20.0,
			"bullet_color": Color(1.0, 0.5, 0.0) # 橙色，匹配Space技能
		}
		bullet.setup(bullet_config)
		bullet.global_position = player.global_position + direction * 50.0
		get_tree().current_scene.call_deferred("add_child", bullet)
		
		# 强力反馈
		SignalBus.screen_shake.emit(0.4, 15.0)
		return

# 辅助：生成火焰弧粒子 (从原_fire_melee_light提取)
func _spawn_fire_arc_particles(direction: Vector2, scale_mod: float):
	var arc_particles = GPUParticles2D.new()
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_radius = 50.0 * scale_mod
	mat.emission_ring_inner_radius = 45.0 * scale_mod
	mat.emission_ring_axis = Vector3(0, 0, 1)
	mat.gravity = Vector3(0, -150, 0)
	mat.scale_min = 0.4 * scale_mod
	mat.scale_max = 0.7 * scale_mod

	var gradient = Gradient.new()
	gradient.offsets = [0.0, 0.5, 1.0]
	gradient.colors = [Color(1.0, 1.0, 0.5), Color(1.0, 0.5, 0.0), Color(1.0, 0.0, 0.0, 0.0)]
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	mat.color_ramp = gradient_tex

	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 150.0
	mat.direction = Vector3(direction.x, direction.y, 0)
	mat.spread = 20.0
	arc_particles.process_material = mat

	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	arc_particles.texture = ImageTexture.create_from_image(img)

	arc_particles.emitting = true
	arc_particles.one_shot = true
	arc_particles.explosiveness = 0.8
	arc_particles.amount = int(80 * scale_mod)
	arc_particles.lifetime = 0.5
	arc_particles.global_position = player.global_position + direction * 30.0
	arc_particles.z_index = 5
	
	var canvas_mat = CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	arc_particles.material = canvas_mat

	get_tree().current_scene.add_child(arc_particles)
	# [修复] 使用 finished 信号自动清理
	arc_particles.finished.connect(func():
		if is_instance_valid(arc_particles):
			arc_particles.queue_free()
	)

# 辅助：扇形伤害判定 (从原_fire_melee_light提取)
func _apply_melee_arc_damage(direction: Vector2, radius: float, arc_dot: float, damage: float, knockback: float, stun_dur: float):
	var enemies = get_tree().get_nodes_in_group("enemy")
	var hit_count = 0
	
	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		
		var to_enemy = enemy.global_position - player.global_position
		var dist = to_enemy.length()
		var enemy_dir = to_enemy.normalized()
		
		if dist < radius and direction.dot(enemy_dir) > arc_dot:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(direction, knockback)
			if stun_dur > 0 and enemy.has_method("apply_stun"):
				enemy.apply_stun(stun_dur)
			hit_count += 1
			
	if hit_count > 0:
		SignalBus.screen_shake.emit(0.1, 5.0)
		_apply_hit_stop(0.05)

func _apply_hit_stop(duration: float):
	"""应用定帧效果 - 增强打击感"""
	if Engine.time_scale > 0.9:
		Engine.time_scale = 0.1
		# 使用独立计时器，确保定帧时间准确
		var timer = get_tree().create_timer(duration, true, false, true)
		timer.timeout.connect(func():
			Engine.time_scale = 1.0
		)

func _fire_melee_light(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary):
	# 占位符，已弃用
	pass

func _fire_melee_heavy(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, override_direction: Vector2 = Vector2.ZERO):
	"""近战攻击 - 强力踢击 (范围击退 + 最近敌人旋转击飞)"""
	# 伤害计算
	var final_damage = config.base_damage * stats.might * 8.0 

	# 获取攻击方向：优先使用 override_direction，然后是 last_move_direction，最后是鼠标
	var direction = Vector2.RIGHT
	if override_direction.length() > 0.1:
		direction = override_direction.normalized()
	elif player and "last_move_direction" in player:
		direction = player.last_move_direction
	else:
		var mouse_pos = get_global_mouse_position()
		direction = (mouse_pos - player.global_position).normalized()

	# 玩家冲刺位移
	if player and player.has_method("apply_knockback"):
		player.apply_knockback(direction, 1200.0)

	# === 1. 攻击动画 ===
	if player.has_method("play_attack_animation"):
		player.play_attack_animation(1, 0.3)  # 0.3秒播放25帧动画

	# === 2. 火焰特效 ===
	var particles = GPUParticles2D.new()
	var mat = ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 20.0
	mat.direction = Vector3(direction.x, direction.y, 0)
	mat.spread = 20.0
	mat.initial_velocity_min = 200.0
	mat.initial_velocity_max = 300.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 0.1
	mat.scale_max = 0.2
	mat.color = Color(1.0, 0.4, 0.1)
	particles.process_material = mat
	
	var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	particles.texture = ImageTexture.create_from_image(img)
	
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.amount = 30
	particles.lifetime = 0.5
	particles.global_position = player.global_position
	particles.z_index = 50
	
	var canvas_mat = CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = canvas_mat

	get_tree().current_scene.add_child(particles)
	# [修复] 使用 finished 信号自动清理
	particles.finished.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)

	# === 3. 立即判定 (分两层攻击) ===
	# 获取所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearby_enemies = []  # 面前大范围的敌人
	var nearest_enemy = null  # 最近的敌人
	var min_dist = INF

	for enemy in enemies:
		if not is_instance_valid(enemy): continue

		# 计算相对位置
		var to_enemy = enemy.global_position - player.global_position
		var dist = to_enemy.length()
		var enemy_dir = to_enemy.normalized()

		# 第一层：面前大范围（距离<250，角度<60度）- 被踢开
		# 0.5 dot product 约为 60 度扇形
		if dist < 250.0 and direction.dot(enemy_dir) > 0.5:
			# 排除最近的敌人（它是重击目标）
			if enemy != nearest_enemy:
				nearby_enemies.append(enemy)

		# 找最近的敌人（重点击飞目标），且必须在前方一定范围内
		if dist < min_dist and dist < 300.0 and direction.dot(enemy_dir) > 0.3:
			min_dist = dist
			nearest_enemy = enemy

	# === 4. 第一波：大范围敌人被猛烈踢开 ===
	if nearby_enemies.size() > 0:
		SignalBus.screen_shake.emit(0.2, 10.0) # 轻微震动
		_apply_hit_stop(0.08) # 中等定帧

		for enemy in nearby_enemies:
			var to_enemy = enemy.global_position - player.global_position
			var enemy_dir = to_enemy.normalized()

			# 踢开（强力击退）
			if enemy.has_method("apply_knockback"):
				# 击退方向稍微向两侧偏一点，形成"破开"的效果
				enemy.apply_knockback(enemy_dir, 1500.0)

			# 造成伤害
			if enemy.has_method("take_damage"):
				enemy.take_damage(final_damage * 0.8)

	# === 5. 第二波：最近敌人旋转击飞 (如果不为空) ===
	if nearest_enemy:
		# 强烈震动
		SignalBus.screen_shake.emit(0.5, 30.0)
		_apply_hit_stop(0.12) # 强力定帧

		# 击飞（极大力度）
		if nearest_enemy.has_method("apply_knockback"):
			# 重置速度以确保击飞方向纯粹
			if "velocity" in nearest_enemy: nearest_enemy.velocity = Vector2.ZERO
			# 向前击飞
			nearest_enemy.apply_knockback(direction, 5000.0)

			# 旋转特效 - 疯狂旋转 [修复] 绑定到 sprite 的生命周期
			if is_instance_valid(nearest_enemy) and "sprite" in nearest_enemy and nearest_enemy.sprite and is_instance_valid(nearest_enemy.sprite):
				var tween = nearest_enemy.sprite.create_tween()
				# 快速旋转多圈
				tween.tween_property(nearest_enemy.sprite, "rotation", PI * 12, 0.8).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

		# 延迟伤害，确保击飞效果可见
		await get_tree().create_timer(0.4).timeout

		if is_instance_valid(nearest_enemy) and nearest_enemy.has_method("take_damage"):
			nearest_enemy.take_damage(final_damage * 2.5)  # 致命伤害


func _create_melee_hitbox(pos: Vector2, radius: float, duration: float, damage: float, knockback: float, direction: Vector2, is_heavy: bool = false, damage_delay: float = 0.0):
	"""创建临时近战伤害判定区域"""
	var area = Area2D.new()
	area.global_position = pos
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask = 4 # Detect Enemy
	
	get_tree().current_scene.add_child(area)
	
	# 连接信号处理伤害
	area.body_entered.connect(func(body):
		if not is_instance_valid(self):
			return
		if body.is_in_group("enemy"):
			# 先击飞 (重击)
			if body.has_method("apply_knockback"):
				var knock_dir = direction if is_heavy else (body.global_position - player.global_position).normalized()
				if is_heavy:
					if "velocity" in body: body.velocity = Vector2.ZERO
					body.apply_knockback(knock_dir, knockback)
				else:
					body.apply_knockback(knock_dir, knockback)

			# 延迟伤害
			if damage_delay > 0:
				await get_tree().create_timer(damage_delay).timeout

			if is_instance_valid(body) and body.has_method("take_damage"):
				body.take_damage(damage)
	)
	
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(area):
		area.queue_free()

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
	# [修复] 使用 Timer 节点而非 SceneTreeTimer 避免 Lambda 捕获错误
	var timer = Timer.new()
	timer.wait_time = delay
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(bullet):
			# 使用保存的方向加速
			bullet.velocity = bullet.direction * final_speed
			bullet.speed = final_speed
			# 清理计时器
			if is_instance_valid(timer):
				timer.queue_free()
	)

func get_weapon_data(weapon_id: String) -> Dictionary:
	"""获取武器的完整数据（包括质变效果）"""
	if weapon_id in weapons:
		return weapons[weapon_id]
	return {}

func get_all_weapons() -> Dictionary:
	"""获取所有已装备武器"""
	return weapons
