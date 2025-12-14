extends Node

# MetaProgressionData.gd - 局外升级数据定义
# 定义所有可永久升级的属性、花费和效果

class_name MetaProgressionData

# 升级类别枚举
enum UpgradeCategory {
	BASIC,      # 基础属性
	OFFENSE,    # 攻击属性
	DEFENSE,    # 防御属性
	UTILITY,    # 辅助属性
	SPECIAL     # 特殊解锁
}

# 单个升级项的数据结构
class MetaUpgrade:
	var id: String                    # 唯一标识
	var name: String                  # 显示名称
	var description: String           # 描述
	var category: UpgradeCategory     # 类别
	var icon: String                  # 图标路径（可选）
	var max_level: int                # 最大等级
	var base_cost: int                # 基础花费
	var cost_multiplier: float        # 每级花费倍率
	var effect_per_level: float       # 每级效果增量
	var effect_type: String           # 效果类型（用于应用效果）

	func _init(p_id: String, p_name: String, p_desc: String, p_category: UpgradeCategory,
			   p_max_level: int, p_base_cost: int, p_cost_mult: float,
			   p_effect: float, p_effect_type: String):
		id = p_id
		name = p_name
		description = p_desc
		category = p_category
		max_level = p_max_level
		base_cost = p_base_cost
		cost_multiplier = p_cost_mult
		effect_per_level = p_effect
		effect_type = p_effect_type

	# 计算指定等级的升级花费
	func get_cost_for_level(level: int) -> int:
		if level >= max_level:
			return -1  # 已满级
		return int(base_cost * pow(cost_multiplier, level))

	# 计算指定等级的总效果
	func get_effect_at_level(level: int) -> float:
		return effect_per_level * level

# === 所有升级项定义 ===
static var UPGRADES: Dictionary = {}

