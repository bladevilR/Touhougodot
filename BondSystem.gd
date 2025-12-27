extends Node
class_name BondSystem

# BondSystem - 羁绊支援系统
# 开局选择一位非主控角色作为羁绊，提供主动技能（F）和永久物理修正

signal bond_skill_activated(bond_name: String)
signal bond_cooldown_changed(cooldown: float, max_cooldown: float)

var player: Node2D = null
var current_bond_id: int = -1  # 当前羁绊角色ID

# 技能冷却
var skill_cooldown: float = 0.0
var max_cooldown: float = 30.0  # 默认30秒CD

# 羁绊配置 (按策划稿)
const BOND_CONFIGS = {
	GameConstants.CharacterId.REIMU: {
		"name": "灵梦",
		"skill_name": "梦想封印",
		"skill_description": "全屏消弹+无敌5秒",
		"cooldown": 30.0,
		"passive_name": "境界弹射",
		"passive_description": "所有子弹反弹次数+1，反弹后微弱诱导",
	},
	GameConstants.CharacterId.MARISA: {
		"name": "魔理沙",
		"skill_name": "极限火花",
		"skill_description": "全屏粗大激光扫射（300伤害）",
		"cooldown": 25.0,
		"passive_name": "魔力质量",
		"passive_description": "子弹体积+30%，击退力+50%",
	},
	GameConstants.CharacterId.MOKOU: {
		"name": "妹红",
		"skill_name": "凯风快晴",
		"skill_description": "全屏瞬间点燃���80伤害+燃烧）",
		"cooldown": 20.0,
		"passive_name": "弹幕复生",
		"passive_description": "子弹销毁时原地复活一次（寿命减半）",
	},
	GameConstants.CharacterId.SAKUYA: {
		"name": "咲夜",
		"skill_name": "杀人玩偶",
		"skill_description": "全屏时停5秒，结算伤害",
		"cooldown": 35.0,
		"passive_name": "延迟裂变",
		"passive_description": "子弹发射后悬停0.3秒，再加速射出",
	},
	GameConstants.CharacterId.YUMA: {
		"name": "尤魔",
		"skill_name": "暴食盛宴",
		"skill_description": "吞噬敌弹回血（+50 HP）",
		"cooldown": 25.0,
		"passive_name": "引力拉扯",
		"passive_description": "子弹命中时将敌人向枪口方向拉扯",
	},
	GameConstants.CharacterId.KOISHI: {
		"name": "恋恋",
		"skill_name": "本我解放",
		"skill_description": "隐身、穿墙、移速翻倍（5秒）",
		"cooldown": 40.0,
		"passive_name": "无意识相位",
		"passive_description": "子弹20%概率无视地形（穿墙）和盾牌",
	},
}

func _ready():
	# 获取玩家引用
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# 监听羁绊选择
	SignalBus.bond_selected.connect(_on_bond_selected)

func _process(delta):
	# 更新技能冷却
	if skill_cooldown > 0:
		skill_cooldown -= delta
		if skill_cooldown < 0:
			skill_cooldown = 0
		bond_cooldown_changed.emit(skill_cooldown, max_cooldown)

func _input(event):
	if not player or current_bond_id < 0:
		return

	# F键触发羁绊技能
	if event is InputEventKey:
		if event.keycode == KEY_F and event.pressed and not event.echo:
			activate_bond_skill()

func _on_bond_selected(bond_id: String):
	"""处理羁绊选择"""
	# 转换bond_id字符串为角色ID
	var char_id = _bond_id_to_char_id(bond_id)
	if char_id >= 0:
		set_bond(char_id)

func _bond_id_to_char_id(bond_id: String) -> int:
	match bond_id:
		"reimu":
			return GameConstants.CharacterId.REIMU
		"marisa":
			return GameConstants.CharacterId.MARISA
		"mokou":
			return GameConstants.CharacterId.MOKOU
		"sakuya":
			return GameConstants.CharacterId.SAKUYA
		"yuma":
			return GameConstants.CharacterId.YUMA
		"koishi":
			return GameConstants.CharacterId.KOISHI
		_:
			return -1

