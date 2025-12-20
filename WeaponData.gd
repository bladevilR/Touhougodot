extends Node
class_name WeaponData

# WeaponData - 武器配置数据

# 武器配置类
class WeaponConfig:
	var id: String
	var weapon_name: String
	var description: String
	var max_level: int
	var cooldown_max: float  # 以秒为单位
	var base_damage: float
	var weapon_type: int  # GameConstants.WeaponType
	var exclusive_to: int = -1  # -1表示通用武器

	# 武器特性
	var projectile_count: int = 1
	var projectile_speed: float = 300.0
	var projectile_lifetime: float = 3.0
	var projectile_spread: float = 0.3  # 扇形散射角度
	var homing_strength: float = 0.0
	var penetration: int = 1
	var bounce_count: int = 0
	var explosion_radius: float = 0.0
	var element_type: int = -1  # GameConstants.ElementType
	var knockback: float = 0.0

	# 特殊效果
	var is_orbital: bool = false
	var orbit_radius: float = 0.0
	var orbit_speed: float = 0.0
	var is_laser: bool = false
	var has_gravity: bool = false
	var is_spell_card: bool = false
	var on_hit_effect: String = ""  # 'heal', 'explode', 'burn', etc.

	func _init(wid: String, n: String, d: String, ml: int, cd: float, bd: float, wt: int):
		id = wid
		weapon_name = n
		description = d
		max_level = ml
		cooldown_max = cd
		base_damage = bd
		weapon_type = wt

# 武器升级选项类
class WeaponUpgradeChoice:
	var id: String
	var weapon_id: String
	var tier: int
	var upgrade_name: String
	var description: String
	var icon: String

	func _init(uid: String, wid: String, t: int, n: String, d: String, i: String):
		id = uid
		weapon_id = wid
		tier = t
		upgrade_name = n
		description = d
		icon = i

# 武器融合配方类
class WeaponRecipe:
	var id: String
	var recipe_name: String
	var description: String
	var requires: Array  # [String, String] - 两个武器ID
	var result_weapon_id: String
	var icon: String

	func _init(rid: String, n: String, d: String, req: Array, result: String, i: String):
		id = rid
		recipe_name = n
		description = d
		requires = req
		result_weapon_id = result
		icon = i

# 所有武器数据
static var WEAPONS = {}

# 所有武器升级树
static var WEAPON_UPGRADE_TREES = {}

# 所有武器融合配方
static var WEAPON_RECIPES = []

