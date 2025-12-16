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

	# 延迟启动第一个房间（等待场景加载完成）
	call_deferred("_start_room", 0)

func _on_game_started():
	"""游戏开始时记录时间"""
	game_start_time = Time.get_ticks_msec() / 1000.0

func _generate_room_map():
	"""生成房间地图网络结构"""
	room_map.clear()

	var room_id = 0

	# 深度0：起始房间
	var start_room = RoomNode.new()
	start_room.id = room_id
	start_room.type = RoomType.NORMAL
	start_room.position = Vector2(0, 0) # 原点
	start_room.depth = 0
	start_room.is_cleared = false # 起始房间也要战斗！
	room_map.append(start_room)
	room_id += 1

	# 深度1：3个房间 (西、北、东)
	var depth1_offsets = [Vector2(-400, 0), Vector2(0, -400), Vector2(400, 0)]
	var depth1_rooms = []
	for i in range(3):
		var room = RoomNode.new()
		room.id = room_id
		room.type = RoomType.NORMAL
		room.position = start_room.position + depth1_offsets[i]
		room.depth = 1
		start_room.connected_rooms.append(room.id)
		room.connected_rooms.append(start_room.id)
		depth1_rooms.append(room)
		room_map.append(room)
		room_id += 1

	# 深度2：4个房间 (在深度1的基础上延伸)
	var depth2_rooms = []
	# 从左(西)房间延伸出2个
	for i in range(2):
		var room = RoomNode.new()
		room.id = room_id
		room.type = RoomType.NORMAL
		# 往西和往北延伸
		var offset = Vector2(-400, 0) if i == 0 else Vector2(0, -400)
		room.position = depth1_rooms[0].position + offset
		room.depth = 2
		depth1_rooms[0].connected_rooms.append(room.id)
		room.connected_rooms.append(depth1_rooms[0].id)
		depth2_rooms.append(room)
		room_map.append(room)
		room_id += 1
	
	# 从右(东)房间延伸出2个
	for i in range(2):
		var room = RoomNode.new()
		room.id = room_id
		room.type = RoomType.NORMAL
		# 往东和往北延伸
		var offset = Vector2(400, 0) if i == 0 else Vector2(0, -400)
		room.position = depth1_rooms[2].position + offset
		room.depth = 2
		depth1_rooms[2].connected_rooms.append(room.id)
		room.connected_rooms.append(depth1_rooms[2].id)
		depth2_rooms.append(room)
		room_map.append(room)
		room_id += 1

	# 深度3：特殊房间 (连接深度2的末端)
	var special_types = [RoomType.SHOP, RoomType.ENCHANT, RoomType.TREASURE]
	var depth3_rooms = []
	for i in range(3):
		var room = RoomNode.new()
		room.id = room_id
		room.type = special_types[i]
		# 简单堆叠在远处，坐标不再重要，只要保持不重叠即可，因为之前的连接已经决定了拓扑
		room.position = Vector2(0, -800 - i * 400) 
		room.depth = 3
		
		# 连接到深度2的房间 (这里简化连接逻辑，随便连一个没连满的)
		var parent_room = depth2_rooms[i % depth2_rooms.size()]
		parent_room.connected_rooms.append(room.id)
		room.connected_rooms.append(parent_room.id)
		
		depth3_rooms.append(room)
		room_map.append(room)
		room_id += 1

	# 后续深度简化处理... 
	# 只要确保 position 不重叠且方向大体正确
	var last_rooms = depth3_rooms
	
	# 深度4-5
	for d in range(2):
		var new_rooms = []
		for i in range(2):
			var room = RoomNode.new()
			room.id = room_id
			room.type = RoomType.NORMAL
			room.position = Vector2(-400 + i * 800, -1600 - d * 400)
			room.depth = 4 + d
			
			var parent = last_rooms[i % last_rooms.size()]
			parent.connected_rooms.append(room.id)
			room.connected_rooms.append(parent.id)
			
			new_rooms.append(room)
			room_map.append(room)
			room_id += 1
		last_rooms = new_rooms

	# 深度6：Boss房间
	var boss_room = RoomNode.new()
	boss_room.id = room_id
	boss_room.type = RoomType.BOSS
	boss_room.position = Vector2(0, -2400)
	boss_room.depth = 6
	for r in last_rooms:
		r.connected_rooms.append(boss_room.id)
		boss_room.connected_rooms.append(r.id)
	room_map.append(boss_room)

	max_depth = 6

	print("房间地图生成完成，共 ", room_map.size(), " 个房间")

