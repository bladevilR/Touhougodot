extends Node
class_name RoomManager

# RoomManager - 房间/关卡管理系统
# 管理房间类型、击杀目标、门/传送门、房间地图

signal room_cleared
signal room_entered(room_type: String, room_index: int)
signal door_opened
signal kill_progress_updated(current_kills: int, target_kills: int)  # 击杀进度更新

# 房间类型
enum RoomType {
	NORMAL = 0,      # 普通战斗房
	SHOP = 1,        # 商店房（河童）
	BOSS = 2,        # BOSS房
	ENCHANT = 3,     # 附魔房
	REST = 4,        # 休息房（回血）
	TREASURE = 5     # 宝箱房
}

# 当前状态
var current_room_index: int = 0
var current_room_type = 0 # 默认为 NORMAL (0)
var is_room_cleared: bool = false
var current_kills: int = 0  # 当前房间击杀数
var target_kills: int = 20  # 目标击杀数（默认20）
var game_start_time: float = 0.0  # 游戏开始时间（用于Boss选择）
var marisa_spawned: bool = false # 魔理沙是否已生成
var entered_room_count: int = 0  # 玩家进入的房间总数计数

# 房间网络结构
class RoomNode:
	var id: int
	var type = 0 # 默认为 NORMAL (0)
	var position: Vector2  # 在地图上的位置
	var connected_rooms: Array[int] = []  # 连接的房间ID列表
	var is_visited: bool = false
	var is_current: bool = false
	var is_cleared: bool = false # 是否已清理
	var depth: int = 0 # 房间深度

var room_map: Array[RoomNode] = []  # 房间网络
var max_depth: int = 0  # 最大深度（Boss房间深度）

# 门/传送门引用
var exit_doors: Array[Node2D] = []  # 可以有多个门

# 配置
const ENEMIES_PER_ROOM_BASE = 20
const ENEMIES_INCREASE_PER_ROOM = 2

func _ready():
	add_to_group("room_manager")

	# 监听敌人死亡信号
	SignalBus.enemy_killed.connect(_on_enemy_killed)

	# 监听游戏开始信号，记录开始时间
	SignalBus.game_started.connect(_on_game_started)

	# 生成房间地图网络
	_generate_room_map()

	# 等待所有管理器初始化完成（确保 RoomLayoutManager 已准备好）
	await get_tree().create_timer(0.1).timeout

	# 启动第一个房间
	_start_room(0)

func _on_game_started():
	"""游戏开始时记录时间"""
	game_start_time = Time.get_ticks_msec() / 1000.0

func reset_dungeon():
	"""重置地牢并重新生成地图"""
	print("RoomManager: 重置地牢...")
	randomize() # 更新随机种子
	
	# 重置状态
	current_room_index = 0
	entered_room_count = 0
	marisa_spawned = false
	current_kills = 0
	is_room_cleared = false
	
	# 清理旧门
	for door in exit_doors:
		if is_instance_valid(door):
			door.queue_free()
	exit_doors.clear()
	
	# 重新生成地图
	_generate_room_map()
	
	# 重置玩家状态和位置
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2(1200, 900)
		if player.has_method("reset_state"): # 假设有这个方法
			player.reset_state()
		elif player.get("health_comp"):
			player.health_comp.current_hp = player.health_comp.max_hp
			SignalBus.player_health_changed.emit(player.health_comp.current_hp, player.health_comp.max_hp)

	# 启动初始房间
	await get_tree().process_frame
	_start_room(0)

func _create_room_node(id: int, type: int, pos: Vector2, depth: int) -> RoomNode:
	var node = RoomNode.new()
	node.id = id
	node.type = type
	node.position = pos
	node.depth = depth
	node.is_cleared = false
	node.is_visited = false
	return node

