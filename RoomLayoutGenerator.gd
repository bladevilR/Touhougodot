extends Node
class_name RoomLayoutGenerator

# RoomLayoutGenerator - 生成不同风格的房间布局
# 为每个房间创建独特的竹子和装饰物排列

enum LayoutStyle {
	SPARSE,      # 稀疏 - 少量障碍物
	DENSE,       # 密集 - 大量竹林
	CORRIDOR,    # 走廊 - 中间通道两侧竹林
	CIRCULAR,    # 环形 - 中心空地周围竹林
	CROSS,       # 十字 - 十字通道分割四个区域
	MAZE,        # 迷宫 - 复杂的竹林迷宫
	ARENA,       # 竞技场 - 大空地适合战斗
}

static func generate_room_layout(room_type: int, room_index: int, map_system: Node, active_directions: Array = []) -> Dictionary:
	"""根据房间类型和索引生成布局"""
	var layout = {
		"bamboos": [],
		"decorations": [],
		"style": LayoutStyle.SPARSE
	}

	# 根据房间索引选择布局风格
	var style = _get_layout_style_for_room(room_type, room_index)
	layout.style = style

	# 生成对应风格的布局 (传递 active_directions)
	match style:
		LayoutStyle.SPARSE:
			layout.bamboos = _generate_sparse_layout(map_system, active_directions)
		LayoutStyle.DENSE:
			layout.bamboos = _generate_dense_layout(map_system, active_directions)
		LayoutStyle.CORRIDOR:
			layout.bamboos = _generate_corridor_layout(map_system, active_directions)
		LayoutStyle.CIRCULAR:
			layout.bamboos = _generate_circular_layout(map_system, active_directions)
		LayoutStyle.CROSS:
			layout.bamboos = _generate_cross_layout(map_system, active_directions)
		LayoutStyle.MAZE:
			layout.bamboos = _generate_maze_layout(map_system, active_directions)
		LayoutStyle.ARENA:
			layout.bamboos = _generate_arena_layout(map_system, active_directions)

	# 添加装饰物
	layout.decorations = _generate_decorations(style, map_system)
	
	# [新增] 针对封闭方向的边缘填充（封死没有门的出口）
	_fill_closed_edges(layout.bamboos, active_directions, map_system)

	return layout

static func _fill_closed_edges(bamboos: Array, active_directions: Array, map_system):
	"""填充没有门的边缘区域 - 强制封死"""
	var w = 2400
	var h = 1800
	if map_system:
		w = map_system.MAP_WIDTH
		h = map_system.MAP_HEIGHT
		
	# 检查四个方向 (N=0, S=1, E=2, W=3)
	# 使用更密集的网格生成，确保视觉上完全堵死
	
	# 北边 (0)
	if not 0 in active_directions: 
		# 极高密度覆盖全宽度，确保无死角
		for x in range(20, w - 20, 20): 
			for y in range(20, 220, 25): # 加深厚度并向外延伸
				bamboos.append({"pos": Vector2(x + randf_range(-3, 3), y + randf_range(-3, 3)), "size": randi_range(8, 10)})
			
	# 南边 (1)
	if not 1 in active_directions: 
		for x in range(20, w - 20, 20):
			for y in range(h - 220, h - 20, 25):
				bamboos.append({"pos": Vector2(x + randf_range(-3, 3), y + randf_range(-3, 3)), "size": randi_range(8, 10)})
			
	# 东边 (2)
	if not 2 in active_directions: 
		for y in range(20, h - 20, 20):
			for x in range(w - 220, w - 20, 25):
				bamboos.append({"pos": Vector2(x + randf_range(-3, 3), y + randf_range(-3, 3)), "size": randi_range(8, 10)})

	# 西边 (3)
	if not 3 in active_directions: 
		for y in range(20, h - 20, 20):
			for x in range(20, 220, 25):
				bamboos.append({"pos": Vector2(x + randf_range(-3, 3), y + randf_range(-3, 3)), "size": randi_range(8, 10)})

static func _is_pos_safe(pos: Vector2, active_directions: Array = []) -> bool:
	var w = GameConstants.MAP_WIDTH
	var h = GameConstants.MAP_HEIGHT
	var center = Vector2(w / 2, h / 2)
	
	# Spawn/Tutorial Center (始终保护)
	if pos.distance_to(center) < 400.0: return false
	
	# Doors - 仅保护有活动连接的方向
	var door_safety_radius = 500.0
	
	# North (0)
	if 0 in active_directions:
		if pos.distance_to(Vector2(w / 2, 0)) < door_safety_radius: return false 
		
	# South (1)
	if 1 in active_directions:
		if pos.distance_to(Vector2(w / 2, h)) < door_safety_radius: return false 
		
	# East (2)
	if 2 in active_directions:
		if pos.distance_to(Vector2(w, h / 2)) < door_safety_radius: return false 
		
	# West (3)
	if 3 in active_directions:
		if pos.distance_to(Vector2(0, h / 2)) < door_safety_radius: return false 
	
	return true

