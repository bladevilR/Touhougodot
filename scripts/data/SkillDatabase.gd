extends RefCounted
class_name SkillDatabase

## 技能数据库 - 存储所有技能的配置数据
## 便于扩展和修改技能属性

# ==================== 技能类型 ====================
enum SkillType {
	ACTIVE,     # 主动技能
	PASSIVE,    # 被动技能
	ULTIMATE,   # 终极技能
	BOND,       # 羁绊技能
}

enum DamageType {
	PHYSICAL,   # 物理伤害
	FIRE,       # 火焰伤害
	ICE,        # 冰冻伤害
	LIGHTNING,  # 雷电伤害
	POISON,     # 毒素伤害
	HOLY,       # 神圣伤害
}

enum TargetType {
	SELF,       # 自身
	SINGLE,     # 单体
	AOE,        # 范围
	LINE,       # 直线
	CONE,       # 锥形
	GLOBAL,     # 全场
}

# ==================== 技能数据结构 ====================
class SkillData:
	var id: String
	var name: String
	var description: String
	var icon_path: String

	var skill_type: int = SkillType.ACTIVE
	var damage_type: int = DamageType.PHYSICAL
	var target_type: int = TargetType.AOE

	var base_damage: float = 0.0
	var cooldown: float = 5.0
	var mana_cost: float = 0.0
	var range: float = 100.0
	var radius: float = 50.0
	var duration: float = 0.0
	var cast_time: float = 0.0

	var effects: Array = []  # 附加效果列表

	func _init(p_id: String = "", p_name: String = ""):
		id = p_id
		name = p_name

# ==================== 技能�� ====================
static var _skills: Dictionary = {}
static var _initialized: bool = false

static func initialize() -> void:
	if _initialized:
		return
	_initialized = true

	# 藤原妹红技能
	_register_mokou_skills()

	# 博丽灵梦技能
	_register_reimu_skills()

	# 雾雨魔理沙技能
	_register_marisa_skills()

	# 十六夜咲夜技能
	_register_sakuya_skills()

static func _register_mokou_skills() -> void:
	# 凤凰之翼 - 火焰冲刺
	var phoenix_dash = SkillData.new("mokou_phoenix_dash", "凤凰之翼")
	phoenix_dash.description = "化身火焰凤凰向前冲刺，对路径上的敌人造成火焰伤害"
	phoenix_dash.skill_type = SkillType.ACTIVE
	phoenix_dash.damage_type = DamageType.FIRE
	phoenix_dash.target_type = TargetType.LINE
	phoenix_dash.base_damage = 50.0
	phoenix_dash.cooldown = 8.0
	phoenix_dash.range = 300.0
	phoenix_dash.effects = ["burn", "knockback"]
	_skills[phoenix_dash.id] = phoenix_dash

	# 不死之炎 - 自我恢复
	var immortal_flame = SkillData.new("mokou_immortal_flame", "不死之炎")
	immortal_flame.description = "点燃不灭之火，持续恢复生命值并免疫控制效果"
	immortal_flame.skill_type = SkillType.ACTIVE
	immortal_flame.damage_type = DamageType.FIRE
	immortal_flame.target_type = TargetType.SELF
	immortal_flame.base_damage = 0.0
	immortal_flame.cooldown = 20.0
	immortal_flame.duration = 5.0
	immortal_flame.effects = ["heal_over_time", "cc_immunity", "fire_aura"]
	_skills[immortal_flame.id] = immortal_flame

	# 火鸟 - 范围火焰
	var firebird = SkillData.new("mokou_firebird", "火鸟")
	firebird.description = "召唤火鸟攻击周围敌人"
	firebird.skill_type = SkillType.ACTIVE
	firebird.damage_type = DamageType.FIRE
	firebird.target_type = TargetType.AOE
	firebird.base_damage = 35.0
	firebird.cooldown = 12.0
	firebird.radius = 150.0
	firebird.effects = ["burn"]
	_skills[firebird.id] = firebird

	# 蓬莱之人 - 被动复活
	var hourai_human = SkillData.new("mokou_hourai_human", "蓬莱之人")
	hourai_human.description = "死亡后可复活一次，复活时爆发火焰"
	hourai_human.skill_type = SkillType.PASSIVE
	hourai_human.damage_type = DamageType.FIRE
	hourai_human.target_type = TargetType.SELF
	hourai_human.effects = ["revive", "explosion_on_revive"]
	_skills[hourai_human.id] = hourai_human

