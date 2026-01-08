extends Node

# MetaProgressionManager.gd - 局外升级管理器
# 管理局外升级的购买和效果应用

# 信号
signal currency_changed(new_amount: int)
signal upgrade_purchased(upgrade_id: String, new_level: int)

func _ready():
	# 初始化升级数据
	MetaProgressionData.initialize()
	print("[MetaProgressionManager] 局外升级系统初始化完成")

# === 货币管理 ===

func get_currency() -> int:
	return GameSaveManager.get_meta_currency()

func add_currency(amount: int):
	GameSaveManager.add_meta_currency(amount)
	currency_changed.emit(get_currency())

func can_afford(amount: int) -> bool:
	return get_currency() >= amount

# === 升级管理 ===

func get_upgrade_level(upgrade_id: String) -> int:
	return GameSaveManager.get_upgrade_level(upgrade_id)

func get_upgrade_data(upgrade_id: String) -> MetaProgressionData.MetaUpgrade:
	return MetaProgressionData.UPGRADES.get(upgrade_id)

func can_purchase_upgrade(upgrade_id: String) -> bool:
	var upgrade = get_upgrade_data(upgrade_id)
	if upgrade == null:
		return false

	var current_level = get_upgrade_level(upgrade_id)
	if current_level >= upgrade.max_level:
		return false  # 已满级

	var cost = upgrade.get_cost_for_level(current_level)
	return can_afford(cost)

func purchase_upgrade(upgrade_id: String) -> bool:
	var upgrade = get_upgrade_data(upgrade_id)
	if upgrade == null:
		print("[MetaProgressionManager] 升级项不存在: " + upgrade_id)
		return false

	var current_level = get_upgrade_level(upgrade_id)
	if current_level >= upgrade.max_level:
		print("[MetaProgressionManager] 已达到最大等级: " + upgrade_id)
		return false

	var cost = upgrade.get_cost_for_level(current_level)
	if not GameSaveManager.spend_meta_currency(cost):
		print("[MetaProgressionManager] 货币不足，无法购买: " + upgrade_id)
		return false

	var new_level = GameSaveManager.increment_upgrade_level(upgrade_id)
	print("[MetaProgressionManager] 升级成功: %s -> Lv.%d" % [upgrade.name, new_level])

	currency_changed.emit(get_currency())
	upgrade_purchased.emit(upgrade_id, new_level)
	return true

func get_next_upgrade_cost(upgrade_id: String) -> int:
	var upgrade = get_upgrade_data(upgrade_id)
	if upgrade == null:
		return -1

	var current_level = get_upgrade_level(upgrade_id)
	return upgrade.get_cost_for_level(current_level)

func is_upgrade_maxed(upgrade_id: String) -> bool:
	var upgrade = get_upgrade_data(upgrade_id)
	if upgrade == null:
		return true

	return get_upgrade_level(upgrade_id) >= upgrade.max_level

# === 效果计算 ===

func get_total_bonus(effect_type: String) -> float:
	# 计算指定效果类型的总加成
	var total: float = 0.0

	for upgrade_id in MetaProgressionData.UPGRADES:
		var upgrade = MetaProgressionData.UPGRADES[upgrade_id]
		if upgrade.effect_type == effect_type:
			var level = get_upgrade_level(upgrade_id)
			total += upgrade.get_effect_at_level(level)

	return total

func get_all_bonuses() -> Dictionary:
	# 获取所有效果类型的加成
	var bonuses: Dictionary = {}

	for upgrade_id in MetaProgressionData.UPGRADES:
		var upgrade = MetaProgressionData.UPGRADES[upgrade_id]
		var level = get_upgrade_level(upgrade_id)
		var effect = upgrade.get_effect_at_level(level)

		if effect > 0:
			if not bonuses.has(upgrade.effect_type):
				bonuses[upgrade.effect_type] = 0.0
			bonuses[upgrade.effect_type] += effect

	return bonuses

# === 应用到角色 ===