func _generate_room_map():
	"""程序化生成房间地图网络结构"""
	room_map.clear()
	var occupied_positions = {} # 用于防止重叠: Vector2(grid_x, grid_y) -> RoomNode
	var room_id_counter = 0
	
	# 1. 起始房间 (Depth 0)
	var start_node = _create_room_node(room_id_counter, RoomType.NORMAL, Vector2(0,0), 0)
	room_map.append(start_node)
	occupied_positions[Vector2(0,0)] = start_node
	room_id_counter += 1
	
	var current_depth_rooms = [start_node]
	var logical_spacing = 600.0 # 逻辑坐标间距
	
	# 2. 生成 Depth 1 到 5 (外围 -> 深处)
	for d in range(1, 6):
		var next_depth_rooms = []
		current_depth_rooms.shuffle() # 随机打乱生成顺序
		
		var made_connection_for_depth = false # 确保这一层至少生成了一个房间
		
		for parent_room in current_depth_rooms:
			# 决定分支数量
			var child_count = 0
			var roll = randf()
			
			if d == 1: 
				child_count = randi_range(2, 3) # 第一层必须多分叉
			elif d < 3:
				child_count = 1 if roll < 0.3 else 2 # 浅层有几率分叉
			else:
				child_count = 1 if roll < 0.7 else 2 # 深处趋向线性，偶尔分叉
			
			# 如果是该层最后一个父节点且还没生成任何子节点，强制生成
			if parent_room == current_depth_rooms.back() and not made_connection_for_depth and child_count == 0:
				child_count = 1
				
			# 尝试四个方向
			var directions = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]
			directions.shuffle()
			
			for dir in directions:
				if child_count <= 0: break
				
				# 计算逻辑坐标 key
				var parent_grid_pos = (parent_room.position / logical_spacing).round()
				var new_grid_pos = parent_grid_pos + dir
				
				if not occupied_positions.has(new_grid_pos):
					# 确定房间类型
					var new_type = RoomType.NORMAL
					# Depth 3+ 开始有几率生成特殊房间
					if d >= 2 and randf() < 0.2:
						var type_roll = randf()
						if type_roll < 0.4: new_type = RoomType.TREASURE
						elif type_roll < 0.7: new_type = RoomType.REST
						# Shop主要靠河童事件，这里也可以放一点
					
					var new_room = _create_room_node(room_id_counter, new_type, new_grid_pos * logical_spacing, d)
					room_id_counter += 1
					
					# 建立双向连接
					parent_room.connected_rooms.append(new_room.id)
					new_room.connected_rooms.append(parent_room.id)
					
					room_map.append(new_room)
					occupied_positions[new_grid_pos] = new_room
					next_depth_rooms.append(new_room)
					
					child_count -= 1
					made_connection_for_depth = true
		
		if next_depth_rooms.size() > 0:
			current_depth_rooms = next_depth_rooms
		else:
			print("警告：深度 ", d, " 生成中断！")
			break

	# 3. 深度6：Boss房间
	if current_depth_rooms.size() > 0:
		# 选择最远的一个房间作为Boss房入口
		var boss_entry = current_depth_rooms[0]
		var boss_grid_pos = (boss_entry.position / logical_spacing).round() + Vector2(0, -1) # 默认往北
		
		# 尝试找个空位
		var dirs = [Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1)]
		for dir in dirs:
			var try_pos = (boss_entry.position / logical_spacing).round() + dir
			if not occupied_positions.has(try_pos):
				boss_grid_pos = try_pos
				break
				
		var boss_room = _create_room_node(room_id_counter, RoomType.BOSS, boss_grid_pos * logical_spacing, 6)
		boss_entry.connected_rooms.append(boss_room.id)
		boss_room.connected_rooms.append(boss_entry.id)
		room_map.append(boss_room)
		max_depth = 6
	
	print("新地图生成完成，共 ", room_map.size(), " 个房间")