static func initialize():
	WEAPONS.clear()
	# WEAPON_UPGRADE_TREES and WEAPON_RECIPES are initialized in separate functions but good to clear here if they were appended.
	# Since they are dictionaries/assigned directly, it might be fine, but let's be safe if we change logic later.
	# Actually upgrade trees are assigned via key, so overwrite is fine. Recipes are array, need clear.
	# Wait, _initialize_weapon_recipes assigns a new array `WEAPON_RECIPES = [...]`, so it's fine.
	
	# ==================== 初始武器 (6个) ====================

	# 1. 博丽符纸 (灵梦专属)
	var homing_amulet = WeaponConfig.new(
		"homing_amulet",
		"博丽符纸",
		"连续射出3张符纸，自动追踪最近的敌人。",
		8, 1.0, 15.0, GameConstants.WeaponType.PROJECTILE
	)
	homing_amulet.exclusive_to = GameConstants.CharacterId.REIMU
	homing_amulet.projectile_count = 3
	homing_amulet.projectile_speed = 250.0
	homing_amulet.homing_strength = 0.1
	homing_amulet.projectile_lifetime = 3.0
	WEAPONS["homing_amulet"] = homing_amulet

	# 2. 星符 (魔理沙专属)
	var star_dust = WeaponConfig.new(
		"star_dust",
		"星符",
		"向最近的敌人自动发射星星弹幕。",
		8, 0.5, 12.0, GameConstants.WeaponType.PROJECTILE
	)
	star_dust.exclusive_to = GameConstants.CharacterId.MARISA
	star_dust.projectile_count = 3
	star_dust.projectile_speed = 400.0
	star_dust.projectile_lifetime = 1.0
	WEAPONS["star_dust"] = star_dust

	# 3. 凤凰羽衣 (妹红专属) - 已移除
	# var phoenix_wings = WeaponConfig.new(
	# 	"phoenix_wings",
	# 	"凤凰羽衣",
	# 	"环绕自身的火焰圆环，持续造成伤害。",
	# 	8, 0.2, 8.0, GameConstants.WeaponType.ORBITAL
	# )
	# phoenix_wings.exclusive_to = GameConstants.CharacterId.MOKOU
	# phoenix_wings.is_orbital = true
	# phoenix_wings.orbit_radius = 0.0  # 0表示跟随玩家中心
	# phoenix_wings.orbit_speed = 0.0  # 不旋转
	# phoenix_wings.projectile_count = 1  # 只有一个光环
	# phoenix_wings.penetration = 999
	# phoenix_wings.element_type = GameConstants.ElementType.FIRE
	# WEAPONS["phoenix_wings"] = phoenix_wings

	# 3.5 火鸟重拳 (妹红重攻击 - 右键)
	var mokou_kick_heavy = WeaponConfig.new(
		"mokou_kick_heavy",
		"火鸟重拳",
		"右键：向前方踢出强力火焰，击飞敌人。",
		20, 0.8, 80.0, GameConstants.WeaponType.MELEE
	)
	mokou_kick_heavy.exclusive_to = GameConstants.CharacterId.MOKOU
	mokou_kick_heavy.projectile_count = 1
	mokou_kick_heavy.projectile_speed = 0.0
	mokou_kick_heavy.projectile_lifetime = 0.3
	mokou_kick_heavy.penetration = 999
	mokou_kick_heavy.element_type = GameConstants.ElementType.FIRE
	mokou_kick_heavy.knockback = 120.0
	mokou_kick_heavy.projectile_spread = 0.6
	mokou_kick_heavy.explosion_radius = 150.0
	WEAPONS["mokou_kick_heavy"] = mokou_kick_heavy

	# 3.6 火鸟轻拳 (妹红普攻 - 左键)
	var mokou_kick_light = WeaponConfig.new(
		"mokou_kick_light",
		"火鸟连踢",
		"左键：快速扫腿，产生火焰弧光。",
		20, 0.2, 15.0, GameConstants.WeaponType.MELEE
	)
	mokou_kick_light.exclusive_to = GameConstants.CharacterId.MOKOU
	mokou_kick_light.projectile_count = 1
	mokou_kick_light.projectile_speed = 0.0
	mokou_kick_light.projectile_lifetime = 0.15
	mokou_kick_light.penetration = 999
	mokou_kick_light.element_type = GameConstants.ElementType.FIRE
	mokou_kick_light.knockback = 20.0
	mokou_kick_light.projectile_spread = 2.0 # 宽弧形
	mokou_kick_light.explosion_radius = 120.0
	WEAPONS["mokou_kick_light"] = mokou_kick_light

	# 4. 银制飞刀 (咲夜专属)
	var knives = WeaponConfig.new(
		"knives",
		"银制飞刀",
		"投掷飞刀，撞墙必定反弹1次。",
		8, 0.6, 10.0, GameConstants.WeaponType.PROJECTILE
	)
	knives.exclusive_to = GameConstants.CharacterId.SAKUYA
	knives.projectile_speed = 500.0
	knives.projectile_lifetime = 3.0
	knives.bounce_count = 1
	WEAPONS["knives"] = knives

	# 5. 刚欲汤勺 (尤魔专属)
	var spoon = WeaponConfig.new(
		"spoon",
		"刚欲汤勺",
		"扇形近战挥舞，击退敌人。",
		8, 1.0, 40.0, GameConstants.WeaponType.PROJECTILE
	)
	spoon.exclusive_to = GameConstants.CharacterId.YUMA
	spoon.projectile_count = 5
	spoon.projectile_speed = 0.0  # 近战，不移动
	spoon.projectile_lifetime = 0.33  # 20帧约0.33秒
	spoon.penetration = 999
	spoon.knockback = 15.0
	spoon.on_hit_effect = "heal"
	WEAPONS["spoon"] = spoon

	# 6. 本我地雷 (恋恋专属)
	var mines = WeaponConfig.new(
		"mines",
		"本我地雷",
		"每隔2秒在随机位置自动生成地雷。",
		8, 2.0, 60.0, GameConstants.WeaponType.SPECIAL
	)
	mines.exclusive_to = GameConstants.CharacterId.KOISHI
	mines.projectile_count = 2
	mines.projectile_lifetime = 20.0  # 20秒
	mines.explosion_radius = 100.0
	mines.on_hit_effect = "explode"
	WEAPONS["mines"] = mines

	# ==================== 通用武器池 (6个) ====================

	# 7. 鸡尾酒瓶
	var molotov = WeaponConfig.new(
		"molotov",
		"鸡尾酒瓶",
		"投掷火瓶，落地产生火焰区域。自带火属性。",
		8, 2.5, 20.0, GameConstants.WeaponType.PROJECTILE
	)
	molotov.projectile_speed = 300.0
	molotov.projectile_lifetime = 1.67
	molotov.explosion_radius = 80.0
	molotov.element_type = GameConstants.ElementType.FIRE
	molotov.has_gravity = true
	molotov.bounce_count = 1
	molotov.on_hit_effect = "burn"
	WEAPONS["molotov"] = molotov

	# 8. 恋符·激光
	var laser = WeaponConfig.new(
		"laser",
		"恋符·激光",
		"瞬发直线激光，穿透所有敌人。",
		8, 4.0, 5.0, GameConstants.WeaponType.LASER
	)
	laser.is_laser = true
	laser.projectile_speed = 1000.0
	laser.projectile_lifetime = 0.5
	laser.penetration = 999
	WEAPONS["laser"] = laser

	# 9. 阴阳玉
	var yin_yang_orb = WeaponConfig.new(
		"yin_yang_orb",
		"阴阳玉",
		"巨大的弹跳球，撞墙疯狂反弹。",
		8, 1.5, 35.0, GameConstants.WeaponType.PROJECTILE
	)
	yin_yang_orb.projectile_speed = 350.0
	yin_yang_orb.projectile_lifetime = 5.0
	yin_yang_orb.penetration = 100
	yin_yang_orb.bounce_count = 10
	yin_yang_orb.knockback = 10.0
	WEAPONS["yin_yang_orb"] = yin_yang_orb

	# 10. 上海人形 - 暂时注释（未完成实现）
	# var shanghai_doll = WeaponConfig.new(
	# 	"shanghai_doll",
	# 	"上海人形",
	# 	"召唤3个小人偶自动索敌攻击。",
	# 	8, 0.8, 8.0, GameConstants.WeaponType.PROJECTILE
	# )
	# shanghai_doll.projectile_count = 3
	# shanghai_doll.projectile_speed = 250.0
	# shanghai_doll.homing_strength = 0.15
	# shanghai_doll.projectile_lifetime = 2.0
	# WEAPONS["shanghai_doll"] = shanghai_doll

	# 11. 天狗团扇
	var tengu_fan = WeaponConfig.new(
		"tengu_fan",
		"天狗团扇",
		"吹出强风，击退敌人但不造成伤害。",
		8, 3.0, 0.0, GameConstants.WeaponType.PROJECTILE
	)
	tengu_fan.projectile_count = 5
	tengu_fan.projectile_speed = 600.0
	tengu_fan.projectile_lifetime = 0.33
	tengu_fan.penetration = 999
	tengu_fan.knockback = 25.0
	WEAPONS["tengu_fan"] = tengu_fan

	# 12. 埴轮骑兵
	var haniwa = WeaponConfig.new(
		"haniwa",
		"埴轮骑兵",
		"召唤一排土偶齐步前进，充当移动墙壁。",
		8, 10.0, 10.0, GameConstants.WeaponType.PROJECTILE
	)
	haniwa.projectile_count = 5
	haniwa.projectile_speed = 100.0
	haniwa.projectile_lifetime = 5.0
	haniwa.penetration = 999
	haniwa.knockback = 8.0
	WEAPONS["haniwa"] = haniwa

	# 13. 博丽结界 (灵梦专属)
	var boundary = WeaponConfig.new(
		"boundary",
		"博丽结界",
		"展开巫女的结界，对范围内敌人持续造成伤害并减速。",
		8, 8.0, 3.0, GameConstants.WeaponType.PROJECTILE
	)
	boundary.exclusive_to = GameConstants.CharacterId.REIMU
	boundary.projectile_speed = 0.0
	boundary.projectile_lifetime = 5.0
	boundary.penetration = 999
	WEAPONS["boundary"] = boundary

	# ==================== 符卡武器 (融合后获得) ====================

	# 14. 梦想封印
	var dream_seal = WeaponConfig.new(
		"dream_seal",
		"梦想封印",
		"向全屏所有敌人发射追踪符咒，无法躲避！",
		8, 3.0, 80.0, GameConstants.WeaponType.PROJECTILE
	)
	dream_seal.is_spell_card = true
	dream_seal.projectile_count = 10
	dream_seal.projectile_speed = 400.0
	dream_seal.projectile_lifetime = 5.0
	dream_seal.homing_strength = 0.3
	dream_seal.penetration = 999
	WEAPONS["dream_seal"] = dream_seal

	# 15. Master Spark
	var master_spark = WeaponConfig.new(
		"master_spark",
		"Master Spark",
		"终极魔炮！超宽超长贯穿激光，持续5秒！",
		8, 10.0, 20.0, GameConstants.WeaponType.LASER
	)
	master_spark.is_spell_card = true
	master_spark.is_laser = true
	master_spark.projectile_speed = 1000.0
	master_spark.projectile_lifetime = 5.0
	master_spark.penetration = 999
	WEAPONS["master_spark"] = master_spark

	# 16. 凤凰涅槃
	var phoenix_rebirth = WeaponConfig.new(
		"phoenix_rebirth",
		"凤凰涅槃",
		"死亡时自动复活，并产生超大范围火焰爆炸！",
		8, 60.0, 500.0, GameConstants.WeaponType.PASSIVE
	)
	phoenix_rebirth.is_spell_card = true
	phoenix_rebirth.explosion_radius = 300.0
	phoenix_rebirth.element_type = GameConstants.ElementType.FIRE
	WEAPONS["phoenix_rebirth"] = phoenix_rebirth

	# 17. The World - 咲夜之世界
	var sakuyas_world = WeaponConfig.new(
		"sakuyas_world",
		"The World",
		"时停5秒，期间疯狂投掷100把飞刀！",
		8, 8.0, 30.0, GameConstants.WeaponType.SPECIAL
	)
	sakuyas_world.is_spell_card = true
	sakuyas_world.projectile_count = 100
	sakuyas_world.projectile_speed = 500.0
	sakuyas_world.projectile_lifetime = 5.0
	WEAPONS["sakuyas_world"] = sakuyas_world

	# ==================== 武器升级树 ====================
	_initialize_upgrade_trees()

	# ==================== 武器融合配方 ====================
	_initialize_weapon_recipes()

