extends Node2D

# EnemySpawner - 敌人生成器（支持房间波次系统）
# 可以使用时间波次模式或房间波次模式

@export var enemy_scene: PackedScene # 敌人场景预制体
@export var spawn_distance = 400.0 # 距离玩家的生成距离
@export var max_enemies = 100 # 最大敌人数量
@export var use_room_system: bool = true  # 是否使用房间系统

var player: Node2D = null
var game_time = 0.0
var active_waves = []  # 当前激活的波次及其计时器
var spawned_bosses = []  # 已生成的Boss列表

# 游戏对象父节点（用于阴影系统）
var game_objects_parent: Node = null

# 精英怪生成系统
var elite_spawn_timer: float = 0.0
const ELITE_SPAWN_START_TIME: float = 120.0  # 2分钟后开始生成精英怪
const ELITE_SPAWN_INTERVAL: float = 60.0     # 每60秒生成一只精英怪
const ELITE_SPAWN_INTERVAL_DECREASE: float = 5.0  # 每分钟减少5秒间隔
const ELITE_MIN_SPAWN_INTERVAL: float = 30.0  # 最低间隔30秒
var current_elite_interval: float = ELITE_SPAWN_INTERVAL

# 房间波次系统
var room_wave_enemies_to_spawn: int = 0
var room_wave_spawned: int = 0
var room_wave_spawn_timer: float = 0.0
const ROOM_WAVE_SPAWN_INTERVAL: float = 0.5  # 每0.5秒生成一个敌人

func _ready():
	add_to_group("enemy_spawner")

	# 查找玩家
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# 获取游戏对象父节点（用于阴影系统）
	var world = get_parent()
	if world and world.has_method("get_game_objects_parent"):
		game_objects_parent = world.get_game_objects_parent()
	else:
		game_objects_parent = get_parent()

	# 监听游戏开始信号
	SignalBus.game_started.connect(on_game_started)

	# 监听房间波次信号
	SignalBus.spawn_wave.connect(_on_spawn_wave)
	SignalBus.spawn_boss.connect(_on_spawn_boss)

	# 初始化敌人数据
	EnemyData.initialize()

func on_game_started():
	game_time = 0.0
	active_waves.clear()
	spawned_bosses.clear()
	elite_spawn_timer = 0.0
	current_elite_interval = ELITE_SPAWN_INTERVAL
	room_wave_enemies_to_spawn = 0
	room_wave_spawned = 0

func _process(delta):
	if not player or not enemy_scene:
		return

	game_time += delta

	# 房间波次模式
	if use_room_system:
		_process_room_wave_spawning(delta)
		return

	# 传统时间波次模式
	_update_active_waves()
	_check_boss_spawn()
	_check_elite_spawn(delta)
	_process_wave_spawning(delta)

# ==================== 房间波次系统 ====================

func _on_spawn_wave(enemy_count: int, room_index: int):
	"""收到房间波次生成请求"""
	room_wave_enemies_to_spawn = enemy_count
	room_wave_spawned = 0
	room_wave_spawn_timer = 0.0
	print("EnemySpawner: 收到波次请求，生成 ", enemy_count, " 个敌人")

func _on_spawn_boss(room_index: int):
	"""收到BOSS生成请求"""
	# 根据房间序号选择BOSS
	var boss_type = GameConstants.BossType.CIRNO  # 默认
	if room_index >= 20:
		boss_type = GameConstants.BossType.KAGUYA
	elif room_index >= 10:
		boss_type = GameConstants.BossType.YOUMU

	var boss_config = EnemyData.BOSSES.get(boss_type)
	if boss_config:
		spawn_boss(boss_config)

func _process_room_wave_spawning(delta):
	"""处理房间波次敌人生成 - 持续刷怪模式"""
	# 在房间系统中持续生成敌人，不限制总数
	# 只限制场上同时存在的敌人数量
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() >= max_enemies:
		return

	room_wave_spawn_timer -= delta
	if room_wave_spawn_timer <= 0:
		room_wave_spawn_timer = ROOM_WAVE_SPAWN_INTERVAL

		# 持续生成敌人
		_spawn_room_enemy()
		room_wave_spawned += 1