func get_active_directions() -> Array:
	"""获取当前房间的活动连接方向 (用于地图生成避让)"""
	var directions = []
	if current_room_index < 0 or current_room_index >= room_map.size():
		return directions
		
	var current_room = room_map[current_room_index]
	
	# 计算所有连接房间的方向
	for target_id in current_room.connected_rooms:
		if target_id >= room_map.size(): continue
		var target_room = room_map[target_id]
		var direction_vec = target_room.position - current_room.position
		
		# 判断主要方向 (0:N, 1:S, 2:E, 3:W - 与 ExitDoor.DoorDirection 对应)
		# 注意：ExitDoor enum: NORTH=0, SOUTH=1, EAST=2, WEST=3
		if abs(direction_vec.x) > abs(direction_vec.y):
			# 东西向
			if direction_vec.x > 0: directions.append(2) # East
			else: directions.append(3) # West
		else:
			# 南北向
			if direction_vec.y > 0: directions.append(1) # South
			else: directions.append(0) # North
			
	return directions

func _start_room(room_index: int):
	"""开始一个房间"""
	# 清理上一个房间的残留物 (全面清理)
	get_tree().call_group("bullet", "queue_free")
	get_tree().call_group("enemy_bullet", "queue_free") # 敌人子弹
	get_tree().call_group("pickup", "queue_free")
	get_tree().call_group("experience_gem", "queue_free")
	get_tree().call_group("treasure_chest", "queue_free") # 宝箱
	get_tree().call_group("fire_wall", "queue_free") # 火墙残留
	get_tree().call_group("npc", "queue_free") # 清理NPC (河童)
	get_tree().call_group("enchant_shop", "queue_free") # 清理附魔店 (魔理沙)
	
	if room_index >= room_map.size():
		print("警告：房间索引超出范围")
		return

	current_room_index = room_index
	var current_room_node = room_map[room_index]
	
	if not current_room_node:
		print("严重错误：房间节点为空！")
		return
	
	current_kills = 0
	is_room_cleared = current_room_node.is_cleared

	# 设置当前房间标记
	for room in room_map:
		room.is_current = (room.id == room_index)
	current_room_node.is_visited = true

	current_room_type = current_room_node.type

	print("进入房间 ", room_index + 1, " 类型: ", _get_room_type_name(current_room_type), " 深度: ", current_room_node.depth)
	room_entered.emit(_get_room_type_name(current_room_type), room_index)

	# 更新光照环境
	var map_system = get_tree().get_first_node_in_group("map_system")
	if map_system and map_system.has_method("update_environment"):
		map_system.update_environment(current_room_node.depth)
		
		# 更新雾效
		if map_system.has_method("set_fog_density"):
			if current_room_node.depth < 3:
				map_system.set_fog_density(0.25) # 外围薄雾
			else:
				map_system.set_fog_density(0.05) # 深处几乎无雾，只有黑暗光柱

	# 发送UI更新信号
	SignalBus.room_info_updated.emit(_get_room_type_name(current_room_type), room_index)

	# 增加进入房间计数
	entered_room_count += 1
	print("已进入第 ", entered_room_count, " 个房间")

	var npc_spawned = false

	# 1. 魔理沙只出现在竹林深处的第一个房间 (Depth = 3)
	if current_room_node.depth == 3 and not marisa_spawned:
		# 再次检查是否已有附魔店 (防止重复)
		if get_tree().get_nodes_in_group("enchant_shop").size() == 0:
			_spawn_marisa_shop()
		marisa_spawned = true
		npc_spawned = true

	# 2. 河童只出现在玩家进入的第三个房间 (Count = 3)
	if entered_room_count == 3:
		# 再次检查是否已有NPC (防止重复)
		if get_tree().get_nodes_in_group("npc").size() == 0:
			_spawn_nitori_shop()
		npc_spawned = true

	# 如果生成了NPC，该房间变为安全房（直接清理）
	if npc_spawned:
		print("重要NPC出现，房间转为安全区")
		_on_room_cleared()
		# 确保门已生成
		if exit_doors.size() == 0:
			_spawn_exit_doors()
			door_opened.emit()
		return # 跳过后续房间类型逻辑（如生成敌人）

	# 根据房间类型执行不同逻辑
	match current_room_type:
		RoomType.NORMAL:
			_start_combat_room()
		RoomType.SHOP:
			_start_shop_room()
		RoomType.BOSS:
			_start_boss_room()
		RoomType.ENCHANT:
			_start_enchant_room()
		RoomType.TREASURE:
			_start_treasure_room()
		RoomType.REST:
			_start_rest_room()

	# 如果房间已清理，生成门
	if is_room_cleared:
		_spawn_exit_doors()
		door_opened.emit()
		print("房间已清理，生成门")
	else:
		# 用户要求：所有门始终开启
		_spawn_exit_doors()
		door_opened.emit()
		print("所有门已开启")

	# 在起始房间生成教程触发器
	if room_index == 0:
		_spawn_tutorial_trigger()