static func _get_layout_style_for_room(room_type: int, room_index: int) -> LayoutStyle:
	"""根据房间类型和索引决定布局风格"""
	# 商店和特殊房间使用开阔布局
	if room_type == 1 or room_type == 3 or room_type == 4 or room_type == 5:  # SHOP, ENCHANT, REST, TREASURE
		return LayoutStyle.ARENA

	# Boss房间使用竞技场布局
	if room_type == 2:  # BOSS
		return LayoutStyle.ARENA

	# 普通房间根据索引循环使用不同风格
	var styles = [
		LayoutStyle.SPARSE,
		LayoutStyle.CORRIDOR,
		LayoutStyle.CIRCULAR,
		LayoutStyle.CROSS,
		LayoutStyle.DENSE,
		LayoutStyle.MAZE,
	]

	return styles[room_index % styles.size()]

static func _generate_sparse_layout(map_system, active_directions) -> Array:
	"""稀疏布局 - 外围竹林，需要更有密度"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 生成35-45个竹丛 (外围密度提升)
	var cluster_count = randi_range(35, 45)
	for i in range(cluster_count):
		var pos = Vector2(
			randf_range(200, map_width - 200),
			randf_range(200, map_height - 200)
		)
		
		# 边缘密度降低逻辑：如果在边缘300范围内，50%概率跳过
		if pos.x < 500 or pos.x > map_width - 500 or pos.y < 500 or pos.y > map_height - 500:
			if randf() < 0.5:
				continue
				
		if _is_pos_safe(pos, active_directions):
			bamboos.append({"pos": pos, "size": randi_range(4, 7)})

	return bamboos

static func _generate_dense_layout(map_system, active_directions) -> Array:
	"""密集布局 - 竹海，但控制性能和通道"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 生成30-40个大竹丛 (减少数量以优化性能，防止过满)
	var cluster_count = randi_range(30, 40)
	for i in range(cluster_count):
		var pos = Vector2(
			randf_range(200, map_width - 200),
			randf_range(200, map_height - 200)
		)
		if _is_pos_safe(pos, active_directions):
			bamboos.append({"pos": pos, "size": randi_range(6, 10)}) # 单个竹丛更大

	return bamboos

static func _generate_corridor_layout(map_system, active_directions) -> Array:
	"""走廊布局 - 中间通道两侧密集竹林"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	var center_x = map_width / 2
	var corridor_width = 400

	# 左侧密集竹林
	for i in range(25):
		var pos = Vector2(
			randf_range(200, center_x - corridor_width / 2 - 50),
			randf_range(200, map_height - 200)
		)
		if _is_pos_safe(pos, active_directions):
			bamboos.append({"pos": pos, "size": randi_range(5, 8)})

	# 右侧密集竹林
	for i in range(25):
		var pos = Vector2(
			randf_range(center_x + corridor_width / 2 + 50, map_width - 200),
			randf_range(200, map_height - 200)
		)
		if _is_pos_safe(pos, active_directions):
			bamboos.append({"pos": pos, "size": randi_range(5, 8)})

	return bamboos

static func _generate_circular_layout(map_system, active_directions) -> Array:
	"""环形布局 - 中心空地，四周是圆形墙壁"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	var center = Vector2(map_width / 2, map_height / 2)
	var arena_radius = 700.0  # 战斗区域半径
	var path_width = 300.0 # 通道宽度

	# 1. 填充四个角落，形成圆形边界
	var grid_size = 150
	var cols = int(map_width / grid_size)
	var rows = int(map_height / grid_size)

	for x in range(cols):
		for y in range(rows):
			var pos = Vector2(x * grid_size + grid_size/2, y * grid_size + grid_size/2)
			var dist = pos.distance_to(center)
			
			# 检查是否在通往出口的路径上（十字轴线）
			var on_path = false
			if abs(pos.x - center.x) < path_width / 2.0: on_path = true # 南北通道
			if abs(pos.y - center.y) < path_width / 2.0: on_path = true # 东西通道

			# 如果在圆圈外，且不在通道上，才填充密集竹林
			if dist > arena_radius and not on_path:
				# 稍微随机化位置
				var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
				var final_pos = pos + offset
				if _is_pos_safe(final_pos, active_directions):
					bamboos.append({"pos": final_pos, "size": randi_range(6, 10)}) # 大簇竹子

	# 2. 内部少量装饰性障碍
	for i in range(8):
		var angle = randf() * TAU
		var radius = randf_range(200, arena_radius - 150)
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		
		# 同样避开通道
		var on_path = false
		if abs(pos.x - center.x) < path_width / 2.0: on_path = true
		if abs(pos.y - center.y) < path_width / 2.0: on_path = true
		
		if not on_path and _is_pos_safe(pos, active_directions):
			bamboos.append({"pos": pos, "size": randi_range(2, 4)})

	return bamboos