static func initialize():
	if UPGRADES.size() > 0:
		return  # 已初始化

	# --- 基础属性 ---
	_add_upgrade(MetaUpgrade.new(
		"max_hp", "生命上限", "增加角色最大生命值",
		UpgradeCategory.BASIC, 20, 100, 1.15, 10.0, "max_hp"
	))

	_add_upgrade(MetaUpgrade.new(
		"hp_regen", "生命回复", "每秒恢复生命值",
		UpgradeCategory.BASIC, 10, 150, 1.2, 0.5, "hp_regen"
	))

	_add_upgrade(MetaUpgrade.new(
		"move_speed", "移动速度", "提高角色移动速度",
		UpgradeCategory.BASIC, 10, 120, 1.18, 3.0, "move_speed"
	))

	_add_upgrade(MetaUpgrade.new(
		"pickup_range", "拾取范围", "增加经验球和掉落物的拾取范围",
		UpgradeCategory.BASIC, 15, 80, 1.12, 8.0, "pickup_range"
	))

	# --- 攻击属性 ---
	_add_upgrade(MetaUpgrade.new(
		"might", "攻击力", "提高所有伤害",
		UpgradeCategory.OFFENSE, 20, 100, 1.15, 2.0, "might"
	))

	_add_upgrade(MetaUpgrade.new(
		"attack_speed", "攻击速度", "提高武器攻击频率",
		UpgradeCategory.OFFENSE, 15, 130, 1.18, 3.0, "attack_speed"
	))

	_add_upgrade(MetaUpgrade.new(
		"crit_chance", "暴击率", "提高暴击概率",
		UpgradeCategory.OFFENSE, 10, 200, 1.25, 2.0, "crit_chance"
	))

	_add_upgrade(MetaUpgrade.new(
		"crit_damage", "暴击伤害", "提高暴击伤害倍率",
		UpgradeCategory.OFFENSE, 10, 180, 1.22, 5.0, "crit_damage"
	))

	_add_upgrade(MetaUpgrade.new(
		"projectile_count", "弹幕数量", "增加额外弹幕数",
		UpgradeCategory.OFFENSE, 5, 500, 1.5, 1.0, "projectile_count"
	))

	_add_upgrade(MetaUpgrade.new(
		"projectile_speed", "弹幕速度", "提高弹幕飞行速度",
		UpgradeCategory.OFFENSE, 10, 100, 1.15, 5.0, "projectile_speed"
	))

	# --- 防御属性 ---
	_add_upgrade(MetaUpgrade.new(
		"armor", "护甲", "减少受到的伤害",
		UpgradeCategory.DEFENSE, 15, 120, 1.18, 1.0, "armor"
	))

	_add_upgrade(MetaUpgrade.new(
		"dodge_chance", "闪避率", "有几率完全躲避伤害",
		UpgradeCategory.DEFENSE, 8, 250, 1.3, 1.5, "dodge_chance"
	))

	_add_upgrade(MetaUpgrade.new(
		"invincibility_time", "无敌时间", "受伤后的无敌时间延长",
		UpgradeCategory.DEFENSE, 5, 200, 1.25, 0.1, "invincibility_time"
	))

	# --- 辅助属性 ---
	_add_upgrade(MetaUpgrade.new(
		"xp_gain", "经验加成", "获得更多经验值",
		UpgradeCategory.UTILITY, 15, 100, 1.15, 5.0, "xp_gain"
	))

	_add_upgrade(MetaUpgrade.new(
		"gold_gain", "金币加成", "获得更多金币",
		UpgradeCategory.UTILITY, 15, 100, 1.15, 5.0, "gold_gain"
	))

	_add_upgrade(MetaUpgrade.new(
		"luck", "幸运", "提高稀有掉落和升级选项的概率",
		UpgradeCategory.UTILITY, 10, 150, 1.2, 3.0, "luck"
	))

	_add_upgrade(MetaUpgrade.new(
		"cooldown_reduction", "冷却缩减", "减少技能和武器冷却时间",
		UpgradeCategory.UTILITY, 10, 180, 1.22, 2.0, "cooldown_reduction"
	))

	_add_upgrade(MetaUpgrade.new(
		"area", "范围", "增加武器和技能的作用范围",
		UpgradeCategory.UTILITY, 10, 140, 1.18, 3.0, "area"
	))

	_add_upgrade(MetaUpgrade.new(
		"duration", "持续时间", "延长武器和效果的持续时间",
		UpgradeCategory.UTILITY, 10, 140, 1.18, 3.0, "duration"
	))

	# --- 特殊解锁 ---
	_add_upgrade(MetaUpgrade.new(
		"revival", "复活", "死亡时有机会复活（每局一次）",
		UpgradeCategory.SPECIAL, 3, 1000, 2.0, 1.0, "revival"
	))

	_add_upgrade(MetaUpgrade.new(
		"starting_weapon", "初始武器", "开局额外获得一把随机武器",
		UpgradeCategory.SPECIAL, 2, 800, 2.5, 1.0, "starting_weapon"
	))

	_add_upgrade(MetaUpgrade.new(
		"reroll", "重选次数", "升级时可重选的次数",
		UpgradeCategory.SPECIAL, 5, 300, 1.5, 1.0, "reroll"
	))

	_add_upgrade(MetaUpgrade.new(
		"banish", "禁选次数", "可永久移除不想要的升级选项次数",
		UpgradeCategory.SPECIAL, 3, 400, 1.6, 1.0, "banish"
	))

	_add_upgrade(MetaUpgrade.new(
		"skip", "跳过奖励", "跳过升级选择获得金币补偿",
		UpgradeCategory.SPECIAL, 1, 500, 1.0, 1.0, "skip"
	))

static func _add_upgrade(upgrade: MetaUpgrade):
	UPGRADES[upgrade.id] = upgrade

# 获取指定类别的所有升级
static func get_upgrades_by_category(category: UpgradeCategory) -> Array:
	var result = []
	for upgrade in UPGRADES.values():
		if upgrade.category == category:
			result.append(upgrade)
	return result

# 获取类别名称
static func get_category_name(category: UpgradeCategory) -> String:
	match category:
		UpgradeCategory.BASIC:
			return "基础属性"
		UpgradeCategory.OFFENSE:
			return "攻击属性"
		UpgradeCategory.DEFENSE:
			return "防御属性"
		UpgradeCategory.UTILITY:
			return "辅助属性"
		UpgradeCategory.SPECIAL:
			return "特殊解锁"
		_:
			return "未知"

# 获取类别颜色
static func get_category_color(category: UpgradeCategory) -> Color:
	match category:
		UpgradeCategory.BASIC:
			return Color(0.6, 0.8, 0.6)  # 绿色
		UpgradeCategory.OFFENSE:
			return Color(0.9, 0.5, 0.5)  # 红色
		UpgradeCategory.DEFENSE:
			return Color(0.5, 0.7, 0.9)  # 蓝色
		UpgradeCategory.UTILITY:
			return Color(0.9, 0.8, 0.5)  # 黄色
		UpgradeCategory.SPECIAL:
			return Color(0.8, 0.6, 0.9)  # 紫色
		_:
			return Color.WHITE