func _start_combat_room():
	"""开始战斗房间 - 基于击杀数"""
	target_kills = ENEMIES_PER_ROOM_BASE + (current_room_index * ENEMIES_INCREASE_PER_ROOM)
	current_kills = 0

	print("战斗房间：需要击败 ", target_kills, " 个敌人")

	# 发送UI更新
	SignalBus.wave_info_updated.emit(0, target_kills)  # 重用波次信号显示击杀进度
	kill_progress_updated.emit(0, target_kills)

	# 一次性生成所有敌人
	SignalBus.spawn_wave.emit(target_kills, current_room_index)

func _on_enemy_killed(xp_value, position):
	"""敌人被击杀"""
	if current_room_type != RoomType.NORMAL and current_room_type != RoomType.BOSS:
		return

	current_kills += 1

	# 发送击杀进度更新
	kill_progress_updated.emit(current_kills, target_kills)
	SignalBus.wave_info_updated.emit(current_kills, target_kills)

	print("击杀进度: ", current_kills, "/", target_kills)

	# 检查是否完成击杀目标
	if current_kills >= target_kills:
		_on_room_cleared()

func _on_room_cleared():
	"""房间清理完成"""
	if is_room_cleared:
		return

	is_room_cleared = true
	room_map[current_room_index].is_cleared = true # 标记为已清理

	# 生成通关宝箱（在房间中心位置）
	_spawn_clear_reward_chest()

	room_cleared.emit()
	print("房间清理完成!")

func _spawn_clear_reward_chest():
	"""生成房间通关奖励宝箱"""
	var chest_scene = load("res://TreasureChest.tscn")
	if not chest_scene:
		print("警告：无法加载 TreasureChest.tscn")
		return

	var chest = chest_scene.instantiate()
	# 在房间中心位置生成宝箱
	chest.position = Vector2(1200, 900)
	get_parent().call_deferred("add_child", chest)
	print("通关宝箱已生成！")

func _spawn_exit_doors():
	"""生成出口门/传送门 - 根据连接房间的相对位置 (修复拓扑)"""
	# 清理旧门
	for door in exit_doors:
		if is_instance_valid(door):
			door.call_deferred("queue_free")
	exit_doors.clear()

	var door_scene = load("res://ExitDoor.tscn")
	if not door_scene:
		print("警告：无法加载 ExitDoor.tscn")
		return

	var current_room = room_map[current_room_index]
	
	# 获取地图尺寸
	var map_width = 2400
	var map_height = 1800
	var map_system = get_tree().get_first_node_in_group("map_system")
	if map_system and "MAP_WIDTH" in map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 定义门的位置配置
	# 留出的空间小一点（80px），形成小凹口
	var door_positions = {
		"north": {"pos": Vector2(map_width / 2, 80), "dir": 0},
		"south": {"pos": Vector2(map_width / 2, map_height - 80), "dir": 1},
		"east": {"pos": Vector2(map_width - 80, map_height / 2), "dir": 2},
		"west": {"pos": Vector2(80, map_height / 2), "dir": 3}
	}

	# 遍历连接的房间，根据相对方向生成门
	for target_id in current_room.connected_rooms:
		if target_id >= room_map.size(): continue
		
		var target_room = room_map[target_id]
		var direction_vec = target_room.position - current_room.position
		
		var door_key = ""
		
		# 判断主要方向
		if abs(direction_vec.x) > abs(direction_vec.y):
			# 东西向
			if direction_vec.x > 0: door_key = "east"
			else: door_key = "west"
		else:
			# 南北向
			if direction_vec.y > 0: door_key = "south"
			else: door_key = "north"
			
		var door_data = door_positions[door_key]
		var door = door_scene.instantiate()
		
		door.position = door_data.pos
		door.set_meta("target_room_id", target_id)
		
		# 设置门的方向
		door.call_deferred("set_door_direction", door_data.dir)
		
		# 连接信号
		door.door_entered.connect(_on_door_entered.bind(target_id))
		
		exit_doors.append(door)
		get_parent().add_child(door)

		# 清除门位置附近的竹子（使用函数开头定义的map_system变量）
		if map_system and map_system.has_method("clear_bamboo_for_door"):
			map_system.call_deferred("clear_bamboo_for_door", door_data.pos, door_data.dir)

		# 打开门
		door.call_deferred("open_door")

	print("生成了 ", exit_doors.size(), " 个定向出口门")

