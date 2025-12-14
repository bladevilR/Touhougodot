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
	NORMAL,      # 普通战斗房
	SHOP,        # 商店房（河童）
	BOSS,        # BOSS房
	ENCHANT,     # 附魔房
	REST,        # 休息房（回血）
	TREASURE     # 宝箱房
}

# 当前状态
var current_room_index: int = 0
var current_room_type: RoomType = RoomType.NORMAL
var is_room_cleared: bool = false
var current_kills: int = 0  # 当前房间击杀数
var target_kills: int = 20  # 目标击杀数（默认20）
var game_start_time: float = 0.0  # 游戏开始时间（用于Boss选择）

# 房间网络结构
class RoomNode:
	var id: int
	var type: RoomType
	var position: Vector2  # 在地图上的位置
	var connected_rooms: Array[int] = []  # 连接的房间ID列表
	var is_visited: bool = false
	var is_current: bool = false

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

	# 创建一个类似roguelike的房间网络
	# 深度0：起始房间
	# 深度1-2：普通战斗
	# 深度3：商店/附魔/宝箱
	# 深度4-5：普通战斗
	# 深度6：Boss房间

	var room_id = 0

	# 深度0：起始房间
	var start_room = RoomNode.new()
	start_room.id = room_id
	start_room.type = RoomType.NORMAL
	start_room.position = Vector2(400, 300)
	room_map.append(start_room)
	room_id += 1

	# 深度1：3个房间
	var depth1_rooms = []
	for i in range(3):
		var room = RoomNode.new()
		room.id = room_id
		room.type = RoomType.NORMAL
		room.position = Vector2(200 + i * 200, 150)
		start_room.connected_rooms.append(room.id)
		room.connected_rooms.append(start_room.id)
		depth1_rooms.append(room)
		room_map.append(room)
		room_id += 1

	# 深度2：4个房间
	var depth2_rooms = []
	for i in range(4):
		var room = RoomNode.new()
		room.id = room_id
		room.type = RoomType.NORMAL
		room.position = Vector2(150 + i * 180, 50)
		# 连接到深度1的相邻房间
		var connect_to = depth1_rooms[min(i, 2)]
		room.connected_rooms.append(connect_to.id)
		connect_to.connected_rooms.append(room.id)
		if i < 3:
			var connect_to2 = depth1_rooms[min(i + 1, 2)]
			room.connected_rooms.append(connect_to2.id)
			connect_to2.connected_rooms.append(room.id)
		depth2_rooms.append(room)
		room_map.append(room)
		room_id += 1

	# 深度3：特殊房间层（商店、附魔、宝箱）
	var special_types = [RoomType.SHOP, RoomType.ENCHANT, RoomType.TREASURE]
	var depth3_rooms = []
	for i in range(3):
		var room = RoomNode.new()
		room.id = room_id
		room.type = special_types[i]
		room.position = Vector2(200 + i * 200, -50)
		# 连接到深度2的房间
		var connect_idx = i * depth2_rooms.size() / 3
		var connect_to = depth2_rooms[connect_idx]
		room.connected_rooms.append(connect_to.id)
		connect_to.connected_rooms.append(room.id)
		depth3_rooms.append(room)
		room_map.append(room)
		room_id += 1

	# 深度4：4个房间
	var depth4_rooms = []
	for i in range(4):
		var room = RoomNode.new()
		room.id = room_id
		room.type = RoomType.NORMAL
		room.position = Vector2(150 + i * 180, -150)
		# 连接到深度3
		var connect_to = depth3_rooms[min(i, 2)]
		room.connected_rooms.append(connect_to.id)
		connect_to.connected_rooms.append(room.id)
		depth4_rooms.append(room)
		room_map.append(room)
		room_id += 1

	# 深度5：2个房间
	var depth5_rooms = []
	for i in range(2):
		var room = RoomNode.new()
		room.id = room_id
		room.type = RoomType.NORMAL
		room.position = Vector2(250 + i * 200, -250)
		# 连接到深度4的多个房间
		for j in range(2):
			var connect_idx = i * 2 + j
			var connect_to = depth4_rooms[connect_idx]
			room.connected_rooms.append(connect_to.id)
			connect_to.connected_rooms.append(room.id)
		depth5_rooms.append(room)
		room_map.append(room)
		room_id += 1

	# 深度6：Boss房间
	var boss_room = RoomNode.new()
	boss_room.id = room_id
	boss_room.type = RoomType.BOSS
	boss_room.position = Vector2(400, -350)
	for depth5_room in depth5_rooms:
		boss_room.connected_rooms.append(depth5_room.id)
		depth5_room.connected_rooms.append(boss_room.id)
	room_map.append(boss_room)

	max_depth = 6

	print("房间地图生成完成，共 ", room_map.size(), " 个房间")