func set_bond(bond_char_id: int):
	"""设置羁绊角色"""
	if not BOND_CONFIGS.has(bond_char_id):
		print("无效的羁绊角色ID: ", bond_char_id)
		return

	current_bond_id = bond_char_id
	var config = BOND_CONFIGS[bond_char_id]
	max_cooldown = config.cooldown

	# 应用被动效果
	_apply_passive_effect(bond_char_id)

	print("羁绊设置: ", config.name, " - ", config.passive_name)

func activate_bond_skill():
	"""激活羁绊主动技能"""
	if skill_cooldown > 0:
		print("羁绊技能冷却中... 剩余: %.1f秒" % skill_cooldown)
		return

	if current_bond_id < 0:
		print("未选择羁绊角色")
		return

	var config = BOND_CONFIGS[current_bond_id]
	print("发动羁绊技能: ", config.skill_name)

	match current_bond_id:
		GameConstants.CharacterId.REIMU:
			_skill_reimu_dream_seal()
		GameConstants.CharacterId.MARISA:
			_skill_marisa_master_spark()
		GameConstants.CharacterId.MOKOU:
			_skill_mokou_phoenix_flame()
		GameConstants.CharacterId.SAKUYA:
			_skill_sakuya_time_stop()
		GameConstants.CharacterId.YUMA:
			_skill_yuma_gluttony()
		GameConstants.CharacterId.KOISHI:
			_skill_koishi_unconscious()

	# 开始冷却
	skill_cooldown = max_cooldown
	bond_skill_activated.emit(config.skill_name)

# ============================================
# 羁绊主动技能实现
# ============================================

func _skill_reimu_dream_seal():
	"""灵梦羁绊：梦想封印 - 全屏消弹+无敌5秒"""
	# 清除所有敌方子弹
	var enemy_bullets = get_tree().get_nodes_in_group("enemy_bullet")
	for bullet in enemy_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()

	# 玩家无敌5秒
	if player and player.has_method("set_invulnerable"):
		player.set_invulnerable(5.0)

	print("梦想封印！消除所有敌弹，无敌5秒！")

func _skill_marisa_master_spark():
	"""魔理沙羁绊：极限火花 - 全屏激光300伤害"""
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(300.0)

	# 触发屏幕震动
	SignalBus.screen_shake.emit(0.5, 20.0)

	print("极限火花！全屏300伤害！")

func _skill_mokou_phoenix_flame():
	"""妹红羁绊：凯风快晴 - 全屏点燃80伤害+燃烧"""
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(80.0)
		if enemy.has_method("apply_burn"):
			enemy.apply_burn(10.0, 5.0)  # 10伤害/秒，持续5秒

	print("凯风快晴！全屏80伤害+燃烧！")

func _skill_sakuya_time_stop():
	"""咲夜羁绊：杀人玩偶 - 全屏时停5秒"""
	# 冻结所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.set_process(false)
		enemy.set_physics_process(false)

	# 冻结所有敌方子弹
	var enemy_bullets = get_tree().get_nodes_in_group("enemy_bullet")
	for bullet in enemy_bullets:
		if is_instance_valid(bullet):
			bullet.set_process(false)
			bullet.set_physics_process(false)

	SignalBus.time_stopped.emit(5.0)

	# 5秒后恢复
	await get_tree().create_timer(5.0).timeout

	if not is_instance_valid(self):
		return

	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.set_process(true)
		enemy.set_physics_process(true)

	for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(bullet):
			bullet.set_process(true)
			bullet.set_physics_process(true)

	SignalBus.time_resumed.emit()
	print("时停结束！")

func _skill_yuma_gluttony():
	"""尤魔羁绊：暴食盛宴 - 吞噬敌弹回血50HP"""
	# 清除所有敌方子弹
	var enemy_bullets = get_tree().get_nodes_in_group("enemy_bullet")
	var bullet_count = enemy_bullets.size()

	for bullet in enemy_bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()

	# 回复生命（固定50HP + 每个子弹额外1HP）
	var heal_amount = 50.0 + bullet_count * 1.0
	if player and player.has_node("HealthComponent"):
		var health_comp = player.get_node("HealthComponent")
		if health_comp.has_method("heal"):
			health_comp.heal(heal_amount)

	print("暴食盛宴！吞噬%d发敌弹，回复%.0f HP！" % [bullet_count, heal_amount])

