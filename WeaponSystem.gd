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

func _input(event):
	# 鼠标左键点击触发近战攻击
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_melee_attack()

func _try_melee_attack():
	"""尝试进行近战攻击"""
	for weapon_id in weapons.keys():
		var weapon_data = weapons[weapon_id]
		if weapon_data.config.weapon_type == GameConstants.WeaponType.MELEE:
			# 检查冷却
			if melee_cooldowns.get(weapon_id, 0.0) <= 0:
				fire_weapon(weapon_id)
				# 设置冷却
				var stats = _get_player_stats()
				var level_cooldown_mult = weapon_data.get("level_bonuses", {}).get("cooldown_mult", 1.0)
				melee_cooldowns[weapon_id] = weapon_data.config.cooldown_max * stats.cooldown * level_cooldown_mult

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
		# === Homing Amulet (博丽符纸) ===
		"amulet_count":
			config.projectile_count += 2
			print("  → 散弹符阵: 发射数量 +2")
		"amulet_homing":
			config.homing_strength *= 2.0
			print("  → 完美追踪: 追踪强度 +100%")
		"amulet_bounce":
			weapon_data["enemy_bounce"] = true
			weapon_data["bounce_count"] = 3
			print("  → 弹跳灵符: 符札在敌人间弹跳")
		"amulet_split":
			weapon_data["split_on_hit"] = true
			weapon_data["split_count"] = 2
			print("  → 阴阳裂变: 命中后分裂成两个追踪符")
		"amulet_pierce":
			config.penetration += 5
			_apply_damage_mult(weapon_data, 1.3)
			print("  → 神灵穿透: 贯穿 +5，伤害 +30%")
		"amulet_heal":
			weapon_data["heal_on_hit"] = 1.0
			print("  → 净化灵符: 命中回复 1 HP")
		"amulet_rain":
			weapon_data["target_all_enemies"] = true
			print("  → 梦想天生: 向所有敌人发射符札")
		"amulet_barrier":
			weapon_data["orbit_shield"] = true
			weapon_data["shield_count"] = 3
			print("  → 常驻结界: 符札环绕身体形成护盾")
		"amulet_explosion":
			config.explosion_radius = 50.0
			print("  → 灵爆符咒: 命中产生小范围爆炸")

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

		# === Boundary (博丽结界) ===
		"boundary_size":
			config.explosion_radius *= 1.5
			print("  → 扩展结界: 范围 +50%")
		"boundary_damage":
			_apply_damage_mult(weapon_data, 2.0)
			print("  → 伤害结界: 伤害 +100%")
		"boundary_duration":
			config.projectile_lifetime *= 2.0
			print("  → 常驻结界: 持续时间 +100%")
		"boundary_reflect":
			weapon_data["reflect_bullets"] = true
			print("  → 反射护盾: 反弹敌方弹幕")
		"boundary_heal":
			weapon_data["heal_per_second"] = 2.0
			print("  → 治愈结界: 每秒恢复 2 HP")
		"boundary_slow":
			weapon_data["slow_enemies"] = 0.3
			print("  → 时缓领域: 结界内敌人速度 -70%")
		"boundary_fantasy":
			weapon_data["invincibility"] = true
			print("  → 幻想封印: 持续时间内完全无敌")
		"boundary_banish":
			weapon_data["banish_on_end"] = true
			print("  → 幻想崩坏: 结束时驱逐所有结界内敌人")
		"boundary_double":
			config.projectile_count = 2
			print("  → 双重结界: 同时展开两层结界")

		# === Star Dust (星符) ===
		"star_count":
			config.projectile_spread *= 1.5
			print("  → 星河漫天: 发射角度范围扩大")
		"star_speed":
			config.projectile_speed *= 2.0
			_apply_damage_mult(weapon_data, 1.3)
			print("  → 光速星尘: 弹速 +100%，伤害 +30%")
		"star_pierce":
			config.penetration += 3
			print("  → 穿星之力: 贯穿 +3")
		"star_homing":
			config.homing_strength = 0.15
			print("  → 追星魔法: 星星获得追踪能力")
		"star_explode":
			config.explosion_radius = 40.0
			print("  → 星爆魔法: 命中产生小爆炸")
		"star_rapid":
			_apply_cooldown_mult(weapon_data, 0.5)
			print("  → 速射星尘: 冷却时间 -50%")
		"star_galaxy":
			config.projectile_count = 16
			weapon_data["all_directions"] = true
			print("  → 银河狂想: 向所有方向发射 16 颗星星")
		"star_comet":
			weapon_data["trail_damage"] = true
			weapon_data["trail_dps"] = 5.0
			print("  → 彗星魔法: 每颗星星留下持续伤害轨迹")
		"star_supernova":
			weapon_data["explode_on_death"] = true
			weapon_data["death_explosion_radius"] = 80.0
			print("  → 超新星: 星星消失时产生大爆炸")

		# === Laser (恋符·激光) ===
		"laser_width":
			weapon_data["laser_width_mult"] = 2.0
			print("  → 极宽火花: 激光宽度 +100%")
		"laser_duration":
			config.projectile_lifetime *= 2.0
			print("  → 持久火花: 持续时间 +100%")
		"laser_damage":
			_apply_damage_mult(weapon_data, 3.0)
			print("  → 终极火花: 伤害 +200%")
		"laser_sweep":
			weapon_data["sweep_mode"] = true
			weapon_data["sweep_speed"] = 0.5
			print("  → 扫射火花: 激光缓慢旋转扫射")
		"laser_multi":
			config.projectile_count = 3
			print("  → 三重火花: 同时发射三道激光")
		"laser_burn":
			config.on_hit_effect = "burn"
			weapon_data["burn_damage"] = 10.0
			weapon_data["burn_duration"] = 3.0
			print("  → 灼烧火花: 命中施加持续燃烧")
		"laser_rainbow":
			config.projectile_count = 7
			weapon_data["rainbow_mode"] = true
			print("  → 七彩究极火花: 发射 7 道彩虹激光")
		"laser_penetrate":
			weapon_data["infinite_range"] = true
			print("  → 贯穿世界: 激光穿透地图边界")
		"laser_charge":
			weapon_data["charge_mode"] = true
			weapon_data["charge_mult"] = 2.0
			print("  → 蓄力火花: 冷却期间蓄力，伤害累加")

		# === Phoenix Wings (凤凰羽衣) ===
		"wings_count":
			config.projectile_count += 2
			print("  → 六翼天使: 火焰羽翼数量 +2")
		"wings_damage":
			_apply_damage_mult(weapon_data, 1.5)
			print("  → 烈焰之翼: 伤害 +50%")
		"wings_range":
			config.orbit_radius *= 1.5
			print("  → 展翅高飞: 旋转范围 +50%")
		"wings_shoot":
			weapon_data["shoot_projectiles"] = true
			weapon_data["shoot_interval"] = 1.0
			print("  → 羽翼射击: 定期发射火焰弹")
		"wings_burn":
			config.on_hit_effect = "burn"
			print("  → 灼热光环: 接触施加燃烧效果")
		"wings_shield":
			weapon_data["block_bullets"] = true
			print("  → 火焰护盾: 抵挡敌方弹幕")
		"wings_double":
			weapon_data["second_layer"] = true
			print("  → 双重旋转: 添加反向旋转的第二层")
		"wings_pull":
			weapon_data["attract_items"] = true
			weapon_data["attract_radius"] = 200.0
			print("  → 火焰漩涡: 吸引敌人和宝石")
		"wings_explode":
			weapon_data["kill_explosion"] = true
			weapon_data["explosion_radius"] = 60.0
			print("  → 爆裂之翼: 击杀触发爆炸")

		# === Phoenix Claws (火鸟拳) ===
		"claw_size":
			weapon_data["size_mult"] = 1.5
			_apply_damage_mult(weapon_data, 1.3)
			print("  → 巨型火拳: 大小 +50%，伤害 +30%")
		"claw_speed":
			_apply_cooldown_mult(weapon_data, 0.7)
			print("  → 迅捷连打: 冷却时间 -30%")
		"claw_burn":
			config.on_hit_effect = "burn"
			weapon_data["burn_damage"] = 8.0
			weapon_data["burn_duration"] = 2.0
			print("  → 灼烧之拳: 命中施加燃烧效果")
		"claw_multi":
			weapon_data["multi_wave"] = 3
			print("  → 多重拳脚: 同时发射 3 波拳击")
		"claw_vamp":
			weapon_data["heal_on_kill"] = 1.0
			print("  → 浴火重生: 击杀敌人回复 1 HP")
		"claw_pierce":
			config.penetration += 3
			print("  → 破甲重击: 穿透 +3")
		"claw_dash":
			weapon_data["dash_attack"] = true
			weapon_data["dash_distance"] = 150.0
			print("  → 火鸟突击: 拳击伴随火鸟冲刺")
		"claw_x":
			weapon_data["four_directions"] = true
			print("  → 四方拳劲: 向四个方向同时挥拳")
		"claw_inferno":
			weapon_data["leave_fire_trail"] = true
			weapon_data["trail_duration"] = 3.0
			print("  → 炼狱火拳: 拳击留下持续燃烧的火焰路径")

		# === Knives (银制飞刀) ===
		"knife_count":
			config.projectile_count = 4
			print("  → 飞刀暴雨: 同时发射 4 把飞刀")
		"knife_bounce":
			config.bounce_count += 3
			print("  → 完美弹射: 弹射次数 +3")
		"knife_speed":
			config.projectile_speed *= 2.5
			print("  → 光速飞刀: 飞刀速度 +150%")
		"knife_explode":
			config.explosion_radius = 40.0
			print("  → 爆裂飞刀: 命中产生小爆炸")
		"knife_poison":
			config.on_hit_effect = "poison"
			weapon_data["poison_damage"] = 5.0
			weapon_data["poison_duration"] = 4.0
			print("  → 剧毒涂层: 命中施加持续毒伤")
		"knife_freeze":
			weapon_data["freeze_on_hit"] = 2.0
			print("  → 冻结飞刀: 命中冻结敌人 2 秒")
		"knife_danmaku":
			weapon_data["random_barrage"] = true
			weapon_data["barrage_count"] = 20
			print("  → 飞刀弹幕: 全屏随机发射飞刀")
		"knife_time":
			weapon_data["time_stop_throw"] = true
			weapon_data["suspend_duration"] = 3.0
			print("  → 时停飞刀: 飞刀在空中静止 3 秒后同时射出")
		"knife_return":
			weapon_data["return_to_player"] = true
			print("  → 回旋飞刀: 飞刀最终返回玩家")

		# === Spoon (刚欲汤勺) ===
		"spoon_size":
			weapon_data["size_mult"] = 2.0
			_apply_damage_mult(weapon_data, 2.0)
			print("  → 巨大勺子: 大小和伤害 +100%")
		"spoon_speed":
			config.projectile_speed *= 2.0
			weapon_data["return_speed_mult"] = 2.0
			print("  → 快速回收: 飞行和返回速度 +100%")
		"spoon_multi":
			config.projectile_count = 3
			print("  → 三重勺子: 同时投掷 3 把勺子")
		"spoon_heal":
			weapon_data["heal_on_hit"] = 3.0
			print("  → 吞噬回复: 命中回复 3 HP")
		"spoon_pull":
			weapon_data["attract_during_flight"] = true
			weapon_data["attract_radius"] = 150.0
			print("  → 吸引勺子: 飞行时吸引敌人和宝石")
		"spoon_spin":
			weapon_data["spin_mode"] = true
			_apply_damage_mult(weapon_data, 1.5)
			print("  → 旋转勺子: 勺子高速旋转，伤害 +50%")
		"spoon_gluttony":
			weapon_data["devour_small"] = true
			print("  → 暴食之勺: 命中吞噬小型敌人")
		"spoon_orbit":
			weapon_data["orbit_before_return"] = true
			weapon_data["orbit_duration"] = 1.0
			print("  → 勺子卫星: 勺子环绕身体后返回")
		"spoon_explosion":
			weapon_data["explode_on_return"] = true
			weapon_data["explosion_radius"] = 80.0
			print("  → 爆裂回收: 返回时产生爆炸伤害")

		# === Mines (本我地雷) ===
		"mine_count":
			config.projectile_count = 5
			print("  → 心灵陷阱: 每次放置 5 个地雷")
		"mine_damage":
			_apply_damage_mult(weapon_data, 2.5)
			print("  → 爆炸之心: 爆炸伤害 +150%")
		"mine_range":
			weapon_data["placement_range_mult"] = 2.0
			print("  → 扩散地雷: 放置范围 +100%")
		"mine_chain":
			weapon_data["chain_explosion"] = true
			weapon_data["chain_radius"] = 150.0
			print("  → 连锁爆炸: 爆炸触发附近地雷")
		"mine_pull":
			weapon_data["attract_before_explode"] = true
			weapon_data["attract_radius"] = 100.0
			print("  → 吸引地雷: 爆炸前吸引敌人")
		"mine_slow":
			weapon_data["slow_on_explode"] = 0.5
			weapon_data["slow_duration"] = 5.0
			print("  → 减速陷阱: 爆炸减速敌人 5 秒")
		"mine_field":
			config.projectile_count = 20
			weapon_data["field_mode"] = true
			print("  → 雷区封锁: 同时布置 20 个地雷")
		"mine_stealth":
			weapon_data["invisible_mines"] = true
			print("  → 隐形地雷: 敌人无法看见地雷")
		"mine_nuclear":
			config.explosion_radius *= 3.0
			_apply_damage_mult(weapon_data, 3.0)
			print("  → 核心爆炸: 超大范围巨额伤害")

		# 其他武器的升级可以继续添加...
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
		GameConstants.WeaponType.AURA:
			_fire_aura(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.ORBITAL:
			_fire_orbital(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.LASER:
			_fire_laser(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.SPECIAL:
			_fire_special(weapon_id, config, stats, weapon_level)
		GameConstants.WeaponType.MELEE:
			_fire_melee(weapon_id, config, stats, weapon_level)
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
			"bullet_color": Color(0.8, 0.4, 0.1, 0.3),  # 变暗，降低透明度 (低调点)
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


func _fire_melee(weapon_id: String, config: WeaponData.WeaponConfig, stats: Dictionary, weapon_level: int):
	"""近战攻击 - 强力踢击 (定帧 + 击飞 + 旋转 + 火焰)"""
	
	# 强制设置3秒冷却
	melee_cooldowns[weapon_id] = 3.0

	# 伤害计算
	var final_damage = config.base_damage * stats.might * 8.0 

	# 获取攻击方向
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - player.global_position).normalized()

	# === 1. 攻击动画 ===
	var player_sprite = player.get_node_or_null("Sprite2D")
	if player_sprite: player_sprite.visible = false
	
	var attack_sprite = Sprite2D.new()
	attack_sprite.texture = load("res://assets/attack.png")
	attack_sprite.hframes = 2
	attack_sprite.frame = melee_attack_frame
	melee_attack_frame = (melee_attack_frame + 1) % 2
	attack_sprite.scale = Vector2(0.1, 0.1)
	attack_sprite.global_position = player.global_position
	if direction.x < 0: attack_sprite.flip_h = true
	get_tree().current_scene.add_child(attack_sprite)
	
	get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(attack_sprite): attack_sprite.queue_free()
		if is_instance_valid(player_sprite): player_sprite.visible = true
	)

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
	# 使用默认白色方块如果没图
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
	get_tree().create_timer(1.0).timeout.connect(func(): particles.queue_free())

	# === 3. 伤害区域 ===
	var attack_area = Area2D.new()
	attack_area.global_position = player.global_position
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 100.0
	collision.shape = shape
	attack_area.add_child(collision)
	attack_area.collision_layer = 0
	attack_area.collision_mask = 4 
	get_tree().current_scene.add_child(attack_area)

	# 伤害检测
	await get_tree().process_frame
	
	var hit_enemies = attack_area.get_overlapping_bodies()
	var first_hit = true
	
	if hit_enemies.size() > 0:
		# === 4. 打击感核心：定帧 (Hit Stop) ===
		Engine.time_scale = 0.05
		get_tree().create_timer(0.1, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
		
		# 屏幕大震动
		SignalBus.screen_shake.emit(0.4, 20.0)
		
		for body in hit_enemies:
			if body.is_in_group("enemy"):
				if body.has_method("apply_knockback"):
					var knockback_dir = (body.global_position - player.global_position).normalized()
					var force = 5000.0 # 暴力击飞
					
					# === 5. 第一个敌人特效：旋转 + 超级击飞 ===
					if first_hit:
						force = 10000.0 # 超级暴力击飞
						# 旋转动画
						if body.get_node_or_null("Sprite2D"):
							var tween = create_tween()
							# 0.5秒内转5圈
							tween.tween_property(body.get_node("Sprite2D"), "rotation", PI * 10, 0.5).as_relative()
						first_hit = false
					
					body.apply_knockback(knockback_dir, force)
				
				if body.has_method("take_damage"):
					body.take_damage(final_damage)

	attack_area.queue_free()


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