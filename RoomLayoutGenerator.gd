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

static func generate_room_layout(room_type: int, room_index: int, map_system: Node) -> Dictionary:
	"""根据房间类型和索引生成布局"""
	var layout = {
		"bamboos": [],
		"decorations": [],
		"style": LayoutStyle.SPARSE
	}

	# 根据房间索引选择布局风格
	var style = _get_layout_style_for_room(room_type, room_index)
	layout.style = style

	# 生成对应风格的布局
	match style:
		LayoutStyle.SPARSE:
			layout.bamboos = _generate_sparse_layout(map_system)
		LayoutStyle.DENSE:
			layout.bamboos = _generate_dense_layout(map_system)
		LayoutStyle.CORRIDOR:
			layout.bamboos = _generate_corridor_layout(map_system)
		LayoutStyle.CIRCULAR:
			layout.bamboos = _generate_circular_layout(map_system)
		LayoutStyle.CROSS:
			layout.bamboos = _generate_cross_layout(map_system)
		LayoutStyle.MAZE:
			layout.bamboos = _generate_maze_layout(map_system)
		LayoutStyle.ARENA:
			layout.bamboos = _generate_arena_layout(map_system)

	# 添加装饰物
	layout.decorations = _generate_decorations(style, map_system)

	return layout

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

static func _generate_sparse_layout(map_system) -> Array:
	"""稀疏布局 - 少量竹丛点缀"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 生成8-12个小竹丛 (增加密度)
	var cluster_count = randi_range(8, 12)
	for i in range(cluster_count):
		var pos = Vector2(
			randf_range(400, map_width - 400),
			randf_range(400, map_height - 400)
		)
		bamboos.append({"pos": pos, "size": randi_range(3, 5)})

	return bamboos

static func _generate_dense_layout(map_system) -> Array:
	"""密集布局 - 大量竹林"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 生成15-20个竹丛
	var cluster_count = randi_range(15, 20)
	for i in range(cluster_count):
		var pos = Vector2(
			randf_range(300, map_width - 300),
			randf_range(300, map_height - 300)
		)
		bamboos.append({"pos": pos, "size": randi_range(4, 8)})

	return bamboos

static func _generate_corridor_layout(map_system) -> Array:
	"""走廊布局 - 中间通道两侧竹林"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	var center_x = map_width / 2
	var corridor_width = 400

	# 左侧竹林
	for i in range(8):
		var pos = Vector2(
			randf_range(300, center_x - corridor_width / 2 - 50),
			randf_range(400, map_height - 400)
		)
		bamboos.append({"pos": pos, "size": randi_range(4, 7)})

	# 右侧竹林
	for i in range(8):
		var pos = Vector2(
			randf_range(center_x + corridor_width / 2 + 50, map_width - 300),
			randf_range(400, map_height - 400)
		)
		bamboos.append({"pos": pos, "size": randi_range(4, 7)})

	return bamboos

static func _generate_circular_layout(map_system) -> Array:
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
				bamboos.append({"pos": pos + offset, "size": randi_range(6, 10)}) # 大簇竹子

	# 2. 内部少量装饰性障碍
	for i in range(8):
		var angle = randf() * TAU
		var radius = randf_range(200, arena_radius - 150)
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		
		# 同样避开通道
		var on_path = false
		if abs(pos.x - center.x) < path_width / 2.0: on_path = true
		if abs(pos.y - center.y) < path_width / 2.0: on_path = true
		
		if not on_path:
			bamboos.append({"pos": pos, "size": randi_range(2, 4)})

	return bamboos

static func _generate_cross_layout(map_system) -> Array:
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
				bamboos.append({"pos": pos + offset, "size": randi_range(6, 9)})

	return bamboos

static func _generate_maze_layout(map_system) -> Array:
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
				bamboos.append({"pos": pos, "size": randi_range(3, 6)})

	return bamboos

static func _generate_arena_layout(map_system) -> Array:
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
			cluster_count = randi_range(12, 18) # 翻倍
		LayoutStyle.DENSE, LayoutStyle.MAZE:
			cluster_count = randi_range(20, 30) # 大幅增加
		_:
			cluster_count = randi_range(15, 25) # 增加

	for i in range(cluster_count):
		var center_pos = Vector2(
			randf_range(200, map_width - 200),
			randf_range(200, map_height - 200)
		)
		
		# 随机选择一种装饰类型进行簇生成
		var type_roll = randf()
		
		if type_roll < 0.5: # 50% 概率是花簇
			var count = randi_range(3, 6)
			for j in range(count):
				var angle = randf() * TAU
				var dist = randf_range(10, 40)
				var pos = center_pos + Vector2(cos(angle), sin(angle)) * dist
				decorations.append({"pos": pos, "type": "flower"})
				
		elif type_roll < 0.8: # 30% 概率是石头组
			var count = randi_range(1, 3)
			for j in range(count):
				var offset = Vector2(randf_range(-30, 30), randf_range(-20, 20))
				decorations.append({"pos": center_pos + offset, "type": "rock"})
				
		else: # 20% 概率是竹笋区域
			var count = randi_range(2, 4)
			for j in range(count):
				var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
				decorations.append({"pos": center_pos + offset, "type": "shoot"})

	return decorations