func _spawn_room_enemy():
	"""生成房间波次敌人"""
	if not is_instance_valid(player):
		return

	var spawn_pos = _get_random_spawn_position()
	var enemy = enemy_scene.instantiate()

	# 随机选择敌人类型
	var enemy_types = [
		GameConstants.EnemyType.KEDAMA,
		GameConstants.EnemyType.FAIRY,
		GameConstants.EnemyType.ELF,
		GameConstants.EnemyType.GHOST
	]
	var enemy_type = enemy_types[randi() % enemy_types.size()]

	# 设置敌人
	if enemy.has_method("setup"):
		enemy.setup(enemy_type, 1)

	enemy.global_position = spawn_pos
	game_objects_parent.add_child(enemy)

# ==================== 传统时间波次系统 ====================

func _update_active_waves():
	# 检查哪些波次应该激活
	for wave_config in EnemyData.WAVES:
		if game_time >= wave_config.time:
			# 检查这个波次是否已经在激活列表中
			var already_active = false
			for active_wave in active_waves:
				if active_wave.config == wave_config:
					already_active = true
					break

			if not already_active:
				active_waves.append({
					"config": wave_config,
					"timer": wave_config.interval * 3.0  # 增加到3倍间隔，避免刷怪过快
				})

func _check_boss_spawn():
	# 检查Boss生成时间点（5分钟、15分钟、30分钟）
	var boss_times = [300.0, 900.0, 1800.0]  # 5min, 15min, 30min
	var boss_types = [
		GameConstants.BossType.CIRNO,
		GameConstants.BossType.YOUMU,
		GameConstants.BossType.KAGUYA
	]

	for i in range(boss_times.size()):
		var boss_time = boss_times[i]
		var boss_type = boss_types[i]

		# 在Boss时间点前后1秒内生成，且未生成过
		if game_time >= boss_time and game_time < boss_time + 1.0:
			if not boss_type in spawned_bosses:
				var boss_config = EnemyData.BOSSES.get(boss_type)
				if boss_config:
					spawn_boss(boss_config)
					spawned_bosses.append(boss_type)

func _check_elite_spawn(delta: float):
	"""检查并生成精英怪"""
	# 2分钟后才开始生成精英怪
	if game_time < ELITE_SPAWN_START_TIME:
		return

	# 更新精英怪生成计时器
	elite_spawn_timer += delta

	# 随着时间推移，缩短精英怪生成间隔
	var minutes_passed = int(game_time / 60.0)
	current_elite_interval = max(
		ELITE_MIN_SPAWN_INTERVAL,
		ELITE_SPAWN_INTERVAL - (minutes_passed - 2) * ELITE_SPAWN_INTERVAL_DECREASE
	)

	# 达到生成间隔时生成精英怪
	if elite_spawn_timer >= current_elite_interval:
		elite_spawn_timer = 0.0
		spawn_elite()

func spawn_elite():
	"""生成精英怪"""
	if not is_instance_valid(player):
		return

	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() >= max_enemies:
		return  # 达到敌人上限

	# 获取精英怪配置
	var elite_config = EnemyData.ENEMIES.get(GameConstants.EnemyType.ELITE)
	if not elite_config:
		return

	# 在玩家周围较远位置生成（精英怪出场更隆重）
	var spawn_pos = _get_random_spawn_position()

	# 实例化敌人
	var elite = enemy_scene.instantiate()

	# 设置精英怪属性
	elite.enemy_type = GameConstants.EnemyType.ELITE

	# 根据游戏时间增强精英怪属性
	var difficulty_multiplier = 1.0 + (game_time / 300.0) * 0.5  # 每5分钟增加50%难度

	# 手动设置组件属性（因为setup_from_wave需要WaveConfig）
	var health_comp = elite.get_node_or_null("HealthComponent")
	if health_comp:
		health_comp.max_hp = elite_config.hp * difficulty_multiplier
		health_comp.current_hp = health_comp.max_hp

	elite.speed = elite_config.speed * 100.0
	elite.xp_value = int(elite_config.exp * difficulty_multiplier)
	elite.mass = elite_config.mass
	elite.enemy_data = elite_config

	# 设置视觉效果
	var sprite = elite.get_node_or_null("Sprite2D")
	if sprite:
		# 使用毛玉纹理但更大
		var texture_path = "res://assets/maoyu.png"
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
		sprite.modulate = elite_config.color  # 橙色
		sprite.scale = Vector2(elite_config.scale, elite_config.scale)

	# 设置碰撞半径
	var collision_shape = elite.get_node_or_null("CollisionShape2D")
	if collision_shape and collision_shape.shape:
		collision_shape.shape.radius = elite_config.radius

	elite.global_position = spawn_pos
	game_objects_parent.add_child(elite)

	# 精英怪出场特效
	SignalBus.screen_shake.emit(0.15, 8.0)
	SignalBus.spawn_death_particles.emit(spawn_pos, Color("#ff6600"), 30)