static func _initialize_upgrade_trees():
	WEAPON_UPGRADE_TREES.clear()

	# --- 阴阳玉 (Yin Yang Orb) - 保留 ---
	WEAPON_UPGRADE_TREES["yin_yang_orb"] = [
		# Tier 1
		WeaponUpgradeChoice.new("orb_size", "yin_yang_orb", 1, "强化阴阳", "伤害 +150%，穿透 +50", "⚫⚪"),
		WeaponUpgradeChoice.new("orb_gravity", "yin_yang_orb", 1, "重力控制", "可手动控制抛物线", "🌀"),
		WeaponUpgradeChoice.new("orb_multi", "yin_yang_orb", 1, "双子阴阳", "同时投掷两个", "♊"),
		# Tier 2
		WeaponUpgradeChoice.new("orb_seeking", "yin_yang_orb", 2, "寻敌阴阳", "落地时追踪最近敌人", "🧲"),
		WeaponUpgradeChoice.new("orb_crush", "yin_yang_orb", 2, "碾压重击", "命中眩晕敌人 3 秒", "😵"),
		WeaponUpgradeChoice.new("orb_bounce_ground", "yin_yang_orb", 2, "地面弹跳", "落地后继续弹跳 5 次", "🏐"),
		# Tier 3
		WeaponUpgradeChoice.new("orb_meteor", "yin_yang_orb", 3, "阴阳天降", "召唤 10 个小阴阳玉从天而降", "☄️"),
		WeaponUpgradeChoice.new("orb_vortex", "yin_yang_orb", 3, "阴阳漩涡", "落地创造吸引敌人的旋涡", "🌊"),
		WeaponUpgradeChoice.new("orb_return", "yin_yang_orb", 3, "回旋阴阳", "落地后飞回玩家", "🔄")
	]

	# --- 妹红：左键蓄力 (Charged Fire Ring) ---
	WEAPON_UPGRADE_TREES["charged_fire_ring"] = [
		# Tier 1
		WeaponUpgradeChoice.new("cfr_quick", "charged_fire_ring", 1, "快速蓄力", "蓄力速度 +30%，点按伤害 +20%", "⚡"),
		WeaponUpgradeChoice.new("cfr_burn", "charged_fire_ring", 1, "灼热气息", "燃烧伤害 +50%，持续时间 +2秒", "🔥"),
		# Tier 2
		WeaponUpgradeChoice.new("cfr_big", "charged_fire_ring", 2, "巨大火球", "满蓄力火球体积 +50%，伤害 +30%", "☄️"),
		WeaponUpgradeChoice.new("cfr_trail", "charged_fire_ring", 2, "烈焰路径", "火球飞行时留下持续燃烧的路径", "🛤️"),
		# Tier 3
		WeaponUpgradeChoice.new("cfr_inferno", "charged_fire_ring", 3, "炼狱爆裂", "满蓄力命中产生大爆炸，留下持久火海", "💥")
	]

	# --- 妹红：右键重击 (Heavy Kick) ---
	WEAPON_UPGRADE_TREES["mokou_kick_heavy"] = [
		# Tier 1
		WeaponUpgradeChoice.new("mkh_force", "mokou_kick_heavy", 1, "强力踢击", "击飞力度 +50%，伤害 +30%", "🦶"),
		WeaponUpgradeChoice.new("mkh_cd", "mokou_kick_heavy", 1, "冷却缩减", "重击冷却时间减少 1秒", "⏱️"),
		# Tier 2
		WeaponUpgradeChoice.new("mkh_shockwave", "mokou_kick_heavy", 2, "震荡波", "攻击范围扩大 50%，附带减速", "🌊"),
		WeaponUpgradeChoice.new("mkh_stun", "mokou_kick_heavy", 2, "粉碎踢", "击飞的敌人眩晕 2秒", "😵"),
		# Tier 3
		WeaponUpgradeChoice.new("mkh_chain", "mokou_kick_heavy", 3, "连环爆破", "被击飞的敌人撞到其他单位会产生爆炸", "💣")
	]

	# --- 妹红：空格技能 (Skill Mokou) ---
	WEAPON_UPGRADE_TREES["skill_mokou"] = [
		# Tier 1
		WeaponUpgradeChoice.new("skm_cost", "skill_mokou", 1, "节能模式", "技能生命消耗减少 50%", "💚"),
		WeaponUpgradeChoice.new("skm_dist", "skill_mokou", 1, "迅捷之鸟", "突进距离 +30%，速度 +30%", "💨"),
		# Tier 2
		WeaponUpgradeChoice.new("skm_wall", "skill_mokou", 2, "烈焰之墙", "火墙持续时间翻倍，伤害 +50%", "🔥"),
		WeaponUpgradeChoice.new("skm_invul", "skill_mokou", 2, "不死之身", "突进后无敌时间延长 1秒", "🛡️"),
		# Tier 3
		WeaponUpgradeChoice.new("skm_rebirth", "skill_mokou", 3, "凤凰涅槃", "落地爆炸伤害翻倍，并治疗自身 20% 已损生命", "🌟")
	]