func _start_room(room_index: int):
	"""开始一个房间"""
	if room_index >= room_map.size():
		print("警告：房间索引超出范围")
		return

	current_room_index = room_index
	var current_room_node = room_map[room_index]
	
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

	# 发送UI更新信号
	SignalBus.room_info_updated.emit(_get_room_type_name(current_room_type), room_index)

	# 如果房间已清理，直接开门，跳过生成敌人
	if is_room_cleared:
		print("房间已清理，跳过战斗")
		_spawn_exit_doors()
		door_opened.emit()
		return

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
	
	room_cleared.emit()
	print("房间清理完成! 门已打开")

	# 打开出口门（根据连接的房间数量生成多个门）
	_spawn_exit_doors()
	door_opened.emit()

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
	var door_positions = {
		"north": {"pos": Vector2(map_width / 2, 150), "dir": 0},
		"south": {"pos": Vector2(map_width / 2, map_height - 150), "dir": 1},
		"east": {"pos": Vector2(map_width - 150, map_height / 2), "dir": 2},
		"west": {"pos": Vector2(150, map_height / 2), "dir": 3}
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
		door.door_entered.connect(_on_door_entered.bind(target_id, door_data.dir))
		
		exit_doors.append(door)
		get_parent().add_child(door)
		
		# 打开门
		door.call_deferred("open_door")

	print("生成了 ", exit_doors.size(), " 个定向出口门")

func _on_door_entered(from_direction: int, target_room_id: int, _enter_dir: int):
	"""玩家进入传送门"""
	print("从方向 ", from_direction, " 进入传送门，前往房间 ", target_room_id)

	# 根据进入方向设置玩家在新房间的位置
	# 从北门进入 → 出现在南侧
	# 从南门进入 → 出现在北侧
	# 从东门进入 → 出现在西侧
	# 从西门进入 → 出现在东侧
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# 注意：from_direction 是门的朝向 (NORTH=0, SOUTH=1...)
		match from_direction:
			0:  # NORTH
				player.global_position = Vector2(1200, 1800 - 300) # 南侧
			1:  # SOUTH
				player.global_position = Vector2(1200, 300) # 北侧
			2:  # EAST
				player.global_position = Vector2(300, 900) # 西侧
			3:  # WEST
				player.global_position = Vector2(2100, 900) # 东侧
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
	"""商店房间 - 河童商店"""
	print("商店房间 - 与河童对话购买道具")

	# 生成河童NPC（如果不存在）
	var nitori = get_tree().get_first_node_in_group("npc")
	if not nitori:
		var nitori_scene = load("res://NitoriNPC.tscn")
		if nitori_scene:
			var npc = nitori_scene.instantiate()
			npc.position = Vector2(1200, 900)
			get_parent().add_child(npc)

	# 商店房间直接打开出口
	await get_tree().create_timer(0.5).timeout
	_on_room_cleared()

func _start_boss_room():
	"""BOSS房间 - 根据玩家到达时间选择Boss"""
	print("BOSS房间 - 准备战斗!")

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

	# 显示对话（通过UI信号）
	SignalBus.emit_signal("boss_dialogue", _get_boss_name(boss_type), boss_dialogue)

	# 设置击杀目标
	target_kills = 1  # Boss算1个击杀目标
	current_kills = 0

	# 延迟生成Boss（给玩家看对话的时间）
	await get_tree().create_timer(3.0).timeout

	# 生成BOSS（传递boss类型）
	var boss_config = EnemyData.BOSSES.get(boss_type)
	if boss_config:
		var spawner = get_tree().get_first_node_in_group("enemy_spawner")
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