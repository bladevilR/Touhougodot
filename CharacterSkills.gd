extends Node2D
class_name CharacterSkills

# CharacterSkills - 角色空格主动技能系统
# 每个角色独特的Space键技能

signal skill_activated(skill_name: String)
signal skill_cooldown_changed(cooldown: float, max_cooldown: float)

@export var enabled: bool = true

var player: CharacterBody2D = null
var character_id: int = 0

# 技能冷却系统
var skill_cooldown: float = 0.0
var max_cooldown: float = 0.0

# 灵梦 - 亚空穴传送标记
var gap_mark_position: Vector2 = Vector2.ZERO
var has_gap_mark: bool = false
var gap_mark_timer: float = 0.0
var gap_mark_timeout: float = 5.0  # 5秒后标记消失

# 妹红 - 火焰飞踢
var is_fire_kicking: bool = false
var fire_kick_direction: Vector2 = Vector2.ZERO
var fire_kick_progress: float = 0.0
var fire_kick_duration: float = 0.5
var fire_kick_distance: float = 400.0
var fire_kick_start_pos: Vector2 = Vector2.ZERO
var fire_trail_timer: float = 0.0

# 魔理沙 - 扫把冲锋
var is_broom_dashing: bool = false
var broom_dash_direction: Vector2 = Vector2.ZERO
var broom_dash_progress: float = 0.0
var broom_dash_duration: float = 0.4
var broom_dash_distance: float = 500.0
var broom_dash_start_pos: Vector2 = Vector2.ZERO

# 技能配置
const SKILL_CONFIGS = {
	GameConstants.CharacterId.REIMU: {
		"name": "亚空穴",
		"cooldown": 5.0,
	},
	GameConstants.CharacterId.MOKOU: {
		"name": "凯风快晴飞翔蹴",
		"cooldown": 3.0,
		"damage": 50.0,
		"fire_trail_damage": 20.0,
	},
	GameConstants.CharacterId.MARISA: {
		"name": "扫把冲锋",
		"cooldown": 2.0,
		"damage": 30.0,
	},
	GameConstants.CharacterId.SAKUYA: {
		"name": "时停步法",
		"cooldown": 5.0,
	},
	GameConstants.CharacterId.YUMA: {
		"name": "潜行捕食",
		"cooldown": 6.0,
	},
	GameConstants.CharacterId.KOISHI: {
		"name": "無意識",
		"cooldown": 7.0,
	},
}

# 可视化节点
var gap_mark_sprite: Node2D = null
var fire_trail_container: Node2D = null

func _ready():
	# 获取父节点（玩家）
	player = get_parent() as CharacterBody2D
	if not player:
		push_error("CharacterSkills必须作为Player的子节点！")
		return

	# 获取角色ID
	character_id = player.character_id

	# 创建可视化容器
	fire_trail_container = Node2D.new()
	fire_trail_container.name = "FireTrailContainer"
	add_child(fire_trail_container)

	# 创建传送标记
	gap_mark_sprite = Node2D.new()
	gap_mark_sprite.name = "GapMark"
	gap_mark_sprite.visible = false
	add_child(gap_mark_sprite)

	print("角色技能系统已初始化，角色ID: ", character_id)

func _process(delta):
	# 更新技能冷却
	if skill_cooldown > 0:
		skill_cooldown -= delta
		if skill_cooldown < 0:
			skill_cooldown = 0
		skill_cooldown_changed.emit(skill_cooldown, max_cooldown)

	# 更新传送标记计时器
	if has_gap_mark:
		gap_mark_timer -= delta
		if gap_mark_timer <= 0:
			clear_gap_mark()

	# 更新技能持续效果
	_update_active_skills(delta)

func _physics_process(delta):
	# 处理需要物理更新的技能
	if is_fire_kicking:
		_process_fire_kick(delta)

	if is_broom_dashing:
		_process_broom_dash(delta)

func _input(event):
	if not enabled or not player:
		return

	# Space键触发技能
	if event.is_action_pressed("ui_accept"):  # Space键默认映射为ui_accept
		activate_skill()

func activate_skill():
	"""激活当前角色的Space技能"""
	if skill_cooldown > 0:
		print("技能冷却中... 剩余: %.1f秒" % skill_cooldown)
		return

	match character_id:
		GameConstants.CharacterId.REIMU:
			_activate_reimu_skill()
		GameConstants.CharacterId.MOKOU:
			_activate_mokou_skill()
		GameConstants.CharacterId.MARISA:
			_activate_marisa_skill()
		GameConstants.CharacterId.SAKUYA:
			_activate_sakuya_skill()
		GameConstants.CharacterId.YUMA:
			_activate_yuma_skill()
		GameConstants.CharacterId.KOISHI:
			_activate_koishi_skill()