static func _generate_cross_layout(map_system, active_directions) -> Array:
	"""十字布局 - 十字通道，四个角落被封死"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	var center = Vector2(map_width / 2, map_height / 2)
	var path_half_width = 250.0  # 通道半宽

	# 定义四个角落区域（需要填充的区域）
	var corners = [
		Rect2(0, 0, center.x - path_half_width, center.y - path_half_width), # 左上
		Rect2(center.x + path_half_width, 0, center.x - path_half_width, center.y - path_half_width), # 右上
		Rect2(0, center.y + path_half_width, center.x - path_half_width, center.y - path_half_width), # 左下
		Rect2(center.x + path_half_width, center.y + path_half_width, center.x - path_half_width, center.y - path_half_width) # 右下
	]

	# 填充角落
	var grid_size = 180
	for rect in corners:
		var c_cols = int(rect.size.x / grid_size)
		var c_rows = int(rect.size.y / grid_size)
		
		for x in range(c_cols):
			for y in range(c_rows):
				var pos = rect.position + Vector2(x * grid_size + grid_size/2, y * grid_size + grid_size/2)
				var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
				var final_pos = pos + offset
				if _is_pos_safe(final_pos, active_directions):
					bamboos.append({"pos": final_pos, "size": randi_range(6, 9)})

	return bamboos

static func _generate_maze_layout(map_system, active_directions) -> Array:
	"""迷宫布局 - 复杂的竹林迷宫"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 创建网格状竹林，但留出通道
	var grid_size = 200
	var cols = int(map_width / grid_size)
	var rows = int(map_height / grid_size)

	for x in range(1, cols - 1):
		for y in range(1, rows - 1):
			# 50%概率放置竹林
			if randf() < 0.5:
				var pos = Vector2(x * grid_size + randf_range(-50, 50), y * grid_size + randf_range(-50, 50))
				if _is_pos_safe(pos, active_directions):
					bamboos.append({"pos": pos, "size": randi_range(3, 6)})

	return bamboos

static func _generate_arena_layout(map_system, active_directions) -> Array:
	"""竞技场布局 - 大空地适合战斗"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 只在四个角落放置少量竹林
	var corners = [
		Vector2(400, 400),
		Vector2(map_width - 400, 400),
		Vector2(400, map_height - 400),
		Vector2(map_width - 400, map_height - 400)
	]

	for corner in corners:
		if _is_pos_safe(corner, active_directions):
			bamboos.append({"pos": corner, "size": randi_range(2, 4)})

	return bamboos

static func _generate_decorations(style: LayoutStyle, map_system) -> Array:
	"""根据布局风格生成装饰物 - 增强版：生成簇群"""
	var decorations = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 根据风格决定装饰物簇的数量（大幅增加以填补空旷）
	var cluster_count = 0
	match style:
		LayoutStyle.SPARSE, LayoutStyle.ARENA:
			cluster_count = randi_range(30, 45) # 翻倍增加
		LayoutStyle.DENSE, LayoutStyle.MAZE:
			cluster_count = randi_range(50, 70) # 极大丰富
		_:
			cluster_count = randi_range(8, 12) # 丰富

	for i in range(cluster_count):
		var center_pos = Vector2(
			randf_range(200, map_width - 200),
			randf_range(200, map_height - 200)
		)
		
		# 随机选择一种装饰类型进行簇生成
		var type_roll = randf()
		
		if type_roll < 0.6: # 60% 概率是花簇 (增加)
			var count = randi_range(2, 4)
			for j in range(count):
				var angle = randf() * TAU
				var dist = randf_range(10, 50)
				var pos = center_pos + Vector2(cos(angle), sin(angle)) * dist
				decorations.append({"pos": pos, "type": "flower"})
				
		elif type_roll < 0.75: # 15% 概率是石头组 (减少，原30%)
			var count = randi_range(1, 2) # 减少每组数量
			for j in range(count):
				var offset = Vector2(randf_range(-30, 30), randf_range(-20, 20))
				decorations.append({"pos": center_pos + offset, "type": "rock"})
				
		else: # 25% 概率是竹笋区域 (增加)
			var count = randi_range(3, 5)
			for j in range(count):
				var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
				decorations.append({"pos": center_pos + offset, "type": "shoot"})

	return decorations
