extends RefCounted
class_name SkillDataRecord

## 技能数据记录 - 单独的数据类
var id: String = ""
var name: String = ""
var description: String = ""
var icon_path: String = ""

var skill_type: int = 0  # SkillDatabase.SkillType.ACTIVE
var damage_type: int = 0  # SkillDatabase.DamageType.PHYSICAL
var target_type: int = 2  # SkillDatabase.TargetType.AOE

var base_damage: float = 0.0
var cooldown: float = 5.0
var mana_cost: float = 0.0
var range: float = 100.0
var radius: float = 50.0
var duration: float = 0.0
var cast_time: float = 0.0

var effects: Array = []  # 附加效果列表
