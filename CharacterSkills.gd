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
var attack_speed_boost_timer: float = 0.0

# 咲夜 - 时停步法
var is_time_stopped: bool = false
var time_stop_timer: float = 0.0
var graze_triggered: bool = false

# 尤魔 - 潜行捕食
var is_submerged: bool = false
var submerge_timer: float = 0.0
var original_collision_layer: int = 0
var original_collision_mask: int = 0

# 恋恋 - 無意識
var is_invisible: bool = false
var invisibility_timer: float = 0.0
var original_speed: float = 0.0

# 技能配置 (按策划稿数值)
const SKILL_CONFIGS = {
	GameConstants.CharacterId.REIMU: {
		"name": "亚空穴",
		"cooldown": 4.0,  # 策划稿: CD 4s
	},
	GameConstants.CharacterId.MOKOU: {
		"name": "不死鸟",
		"cooldown": 5.0,  # 策划稿: CD 5s
		"hp_cost_percent": 0.1,  # 消耗10%当前生命
		"kick_damage": 50.0,  # 突进伤害
		"fire_wall_damage": 15.0,
		"fire_wall_duration": 8.0,
	},
	GameConstants.CharacterId.MARISA: {
		"name": "扫把冲锋",
		"cooldown": 3.0,  # 策划稿: CD 3s
		"damage": 30.0,
		"attack_speed_boost": 1.3,  # 结束后2秒攻速+30%
		"boost_duration": 2.0,
	},
	GameConstants.CharacterId.SAKUYA: {
		"name": "时停步法",
		"cooldown": 2.0,  # 策划稿: CD 2s
		"blink_distance": 150.0,
		"time_stop_duration": 1.5,
		"graze_radius": 50.0,
	},
	GameConstants.CharacterId.YUMA: {
		"name": "潜行捕食",
		"cooldown": 6.0,  # 策划稿: CD 6s
		"submerge_duration": 2.0,
		"emerge_damage": 80.0,
		"emerge_radius": 200.0,
	},
	GameConstants.CharacterId.KOISHI: {
		"name": "無意識",
		"cooldown": 8.0,  # 策划稿: CD 8s
		"invisibility_duration": 3.0,
		"speed_boost": 1.5,  # 移速+50%
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
# 妹红 - 不死鸟 (Phoenix) - 按策划稿实现
# ============================================
func _activate_mokou_skill():
	"""妹红：不死鸟 - 消耗HP化身火鸟突进，留下火墙"""
	if is_fire_kicking:
		return

	var config = SKILL_CONFIGS[GameConstants.CharacterId.MOKOU]

	# 消耗10%当前生命值
	if player.has_node("HealthComponent"):
		var health_comp = player.get_node("HealthComponent")
		var hp_cost = health_comp.current_hp * config.hp_cost_percent
		health_comp.take_damage(hp_cost)
		print("消耗 %.0f HP！" % hp_cost)

	# 获取移动方向
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length() < 0.1:
		input_dir = Vector2(1, 0) if player.sprite.scale.x > 0 else Vector2(-1, 0)
	input_dir = input_dir.normalized()

	# 开始火凤凰突进
	is_fire_kicking = true
	fire_kick_direction = input_dir
	fire_kick_progress = 0.0
	fire_kick_start_pos = player.global_position
	fire_trail_timer = 0.0

	# 设置无敌
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(fire_kick_duration)

	print("不死鸟！化身火鸟突进！")
	skill_activated.emit("不死鸟")

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
	"""生成火墙（持续8秒）"""
	var config = SKILL_CONFIGS[GameConstants.CharacterId.MOKOU]
	var fire_area = Area2D.new()
	fire_area.global_position = pos
	fire_area.name = "FireWall"

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
	fire_area.collision_mask = 4  # 检测敌人（第3层）

	# 添加到场景
	fire_trail_container.add_child(fire_area)

	# 按策划稿：火墙持续8秒
	var timer = get_tree().create_timer(config.fire_wall_duration)
	timer.timeout.connect(func():
		if is_instance_valid(fire_area):
			fire_area.queue_free()
	)

	# 持续伤害
	_apply_fire_trail_damage(fire_area, config.fire_wall_damage)

func _apply_fire_trail_damage(fire_area: Area2D, damage: float):
	"""火墙持续伤害"""
	var damage_timer = Timer.new()
	damage_timer.wait_time = 0.2  # 每0.2秒伤害一次
	damage_timer.autostart = true
	fire_area.add_child(damage_timer)

	damage_timer.timeout.connect(func():
		if not is_instance_valid(fire_area):
			return

		# 获取范围内的敌人
		var enemies = get_tree().get_nodes_in_group("enemy")
		for enemy in enemies:
			if enemy.has_method("take_damage"):
				var dist = fire_area.global_position.distance_to(enemy.global_position)
				if dist < 50:
					enemy.take_damage(damage)
	)

func damage_enemies_in_kick_path():
	"""对飞踢路径上的敌人造成伤害"""
	var config = SKILL_CONFIGS[GameConstants.CharacterId.MOKOU]
	var damage = config.kick_damage

	var enemies = get_tree().get_nodes_in_group("enemy")
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

		# 冲锋结束后攻速加成
		var config = SKILL_CONFIGS[GameConstants.CharacterId.MARISA]
		attack_speed_boost_timer = config.boost_duration
		SignalBus.attack_speed_modifier_changed.emit(config.attack_speed_boost)

		print("扫把冲锋结束！攻速+30% 持续2秒！")

func damage_enemies_in_dash_path():
	"""对冲锋路径上的敌人造成伤害"""
	var config = SKILL_CONFIGS[GameConstants.CharacterId.MARISA]
	var damage = config.damage

	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < 50:  # 冲锋判定范围
				enemy.take_damage(damage)

# ============================================
# 咲夜 - 时停步法 (Time Stop Blink)
# ============================================
func _activate_sakuya_skill():
	"""咲夜：时停步法 - 短距离闪烁，擦弹触发时停"""
	var config = SKILL_CONFIGS[GameConstants.CharacterId.SAKUYA]

	# 获取移动方向
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length() < 0.1:
		input_dir = Vector2(1, 0) if player.sprite.scale.x > 0 else Vector2(-1, 0)
	input_dir = input_dir.normalized()

	# 记录起始位置
	var start_pos = player.global_position
	var end_pos = start_pos + input_dir * config.blink_distance

	# 检测擦弹（闪烁路径上是否有敌方子弹）
	graze_triggered = _check_graze_on_path(start_pos, end_pos, config.graze_radius)

	# 执行闪烁
	player.global_position = end_pos
	player.velocity = Vector2.ZERO

	# 设置短暂无敌
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(0.3)

	# 如果擦弹成功，触发时停
	if graze_triggered:
		_trigger_time_stop(config.time_stop_duration)
		print("擦弹成功！触发时停 %.1f秒！" % config.time_stop_duration)
	else:
		print("时停步法！闪烁完成")

	start_cooldown(GameConstants.CharacterId.SAKUYA)
	skill_activated.emit("时停步法")

func _check_graze_on_path(start: Vector2, end: Vector2, radius: float) -> bool:
	"""检测闪烁路径上是否有敌方弹幕（擦弹判定）"""
	# 获取所有敌方子弹
	var enemy_bullets = get_tree().get_nodes_in_group("enemy_bullet")

	for bullet in enemy_bullets:
		if not is_instance_valid(bullet):
			continue
		# 计算点到线段的距离
		var bullet_pos = bullet.global_position
		var closest = _closest_point_on_segment(start, end, bullet_pos)
		var dist = closest.distance_to(bullet_pos)

		if dist < radius:
			return true

	return false

func _closest_point_on_segment(a: Vector2, b: Vector2, p: Vector2) -> Vector2:
	"""计算点p到线段ab的最近点"""
	var ab = b - a
	var ap = p - a
	var t = clamp(ap.dot(ab) / ab.length_squared(), 0.0, 1.0)
	return a + ab * t

func _trigger_time_stop(duration: float):
	"""触发全局时停"""
	is_time_stopped = true
	time_stop_timer = duration

	# 冻结所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("freeze"):
			enemy.freeze(duration)
		else:
			# 备用：直接设置process_mode
			enemy.set_process(false)
			enemy.set_physics_process(false)

	# 冻结所有敌方子弹
	var enemy_bullets = get_tree().get_nodes_in_group("enemy_bullet")
	for bullet in enemy_bullets:
		if is_instance_valid(bullet):
			bullet.set_process(false)
			bullet.set_physics_process(false)

	# 发送时停信号
	SignalBus.time_stopped.emit(duration)

func _end_time_stop():
	"""结束时停效果"""
	is_time_stopped = false

	# 解冻所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("unfreeze"):
			enemy.unfreeze()
		else:
			enemy.set_process(true)
			enemy.set_physics_process(true)

	# 解冻所有敌方子弹
	var enemy_bullets = get_tree().get_nodes_in_group("enemy_bullet")
	for bullet in enemy_bullets:
		if is_instance_valid(bullet):
			bullet.set_process(true)
			bullet.set_physics_process(true)

	SignalBus.time_resumed.emit()
	print("时停结束！")

# ============================================
# 尤魔 - 潜行捕食 (Submerge)
# ============================================
func _activate_yuma_skill():
	"""尤魔：潜行捕食 - 潜入地下无敌，浮出时AOE伤害"""
	if is_submerged:
		return

	var config = SKILL_CONFIGS[GameConstants.CharacterId.YUMA]

	# 开始潜地
	is_submerged = true
	submerge_timer = config.submerge_duration

	# 保存原始碰撞设置
	original_collision_layer = player.collision_layer
	original_collision_mask = player.collision_mask

	# 关闭碰撞（无敌+穿过敌人）
	player.collision_layer = 0
	player.collision_mask = 0

	# 设置视觉效果（变成阴影）
	if player.sprite:
		player.sprite.modulate = Color(0.2, 0.2, 0.2, 0.6)

	print("潜行捕食！潜入地下...")
	skill_activated.emit("潜行捕食")

func _process_submerge(delta):
	"""处理潜地状态"""
	if not is_submerged:
		return

	submerge_timer -= delta

	# 潜地时吸引掉落物
	_attract_items()

	# 潜地结束
	if submerge_timer <= 0:
		_emerge_from_ground()

func _attract_items():
	"""吸引全屏掉落物"""
	var items = get_tree().get_nodes_in_group("pickup")
	for item in items:
		if is_instance_valid(item):
			var dir = (player.global_position - item.global_position).normalized()
			item.global_position += dir * 500 * get_process_delta_time()

	# 也吸引经验宝石
	var gems = get_tree().get_nodes_in_group("experience_gem")
	for gem in gems:
		if is_instance_valid(gem):
			var dir = (player.global_position - gem.global_position).normalized()
			gem.global_position += dir * 500 * get_process_delta_time()

func _emerge_from_ground():
	"""从地下钻出，造成AOE伤害"""
	is_submerged = false

	# 恢复碰撞
	player.collision_layer = original_collision_layer
	player.collision_mask = original_collision_mask

	# 恢复视觉
	if player.sprite:
		player.sprite.modulate = Color.WHITE

	# 造成AOE伤害
	var config = SKILL_CONFIGS[GameConstants.CharacterId.YUMA]
	var enemies = get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < config.emerge_radius:
				enemy.take_damage(config.emerge_damage)

	# 创建AOE视觉效果
	_create_emerge_effect(config.emerge_radius)

	# 开始冷却
	start_cooldown(GameConstants.CharacterId.YUMA)
	print("钻出地面！造成 %.0f 范围伤害！" % config.emerge_damage)

func _create_emerge_effect(radius: float):
	"""创建钻出地面的视觉效果"""
	var effect = Node2D.new()
	effect.global_position = player.global_position

	var circle = ColorRect.new()
	circle.size = Vector2(radius * 2, radius * 2)
	circle.position = Vector2(-radius, -radius)
	circle.color = Color(0.6, 0.2, 0.0, 0.5)
	effect.add_child(circle)

	get_tree().current_scene.add_child(effect)

	# 0.5秒后销毁
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

# ============================================
# 恋 - 無意識 (Invisibility)
# ============================================
func _activate_koishi_skill():
	"""恋：無意識 - 完全隐身，移速提升"""
	if is_invisible:
		return

	var config = SKILL_CONFIGS[GameConstants.CharacterId.KOISHI]

	# 开始隐身
	is_invisible = true
	invisibility_timer = config.invisibility_duration

	# 保存原始移速
	if player.get("speed"):
		original_speed = player.speed
		player.speed = original_speed * config.speed_boost

	# 设置视觉效果（半透明）
	if player.sprite:
		player.sprite.modulate = Color(1.0, 1.0, 1.0, 0.2)

	# 关闭敌人碰撞（可穿过敌人）
	original_collision_layer = player.collision_layer
	original_collision_mask = player.collision_mask
	# 保留与墙壁的碰撞，但不与敌人碰撞
	player.collision_mask = player.collision_mask & ~4  # 假设敌人在第3层(bit 2)

	# 设置无敌
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(config.invisibility_duration)

	print("無意識！隐身中... 移速+50%！")
	skill_activated.emit("無意識")

func _process_invisibility(delta):
	"""处理隐身状态"""
	if not is_invisible:
		return

	invisibility_timer -= delta

	# 隐身结束
	if invisibility_timer <= 0:
		_end_invisibility()

func _end_invisibility():
	"""结束隐身效果"""
	is_invisible = false

	# 恢复移速
	if player.get("speed") and original_speed > 0:
		player.speed = original_speed

	# 恢复视觉
	if player.sprite:
		player.sprite.modulate = Color.WHITE

	# 恢复碰撞
	player.collision_layer = original_collision_layer
	player.collision_mask = original_collision_mask

	# 开始冷却
	start_cooldown(GameConstants.CharacterId.KOISHI)
	print("隐身结束！")

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

	# 更新时停计时器
	if is_time_stopped:
		time_stop_timer -= delta
		if time_stop_timer <= 0:
			_end_time_stop()

	# 更新潜地状态
	_process_submerge(delta)

	# 更新隐身状态
	_process_invisibility(delta)

	# 更新攻速加成计时器（魔理沙冲锋后）
	if attack_speed_boost_timer > 0:
		attack_speed_boost_timer -= delta
		if attack_speed_boost_timer <= 0:
			# 恢复正常攻速
			SignalBus.attack_speed_modifier_changed.emit(1.0)

func is_skill_active() -> bool:
	"""检查是否有技能正在执行"""
	return is_fire_kicking or is_broom_dashing or is_submerged or is_invisible or is_time_stopped

func get_cooldown_percent() -> float:
	"""获取冷却百分比（0-1）"""
	if max_cooldown <= 0:
		return 0.0
	return skill_cooldown / max_cooldown
