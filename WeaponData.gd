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
	# --- Reimu (博丽灵梦) Weapons ---
	WEAPON_UPGRADE_TREES["homing_amulet"] = [
		# Tier 1
		WeaponUpgradeChoice.new("amulet_count", "homing_amulet", 1, "散弹符阵", "同时发射数量 +2", "📜"),
		WeaponUpgradeChoice.new("amulet_homing", "homing_amulet", 1, "完美追踪", "追踪强度 +100%", "🎯"),
		WeaponUpgradeChoice.new("amulet_bounce", "homing_amulet", 1, "弹跳灵符", "符札可在敌人间弹跳", "↩️"),
		# Tier 2
		WeaponUpgradeChoice.new("amulet_split", "homing_amulet", 2, "阴阳裂变", "命中后分裂成两个追踪符", "✨"),
		WeaponUpgradeChoice.new("amulet_pierce", "homing_amulet", 2, "神灵穿透", "贯穿 +5，伤害 +30%", "💥"),
		WeaponUpgradeChoice.new("amulet_heal", "homing_amulet", 2, "净化灵符", "命中回复 1 HP", "💚"),
		# Tier 3
		WeaponUpgradeChoice.new("amulet_rain", "homing_amulet", 3, "梦想天生", "向所有敌人发射符札", "🌟"),
		WeaponUpgradeChoice.new("amulet_barrier", "homing_amulet", 3, "常驻结界", "符札环绕身体形成护盾", "🛡️"),
		WeaponUpgradeChoice.new("amulet_explosion", "homing_amulet", 3, "灵爆符咒", "命中产生小范围爆炸", "💢")
	]

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

	WEAPON_UPGRADE_TREES["boundary"] = [
		# Tier 1
		WeaponUpgradeChoice.new("boundary_size", "boundary", 1, "扩展结界", "范围 +50%", "📐"),
		WeaponUpgradeChoice.new("boundary_damage", "boundary", 1, "伤害结界", "伤害 +100%", "⚡"),
		WeaponUpgradeChoice.new("boundary_duration", "boundary", 1, "常驻结界", "持续时间 +100%", "⏱️"),
		# Tier 2
		WeaponUpgradeChoice.new("boundary_reflect", "boundary", 2, "反射护盾", "反弹敌方弹幕", "🪞"),
		WeaponUpgradeChoice.new("boundary_heal", "boundary", 2, "治愈结界", "每秒恢复 2 HP", "💚"),
		WeaponUpgradeChoice.new("boundary_slow", "boundary", 2, "时缓领域", "结界内敌人速度 -70%", "🐌"),
		# Tier 3
		WeaponUpgradeChoice.new("boundary_fantasy", "boundary", 3, "幻想封印", "持续时间内完全无敌", "✨"),
		WeaponUpgradeChoice.new("boundary_banish", "boundary", 3, "幻想崩坏", "结束时驱逐所有结界内敌人", "💫"),
		WeaponUpgradeChoice.new("boundary_double", "boundary", 3, "双重结界", "同时展开两层结界", "♾️")
	]

	# --- Marisa (雾雨魔理沙) Weapons ---
	WEAPON_UPGRADE_TREES["star_dust"] = [
		# Tier 1
		WeaponUpgradeChoice.new("star_count", "star_dust", 1, "星河漫天", "发射角度范围扩大", "🌠"),
		WeaponUpgradeChoice.new("star_speed", "star_dust", 1, "光速星尘", "弹速 +100%，伤害 +30%", "💫"),
		WeaponUpgradeChoice.new("star_pierce", "star_dust", 1, "穿星之力", "贯穿 +3", "🎯"),
		# Tier 2
		WeaponUpgradeChoice.new("star_homing", "star_dust", 2, "追星魔法", "星星获得追踪能力", "🧭"),
		WeaponUpgradeChoice.new("star_explode", "star_dust", 2, "星爆魔法", "命中产生小爆炸", "💥"),
		WeaponUpgradeChoice.new("star_rapid", "star_dust", 2, "速射星尘", "冷却时间 -50%", "⚡"),
		# Tier 3
		WeaponUpgradeChoice.new("star_galaxy", "star_dust", 3, "银河狂想", "向所有方向发射 16 颗星星", "🌌"),
		WeaponUpgradeChoice.new("star_comet", "star_dust", 3, "彗星魔法", "每颗星星留下持续伤害轨迹", "☄️"),
		WeaponUpgradeChoice.new("star_supernova", "star_dust", 3, "超新星", "星星消失时产生大爆炸", "💫")
	]

	WEAPON_UPGRADE_TREES["laser"] = [
		# Tier 1
		WeaponUpgradeChoice.new("laser_width", "laser", 1, "极宽火花", "激光宽度 +100%", "📏"),
		WeaponUpgradeChoice.new("laser_duration", "laser", 1, "持久火花", "持续时间 +100%", "⏱️"),
		WeaponUpgradeChoice.new("laser_damage", "laser", 1, "终极火花", "伤害 +200%", "⚡"),
		# Tier 2
		WeaponUpgradeChoice.new("laser_sweep", "laser", 2, "扫射火花", "激光缓慢旋转扫射", "🌀"),
		WeaponUpgradeChoice.new("laser_multi", "laser", 2, "三重火花", "同时发射三道激光", "🔱"),
		WeaponUpgradeChoice.new("laser_burn", "laser", 2, "灼烧火花", "命中施加持续燃烧", "🔥"),
		# Tier 3
		WeaponUpgradeChoice.new("laser_rainbow", "laser", 3, "七彩究极火花", "发射 7 道彩虹激光", "🌈"),
		WeaponUpgradeChoice.new("laser_penetrate", "laser", 3, "贯穿世界", "激光穿透地图边界", "🌍"),
		WeaponUpgradeChoice.new("laser_charge", "laser", 3, "蓄力火花", "冷却期间蓄力，伤害累加", "⚡")
	]

	# --- Mokou (藤原妹红) Weapons ---
	WEAPON_UPGRADE_TREES["phoenix_wings"] = [
		# Tier 1
		WeaponUpgradeChoice.new("wings_count", "phoenix_wings", 1, "六翼天使", "火焰羽翼数量 +2", "👼"),
		WeaponUpgradeChoice.new("wings_damage", "phoenix_wings", 1, "烈焰之翼", "伤害 +50%", "🔥"),
		WeaponUpgradeChoice.new("wings_range", "phoenix_wings", 1, "展翅高飞", "旋转范围 +50%", "📐"),
		# Tier 2
		WeaponUpgradeChoice.new("wings_shoot", "phoenix_wings", 2, "羽翼射击", "定期发射火焰弹", "🎯"),
		WeaponUpgradeChoice.new("wings_burn", "phoenix_wings", 2, "灼热光环", "接触敌人施加燃烧效果", "♨️"),
		WeaponUpgradeChoice.new("wings_shield", "phoenix_wings", 2, "火焰护盾", "抵挡敌方弹幕", "🛡️"),
		# Tier 3
		WeaponUpgradeChoice.new("wings_double", "phoenix_wings", 3, "双重旋转", "添加反向旋转的第二层", "♾️"),
		WeaponUpgradeChoice.new("wings_pull", "phoenix_wings", 3, "火焰漩涡", "吸引敌人和宝石", "🌀"),
		WeaponUpgradeChoice.new("wings_explode", "phoenix_wings", 3, "爆裂之翼", "击杀敌人触发爆炸", "💣")
	]
	
	WEAPON_UPGRADE_TREES["phoenix_claws"] = [] # 移除升级，改为固定技能

	# --- Sakuya (十六夜咲夜) Weapons ---
	WEAPON_UPGRADE_TREES["knives"] = [
		# Tier 1
		WeaponUpgradeChoice.new("knife_count", "knives", 1, "飞刀暴雨", "同时发射 4 把飞刀", "🔪"),
		WeaponUpgradeChoice.new("knife_bounce", "knives", 1, "完美弹射", "弹射次数 +3", "↩️"),
		WeaponUpgradeChoice.new("knife_speed", "knives", 1, "光速飞刀", "飞刀速度 +150%", "💨"),
		# Tier 2
		WeaponUpgradeChoice.new("knife_explode", "knives", 2, "爆裂飞刀", "命中产生小爆炸", "💥"),
		WeaponUpgradeChoice.new("knife_poison", "knives", 2, "剧毒涂层", "命中施加持续毒伤", "☠️"),
		WeaponUpgradeChoice.new("knife_freeze", "knives", 2, "冻结飞刀", "命中冻结敌人 2 秒", "❄️"),
		# Tier 3
		WeaponUpgradeChoice.new("knife_danmaku", "knives", 3, "飞刀弹幕", "全屏随机发射飞刀", "🌪️"),
		WeaponUpgradeChoice.new("knife_time", "knives", 3, "时停飞刀", "飞刀在空中静止 3 秒后同时射出", "⏰"),
		WeaponUpgradeChoice.new("knife_return", "knives", 3, "回旋飞刀", "飞刀最终返回玩家", "🔄")
	]

	# --- Yuma (饕餮尤魔) Weapons ---
	WEAPON_UPGRADE_TREES["spoon"] = [
		# Tier 1
		WeaponUpgradeChoice.new("spoon_size", "spoon", 1, "巨大勺子", "大小和伤害 +100%", "🥄"),
		WeaponUpgradeChoice.new("spoon_speed", "spoon", 1, "快速回收", "飞行和返回速度 +100%", "💨"),
		WeaponUpgradeChoice.new("spoon_multi", "spoon", 1, "三重勺子", "同时投掷 3 把勺子", "🍴"),
		# Tier 2
		WeaponUpgradeChoice.new("spoon_heal", "spoon", 2, "吞噬回复", "命中回复 3 HP", "💚"),
		WeaponUpgradeChoice.new("spoon_pull", "spoon", 2, "吸引勺子", "飞行时吸引敌人和宝石", "🧲"),
		WeaponUpgradeChoice.new("spoon_spin", "spoon", 2, "旋转勺子", "勺子高速旋转，伤害 +50%", "🌀"),
		# Tier 3
		WeaponUpgradeChoice.new("spoon_gluttony", "spoon", 3, "暴食之勺", "命中吞噬小型敌人", "👹"),
		WeaponUpgradeChoice.new("spoon_orbit", "spoon", 3, "勺子卫星", "勺子环绕身体后返回", "🛸"),
		WeaponUpgradeChoice.new("spoon_explosion", "spoon", 3, "爆裂回收", "返回时产生爆炸伤害", "💥")
	]

	# --- Koishi (古明地恋) Weapons ---
	WEAPON_UPGRADE_TREES["mines"] = [
		# Tier 1
		WeaponUpgradeChoice.new("mine_count", "mines", 1, "心灵陷阱", "每次放置 5 个地雷", "💚"),
		WeaponUpgradeChoice.new("mine_damage", "mines", 1, "爆炸之心", "爆炸伤害 +150%", "💥"),
		WeaponUpgradeChoice.new("mine_range", "mines", 1, "扩散地雷", "放置范围 +100%", "📐"),
		# Tier 2
		WeaponUpgradeChoice.new("mine_chain", "mines", 2, "连锁爆炸", "爆炸触发附近地雷", "⛓️"),
		WeaponUpgradeChoice.new("mine_pull", "mines", 2, "吸引地雷", "爆炸前吸引敌人", "🧲"),
		WeaponUpgradeChoice.new("mine_slow", "mines", 2, "减速陷阱", "爆炸减速敌人 5 秒", "🐌"),
		# Tier 3
		WeaponUpgradeChoice.new("mine_field", "mines", 3, "雷区封锁", "同时布置 20 个地雷", "☢️"),
		WeaponUpgradeChoice.new("mine_stealth", "mines", 3, "隐形地雷", "敌人无法看见地雷", "👻"),
		WeaponUpgradeChoice.new("mine_nuclear", "mines", 3, "核心爆炸", "超大范围巨额伤害", "☢️")
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
