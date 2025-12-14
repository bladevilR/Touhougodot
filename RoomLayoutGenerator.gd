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

	# 生成5-8个小竹丛
	var cluster_count = randi_range(5, 8)
	for i in range(cluster_count):
		var pos = Vector2(
			randf_range(400, map_width - 400),
			randf_range(400, map_height - 400)
		)
		bamboos.append({"pos": pos, "size": randi_range(2, 4)})

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
	"""环形布局 - 中心空地周围竹林"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	var center = Vector2(map_width / 2, map_height / 2)
	var inner_radius = 300
	var outer_radius = 600

	# 在环形区域生成竹林
	for i in range(12):
		var angle = (TAU / 12) * i
		var radius = randf_range(inner_radius, outer_radius)
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		bamboos.append({"pos": pos, "size": randi_range(5, 8)})

	return bamboos

static func _generate_cross_layout(map_system) -> Array:
	"""十字布局 - 十字通道分割四个区域"""
	var bamboos = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	var center = Vector2(map_width / 2, map_height / 2)
	var corridor_width = 300

	# 四个象限分别放置竹林
	var quadrants = [
		Rect2(300, 300, center.x - corridor_width / 2 - 300, center.y - corridor_width / 2 - 300),  # 左上
		Rect2(center.x + corridor_width / 2, 300, map_width - center.x - corridor_width / 2 - 300, center.y - corridor_width / 2 - 300),  # 右上
		Rect2(300, center.y + corridor_width / 2, center.x - corridor_width / 2 - 300, map_height - center.y - corridor_width / 2 - 300),  # 左下
		Rect2(center.x + corridor_width / 2, center.y + corridor_width / 2, map_width - center.x - corridor_width / 2 - 300, map_height - center.y - corridor_width / 2 - 300),  # 右下
	]

	for quadrant in quadrants:
		for i in range(4):
			var pos = Vector2(
				quadrant.position.x + randf() * quadrant.size.x,
				quadrant.position.y + randf() * quadrant.size.y
			)
			bamboos.append({"pos": pos, "size": randi_range(3, 6)})

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
	"""根据布局风格生成装饰物"""
	var decorations = []
	var map_width = 2400
	var map_height = 1800

	if map_system:
		map_width = map_system.MAP_WIDTH
		map_height = map_system.MAP_HEIGHT

	# 根据风格决定装饰物数量
	var decoration_count = 0
	match style:
		LayoutStyle.SPARSE, LayoutStyle.ARENA:
			decoration_count = randi_range(8, 12)
		LayoutStyle.DENSE, LayoutStyle.MAZE:
			decoration_count = randi_range(15, 20)
		_:
			decoration_count = randi_range(10, 15)

	# 生成随机位置的装饰物（花朵、石头、竹笋）
	for i in range(decoration_count):
		var pos = Vector2(
			randf_range(400, map_width - 400),
			randf_range(400, map_height - 400)
		)
		var type = ["flower", "rock", "shoot"][randi() % 3]
		decorations.append({"pos": pos, "type": type})

	return decorations