func _process_wave_spawning(delta):
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() >= max_enemies:
		return  # 达到敌人上限，停止生成

	for active_wave in active_waves:
		active_wave.timer -= delta

		if active_wave.timer <= 0:
			# 生成敌人
			spawn_enemy_from_wave(active_wave.config)

			# 重置计时器，增加3倍间隔，降低刷怪频率
			active_wave.timer = active_wave.config.interval * 3.0

func spawn_enemy_from_wave(wave_config: EnemyData.WaveConfig):
	if not is_instance_valid(player):
		return

	# Boss类型波次单独处理（已在_check_boss_spawn处理）
	if wave_config.enemy_type.begins_with("boss"):
		return

	# 在玩家周围随机位置生成敌人
	var spawn_pos = _get_random_spawn_position()

	# 实例化敌人
	var enemy = enemy_scene.instantiate()

	# 从波次配置设置敌人属性
	if enemy.has_method("setup_from_wave"):
		enemy.setup_from_wave(wave_config)
	elif enemy.has_method("setup"):
		# 使用旧的setup方法
		var enemy_type = _get_enemy_type_from_string(wave_config.enemy_type)
		enemy.setup(enemy_type, 1)

		# 应用波次特定的属性
		if enemy.has_method("set_stats"):
			enemy.set_stats(wave_config.hp, wave_config.damage, wave_config.speed, wave_config.exp)

	enemy.global_position = spawn_pos
	game_objects_parent.add_child(enemy)

func spawn_boss(boss_config: EnemyData.BossConfig):
	print("生成Boss: ", boss_config.enemy_name, " - ", boss_config.boss_title)

	if not is_instance_valid(player):
		return

	# 实例化敌人（Boss使用相同的敌人场景，但属性更强）
	var boss = enemy_scene.instantiate()

	# 在玩家前方生成Boss
	var spawn_pos = player.global_position + Vector2(0, -300)

	# 设置Boss属性
	if boss.has_method("setup_as_boss"):
		boss.setup_as_boss(boss_config)
	elif boss.has_method("setup"):
		# 使用通用setup方法
		boss.setup(GameConstants.EnemyType.BOSS, 100)  # 高波次值使其更强

		# 应用Boss特定属性
		if boss.has_method("set_stats"):
			boss.set_stats(boss_config.hp, boss_config.damage, boss_config.speed, boss_config.exp)

	boss.global_position = spawn_pos
	game_objects_parent.add_child(boss)

func _get_random_spawn_position() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
		
	var spawn_pos = Vector2.ZERO
	var map_system = get_tree().get_first_node_in_group("map_system")
	var map_rect = Rect2(0, 0, 10000, 10000) # Default huge map if no system
	
	if map_system and map_system.has_method("get_map_size"):
		var size = map_system.get_map_size()
		map_rect = Rect2(0, 0, size.x, size.y)
	
	# Try to find a valid spawn position
	for i in range(10): # Try 10 times to find a good spot
		var angle = randf() * PI * 2
		var distance = randf_range(600.0, 900.0) # Outside typical screen area
		
		var potential_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Clamp to map bounds
		if map_rect.has_point(potential_pos):
			spawn_pos = potential_pos
			return spawn_pos
			
	# If we couldn't find a spot (e.g. player in corner), just clamp the last attempt
	var angle = randf() * PI * 2
	var distance = 600.0
	spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	
	spawn_pos.x = clamp(spawn_pos.x, map_rect.position.x, map_rect.end.x)
	spawn_pos.y = clamp(spawn_pos.y, map_rect.position.y, map_rect.end.y)
	
	return spawn_pos

func _get_enemy_type_from_string(enemy_type_str: String) -> int:
	# 将字符串敌人类型转换为GameConstants枚举
	match enemy_type_str:
		"kedama":
			return GameConstants.EnemyType.KEDAMA
		"elf":
			return GameConstants.EnemyType.ELF
		"ghost":
			return GameConstants.EnemyType.GHOST
		"fairy":
			return GameConstants.EnemyType.FAIRY
		"elite":
			return GameConstants.EnemyType.ELITE
		_:
			return GameConstants.EnemyType.FAIRY  # 默认