func _skill_koishi_unconscious():
	"""恋恋羁绊：本我解放 - 隐身、穿墙、移速翻倍5秒"""
	if not player:
		return

	# 保存原始状态
	var original_speed = player.speed if player.get("speed") else 200.0
	var original_collision_mask = player.collision_mask

	# 设置隐身效果
	if player.sprite:
		player.sprite.modulate = Color(1.0, 1.0, 1.0, 0.2)

	# 移速翻倍
	if player.get("speed"):
		player.speed = original_speed * 2.0

	# 穿墙（移除墙壁碰撞）
	player.collision_mask = player.collision_mask & ~2  # 移除墙壁层

	# 无敌
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(5.0)

	print("本我解放！隐身+穿墙+移速翻倍 5秒！")

	# 5秒后恢复
	await get_tree().create_timer(5.0).timeout

	if is_instance_valid(player):
		if player.sprite:
			player.sprite.modulate = Color.WHITE
		if player.get("speed"):
			player.speed = original_speed
		player.collision_mask = original_collision_mask

	print("本我解放结束！")

# ============================================
# 羁绊被动效果
# ============================================

func _apply_passive_effect(bond_id: int):
	"""应用羁绊被动效果"""
	match bond_id:
		GameConstants.CharacterId.REIMU:
			# 境界弹射：反弹+1，反弹后微弱诱导
			SignalBus.connect("weapon_added", _on_weapon_added_reimu_passive)
		GameConstants.CharacterId.MARISA:
			# 魔力质量：子弹体积+30%，击退+50%
			pass  # 在WeaponSystem中处理
		GameConstants.CharacterId.MOKOU:
			# 弹幕复生：子弹销毁时复活一次
			pass  # 在Bullet中处理
		GameConstants.CharacterId.SAKUYA:
			# 延迟裂变：子弹悬停0.3秒后加速
			pass  # 在Bullet中处理
		GameConstants.CharacterId.YUMA:
			# 引力拉扯：命中时拉扯敌人
			pass  # 在Bullet中处理
		GameConstants.CharacterId.KOISHI:
			# 无意识相位：20%穿墙
			pass  # 在Bullet中处理

func _on_weapon_added_reimu_passive(weapon_id: String):
	"""灵梦被动：为新武器添加反弹+1"""
	# 这个被动效果会在WeaponSystem中应用
	pass

# ============================================
# 辅助函数
# ============================================

func get_current_bond_config() -> Dictionary:
	"""获取当前羁绊配置"""
	if current_bond_id >= 0 and BOND_CONFIGS.has(current_bond_id):
		return BOND_CONFIGS[current_bond_id]
	return {}

func get_passive_modifier(modifier_type: String) -> float:
	"""获取被动修正值"""
	match current_bond_id:
		GameConstants.CharacterId.REIMU:
			if modifier_type == "bounce_bonus":
				return 1.0  # +1反弹
			if modifier_type == "homing_after_bounce":
				return 0.1  # 反弹后追踪强度
		GameConstants.CharacterId.MARISA:
			if modifier_type == "size_bonus":
				return 1.3  # +30%体积
			if modifier_type == "knockback_bonus":
				return 1.5  # +50%击退
		GameConstants.CharacterId.MOKOU:
			if modifier_type == "bullet_revive":
				return 1.0  # 启用复活
		GameConstants.CharacterId.SAKUYA:
			if modifier_type == "delay_time":
				return 0.3  # 悬停0.3秒
		GameConstants.CharacterId.YUMA:
			if modifier_type == "gravity_pull":
				return 50.0  # 引力拉扯力度
		GameConstants.CharacterId.KOISHI:
			if modifier_type == "phase_chance":
				return 0.2  # 20%穿墙概率

	return 0.0

func has_bond() -> bool:
	"""检查是否已选择羁绊"""
	return current_bond_id >= 0