static func _initialize_weapon_recipes():
	WEAPON_RECIPES = [
		WeaponRecipe.new(
			"dream_seal_fusion",
			"梦想封印",
			"博丽符纸 + 阴阳玉 = 灵梦的最强符卡！全屏追踪符咒。",
			["homing_amulet", "yin_yang_orb"],
			"dream_seal",
			"✨"
		),
		WeaponRecipe.new(
			"master_spark_fusion",
			"恋符·Master Spark",
			"星符 + 激光 = 魔理沙的终极魔炮！超巨型贯穿激光。",
			["star_dust", "laser"],
			"master_spark",
			"🌟"
		),
		WeaponRecipe.new(
			"phoenix_rebirth_fusion",
			"凤凰涅槃",
			"凤凰羽衣 + 鸡尾酒瓶 = 妹红的永恒业火！复活后触发超大爆炸。",
			["phoenix_wings", "molotov"],
			"phoenix_rebirth",
			"🔥"
		),
		WeaponRecipe.new(
			"sakuyas_world_fusion",
			"The World - 咲夜之世界",
			"银制飞刀 + 时停 = 咲夜的时空掌控！时停期间狂飞刀。",
			["knives", "time_stop"],
			"sakuyas_world",
			"⏰"
		)
	]

static func get_weapon(weapon_id: String) -> WeaponConfig:
	if WEAPONS.has(weapon_id):
		return WEAPONS[weapon_id]
	return null

static func get_upgrade_tree(weapon_id: String) -> Array:
	if WEAPON_UPGRADE_TREES.has(weapon_id):
		return WEAPON_UPGRADE_TREES[weapon_id]
	return []

static func get_upgrades_by_tier(weapon_id: String, tier: int) -> Array:
	var upgrades = get_upgrade_tree(weapon_id)
	var result = []
	for upgrade in upgrades:
		if upgrade.tier == tier:
			result.append(upgrade)
	return result

static func get_all_recipes() -> Array:
	return WEAPON_RECIPES

static func can_fuse_weapons(weapon_id1: String, weapon_id2: String) -> WeaponRecipe:
	for recipe in WEAPON_RECIPES:
		var req = recipe.requires
		if (req[0] == weapon_id1 and req[1] == weapon_id2) or \
		   (req[0] == weapon_id2 and req[1] == weapon_id1):
			return recipe
	return null
