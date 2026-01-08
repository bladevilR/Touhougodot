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

# ==================== 技能数据库 ====================
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
	var phoenix_dash = SkillDataRecord.new()
	phoenix_dash.id = "mokou_phoenix_dash"
	phoenix_dash.name = "凤凰之翼"
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
	var immortal_flame = SkillDataRecord.new()
	immortal_flame.id = "mokou_immortal_flame"
	immortal_flame.name = "不死之炎"
	immortal_flame.description = "点燃不灭之火，持续恢复生命值并免疫控制效果"
	immortal_flame.skill_type = SkillType.ACTIVE
	immortal_flame.damage_type = DamageType.FIRE
	immortal_flame.target_type = TargetType.SELF
	immortal_flame.base_damage = 0.0
	immortal_flame.cooldown = 20.0
	immortal_flame.duration = 5.0
	_skills[immortal_flame.id] = immortal_flame

static func _register_reimu_skills() -> void:
	# 博丽灵梦 - 示例技能
	var dummy_skill = SkillDataRecord.new()
	dummy_skill.id = "reimu_skill_1"
	dummy_skill.name = "灵梦技能"
	dummy_skill.description = "博丽灵梦的示例技能"
	dummy_skill.skill_type = SkillType.ACTIVE
	_skills[dummy_skill.id] = dummy_skill

static func _register_marisa_skills() -> void:
	# 雾雨魔理沙 - 示例技能
	var dummy_skill = SkillDataRecord.new()
	dummy_skill.id = "marisa_skill_1"
	dummy_skill.name = "魔理沙技能"
	dummy_skill.description = "雾雨魔理沙的示例技能"
	dummy_skill.skill_type = SkillType.ACTIVE
	_skills[dummy_skill.id] = dummy_skill

static func _register_sakuya_skills() -> void:
	# 十六夜咲夜 - 示例技能
	var dummy_skill = SkillDataRecord.new()
	dummy_skill.id = "sakuya_skill_1"
	dummy_skill.name = "咲夜技能"
	dummy_skill.description = "十六夜咲夜的示例技能"
	dummy_skill.skill_type = SkillType.ACTIVE
	_skills[dummy_skill.id] = dummy_skill

# ==================== 公共接口 ====================
static func get_skill(skill_id: String):
	initialize()
	return _skills.get(skill_id)

static func get_all_skills() -> Dictionary:
	initialize()
	return _skills.duplicate()

static func get_skills_by_type(skill_type: int) -> Array:
	initialize()
	var result: Array = []
	for skill in _skills.values():
		if skill.skill_type == skill_type:
			result.append(skill)
	return result

static func get_character_skills(character_id: String) -> Array:
	initialize()
	var result: Array = []
	var prefix = character_id + "_"
	for key in _skills:
		if key.begins_with(prefix):
			result.append(_skills[key])
	return result