func _on_door_entered(from_direction: int, target_room_id: int):
	"""玩家进入传送门"""
	print("从方向 ", from_direction, " 进入传送门，前往房间 ", target_room_id)

	# 根据进入方向设置玩家在新房间的位置
	# 从北门进入 → 出现在南侧
	# 从南门进入 → 出现在北侧
	# 从东门进入 → 出现在西侧
	# 从西门进入 → 出现在东侧
	var player = get_tree().get_first_node_in_group("player")
	if player:
		match from_direction:
			0:  # NORTH - 从北门进入，出现在新房间南侧 (远离南门)
				player.global_position = Vector2(1200, 1500)
			1:  # SOUTH - 从南门进入，出现在新房间北侧 (远离北门)
				player.global_position = Vector2(1200, 300)
			2:  # EAST - 从东门进入，出现在新房间西侧 (远离西门)
				player.global_position = Vector2(300, 900)
			3:  # WEST - 从西门进入，出现在新房间东侧 (远离东门)
				player.global_position = Vector2(2100, 900)
		print("玩家位置设置为: ", player.global_position)

	# 清理门
	for door in exit_doors:
		if is_instance_valid(door):
			door.call_deferred("queue_free")
	exit_doors.clear()

	# 清理当前房间的敌人（如果有）
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy.queue_free()

	# 开始目标房间
	_start_room(target_room_id)

# ==================== 特殊房间逻辑 ====================

func _start_shop_room():
	"""商店房间 - 商店开业"""
	print("商店房间 - 商店开业")
	# 注意：河童现在只在第3个房间出现，普通商店房可能只是装饰或空的
	
	# 商店房间直接打开出口
	await get_tree().create_timer(0.5).timeout
	_on_room_cleared()

func _spawn_nitori_shop():
	"""生成河童商店"""
	print("河童出现了！")
	var nitori_scene = load("res://NitoriNPC.tscn")
	if nitori_scene:
		var npc = nitori_scene.instantiate()
		npc.position = Vector2(1600, 900) # 右侧
		get_parent().call_deferred("add_child", npc)
	
	# 确保不刷怪
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner:
		spawner.room_wave_enemies_to_spawn = 0