func apply_bonuses_to_stats(base_stats: Dictionary) -> Dictionary:
	# 将局外升级加成应用到角色基础属性
	var modified_stats = base_stats.duplicate()
	var bonuses = get_all_bonuses()

	# 生命值
	if bonuses.has("max_hp"):
		modified_stats.max_hp = modified_stats.get("max_hp", 100) + bonuses.max_hp

	# 生命回复
	if bonuses.has("hp_regen"):
		modified_stats.hp_regen = modified_stats.get("hp_regen", 0) + bonuses.hp_regen

	# 移动速度（百分比加成）
	if bonuses.has("move_speed"):
		var base_speed = modified_stats.get("speed", 200)
		modified_stats.speed = base_speed * (1.0 + bonuses.move_speed / 100.0)

	# 拾取范围
	if bonuses.has("pickup_range"):
		modified_stats.pickup_range = modified_stats.get("pickup_range", 50) + bonuses.pickup_range

	# 攻击力（百分比加成）
	if bonuses.has("might"):
		var base_might = modified_stats.get("might", 1.0)
		modified_stats.might = base_might * (1.0 + bonuses.might / 100.0)

	# 攻击速度（百分比加成）
	if bonuses.has("attack_speed"):
		var base_attack_speed = modified_stats.get("attack_speed", 1.0)
		modified_stats.attack_speed = base_attack_speed * (1.0 + bonuses.attack_speed / 100.0)

	# 暴击率
	if bonuses.has("crit_chance"):
		modified_stats.crit_chance = modified_stats.get("crit_chance", 0) + bonuses.crit_chance

	# 暴击伤害（百分比加成）
	if bonuses.has("crit_damage"):
		modified_stats.crit_damage = modified_stats.get("crit_damage", 150) + bonuses.crit_damage

	# 弹幕数量
	if bonuses.has("projectile_count"):
		modified_stats.projectile_count = modified_stats.get("projectile_count", 0) + int(bonuses.projectile_count)

	# 弹幕速度（百分比加成）
	if bonuses.has("projectile_speed"):
		var base_proj_speed = modified_stats.get("projectile_speed", 1.0)
		modified_stats.projectile_speed = base_proj_speed * (1.0 + bonuses.projectile_speed / 100.0)

	# 护甲
	if bonuses.has("armor"):
		modified_stats.armor = modified_stats.get("armor", 0) + bonuses.armor

	# 闪避率
	if bonuses.has("dodge_chance"):
		modified_stats.dodge_chance = modified_stats.get("dodge_chance", 0) + bonuses.dodge_chance

	# 无敌时间
	if bonuses.has("invincibility_time"):
		modified_stats.invincibility_time = modified_stats.get("invincibility_time", 0.5) + bonuses.invincibility_time

	# 经验加成（百分比）
	if bonuses.has("xp_gain"):
		modified_stats.xp_gain = modified_stats.get("xp_gain", 100) + bonuses.xp_gain

	# 金币加成（百分比）
	if bonuses.has("gold_gain"):
		modified_stats.gold_gain = modified_stats.get("gold_gain", 100) + bonuses.gold_gain

	# 幸运
	if bonuses.has("luck"):
		modified_stats.luck = modified_stats.get("luck", 0) + bonuses.luck

	# 冷却缩减（百分比）
	if bonuses.has("cooldown_reduction"):
		modified_stats.cooldown_reduction = modified_stats.get("cooldown_reduction", 0) + bonuses.cooldown_reduction

	# 范围（百分比加成）
	if bonuses.has("area"):
		modified_stats.area = modified_stats.get("area", 100) + bonuses.area

	# 持续时间（百分比加成）
	if bonuses.has("duration"):
		modified_stats.duration = modified_stats.get("duration", 100) + bonuses.duration

	# 复活次数
	if bonuses.has("revival"):
		modified_stats.revival = int(bonuses.revival)

	# 初始武器数量
	if bonuses.has("starting_weapon"):
		modified_stats.starting_weapon = int(bonuses.starting_weapon)

	# 重选次数
	if bonuses.has("reroll"):
		modified_stats.reroll = int(bonuses.reroll)

	# 禁选次数
	if bonuses.has("banish"):
		modified_stats.banish = int(bonuses.banish)

	# 跳过奖励
	if bonuses.has("skip"):
		modified_stats.skip_enabled = bonuses.skip >= 1.0

	return modified_stats

# === 游戏结束奖励 ===

func calculate_run_reward(run_stats: Dictionary) -> int:
	# 根据游戏结果计算灵魂碎片奖励
	var reward: int = 0

	# 基础奖励：存活时间
	var survival_time = run_stats.get("survival_time", 0)
	reward += int(survival_time / 60.0 * 10)  # 每分钟10碎片

	# 击杀奖励
	var kills = run_stats.get("kills", 0)
	reward += int(kills * 0.5)  # 每2个击杀1碎片

	# Boss奖励
	var bosses = run_stats.get("bosses_defeated", 0)
	reward += bosses * 50  # 每个Boss 50碎片

	# 等级奖励
	var level = run_stats.get("level_reached", 1)
	reward += level * 5  # 每级5碎片

	# 胜利奖励
	if run_stats.get("won", false):
		reward += 200

	# 应用金币加成
	var gold_bonus = get_total_bonus("gold_gain")
	reward = int(reward * (1.0 + gold_bonus / 100.0))

	return reward

func end_run(won: bool, character_id: int, run_stats: Dictionary):
	# 处理游戏结束
	var reward = calculate_run_reward(run_stats)
	add_currency(reward)

	# 记录统计
	run_stats["gold_earned"] = reward
	GameSaveManager.record_run_end(won, character_id, run_stats)

	print("[MetaProgressionManager] 游戏结束，获得灵魂碎片: %d" % reward)
	return reward