# ============================================
# 灵梦 - 亚空穴 (Gap Teleport)
# ============================================
func _activate_reimu_skill():
	"""灵梦：亚空穴传送"""
	if not has_gap_mark:
		# 第一次按Space：标记位置
		mark_gap_position()
	else:
		# 第二次按Space：传送到标记位置
		teleport_to_gap_mark()

func mark_gap_position():
	"""标记传送位置"""
	gap_mark_position = player.global_position
	has_gap_mark = true
	gap_mark_timer = gap_mark_timeout
	gap_mark_sprite.visible = true
	gap_mark_sprite.global_position = gap_mark_position

	print("亚空穴标记已设置: ", gap_mark_position)
	skill_activated.emit("亚空穴标记")

func teleport_to_gap_mark():
	"""传送到标记位置"""
	if not has_gap_mark:
		return

	# 传送玩家
	player.global_position = gap_mark_position
	player.velocity = Vector2.ZERO

	# 设置短暂无敌（需要在Player中实现）
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(0.5)  # 0.5秒无敌

	# 清除标记并进入冷却
	clear_gap_mark()
	start_cooldown(GameConstants.CharacterId.REIMU)

	print("传送完成！")
	skill_activated.emit("亚空穴传送")

	# TODO: 添加传送特效和音效

func clear_gap_mark():
	"""清除传送标记"""
	has_gap_mark = false
	gap_mark_sprite.visible = false

# ============================================
# 妹红 - 凯风快晴飞翔蹴 (Fire Kick)
# ============================================
func _activate_mokou_skill():
	"""妹红：火焰飞踢"""
	if is_fire_kicking:
		return

	# 获取移动方向
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 如果没有输入，使用玩家朝向
	if input_dir.length() < 0.1:
		# 使用玩家sprite的scale.x来判断朝向
		input_dir = Vector2(1, 0) if player.sprite.scale.x > 0 else Vector2(-1, 0)

	input_dir = input_dir.normalized()

	# 开始火焰飞踢
	is_fire_kicking = true
	fire_kick_direction = input_dir
	fire_kick_progress = 0.0
	fire_kick_start_pos = player.global_position
	fire_trail_timer = 0.0

	# 设置无敌时间
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(fire_kick_duration)

	print("凯风快晴飞翔蹴！方向: ", fire_kick_direction)
	skill_activated.emit("凯风快晴飞翔蹴")

func _process_fire_kick(delta):
	"""处理火焰飞踢移动"""
	if not is_fire_kicking:
		return

	fire_kick_progress += delta / fire_kick_duration

	# 移动玩家
	var target_pos = fire_kick_start_pos + fire_kick_direction * fire_kick_distance
	player.global_position = fire_kick_start_pos.lerp(target_pos, fire_kick_progress)

	# 留下火焰轨迹
	fire_trail_timer += delta
	if fire_trail_timer >= 0.05:  # 每0.05秒生成一个火焰区域
		spawn_fire_trail(player.global_position)
		fire_trail_timer = 0.0

	# 对路径上的敌人造成伤害
	damage_enemies_in_kick_path()

	# 结束飞踢
	if fire_kick_progress >= 1.0:
		is_fire_kicking = false
		start_cooldown(GameConstants.CharacterId.MOKOU)
		print("火焰飞踢结束！")

func spawn_fire_trail(pos: Vector2):
	"""生成火焰轨迹"""
	var fire_area = Area2D.new()
	fire_area.global_position = pos
	fire_area.name = "FireTrail"

	# 添加碰撞形状
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40
	collision.shape = shape
	fire_area.add_child(collision)

	# 添加视觉效果（红色圆圈）
	var sprite = ColorRect.new()
	sprite.size = Vector2(80, 80)
	sprite.position = Vector2(-40, -40)
	sprite.color = Color(1.0, 0.3, 0.0, 0.5)
	fire_area.add_child(sprite)

	# 设置碰撞层
	fire_area.collision_layer = 0
	fire_area.collision_mask = 2  # 只检测敌人（假设敌人在第2层）

	# 添加到场景
	fire_trail_container.add_child(fire_area)

	# 2秒后自动销毁
	var timer = get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		if is_instance_valid(fire_area):
			fire_area.queue_free()
	)

	# 持续伤害
	_apply_fire_trail_damage(fire_area)

func _apply_fire_trail_damage(fire_area: Area2D):
	"""火焰轨迹持续伤害"""
	var damage_timer = Timer.new()
	damage_timer.wait_time = 0.2  # 每0.2秒伤害一次
	damage_timer.autostart = true
	fire_area.add_child(damage_timer)

	damage_timer.timeout.connect(func():
		if not is_instance_valid(fire_area):
			return

		var config = SKILL_CONFIGS[GameConstants.CharacterId.MOKOU]
		var damage = config.fire_trail_damage

		# 获取范围内的敌人
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if enemy.has_method("take_damage"):
				var dist = fire_area.global_position.distance_to(enemy.global_position)
				if dist < 50:
					enemy.take_damage(damage)
	)