func _start_room(room_index: int):
	"""开始一个房间"""
	if room_index >= room_map.size():
		print("警告：房间索引超出范围")
		return

	current_room_index = room_index
	current_kills = 0
	is_room_cleared = false

	# 设置当前房间标记
	for room in room_map:
		room.is_current = (room.id == room_index)
	room_map[room_index].is_visited = true

	current_room_type = room_map[room_index].type

	print("进入房间 ", room_index + 1, " 类型: ", _get_room_type_name(current_room_type))
	room_entered.emit(_get_room_type_name(current_room_type), room_index)

	# 发送UI更新信号
	SignalBus.room_info_updated.emit(_get_room_type_name(current_room_type), room_index)

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
	room_cleared.emit()
	print("房间清理完成! 门已打开")

	# 打开出口门（根据连接的房间数量生成多个门）
	_spawn_exit_doors()
	door_opened.emit()

func _spawn_exit_doors():
	"""生成出口门/传送门 - 在地图边缘的自然门口"""
	# 清理旧门
	for door in exit_doors:
		if is_instance_valid(door):
			door.queue_free()
	exit_doors.clear()

	var door_scene = load("res://ExitDoor.tscn")
	if not door_scene:
		print("警告：无法加载 ExitDoor.tscn")
		return

	var current_room = room_map[current_room_index]
	var connected_count = current_room.connected_rooms.size()

	if connected_count == 0:
		print("当前房间没有连接的房间")
		return

	# 获取地图尺寸
	var map_system = get_tree().get_first_node_in_group("map_system")
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 定义四个方向的门位置（在地图边缘的自然豁口处）
	var door_positions_map = {
		"north": {"pos": Vector2(map_width / 2, 150), "dir": 0},  # NORTH
		"south": {"pos": Vector2(map_width / 2, map_height - 150), "dir": 1},  # SOUTH
		"east": {"pos": Vector2(map_width - 150, map_height / 2), "dir": 2},  # EAST
		"west": {"pos": Vector2(150, map_height / 2), "dir": 3},  # WEST
	}

	# 可用方向
	var available_directions = ["north", "south", "east", "west"]

	# 根据连接房间数量选择门的位置
	var selected_directions = []
	match connected_count:
		1:
			selected_directions = ["north"]
		2:
			selected_directions = ["north", "east"]
		3:
			selected_directions = ["north", "east", "south"]
		_:
			selected_directions = available_directions

	# 生成门
	for i in range(min(connected_count, selected_directions.size())):
		var door = door_scene.instantiate()
		var dir_key = selected_directions[i]
		var door_data = door_positions_map[dir_key]

		door.position = door_data.pos
		door.set_meta("target_room_id", current_room.connected_rooms[i])

		# 设置门的方向
		door.call_deferred("set_door_direction", door_data.dir)

		# 连接信号
		door.door_entered.connect(_on_door_entered.bind(current_room.connected_rooms[i], door_data.dir))

		exit_doors.append(door)
		get_parent().add_child(door)

		# 打开门（移除竹林封印）
		door.call_deferred("open_door")

	print("生成了 ", exit_doors.size(), " 个出口门在地图边缘")

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
		match from_direction:
			0:  # NORTH - 从北门进入，出现在新房间南侧
				player.global_position = Vector2(1200, 1800)
			1:  # SOUTH - 从南门进入，出现在新房间北侧
				player.global_position = Vector2(1200, 600)
			2:  # EAST - 从东门进入，出现在新房间西侧
				player.global_position = Vector2(600, 1200)
			3:  # WEST - 从西门进入，出现在新房间东侧
				player.global_position = Vector2(1800, 1200)
		print("玩家位置设置为: ", player.global_position)

	# 清理门
	for door in exit_doors:
		if is_instance_valid(door):
			door.queue_free()
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

	# 生��附魔商店
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

func _get_room_type_name(room_type: RoomType) -> String:
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
