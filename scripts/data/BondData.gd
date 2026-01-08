extends Node
class_name BondData

# BondData - 羁绊角色/支援角色系统

# 主动技能配置
class ActiveSkill:
	var skill_name: String
	var skill_type: String        # clear_bullets, laser, ignite, timestop, absorb, stealth
	var duration: float           # 持续时间（帧数）
	var damage: float             # 伤害值
	var invulnerable: bool        # 是否无敌

	func _init(name: String, type: String, dur: float = 0.0, dmg: float = 0.0, invul: bool = false):
		skill_name = name
		skill_type = type
		duration = dur
		damage = dmg
		invulnerable = invul

# 物理修正器配置（被动技能）
class PhysicsModifier:
	var modifier_name: String
	var modifier_type: String     # bounce, mass, resurrect, delay, pull, phase
	var bounce_bonus: int         # 额外反弹次数
	var homing_after_bounce: bool # 反弹后追踪
	var mass_multiplier: float    # 质量倍率
	var size_multiplier: float    # 大小倍率
	var resurrect_on_destroy: bool # 销毁时复活
	var delay_time: int           # 延迟时间（帧数）
	var pull_force: float         # 拉力
	var phase_chance: float       # 相位穿透概率

	func _init(name: String, type: String):
		modifier_name = name
		modifier_type = type
		bounce_bonus = 0
		homing_after_bounce = false
		mass_multiplier = 1.0
		size_multiplier = 1.0
		resurrect_on_destroy = false
		delay_time = 0
		pull_force = 0.0
		phase_chance = 0.0

# 羁绊角色配置
class BondCharacter:
	var id: String
	var char_name: String
	var description: String
	var icon: String
	var cooldown: float           # 冷却时间（帧数）
	var active_skill: ActiveSkill
	var physics_modifier: PhysicsModifier

	func _init(cid: String, name: String, desc: String, ic: String, cd: float, active: ActiveSkill, modifier: PhysicsModifier):
		id = cid
		char_name = name
		description = desc
		icon = ic
		cooldown = cd
		active_skill = active
		physics_modifier = modifier

# 所有羁绊角色数据
static var BOND_CHARACTERS = {}

static func initialize():
	# 博丽灵梦 - 梦想封印
	var reimu_active = ActiveSkill.new(
		"梦想封印",
		"clear_bullets",
		300.0,  # 5秒无敌
		0.0,
		true    # 无敌
	)
	var reimu_modifier = PhysicsModifier.new("境界弹射", "bounce")
	reimu_modifier.bounce_bonus = 1
	reimu_modifier.homing_after_bounce = true

	BOND_CHARACTERS["reimu"] = BondCharacter.new(
		"reimu",
		"博丽灵梦",
		"梦想封印 - 全屏消弹+无敌5秒 | 境界弹射：所有子弹反弹次数+1且反弹后微弱诱导",
		"🎀",
		300.0,  # 5秒冷却
		reimu_active,
		reimu_modifier
	)

	# 雾雨魔理沙 - 极限火花
	var marisa_active = ActiveSkill.new(
		"极限火花",
		"laser",
		0.0,
		300.0   # 300伤害
	)
	var marisa_modifier = PhysicsModifier.new("魔力质量", "mass")
	marisa_modifier.mass_multiplier = 1.5
	marisa_modifier.size_multiplier = 1.3

	BOND_CHARACTERS["marisa"] = BondCharacter.new(
		"marisa",
		"雾雨魔理沙",
		"极限火花 - 全屏粗大激光扫射(300伤害) | 魔力质量：子弹体积+30%、质量+50%",
		"⭐",
		360.0,  # 6秒冷却
		marisa_active,
		marisa_modifier
	)

	# 藤原妹红 - 凯风快晴
	var mokou_active = ActiveSkill.new(
		"凯风快晴",
		"ignite",
		0.0,
		80.0    # 80伤害+燃烧
	)
	var mokou_modifier = PhysicsModifier.new("弹幕复生", "resurrect")
	mokou_modifier.resurrect_on_destroy = true

	BOND_CHARACTERS["mokou"] = BondCharacter.new(
		"mokou",
		"藤原妹红",
		"凯风快晴 - 全屏瞬间点燃(80伤害+燃烧) | 弹幕复生：子弹销毁时原地复活一次",
		"🔥",
		420.0,  # 7秒冷却
		mokou_active,
		mokou_modifier
	)

	# 十六夜咲夜 - 杀人玩偶
	var sakuya_active = ActiveSkill.new(
		"杀人玩偶",
		"timestop",
		300.0,  # 5秒时停
		0.0
	)
	var sakuya_modifier = PhysicsModifier.new("延迟裂变", "delay")
	sakuya_modifier.delay_time = 18  # 0.3秒 = 18帧

	BOND_CHARACTERS["sakuya"] = BondCharacter.new(
		"sakuya",
		"十六夜咲夜",
		"杀人玩偶 - 全屏时停5秒后结算伤害 | 延迟裂变：子弹发射后悬停0.3秒再加速射出",
		"🔪",
		480.0,  # 8秒冷却
		sakuya_active,
		sakuya_modifier
	)

	# 饕餮尤魔 - 暴食盛宴
	var yuuma_active = ActiveSkill.new(
		"暴食盛宴",
		"absorb",
		0.0,
		50.0    # 回血50HP
	)
	var yuuma_modifier = PhysicsModifier.new("引力拉扯", "pull")
	yuuma_modifier.pull_force = 5.0

	BOND_CHARACTERS["yuuma"] = BondCharacter.new(
		"yuuma",
		"饕餮尤魔",
		"暴食盛宴 - 吞噬敌弹回血(+50HP) | 引力拉扯：子弹命中时将敌人向枪口拉扯",
		"🍴",
		540.0,  # 9秒冷却
		yuuma_active,
		yuuma_modifier
	)

	# 古明地恋 - 本我解放
	var koishi_active = ActiveSkill.new(
		"本我解放",
		"stealth",
		300.0,  # 5秒隐身
		0.0
	)
	var koishi_modifier = PhysicsModifier.new("无意识相位", "phase")
	koishi_modifier.phase_chance = 0.2  # 20%穿透

	BOND_CHARACTERS["koishi"] = BondCharacter.new(
		"koishi",
		"古明地恋",
		"本我解放 - 隐身、穿墙、移速翻倍(5秒) | 无意识相位：子弹20%概率无视地形和盾牌",
		"👁️",
		600.0,  # 10秒冷却
		koishi_active,
		koishi_modifier
	)

# 获取羁绊角色
static func get_bond_character(bond_id: String) -> BondCharacter:
	if BOND_CHARACTERS.has(bond_id):
		return BOND_CHARACTERS[bond_id]
	return null

# 获取所有羁绊角色ID
static func get_all_bond_ids() -> Array:
	return ["reimu", "marisa", "mokou", "sakuya", "yuuma", "koishi"]
