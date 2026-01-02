extends Control
class_name RoomMapCanvas

# RoomMapCanvas - 房间地图绘制画布（方格布局，类似以撒的结合）

const ROOM_SIZE = 35.0  # 每个房间方格的大小
const ROOM_PADDING = 3.0  # 房间之间的间距
const DOOR_WIDTH = 8.0  # 门的宽度

func _draw():
	var room_manager = get_tree().get_first_node_in_group("room_manager")
	if not room_manager or not room_manager.has_method("get_room_map_data"):
		return

	var room_map = room_manager.get_room_map_data()
	if room_map.is_empty():
		return

	# 将房间数据转换为网格布局
	var grid_layout = _convert_to_grid_layout(room_map)

	# 绘制房间和门
	for room_id in grid_layout.keys():
		var grid_pos = grid_layout[room_id]
		var room = room_map[room_id]
		_draw_room(room, grid_pos, grid_layout, room_manager)

func _convert_to_grid_layout(room_map: Array) -> Dictionary:
	"""将房间网络转换为网格坐标（根据实际position计算方向）"""
	var layout = {}
	var visited = {}

	# 使用BFS遍历，从起始房间开始
	var queue = []
	queue.append(0)  # 起始房间ID
	layout[0] = Vector2(3, 3)  # 起始房间在中心
	visited[0] = true

	while queue.size() > 0:
		var current_id = queue.pop_front()
		var current_room = room_map[current_id]
		var current_grid_pos = layout[current_id]

		# 为每个连接的房间分配位置
		for connected_id in current_room.connected_rooms:
			if visited.has(connected_id):
				continue

			var connected_room = room_map[connected_id]

			# 根据实际的position差异判断方向
			var dir_vec = connected_room.position - current_room.position
			var grid_offset = Vector2.ZERO

			# 判断主要方向
			if abs(dir_vec.x) > abs(dir_vec.y):
				# 东西向
				if dir_vec.x > 0:
					grid_offset = Vector2(1, 0)  # 东→右
				else:
					grid_offset = Vector2(-1, 0)  # 西→左
			else:
				# 南北向
				if dir_vec.y > 0:
					grid_offset = Vector2(0, 1)  # 南→下
				else:
					grid_offset = Vector2(0, -1)  # 北→上

			var new_grid_pos = current_grid_pos + grid_offset

			# 检查位置是否被占用，如果被占用则尝试其他方向
			var occupied = false
			for existing_id in layout.keys():
				if layout[existing_id] == new_grid_pos:
					occupied = true
					break

			if not occupied:
				layout[connected_id] = new_grid_pos
				visited[connected_id] = true
				queue.append(connected_id)

	return layout

