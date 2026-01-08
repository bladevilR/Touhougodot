extends Node
class_name ElementData

# ElementData - 元素附魔与元素反应系统

# 元素道具配置
class ElementItem:
	var element_type: int          # GameConstants.ElementType
	var item_name: String
	var description: String
	var color: Color
	var sprite: String

	func _init(etype: int, name: String, desc: String, c: Color, spr: String):
		element_type = etype
		item_name = name
		description = desc
		color = c
		sprite = spr

# 元素反应配置
class ElementReaction:
	var elements: Array[int]       # [ElementType, ElementType]
	var reaction_name: String
	var description: String
	var effect_type: String        # explosion, freeze_shatter, corrosion, steam, thunder_field
	var damage_multiplier: float
	var radius: float

	func _init(elem: Array[int], name: String, desc: String, effect: String, dmg_mult: float = 1.0, rad: float = 0.0):
		elements = elem
		reaction_name = name
		description = desc
		effect_type = effect
		damage_multiplier = dmg_mult
		radius = rad

# 所有元素道具数据
static var ELEMENT_ITEMS = {}

# 所有元素反应数据
static var ELEMENT_REACTIONS = []

static func initialize():
	# ====== 元素道具配置 ======

	# 冰元素 - 琪露诺喝剩的水
	ELEMENT_ITEMS[GameConstants.ElementType.ICE] = ElementItem.new(
		GameConstants.ElementType.ICE,
		"琪露诺喝剩的水",
		"命中敌人积累寒冷值，叠满3层冻结。弹幕变成半透明的冰晶状。",
		Color("#00bfff"),
		"❄️"
	)

	# 火元素 - 火鸟的废羽
	ELEMENT_ITEMS[GameConstants.ElementType.FIRE] = ElementItem.new(
		GameConstants.ElementType.FIRE,
		"火鸟的废羽",
		"弹幕附加[点燃]效果（DOT 5dmg/s，持续3s）。死亡传染附近敌人。",
		Color("#ff4500"),
		"🔥"
	)

	# 毒元素 - 铃兰花毒
	ELEMENT_ITEMS[GameConstants.ElementType.POISON] = ElementItem.new(
		GameConstants.ElementType.POISON,
		"铃兰花毒",
		"弹幕命中施加[易伤]。每层使受到的最终伤害 +5 固定值。",
		Color("#9370db"),
		"☠️"
	)

	# 油元素 - 地灵殿黑水
	ELEMENT_ITEMS[GameConstants.ElementType.OIL] = ElementItem.new(
		GameConstants.ElementType.OIL,
		"地灵殿黑水",
		"弹幕击中地面会留下油渍（减速60%）。配合火属性打连招。",
		Color("#8b4513"),
		"🛢️"
	)

	# 雷元素 - 永江衣玖的披肩
	ELEMENT_ITEMS[GameConstants.ElementType.LIGHTNING] = ElementItem.new(
		GameConstants.ElementType.LIGHTNING,
		"永江衣玖的披肩",
		"弹幕命中时产生连锁闪电，跳跃至附近3个敌人（每跳-30%伤害）。",
		Color("#ffd700"),
		"⚡"
	)

	# 重力元素 - 伊吹瓢
	ELEMENT_ITEMS[GameConstants.ElementType.GRAVITY] = ElementItem.new(
		GameConstants.ElementType.GRAVITY,
		"伊吹瓢",
		"弹幕击中点产生微型黑洞（150px范围），吸附敌人1.5秒。",
		Color("#9932cc"),
		"🌀"
	)

	# ====== 元素反应配置 ======

	# 火 + 油 = 地狱火爆炸
	ELEMENT_REACTIONS.append(ElementReaction.new(
		[GameConstants.ElementType.FIRE, GameConstants.ElementType.OIL],
		"地狱火",
		"火焰击中油渍产生大爆炸",
		"explosion",
		3.0,    # 300% 伤害
		200.0   # 200px 范围
	))

	# 冰 + 毒 = 寒霜瘟疫
	ELEMENT_REACTIONS.append(ElementReaction.new(
		[GameConstants.ElementType.ICE, GameConstants.ElementType.POISON],
		"寒霜瘟疫",
		"冰霜击中中毒敌人触发碎冰AOE",
		"freeze_shatter",
		2.0,    # 200% 伤害
		120.0   # 120px 范围
	))

	# 雷 + 毒 = 腐蚀雷电
	ELEMENT_REACTIONS.append(ElementReaction.new(
		[GameConstants.ElementType.LIGHTNING, GameConstants.ElementType.POISON],
		"腐蚀雷电",
		"雷电+毒素 = 护甲穿透",
		"corrosion",
		1.5,    # 150% 伤害
		0.0     # 无AOE
	))

	# 冰 + 火 = 蒸汽爆炸
	ELEMENT_REACTIONS.append(ElementReaction.new(
		[GameConstants.ElementType.ICE, GameConstants.ElementType.FIRE],
		"蒸汽爆炸",
		"冰火交融产生蒸汽遮蔽",
		"steam",
		1.0,
		150.0   # 150px 范围
	))

	# 重力 + 雷 = 雷暴领域
	ELEMENT_REACTIONS.append(ElementReaction.new(
		[GameConstants.ElementType.GRAVITY, GameConstants.ElementType.LIGHTNING],
		"雷暴领域",
		"引力+雷电产生持续电击区域",
		"thunder_field",
		0.5,    # 持续伤害
		180.0   # 180px 范围
	))

# 获取元素道具
static func get_element_item(element_type: int) -> ElementItem:
	if ELEMENT_ITEMS.has(element_type):
		return ELEMENT_ITEMS[element_type]
	return null

# 检查元素反应
static func check_reaction(element1: int, element2: int) -> ElementReaction:
	for reaction in ELEMENT_REACTIONS:
		if (reaction.elements[0] == element1 and reaction.elements[1] == element2) or \
		   (reaction.elements[0] == element2 and reaction.elements[1] == element1):
			return reaction
	return null

# 获取所有元素类型
static func get_all_element_types() -> Array:
	return [
		GameConstants.ElementType.ICE,
		GameConstants.ElementType.FIRE,
		GameConstants.ElementType.POISON,
		GameConstants.ElementType.OIL,
		GameConstants.ElementType.LIGHTNING,
		GameConstants.ElementType.GRAVITY
	]
