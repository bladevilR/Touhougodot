extends Node2D

# EnemySpawner - 敌人生成器（基于波次系统）
# 使用EnemyData.WAVES配置进行波次生成

@export var enemy_scene: PackedScene # 敌人场景预制体
@export var spawn_distance = 400.0 # 距离玩家的生成距离
@export var max_enemies = 100 # 最大敌人数量

var player: Node2D = null
var game_time = 0.0
var active_waves = []  # 当前激活的波次及其计时器
var spawned_bosses = []  # 已生成的Boss列表

func _ready():
	# 查找玩家
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	# 监听游戏开始信号
	SignalBus.game_started.connect(on_game_started)

	# 初始化敌人数据
	EnemyData.initialize()

func on_game_started():
	game_time = 0.0
	active_waves.clear()
	spawned_bosses.clear()
	print("敌人生成器启动 - 波次系统已加载")

func _process(delta):
	if not player or not enemy_scene:
		return

	game_time += delta

	# 更新激活的波次
	_update_active_waves()

	# 检查是否应该生成Boss
	_check_boss_spawn()

	# 处理所有激活波次的生成
	_process_wave_spawning(delta)

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
					"timer": wave_config.interval  # 第一次也要等待interval秒再生成
				})
				print("波次激活: ", wave_config.enemy_type, " - 每", wave_config.interval, "秒生成")

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

func _process_wave_spawning(delta):
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() >= max_enemies:
		return  # 达到敌人上限，停止生成

	for active_wave in active_waves:
		active_wave.timer -= delta

		if active_wave.timer <= 0:
			# 生成敌人
			spawn_enemy_from_wave(active_wave.config)

			# 重置计时器
			active_wave.timer = active_wave.config.interval

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
	get_parent().add_child(enemy)

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
	get_parent().add_child(boss)

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
		_:
			return GameConstants.EnemyType.FAIRY  # 默认
