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

var spawn_warning_scene = preload("res://SpawnWarning.tscn")

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
	if not use_room_system:
		return
		
	# 房间波次生成逻辑
	if room_wave_enemies_to_spawn > 0:
		room_wave_spawn_timer += delta
		if room_wave_spawn_timer >= ROOM_WAVE_SPAWN_INTERVAL:
			room_wave_spawn_timer = 0
			_spawn_next_room_enemy()

func _spawn_next_room_enemy():
	if room_wave_enemies_to_spawn <= 0:
		return
		
	# 检查当前敌人总数
	var current_enemies = get_tree().get_nodes_in_group("enemy").size()
	if current_enemies >= max_enemies:
		return
		
	# 提前计算生成位置
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return

	var random_angle = randf() * PI * 2.0
	var spawn_pos = player.global_position + Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
	
	# 确保在地图边界内
	spawn_pos.x = clamp(spawn_pos.x, 100, 2300)
	spawn_pos.y = clamp(spawn_pos.y, 100, 1700)
	
	# 生成预警
	var warning_instance = null
	if spawn_warning_scene:
		warning_instance = spawn_warning_scene.instantiate()
		if warning_instance:
			warning_instance.global_position = spawn_pos
			game_objects_parent.add_child(warning_instance)
	else:
		print("Error: spawn_warning_scene is null")
	
	# 减少待生成计数（即使还没真正生成，避免重复触发）
	room_wave_enemies_to_spawn -= 1
	
	# 延迟生成敌人
	await get_tree().create_timer(0.8).timeout

	if not is_instance_valid(self):
		return

	# 销毁预警
	if warning_instance and is_instance_valid(warning_instance):
		if warning_instance.has_method("disappear"):
			warning_instance.disappear()
		else:
			warning_instance.queue_free()
	
	print("EnemySpawner: Spawning enemy at ", spawn_pos)
	spawn_enemy(null, spawn_pos)
	room_wave_spawned += 1

func _on_spawn_wave(count: int, room_index: int):
	"""接收来自 RoomManager 的生成信号"""
	print("[EnemySpawner] 收到生成请求: ", count, " 个敌人")
	room_wave_enemies_to_spawn = count
	room_wave_spawned = 0
	room_wave_spawn_timer = ROOM_WAVE_SPAWN_INTERVAL # 立即开始生成第一个

func spawn_enemy(config = null, pos_override = null):
	"""在随机位置或指定位置生成一个敌人"""
	if not player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		else:
			return null

	# 如果没有提供配置，根据游戏进度随机选择
	if config == null:
		config = EnemyData.get_random_enemy_for_time(game_time)

	var spawn_pos = Vector2.ZERO
	
	if pos_override != null:
		spawn_pos = pos_override
	else:
		# 随机位置（在玩家周围的一定距离）
		var random_angle = randf() * PI * 2.0
		spawn_pos = player.global_position + Vector2(cos(random_angle), sin(random_angle)) * spawn_distance
		
		# 确保在地图边界内 (100-2300, 100-1700)
		spawn_pos.x = clamp(spawn_pos.x, 100, 2300)
		spawn_pos.y = clamp(spawn_pos.y, 100, 1700)

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	
	# 设置敌人数据
	if enemy.has_method("setup_from_config"):
		enemy.setup_from_config(config)
	elif enemy.has_method("setup"):
		# 尝试为了兼容性（虽然可能会失败如果setup只接受int）
		enemy.setup(config)
	
	game_objects_parent.add_child(enemy)
	return enemy

func spawn_boss(boss_config):
	"""生成BOSS"""
	print("[EnemySpawner] 正在生成BOSS: ", boss_config.enemy_name)
	
	if not player: return
	
	var spawn_pos = player.global_position + Vector2(0, -300) # 玩家上方
	spawn_pos.x = clamp(spawn_pos.x, 500, 1900)
	spawn_pos.y = clamp(spawn_pos.y, 400, 1400)
	
	var boss = enemy_scene.instantiate()
	boss.global_position = spawn_pos
	
	if boss.has_method("setup_as_boss"):
		boss.setup_as_boss(boss_config)
	elif boss.has_method("setup"):
		boss.setup(boss_config)
		
	game_objects_parent.add_child(boss)
	return boss

func _on_spawn_boss(boss_config):
	spawn_boss(boss_config)
