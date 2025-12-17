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