func damage_enemies_in_kick_path():
	"""对飞踢路径上的敌人造成伤害"""
	var config = SKILL_CONFIGS[GameConstants.CharacterId.MOKOU]
	var damage = config.damage

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < 60:  # 飞踢判定范围
				enemy.take_damage(damage)

# ============================================
# 魔理沙 - 扫把冲锋 (Broom Charge)
# ============================================
func _activate_marisa_skill():
	"""魔理沙：扫把冲锋"""
	if is_broom_dashing:
		return

	# 获取移动方向
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# 如果没有输入，使用玩家朝向
	if input_dir.length() < 0.1:
		input_dir = Vector2(1, 0) if player.sprite.scale.x > 0 else Vector2(-1, 0)

	input_dir = input_dir.normalized()

	# 开始扫把冲锋
	is_broom_dashing = true
	broom_dash_direction = input_dir
	broom_dash_progress = 0.0
	broom_dash_start_pos = player.global_position

	# 设置短暂无敌
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(broom_dash_duration)

	print("扫把冲锋！方向: ", broom_dash_direction)
	skill_activated.emit("扫把冲锋")

func _process_broom_dash(delta):
	"""处理扫把冲锋移动"""
	if not is_broom_dashing:
		return

	broom_dash_progress += delta / broom_dash_duration

	# 移动玩家
	var target_pos = broom_dash_start_pos + broom_dash_direction * broom_dash_distance
	player.global_position = broom_dash_start_pos.lerp(target_pos, broom_dash_progress)

	# 对路径上的敌人造成伤害
	damage_enemies_in_dash_path()

	# 结束冲锋
	if broom_dash_progress >= 1.0:
		is_broom_dashing = false
		start_cooldown(GameConstants.CharacterId.MARISA)
		print("扫把冲锋结束！")

func damage_enemies_in_dash_path():
	"""对冲锋路径上的敌人造成伤害"""
	var config = SKILL_CONFIGS[GameConstants.CharacterId.MARISA]
	var damage = config.damage

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < 50:  # 冲锋判定范围
				enemy.take_damage(damage)

# ============================================
# 咲夜 - 时停步法 (Time Stop) - 未完成
# ============================================
func _activate_sakuya_skill():
	"""咲夜：时停步法（未实现）"""
	print("⚠️ 技能未实现：时停步法")
	print("TODO: 实现咲夜的时停技能")
	# TODO: 实现时停效果
	# - 冻结所有敌人和子弹
	# - 持续1.5秒
	# - 玩家可以自由移动
	# - 玩家无敌

# ============================================
# 尤魔 - 潜行捕食 (Submerge) - 未完成
# ============================================
func _activate_yuma_skill():
	"""尤魔：潜行捕食（未实现）"""
	print("⚠️ 技能未实现：潜行捕食")
	print("TODO: 实现尤魔的潜地技能")
	# TODO: 实现潜地效果
	# - 玩家隐身，只显示涟漪
	# - 持续2秒
	# - 无敌
	# - 浮出时造成范围伤害

# ============================================
# 恋 - 無意識 (Invisibility) - 未完成
# ============================================
func _activate_koishi_skill():
	"""恋：無意識（未实现）"""
	print("⚠️ 技能未实现：無意識")
	print("TODO: 实现恋的隐身技能")
	# TODO: 实现隐身效果
	# - 玩家隐身，显示微弱轮廓
	# - 持续3秒
	# - 移速+50%
	# - 可穿过敌人

# ============================================
# 辅助函数
# ============================================
func start_cooldown(char_id: int):
	"""开始技能冷却"""
	if char_id in SKILL_CONFIGS:
		max_cooldown = SKILL_CONFIGS[char_id].cooldown
		skill_cooldown = max_cooldown
		skill_cooldown_changed.emit(skill_cooldown, max_cooldown)

func _update_active_skills(delta):
	"""更新持续技能效果"""
	# 更新传送标记的视觉效果
	if has_gap_mark and gap_mark_sprite.visible:
		# 简单的脉冲效果
		var pulse = sin(Time.get_ticks_msec() / 200.0) * 0.3 + 0.7
		gap_mark_sprite.scale = Vector2.ONE * pulse

func is_skill_active() -> bool:
	"""检查是否有技能正在执行"""
	return is_fire_kicking or is_broom_dashing

func get_cooldown_percent() -> float:
	"""获取冷却百分比（0-1）"""
	if max_cooldown <= 0:
		return 0.0
	return skill_cooldown / max_cooldown
