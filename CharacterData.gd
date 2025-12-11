extends Node
class_name CharacterData

# CharacterData - 角色配置数据

# 角色物理属性
class CharacterPhysics:
	var mass: float                      # 质量（影响击退）
	var friction: float                  # 摩擦力
	var hitbox_scale: float              # 判定倍率
	var immune_to_oil_slow: bool         # 免疫油渍减速
	var heal_in_fire: bool               # 火中回血
	var immune_to_knockback: bool        # 免疫击退
	var can_pass_through_enemies: bool   # 穿过敌人

	func _init(m: float, f: float, h: float, oil: bool, fire: bool, kb: bool, can_pass: bool):
		mass = m
		friction = f
		hitbox_scale = h
		immune_to_oil_slow = oil
		heal_in_fire = fire
		immune_to_knockback = kb
		can_pass_through_enemies = can_pass

# 角色基础属性
class CharacterStats:
	var max_hp: float
	var hp: float
	var speed: float
	var might: float          # 伤害倍率
	var area: float           # 范围倍率
	var cooldown: float       # 冷却倍率
	var pickup_range: float   # 拾取范围
	var luck: float           # 幸运
	var armor: float          # 护甲
	var recovery: float       # 生命恢复/秒
	var revivals: int         # 复活次数

	func _init(mhp: float, s: float, m: float, a: float, cd: float, pr: float, l: float, ar: float, rec: float, rev: int):
		max_hp = mhp
		hp = mhp
		speed = s
		might = m
		area = a
		cooldown = cd
		pickup_range = pr
		luck = l
		armor = ar
		recovery = rec
		revivals = rev

# 角色配置
class Character:
	var id: int
	var char_name: String
	var title: String
	var description: String
	var color: Color
	var starting_weapon_id: String
	var stats: CharacterStats
	var physics: CharacterPhysics
	var scale: float

	func _init(cid: int, n: String, t: String, d: String, c: Color, w: String, s: CharacterStats, p: CharacterPhysics, sc: float = 0.05):
		id = cid
		char_name = n
		title = t
		description = d
		color = c
		starting_weapon_id = w
		stats = s
		physics = p
		scale = sc

# 所有角色数据
static var CHARACTERS = {}

static func initialize():
	CHARACTERS.clear()
	
	# 博丽灵梦 - 乐园的巫女
	CHARACTERS[GameConstants.CharacterId.REIMU] = Character.new(
		GameConstants.CharacterId.REIMU,
		"博丽灵梦",
		"乐园的巫女",
		"新手推荐。小判定，浮空特性，符札自动索敌。",
		Color("#e74c3c"),
		"homing_amulet",
		CharacterStats.new(90, 3.0, 1.0, 1.0, 1.0, 130, 1.0, 0, 0, 0),
		CharacterPhysics.new(10, 0.05, 0.8, true, false, false, false),
		0.05
	)

	# 藤原妹红 - 蓬莱人形
	CHARACTERS[GameConstants.CharacterId.MOKOU] = Character.new(
		GameConstants.CharacterId.MOKOU,
		"藤原妹红",
		"蓬莱人形",
		"近战坦克。重装，站火回血，复活能力。",
		Color("#ecf0f1"),
		"phoenix_wings",
		CharacterStats.new(120, 3.2, 1.0, 1.0, 1.0, 100, 1.0, 0, 0, 1),
		CharacterPhysics.new(20, 0.15, 1.0, false, true, true, false), # Reduced mass from 40 to 20
		0.1 # Mokou needs larger scale due to smaller sprite sheet frames
	)

	# 雾雨魔理沙 - 普通的魔法使
	CHARACTERS[GameConstants.CharacterId.MARISA] = Character.new(
		GameConstants.CharacterId.MARISA,
		"雾雨魔理沙",
		"普通的魔法使",
		"极速爆发。惯性大，速度越快伤害越高。",
		Color("#f1c40f"),
		"star_dust",
		CharacterStats.new(100, 4.0, 1.0, 1.0, 0.9, 150, 1.0, 0, 0, 0),
		CharacterPhysics.new(8, 0.08, 1.0, false, false, false, false),
		0.05
	)

	# 十六夜咲夜 - 完美潇洒的女仆
	CHARACTERS[GameConstants.CharacterId.SAKUYA] = Character.new(
		GameConstants.CharacterId.SAKUYA,
		"十六夜咲夜",
		"完美潇洒的女仆",
		"高频技巧。攻速+20%，飞刀反弹。",
		Color("#3498db"),
		"knives",
		CharacterStats.new(100, 3.3, 1.0, 1.0, 0.8, 120, 1.0, 0, 0, 0),
		CharacterPhysics.new(5, 0.12, 1.0, false, false, false, false),
		0.05
	)

	# 饕餮尤魔 - 刚欲同盟长
	CHARACTERS[GameConstants.CharacterId.YUMA] = Character.new(
		GameConstants.CharacterId.YUMA,
		"饕餮尤魔",
		"刚欲同盟长",
		"吸血坦克。质量大，击杀回血，聚怪能力。",
		Color("#8e44ad"),
		"spoon",
		CharacterStats.new(150, 2.8, 1.0, 1.0, 1.0, 100, 1.0, 3, 0, 0),
		CharacterPhysics.new(100, 0.18, 1.0, false, false, true, false),
		0.05
	)

	# 古明地恋 - 紧闭的恋之瞳
	CHARACTERS[GameConstants.CharacterId.KOISHI] = Character.new(
		GameConstants.CharacterId.KOISHI,
		"古明地恋",
		"紧闭的恋之瞳",
		"陷阱游走。仇恨低，可穿过敌人，随机地雷。",
		Color("#2ecc71"),
		"mines",
		CharacterStats.new(80, 3.5, 1.0, 1.2, 1.0, 100, 1.5, 0, 0, 0),
		CharacterPhysics.new(10, 0.1, 1.0, false, false, false, true),
		0.05
	)