func _start_boss_room():
	"""BOSS房间 - 根据玩家到达时间选择Boss"""
	print("BOSS房间 - 准备战斗!")
	
	# [修复] 强制清理所有残留小怪，确保Boss战纯净
	get_tree().call_group("enemy", "queue_free")
	
	# [修复] 确保生成器不会生成小怪
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner:
		spawner.room_wave_enemies_to_spawn = 0
		spawner.room_wave_spawned = 0

	# 计算玩家到达Boss房间的时间（秒）
	var elapsed_time = (Time.get_ticks_msec() / 1000.0) - game_start_time
	var minutes = elapsed_time / 60.0

	# 根据时间选择Boss
	var boss_type = GameConstants.BossType.CIRNO  # 默认（10分钟后）
	var boss_dialogue = "你来找辉夜吗，刚看到她跟妖梦一起走了"

	if minutes <= 5.0:
		# 5分钟内：辉夜
		boss_type = GameConstants.BossType.KAGUYA
		boss_dialogue = "哦呀，来得这么早，真是执着呢"
	elif minutes <= 8.0:
		# 8分钟内：妖梦
		boss_type = GameConstants.BossType.YOUMU
		boss_dialogue = "抱歉 暂时不能让你打扰幽幽子大人她们的计划，我来做你的对手"
	# 否则是琪露诺（10分钟后）

	print("Boss出现: ", _get_boss_name(boss_type), " (", int(minutes), " 分钟)")
	print("Boss台词: ", boss_dialogue)

	# 显示对话（通过UI信号） - 替换为新的对话系统
	# SignalBus.emit_signal("boss_dialogue", _get_boss_name(boss_type), boss_dialogue)
	
	if boss_type == GameConstants.BossType.KAGUYA:
		var kaguya_dialogue = [
			{"speaker": "辉夜", "text": "啊啦，妹红酱这么早就急着来找我，人家有点开心呢", "portrait": "res://assets/characters/4C.png"},
			{"speaker": "妹红", "text": "少说废话", "portrait": "res://assets/characters/1C.png"},
			{"speaker": "辉夜", "text": "果然还是这么急躁呀", "portrait": "res://assets/characters/4C.png"},
			{"speaker": "妹红", "text": "果然还是先打到你闭嘴好了", "portrait": "res://assets/characters/1C.png"},
			{"speaker": "辉夜", "text": "……", "portrait": "res://assets/characters/4C.png"},
			{"speaker": "辉夜", "text": "……果然很急躁呢", "portrait": "res://assets/characters/42C.png"},
		]
		await _play_dialogue(kaguya_dialogue)
	else:
		# 其他Boss的默认对话
		var default_boss_dialogue = [
			{"speaker": _get_boss_name(boss_type), "text": boss_dialogue, "portrait": _get_boss_portrait_path(boss_type)},
		]
		await _play_dialogue(default_boss_dialogue)

	# 设置击杀目标
	target_kills = 1  # Boss算1个击杀目标
	current_kills = 0

	# 延迟生成Boss（给玩家看对话的时间）
	await get_tree().create_timer(1.0).timeout # 对话结束后只需短暂停顿

	# 生成BOSS（传递boss类型）
	var boss_config = EnemyData.BOSSES.get(boss_type)
	if boss_config:
		# 复用之前获取的 spawner
		if spawner and spawner.has_method("spawn_boss"):
			spawner.spawn_boss(boss_config)

func _start_enchant_room():
	"""附魔房间"""
	print("附魔房间 - 使用転流购买元素附魔")

	# 生附魔商店
	var enchant_shop_scene = load("res://EnchantShop.tscn")
	if enchant_shop_scene:
		var shop = enchant_shop_scene.instantiate()
		shop.position = Vector2(1200, 900)
		get_parent().add_child(shop)

	# 延迟开门
	await get_tree().create_timer(0.5).timeout
	_on_room_cleared()

func _start_treasure_room():
	"""宝箱房间"""
	print("宝箱房间 - 获取奖励!")

	# 生成宝箱
	var chest_scene = load("res://TreasureChest.tscn")
	if chest_scene:
		var chest = chest_scene.instantiate()
		chest.position = Vector2(1200, 900)
		get_parent().add_child(chest)

	# 延迟开门
	await get_tree().create_timer(0.5).timeout
	_on_room_cleared()

func _start_rest_room():
	"""休息房间"""
	print("休息房间 - 回复生命值")

	# 恢复玩家生命
	var player = get_tree().get_first_node_in_group("player")
	if player and player.health_comp:
		player.health_comp.current_hp = player.health_comp.max_hp
		SignalBus.player_health_changed.emit(player.health_comp.current_hp, player.health_comp.max_hp)

	# 延迟开门
	await get_tree().create_timer(1.0).timeout
	_on_room_cleared()

# ==================== 工具函数 ====================

func _play_dialogue(data: Array):
	"""使用统一的对话系统播放对话"""
	var dm = _get_dialogue_manager()
	if dm:
		dm.show_sequence(data)
		await dm.dialogue_finished
	else:
		print("Error: Dialogue Manager not found!")
		await get_tree().create_timer(1.0).timeout