func _draw_room(room, grid_pos: Vector2, layout: Dictionary, room_manager):
	"""绘制单个房间方格"""
	var x = grid_pos.x * (ROOM_SIZE + ROOM_PADDING) + 10
	var y = grid_pos.y * (ROOM_SIZE + ROOM_PADDING) + 10

	var rect = Rect2(x, y, ROOM_SIZE, ROOM_SIZE)

	# 根据房间类型选择颜色
	var color = _get_room_color(room.type, room_manager)

	# 已访问但非当前房间，颜色变暗
	if room.is_visited and not room.is_current:
		color = color.darkened(0.4)

	# 未访问的房间显示为虚线边框
	if not room.is_visited:
		draw_rect(rect, Color(0.3, 0.3, 0.3, 0.8), false, 2.0)
		# 绘制问号
		var question_pos = Vector2(x + ROOM_SIZE / 2 - 3, y + ROOM_SIZE / 2 + 4)
		draw_string(ThemeDB.fallback_font, question_pos, "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(0.5, 0.5, 0.5, 0.8))
	else:
		# 已访问的房间填充颜色
		draw_rect(rect, color, true)
		draw_rect(rect, color.lightened(0.3), false, 2.0)

	# 当前房间额外的高亮边框
	if room.is_current:
		var highlight_rect = Rect2(x - 2, y - 2, ROOM_SIZE + 4, ROOM_SIZE + 4)
		draw_rect(highlight_rect, Color("#ffff00"), false, 3.0)

	# 绘制房间类型图标
	if room.is_visited:
		var icon = _get_room_icon(room.type, room_manager)
		if icon != "":
			var icon_pos = Vector2(x + ROOM_SIZE / 2 - 4, y + ROOM_SIZE / 2 + 4)
			draw_string(ThemeDB.fallback_font, icon_pos, icon, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)

	# 绘制门（连接线）
	for connected_id in room.connected_rooms:
		if not layout.has(connected_id):
			continue

		var connected_pos = layout[connected_id]
		_draw_door(grid_pos, connected_pos, x, y)

func _draw_door(from_pos: Vector2, to_pos: Vector2, room_x: float, room_y: float):
	"""绘制门（连接到相邻房间的通道）"""
	var center = Vector2(room_x + ROOM_SIZE / 2, room_y + ROOM_SIZE / 2)
	var door_color = Color(0.7, 0.7, 0.7, 0.8)

	# 判断方向
	var dx = to_pos.x - from_pos.x
	var dy = to_pos.y - from_pos.y

	if dx == 1:  # 右门
		var door_start = Vector2(room_x + ROOM_SIZE, center.y - DOOR_WIDTH / 2)
		var door_end = Vector2(room_x + ROOM_SIZE + ROOM_PADDING, center.y + DOOR_WIDTH / 2)
		draw_rect(Rect2(door_start, door_end - door_start), door_color, true)
	elif dx == -1:  # 左门
		var door_start = Vector2(room_x - ROOM_PADDING, center.y - DOOR_WIDTH / 2)
		var door_end = Vector2(room_x, center.y + DOOR_WIDTH / 2)
		draw_rect(Rect2(door_start, door_end - door_start), door_color, true)
	elif dy == 1:  # 下门
		var door_start = Vector2(center.x - DOOR_WIDTH / 2, room_y + ROOM_SIZE)
		var door_end = Vector2(center.x + DOOR_WIDTH / 2, room_y + ROOM_SIZE + ROOM_PADDING)
		draw_rect(Rect2(door_start, door_end - door_start), door_color, true)
	elif dy == -1:  # 上门
		var door_start = Vector2(center.x - DOOR_WIDTH / 2, room_y - ROOM_PADDING)
		var door_end = Vector2(center.x + DOOR_WIDTH / 2, room_y)
		draw_rect(Rect2(door_start, door_end - door_start), door_color, true)

func _get_room_color(room_type: int, room_manager) -> Color:
	"""获取房间颜色"""
	# 直接使用RoomManager的RoomType枚举（class_name定义）
	if not room_manager:
		return Color("#888888")

	match room_type:
		RoomManager.RoomType.NORMAL:
			return Color("#7a7a7a")  # 深灰
		RoomManager.RoomType.SHOP:
			return Color("#4a9d4a")  # 深绿
		RoomManager.RoomType.BOSS:
			return Color("#c43a3a")  # 深红
		RoomManager.RoomType.ENCHANT:
			return Color("#9a4ad2")  # 深紫
		RoomManager.RoomType.TREASURE:
			return Color("#d2941f")  # 深橙
		RoomManager.RoomType.REST:
			return Color("#4a8ad2")  # 深蓝

	return Color("#888888")

func _get_room_icon(room_type: int, room_manager) -> String:
	"""获取房间类型图标"""
	# 直接使用RoomManager的RoomType枚举（class_name定义）
	if not room_manager:
		return ""

	match room_type:
		RoomManager.RoomType.NORMAL:
			return ""  # 普通房间不显示图标
		RoomManager.RoomType.SHOP:
			return "$"  # 商店
		RoomManager.RoomType.BOSS:
			return "!"  # Boss
		RoomManager.RoomType.ENCHANT:
			return "E"  # 附魔
		RoomManager.RoomType.TREASURE:
			return "?"  # 宝箱
		RoomManager.RoomType.REST:
			return "+"  # 休息

	return ""