static func _register_reimu_skills() -> void:
	# 梦想封印
	var fantasy_seal = SkillData.new("reimu_fantasy_seal", "梦想封印")
	fantasy_seal.description = "释放多个追踪光弹攻击敌人"
	fantasy_seal.skill_type = SkillType.ACTIVE
	fantasy_seal.damage_type = DamageType.HOLY
	fantasy_seal.target_type = TargetType.AOE
	fantasy_seal.base_damage = 20.0
	fantasy_seal.cooldown = 10.0
	fantasy_seal.radius = 200.0
	fantasy_seal.effects = ["homing"]
	_skills[fantasy_seal.id] = fantasy_seal

	# 博丽护符
	var hakurei_amulet = SkillData.new("reimu_hakurei_amulet", "博丽护符")
	hakurei_amulet.description = "投掷符咒攻击敌人"
	hakurei_amulet.skill_type = SkillType.ACTIVE
	hakurei_amulet.damage_type = DamageType.HOLY
	hakurei_amulet.target_type = TargetType.SINGLE
	hakurei_amulet.base_damage = 15.0
	hakurei_amulet.cooldown = 3.0
	hakurei_amulet.range = 400.0
	_skills[hakurei_amulet.id] = hakurei_amulet

	# 阴阳玉
	var yin_yang_orb = SkillData.new("reimu_yin_yang_orb", "阴阳玉")
	yin_yang_orb.description = "召唤阴阳玉环绕自身，接触敌人造成伤害"
	yin_yang_orb.skill_type = SkillType.ACTIVE
	yin_yang_orb.damage_type = DamageType.HOLY
	yin_yang_orb.target_type = TargetType.SELF
	yin_yang_orb.base_damage = 10.0
	yin_yang_orb.cooldown = 15.0
	yin_yang_orb.duration = 8.0
	yin_yang_orb.effects = ["orbital"]
	_skills[yin_yang_orb.id] = yin_yang_orb

static func _register_marisa_skills() -> void:
	# 魔炮 - 大威力直线攻击
	var master_spark = SkillData.new("marisa_master_spark", "魔炮")
	master_spark.description = "释放强力的魔法激光，贯穿所有敌人"
	master_spark.skill_type = SkillType.ULTIMATE
	master_spark.damage_type = DamageType.LIGHTNING
	master_spark.target_type = TargetType.LINE
	master_spark.base_damage = 100.0
	master_spark.cooldown = 30.0
	master_spark.range = 800.0
	master_spark.duration = 2.0
	master_spark.effects = ["piercing", "stun"]
	_skills[master_spark.id] = master_spark

	# 星尘
	var stardust = SkillData.new("marisa_stardust", "星尘")
	stardust.description = "撒下魔法星尘，对范围内敌人造成伤害"
	stardust.skill_type = SkillType.ACTIVE
	stardust.damage_type = DamageType.LIGHTNING
	stardust.target_type = TargetType.AOE
	stardust.base_damage = 25.0
	stardust.cooldown = 8.0
	stardust.radius = 120.0
	_skills[stardust.id] = stardust

static func _register_sakuya_skills() -> void:
	# 时停 - 暂停时间
	var time_stop = SkillData.new("sakuya_time_stop", "时停")
	time_stop.description = "暂停时间，所有敌人无法移动"
	time_stop.skill_type = SkillType.ULTIMATE
	time_stop.damage_type = DamageType.PHYSICAL
	time_stop.target_type = TargetType.GLOBAL
	time_stop.cooldown = 40.0
	time_stop.duration = 5.0
	time_stop.effects = ["time_stop"]
	_skills[time_stop.id] = time_stop

	# 飞刀
	var throwing_knives = SkillData.new("sakuya_throwing_knives", "飞刀")
	throwing_knives.description = "投掷多把飞刀攻击敌人"
	throwing_knives.skill_type = SkillType.ACTIVE
	throwing_knives.damage_type = DamageType.PHYSICAL
	throwing_knives.target_type = TargetType.CONE
	throwing_knives.base_damage = 12.0
	throwing_knives.cooldown = 5.0
	throwing_knives.range = 300.0
	_skills[throwing_knives.id] = throwing_knives

# ==================== 公共接口 ====================
static func get_skill(skill_id: String) -> SkillData:
	initialize()
	return _skills.get(skill_id)

static func get_all_skills() -> Dictionary:
	initialize()
	return _skills.duplicate()

static func get_skills_by_type(skill_type: int) -> Array[SkillData]:
	initialize()
	var result: Array[SkillData] = []
	for skill in _skills.values():
		if skill.skill_type == skill_type:
			result.append(skill)
	return result

static func get_character_skills(character_id: String) -> Array[SkillData]:
	initialize()
	var result: Array[SkillData] = []
	var prefix = character_id + "_"
	for key in _skills:
		if key.begins_with(prefix):
			result.append(_skills[key])
	return result