func _get_dialogue_manager() -> Node:
	# 检查是否存在 DialogueLayer/DialogueManager (在当前场景中查找)
	var world = get_tree().current_scene
	if not world: return null

	var existing_layer = world.get_node_or_null("DialogueLayer")
	if existing_layer:
		return existing_layer.get_node_or_null("DialogueManager")

	# 创建新的 Layer 和 Manager
	var layer = CanvasLayer.new()
	layer.layer = 128 # 确保在最上层
	layer.name = "DialogueLayer"
	world.add_child(layer)

	var DialoguePortraitScript = load("res://DialoguePortrait.gd")
	var dm = DialoguePortraitScript.new()
	dm.name = "DialogueManager"
	layer.add_child(dm)

	return dm

func _get_room_type_name(room_type: int) -> String:
	match room_type:
		RoomType.NORMAL: return "普通"
		RoomType.SHOP: return "商店"
		RoomType.BOSS: return "BOSS"
		RoomType.ENCHANT: return "附魔"
		RoomType.TREASURE: return "宝箱"
		RoomType.REST: return "休息"
		_: return "未知"

func _get_boss_name(boss_type: int) -> String:
	"""根据Boss类型返回Boss名字"""
	match boss_type:
		GameConstants.BossType.CIRNO: return "琪露诺"
		GameConstants.BossType.YOUMU: return "妖梦"
		GameConstants.BossType.KAGUYA: return "辉夜"
		_: return "未知Boss"

func _get_boss_portrait_path(boss_type: int) -> String:
	"""根据Boss类型返回Boss对话立绘路径"""
	match boss_type:
		GameConstants.BossType.CIRNO: return "res://assets/characters/cirno_portrait.png" # 假设存在琪露诺立绘
		GameConstants.BossType.YOUMU: return "res://assets/characters/youmu_portrait.png" # 假设存在妖梦立绘
		GameConstants.BossType.KAGUYA: return "res://assets/characters/4C.png"
		_: return ""

func get_current_room_info() -> Dictionary:
	return {
		"room_index": current_room_index,
		"room_type": _get_room_type_name(current_room_type),
		"current_kills": current_kills,
		"target_kills": target_kills,
		"is_cleared": is_room_cleared
	}

func get_room_map_data() -> Array[RoomNode]:
	"""返回房间地图数据供UI使用"""
	return room_map

func _spawn_tutorial_trigger():
	"""在起始房间生成教程触发器"""
	# 检查是否已存在教程触发器
	var existing_trigger = get_tree().get_first_node_in_group("tutorial_trigger")
	if existing_trigger:
		return

	# 加载教程触发器场景/脚本
	var TutorialTriggerScript = load("res://TutorialTrigger.gd")
	if not TutorialTriggerScript:
		print("警告：无法加载 TutorialTrigger.gd")
		return

	# TutorialTrigger 继承自 Area2D，所以需要创建 Area2D 实例
	var trigger = TutorialTriggerScript.new()

	# 将触发器放在玩家出生点附近
	var player = get_tree().get_first_node_in_group("player")
	if player:
		trigger.position = player.global_position + Vector2(150, -100)
	else:
		trigger.position = Vector2(1200, 800)  # 默认位置

	# 添加到场景
	var world = get_parent()
	if world:
		world.call_deferred("add_child", trigger)
		print("教程触发器已生成在起始房间")

func _spawn_marisa_shop():
	"""生成魔理沙附魔店"""
	print("竹林深处 - 魔理沙出现了！")
	var enchant_shop_scene = load("res://EnchantShop.tscn")
	if enchant_shop_scene:
		var shop = enchant_shop_scene.instantiate()
		if shop:
			# 放在房间一侧，避免与门重叠
			shop.position = Vector2(600, 900) 
			get_parent().call_deferred("add_child", shop)
		else:
			print("错误：无法实例化 EnchantShop")
	else:
		print("错误：找不到 EnchantShop.tscn")
