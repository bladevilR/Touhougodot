extends Node2D
class_name MapSystem

# Map constants from Room 1 (竹林入口)
const MAP_WIDTH = 2400
const MAP_HEIGHT = 1800
const PLAYER_SPAWN_X = 1200
const PLAYER_SPAWN_Y = 1500

# 玩家高度参考（用于计算竹子缩放）
const PLAYER_HEIGHT = 100.0
# 竹子目标高度（相对于玩家）
const BAMBOO_TALL_HEIGHT = 350.0    # 高大竹子 - 约3.5倍玩家高度
const BAMBOO_MEDIUM_HEIGHT = 250.0  # 中等竹子 - 约2.5倍玩家高度
const BAMBOO_SHORT_HEIGHT = 180.0   # 矮竹子 - 约1.8倍玩家高度

# 边界墙厚度（竹海深度）
const WALL_THICKNESS = 200

# Bamboo texture paths with metadata
# Format: {path, original_height (approx), type}
var bamboo_configs = [
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_xlarge_1.png", "height": 1200, "type": "xlarge"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_xlarge_2.png", "height": 1000, "type": "xlarge"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_1.png", "height": 800, "type": "large"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_2.png", "height": 750, "type": "large"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_3.png", "height": 850, "type": "large"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_4.png", "height": 780, "type": "large"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_5.png", "height": 760, "type": "large"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_1.png", "height": 600, "type": "medium"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_2.png", "height": 650, "type": "medium"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_3.png", "height": 580, "type": "medium"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_small_1.png", "height": 500, "type": "small"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_small_2.png", "height": 520, "type": "small"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_1.png", "height": 450, "type": "single"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_2.png", "height": 460, "type": "single"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_1.png", "height": 400, "type": "broken"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_2.png", "height": 380, "type": "broken"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_3.png", "height": 390, "type": "broken"},
	{"path": "res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_4.png", "height": 410, "type": "broken"},
]

# 保留旧数组以兼容
var bamboo_textures = [
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_1.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_2.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_3.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_4.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_5.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_1.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_2.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_3.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_small_1.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_small_2.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_xlarge_1.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_xlarge_2.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_1.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_2.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_3.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_4.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_1.png",
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_2.png"
]

# 装饰物纹理路径
var decoration_textures = {
	"flowers": [
		"res://assets/SUCAI/images_resized/flower_white_daisy_single.png",
		"res://assets/SUCAI/images_resized/flower_blue_single_1.png",
		"res://assets/SUCAI/images_resized/flower_red_cluster_1.png",
		"res://assets/SUCAI/images_resized/flower_yellow_cluster_1.png",
		"res://assets/SUCAI/images_resized/flower_white_cluster_1.png",
	],
	"shoots": [
		"res://assets/SUCAI/images_resized/shoot_small_1.png",
		"res://assets/SUCAI/images_resized/shoot_small_2.png",
		"res://assets/SUCAI/images_resized/shoot_medium_1.png",
		"res://assets/SUCAI/images_resized/shoot_medium_2.png",
	],
	"rocks": [
		"res://assets/SUCAI/images_resized/rock_medium_grey.png",
		"res://assets/SUCAI/images_resized/rock_large_moss_1.png",
		"res://assets/SUCAI/images_resized/rock_medium_scattered.png",
	]
}

# Wall data from constants.ts ROOMS[0].walls
# Format: [textureIndex, x, y, scale]
var wall_data = [
	[0, 2292, 397, 0.620538559848569],
	[0, 1443, 357, 0.564475057979241],
	[11, 672, 190, 0.7705180832167087],
	[0, 1522, 280, 0.631558896807471],
	[10, 1317, 170, 0.7786577718348544],
	[4, 1132, 296, 0.7034149554508092],
	[8, 2392, 7, 0.5347618186359655],
	[10, 1405, 218, 0.72786098217855],
	[1, 831, 246, 0.5342583482463846],
	[13, 2238, 184, 0.5806175062626032],
	[6, 1086, 56, 0.7480405873141227],
	[5, 507, 73, 0.5829413547864343],
	[1, 1677, 70, 0.710119897402048],
	[10, 1655, 1, 0.5468290660174313],
	[6, 2391, 306, 0.7973678509141051],
	[14, 1333, 221, 0.7502779186818131],
	[10, 1581, 52, 0.6863453658504604],
	[4, 910, 314, 0.5400005176562853],
	[11, 55, 40, 0.6846693935697344],
	[4, 1663, 34, 0.6784259881187749],
	[2, 2120, 309, 0.6545842762461248],
	[12, 1373, 345, 0.6972625221632968],
	[10, 1910, 47, 0.6661123637698435],
	[11, 1991, 259, 0.6480203168547588],
	[11, 58, 180, 0.6633138416241929],
	[9, 1884, 288, 0.6959978046233485],
	[0, 43, 97, 0.7348377328649139],
	[8, 1564, 394, 0.5822190085893553],
	[7, 1122, 287, 0.6097603048595837],
	[9, 1619, 393, 0.7277883023203057],
	[0, 798, 284, 0.7760594618622234],
	[12, 826, 141, 0.6032619840911612],
	[3, 976, 161, 0.5452933250630203],
	[10, 1773, 348, 0.709117203252288],
	[13, 2106, 222, 0.5014082467758816],
	[8, 394, 187, 0.5497627902398853],
	[4, 350, 275, 0.5678438547146604],
	[14, 97, 161, 0.7943660588373687],
	[2, 481, 282, 0.7345674505111114],
	[4, 477, 115, 0.6052542496357836],
	[9, 654, 124, 0.6897629500702415],
	[10, 999, 242, 0.6552012486387465],
	[12, 1469, 147, 0.7199147989567237],
	[12, 1482, 81, 0.548990351515429],
	[10, 981, 164, 0.7707795108183824],
	[1, 154, 81, 0.5375008947139773],
	[12, 682, 235, 0.6942401224022864],
	[7, 1506, 341, 0.7332681682193194],
	[1, 521, 308, 0.6924650670298103],
	[5, 1396, 258, 0.6204556945211426],
	[3, 2312, 26, 0.6503579642404231],
	[11, 552, 351, 0.6806789370850755],
	[10, 779, 101, 0.5569426227972388],
	[10, 520, 135, 0.6971251530706096],
	[10, 1100, 75, 0.7616132833397932],
]

# Enemy spawn points from constants.ts
var enemy_spawn_points = [
	Vector2(1200, 600),
	Vector2(800, 700),
	Vector2(1600, 700),
	Vector2(1000, 900),
	Vector2(1400, 900)
]

var background_layer: Node2D
var decorations_layer: Node2D  # 装饰层
var bamboo_background_layer: Node2D  # 远景竹林层（纯装饰，无碰撞）
var bamboo_collision_layer: Node2D  # 竹子碰撞层（Y-sorted，有碰撞）
var lighting_layer: CanvasLayer  # 光照层
var wall_bodies: Array = []

func _ready():
	add_to_group("map_system")
	print("MapSystem: Initializing bamboo forest map...")
	setup_layers()
	create_background()
	create_bamboo_sea_walls()  # 创建边缘竹海墙壁
	create_interior_bamboo()   # 创建内部装饰竹子
	create_decorations_designed()
	create_lighting()
	setup_camera_limits()
	print("MapSystem: Map initialization complete!")

func _process(_delta):
	pass  # 移除动态透明度更新，使用Y-sorting代替

func setup_layers():
	# ===== 背景层 =====
	background_layer = Node2D.new()
	background_layer.name = "BackgroundLayer"
	background_layer.z_index = -100
	add_child(background_layer)

	# ===== 远景竹林层（纯装饰，营造深度感）=====
	bamboo_background_layer = Node2D.new()
	bamboo_background_layer.name = "BambooBackgroundLayer"
	bamboo_background_layer.z_index = -50
	add_child(bamboo_background_layer)

	# ===== 装饰层（花草石头）=====
	decorations_layer = Node2D.new()
	decorations_layer.name = "DecorationsLayer"
	decorations_layer.z_index = -10
	add_child(decorations_layer)

	# ===== 竹子碰撞层（Y-sorted，与玩家同层）=====
	# 这一层添加到World父节点，以便与Player一起Y-sorting
	bamboo_collision_layer = Node2D.new()
	bamboo_collision_layer.name = "BambooCollisionLayer"
	bamboo_collision_layer.y_sort_enabled = true
	# 将在 _ready 完成后由 World 的 y_sort_enabled 处理排序

	# ===== 光照层 =====
	lighting_layer = CanvasLayer.new()
	lighting_layer.name = "LightingLayer"
	lighting_layer.layer = 10
	add_child(lighting_layer)

func create_background():
	print("MapSystem: Creating grass background...")
	var grass_texture = load("res://assets/grass2.png")

	if grass_texture:
		var GRASS_TILE_SIZE = 256
		var tiles_x = ceil(MAP_WIDTH / float(GRASS_TILE_SIZE)) + 1
		var tiles_y = ceil(MAP_HEIGHT / float(GRASS_TILE_SIZE)) + 1

		for x in range(tiles_x):
			for y in range(tiles_y):
				var sprite = Sprite2D.new()
				sprite.texture = grass_texture
				var scale_factor = GRASS_TILE_SIZE / float(grass_texture.get_width())
				sprite.scale = Vector2(scale_factor, scale_factor)
				sprite.position = Vector2(x * GRASS_TILE_SIZE, y * GRASS_TILE_SIZE)
				sprite.centered = false
				background_layer.add_child(sprite)

		print("MapSystem: Background created with %d tiles" % (tiles_x * tiles_y))
	else:
		print("MapSystem: ERROR - Could not load grass texture!")
		var color_rect = ColorRect.new()
		color_rect.color = Color(0.2, 0.6, 0.2)
		color_rect.size = Vector2(MAP_WIDTH, MAP_HEIGHT)
		background_layer.add_child(color_rect)

# ==================== 竹海墙壁系统（边缘密集竹林）====================
func create_bamboo_sea_walls():
	"""创建地图边缘的竹林 - 自然有机的边界"""
	print("MapSystem: Creating bamboo forest edges...")
	var bamboo_count = 0

	# 使用噪声生成不规则的可行走区域边界
	# 边界线是一条不规则曲线，而非直线
	bamboo_count += _create_organic_forest_edge()

	print("MapSystem: Created %d bamboo elements" % bamboo_count)

func _get_edge_depth(pos_along: float, wall_length: float, side: String) -> float:
	"""获取边界深度（使用多个正弦波叠加模拟噪声）"""
	# 基础深度
	var base_depth = WALL_THICKNESS

	# 多个正弦波叠加产生不规则感
	var wave1 = sin(pos_along * 0.008) * 60
	var wave2 = sin(pos_along * 0.023 + 1.5) * 35
	var wave3 = sin(pos_along * 0.041 + 3.0) * 20

	# 出入口 - 使用平滑的凹陷而非硬边界
	var entrance_pos = wall_length * 0.5
	var entrance_influence = 0.0
	var dist_to_entrance = abs(pos_along - entrance_pos)
	if dist_to_entrance < 200:
		# 平滑的高斯形状凹陷
		entrance_influence = exp(-dist_to_entrance * dist_to_entrance / 8000.0) * 120

	return base_depth + wave1 + wave2 + wave3 - entrance_influence

func _create_organic_forest_edge() -> int:
	"""创建有机形状的竹林边缘"""
	var count = 0

	# 四个方向的边缘
	var sides = ["top", "bottom", "left", "right"]

	for side in sides:
		var is_horizontal = (side == "top" or side == "bottom")
		var wall_length = MAP_WIDTH if is_horizontal else MAP_HEIGHT

		# 沿边缘分布竹子（不规则间距）
		var pos = 0.0
		while pos < wall_length:
			var edge_depth = _get_edge_depth(pos, wall_length, side)

			# 在边界深度范围内随机放置竹子
			var bamboo_in_depth = randi_range(2, 5)  # 每个位置2-5棵深度方向的竹子

			for d in range(bamboo_in_depth):
				# 深度位置（从边缘向内）
				var depth = randf_range(10, edge_depth * 0.95)
				var along_offset = randf_range(-30, 30)

				var bamboo_pos: Vector2
				match side:
					"top":
						bamboo_pos = Vector2(pos + along_offset, depth)
					"bottom":
						bamboo_pos = Vector2(pos + along_offset, MAP_HEIGHT - depth)
					"left":
						bamboo_pos = Vector2(depth, pos + along_offset)
					"right":
						bamboo_pos = Vector2(MAP_WIDTH - depth, pos + along_offset)

				# 边界检查
				if bamboo_pos.x < -50 or bamboo_pos.x > MAP_WIDTH + 50:
					continue
				if bamboo_pos.y < -50 or bamboo_pos.y > MAP_HEIGHT + 50:
					continue

				# 根据深度决定竹子特性
				var depth_ratio = depth / edge_depth
				var has_collision = depth_ratio > 0.7  # 靠近可行走区域的竹子有碰撞

				count += _create_forest_bamboo(bamboo_pos, depth_ratio, has_collision)

			# 不规则间距前进
			pos += randf_range(25, 55)

	return count

func _create_forest_bamboo(pos: Vector2, depth_ratio: float, has_collision: bool) -> int:
	"""创建竹林中的竹子"""
	# 根据深度选择竹子类型
	var suitable_types: Array
	if depth_ratio < 0.3:
		suitable_types = ["xlarge", "large"]  # 外围大竹子
	elif depth_ratio < 0.6:
		suitable_types = ["large", "medium"]
	else:
		suitable_types = ["medium", "small", "single", "broken"]  # 内侧混合

	var suitable_indices = []
	for i in range(bamboo_configs.size()):
		if bamboo_configs[i].type in suitable_types:
			suitable_indices.append(i)
	if suitable_indices.is_empty():
		suitable_indices = range(bamboo_configs.size())

	var config = bamboo_configs[suitable_indices[randi() % suitable_indices.size()]]
	var texture = load(config.path)
	if not texture:
		return 0

	# 高度变化 - 外围高，内侧矮
	var height_base = lerp(BAMBOO_TALL_HEIGHT, BAMBOO_SHORT_HEIGHT, depth_ratio)
	var target_height = height_base * randf_range(0.75, 1.25)
	var scale = target_height / texture.get_height()

	# 透明度 - 外围透明，内侧实
	var alpha = lerp(0.4, 1.0, depth_ratio * depth_ratio)
	# 颜色变化 - 增加层次感
	var color_var = randf_range(0.85, 1.0)
	var green_boost = randf_range(0.0, 0.08)

	if has_collision:
		var body = StaticBody2D.new()
		body.position = pos
		body.collision_layer = 2
		body.collision_mask = 0

		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale, scale)
		# 底部锚点：让精灵从position向上绘制
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		sprite.modulate = Color(color_var, color_var + green_boost, color_var - 0.05, alpha)
		body.add_child(sprite)

		# 底部碰撞
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(texture.get_width() * scale * 0.25, 20)
		collision.shape = shape
		collision.position = Vector2(0, -10)
		body.add_child(collision)

		get_parent().call_deferred("add_child", body)
		wall_bodies.append(body)
	else:
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale, scale)
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		sprite.position = pos
		sprite.modulate = Color(color_var, color_var + green_boost, color_var - 0.05, alpha)

		# 外围竹子放到背景层
		if depth_ratio < 0.5:
			bamboo_background_layer.add_child(sprite)
		else:
			get_parent().call_deferred("add_child", sprite)

	return 1

# ==================== 内部装饰竹子 ====================
func create_interior_bamboo():
	"""在地图内部创建零散的装饰竹子和障碍物"""
	print("MapSystem: Creating interior bamboo...")
	var count = 0

	# 定义安全区域（玩家出生点附近不放置障碍）
	var spawn_safe_zone = Rect2(PLAYER_SPAWN_X - 200, PLAYER_SPAWN_Y - 200, 400, 400)

	# 定义几个竹子群落位置（手工设计的布局）
	var cluster_positions = [
		# 上半部分
		Vector2(400, 500),
		Vector2(800, 400),
		Vector2(1600, 450),
		Vector2(2000, 550),
		# 中间区域（稀疏）
		Vector2(600, 900),
		Vector2(1800, 850),
		Vector2(1000, 1000),
		Vector2(1500, 950),
		# 下半部分（避开出生点）
		Vector2(400, 1300),
		Vector2(700, 1600),
		Vector2(1900, 1350),
		Vector2(2100, 1550),
	]

	for cluster_pos in cluster_positions:
		# 检查是否在安全区域
		if spawn_safe_zone.has_point(cluster_pos):
			continue

		# 每个群落放置2-4棵竹子
		var cluster_size = randi_range(2, 4)
		for i in range(cluster_size):
			var offset = Vector2(randf_range(-60, 60), randf_range(-40, 40))
			var pos = cluster_pos + offset

			# 边界检查
			if pos.x < WALL_THICKNESS + 50 or pos.x > MAP_WIDTH - WALL_THICKNESS - 50:
				continue
			if pos.y < WALL_THICKNESS + 50 or pos.y > MAP_HEIGHT - WALL_THICKNESS - 50:
				continue

			count += _create_interior_bamboo_single(pos)

	print("MapSystem: Created %d interior bamboo" % count)

func _create_interior_bamboo_single(pos: Vector2) -> int:
	"""创建单个内部竹子（有碰撞，用于Y-sorting）"""
	# 使用中小型竹子
	var suitable_indices = []
	for i in range(bamboo_configs.size()):
		if bamboo_configs[i].type in ["medium", "small", "single"]:
			suitable_indices.append(i)

	if suitable_indices.is_empty():
		return 0

	var config = bamboo_configs[suitable_indices[randi() % suitable_indices.size()]]
	var texture = load(config.path)
	if not texture:
		return 0

	# 内部竹子稍矮
	var target_height = randf_range(BAMBOO_MEDIUM_HEIGHT * 0.8, BAMBOO_MEDIUM_HEIGHT * 1.1)
	var scale = target_height / texture.get_height()

	# 创建 StaticBody2D
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 0

	# 精灵（底部锚点）
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale, scale)
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	body.add_child(sprite)

	# 底部碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var collision_width = texture.get_width() * scale * 0.35
	var collision_height = 25
	shape.size = Vector2(collision_width, collision_height)
	collision.shape = shape
	collision.position = Vector2(0, -collision_height * 0.5)
	body.add_child(collision)

	get_parent().call_deferred("add_child", body)
	wall_bodies.append(body)
	return 1

func setup_camera_limits():
	# Get reference to player's camera
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			camera.limit_left = 0
			camera.limit_top = 0
			camera.limit_right = MAP_WIDTH
			camera.limit_bottom = MAP_HEIGHT
			print("MapSystem: Camera limits set to map boundaries")

func get_player_spawn_position() -> Vector2:
	return Vector2(PLAYER_SPAWN_X, PLAYER_SPAWN_Y)

func get_enemy_spawn_points() -> Array:
	return enemy_spawn_points

func get_map_size() -> Vector2:
	return Vector2(MAP_WIDTH, MAP_HEIGHT)

func get_random_position_in_map() -> Vector2:
	# Returns a random position within playable area (inside wall boundaries)
	var margin = WALL_THICKNESS + 50  # 保持在墙壁内侧
	var x = randf_range(margin, MAP_WIDTH - margin)
	var y = randf_range(margin, MAP_HEIGHT - margin)
	return Vector2(x, y)

func is_position_valid(pos: Vector2) -> bool:
	# Check if position is within map boundaries
	return pos.x >= 0 and pos.x <= MAP_WIDTH and pos.y >= 0 and pos.y <= MAP_HEIGHT

# ==================== 装饰物系统（精心设计版）====================
func create_decorations_designed():
	"""按照关卡设计原则摆放装饰物"""
	print("MapSystem: Creating designed decorations...")

	var decorations_count = 0

	# 可玩区域边界（考虑墙壁厚度）
	var play_area_margin = WALL_THICKNESS + 50

	# ===== 1. 花朵簇 - 沿"小径"分布 =====
	# 左上区域花簇
	decorations_count += _create_flower_cluster(Vector2(350, 450), 5, 0.12)
	decorations_count += _create_flower_cluster(Vector2(500, 600), 4, 0.1)

	# 右上区域花簇
	decorations_count += _create_flower_cluster(Vector2(2050, 500), 5, 0.12)
	decorations_count += _create_flower_cluster(Vector2(1900, 650), 3, 0.1)

	# 左下区域花簇（靠近玩家出生点但不在出生区域内）
	decorations_count += _create_flower_cluster(Vector2(450, 1350), 4, 0.12)
	decorations_count += _create_flower_cluster(Vector2(650, 1550), 5, 0.1)

	# 右下区域花簇
	decorations_count += _create_flower_cluster(Vector2(1950, 1450), 4, 0.12)
	decorations_count += _create_flower_cluster(Vector2(2100, 1300), 3, 0.1)

	# 中央区域零星花朵（不能太多，保持战斗空间）
	decorations_count += _create_flower_cluster(Vector2(1100, 850), 2, 0.1)
	decorations_count += _create_flower_cluster(Vector2(1450, 900), 2, 0.1)

	# ===== 2. 石头组 - 可玩区域边缘 =====
	# 上方边界内侧
	decorations_count += _create_rock_group(Vector2(850, 350), 2, 0.18)
	decorations_count += _create_rock_group(Vector2(1650, 380), 3, 0.2)

	# 左侧边界内侧
	decorations_count += _create_rock_group(Vector2(350, 850), 2, 0.18)
	decorations_count += _create_rock_group(Vector2(380, 1150), 3, 0.22)

	# 右侧边界内侧
	decorations_count += _create_rock_group(Vector2(2100, 800), 2, 0.18)
	decorations_count += _create_rock_group(Vector2(2050, 1100), 3, 0.2)

	# 下方边界内侧
	decorations_count += _create_rock_group(Vector2(900, 1550), 2, 0.18)
	decorations_count += _create_rock_group(Vector2(1550, 1580), 2, 0.18)

	# ===== 3. 竹笋 - 靠近竹林边缘但在可玩区域内 =====
	var shoot_positions = [
		Vector2(400, 350), Vector2(570, 530),   # 左上
		Vector2(2000, 400), Vector2(1800, 570), # 右上
		Vector2(350, 1050), Vector2(500, 1250), # 左中
		Vector2(2050, 1000), Vector2(2000, 1200), # 右中
		Vector2(550, 1500), Vector2(750, 1580), # 左下
		Vector2(1900, 1550), Vector2(2050, 1400) # 右下
	]

	for pos in shoot_positions:
		decorations_count += _create_shoot(pos, 0.15)  # 竹笋约玩家一半高

	print("MapSystem: Created %d designed decorations" % decorations_count)

func _create_flower_cluster(center: Vector2, count: int, base_scale: float) -> int:
	"""创建一簇花朵"""
	var flower_types = decoration_textures["flowers"]
	var created = 0

	for i in range(count):
		var angle = (TAU / count) * i
		var radius = randf_range(30, 60)
		var offset = Vector2(cos(angle), sin(angle)) * radius
		var pos = center + offset

		var flower_tex = flower_types[randi() % flower_types.size()]
		var sprite = _create_decoration_sprite(flower_tex, pos, base_scale + randf_range(-0.05, 0.05))

		if sprite:
			sprite.modulate.a = randf_range(0.7, 0.9)
			decorations_layer.add_child(sprite)
			created += 1

	return created

func _create_rock_group(center: Vector2, count: int, base_scale: float) -> int:
	"""创建一组石头"""
	var rock_types = decoration_textures["rocks"]
	var created = 0

	for i in range(count):
		var offset_x = randf_range(-40, 40)
		var offset_y = randf_range(-30, 30)
		var pos = center + Vector2(offset_x, offset_y)

		var rock_tex = rock_types[randi() % rock_types.size()]
		var sprite = _create_decoration_sprite(rock_tex, pos, base_scale + randf_range(-0.1, 0.1))

		if sprite:
			decorations_layer.add_child(sprite)
			created += 1

	return created

func _create_shoot(pos: Vector2, scale: float) -> int:
	"""创建单个竹笋"""
	var shoot_types = decoration_textures["shoots"]
	var shoot_tex = shoot_types[randi() % shoot_types.size()]
	var sprite = _create_decoration_sprite(shoot_tex, pos, scale)

	if sprite:
		decorations_layer.add_child(sprite)
		return 1
	return 0

func _create_decoration_sprite(texture_path: String, pos: Vector2, scale: float) -> Sprite2D:
	"""创建装饰物精灵（不旋转）"""
	var texture = load(texture_path)
	if not texture:
		return null

	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2(scale, scale)
	sprite.centered = true
	# 不旋转！保持植物自然朝向

	return sprite

# ==================== 光照系统 ====================
func create_lighting():
	"""午后竹林光影效果 - 使用加法混合的真实阳光"""
	print("MapSystem: Creating afternoon forest lighting...")

	# 1. 整体色调 - 轻微压暗，模拟树荫
	var canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color(0.92, 0.90, 0.85)  # 轻微暖色压暗
	get_parent().add_child(canvas_modulate)

	# 2. 创建加法混合材质
	var additive_material = CanvasItemMaterial.new()
	additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	# 3. 创建光斑纹理（更锐利的衰减）
	var soft_tex = _create_light_texture(128, 3.0)    # 柔和大光斑
	var medium_tex = _create_light_texture(64, 2.5)   # 中等光斑
	var sharp_tex = _create_light_texture(32, 2.0)    # 锐利小光斑

	# 4. 大面积柔和光照区域
	var ambient_spots = [
		{"pos": Vector2(1200, 700), "scale": 8.0, "intensity": 0.08},
		{"pos": Vector2(750, 500), "scale": 7.0, "intensity": 0.06},
		{"pos": Vector2(1650, 550), "scale": 6.5, "intensity": 0.06},
		{"pos": Vector2(950, 1000), "scale": 6.0, "intensity": 0.05},
		{"pos": Vector2(1550, 1100), "scale": 6.0, "intensity": 0.05},
	]

	for spot in ambient_spots:
		var sprite = Sprite2D.new()
		sprite.texture = soft_tex
		sprite.position = spot.pos
		sprite.scale = Vector2(spot.scale, spot.scale)
		sprite.z_index = 50
		sprite.material = additive_material
		# 淡淡的暖白色光
		sprite.modulate = Color(spot.intensity, spot.intensity * 0.95, spot.intensity * 0.8, 1.0)
		add_child(sprite)

	# 5. 阳光光柱 - 穿透竹林的明显光束
	var light_beams = [
		{"pos": Vector2(1100, 580), "scale": 3.0, "intensity": 0.15},
		{"pos": Vector2(1380, 720), "scale": 2.8, "intensity": 0.14},
		{"pos": Vector2(680, 520), "scale": 2.5, "intensity": 0.12},
		{"pos": Vector2(1700, 680), "scale": 2.5, "intensity": 0.12},
		{"pos": Vector2(880, 920), "scale": 2.2, "intensity": 0.10},
		{"pos": Vector2(1520, 1020), "scale": 2.0, "intensity": 0.10},
		{"pos": Vector2(1200, 420), "scale": 2.5, "intensity": 0.12},
	]

	for beam in light_beams:
		var sprite = Sprite2D.new()
		sprite.texture = medium_tex
		sprite.position = beam.pos
		sprite.scale = Vector2(beam.scale, beam.scale)
		sprite.z_index = 55
		sprite.material = additive_material
		# 阳光色 - 偏黄白
		var i = beam.intensity
		sprite.modulate = Color(i, i * 0.92, i * 0.7, 1.0)
		add_child(sprite)

	# 6. 小光斑 - 树叶间隙漏下的碎光
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345

	for idx in range(25):
		var x = rng.randf_range(400, MAP_WIDTH - 400)
		var y = rng.randf_range(400, MAP_HEIGHT - 400)
		var s = rng.randf_range(0.8, 1.5)
		var intensity = rng.randf_range(0.08, 0.18)

		var sprite = Sprite2D.new()
		sprite.texture = sharp_tex
		sprite.position = Vector2(x, y)
		sprite.scale = Vector2(s, s)
		sprite.z_index = 60
		sprite.material = additive_material
		# 明亮的小光点
		sprite.modulate = Color(intensity, intensity * 0.9, intensity * 0.65, 1.0)
		add_child(sprite)

	# 7. 边缘暗角（保持不变）
	_create_edge_vignette()

	print("MapSystem: Afternoon lighting complete")

func _create_light_texture(size: int, falloff: float) -> ImageTexture:
	"""创建用于加法混合的光斑纹理 - 中心亮边缘快速衰减"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_dist = size / 2.0

	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(dist / max_dist, 0.0, 1.0)
			# 使用更锐利的衰减曲线
			var brightness = pow(1.0 - t, falloff)
			# 加法混合用白色，亮度控制在RGB通道
			image.set_pixel(x, y, Color(brightness, brightness, brightness, 1.0))

	return ImageTexture.create_from_image(image)

func _create_gradient_texture(size: int, falloff: float) -> ImageTexture:
	"""创建圆形渐变纹理（保留兼容）"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_dist = size / 2.0

	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(dist / max_dist, 0.0, 1.0)
			var alpha = 1.0 - smoothstep(0.0, 1.0, pow(t, falloff))
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(image)

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _create_edge_vignette():
	"""边缘暗角 - 暖色调"""
	var vignette_tex = _create_vignette_texture()
	var vignette = Sprite2D.new()
	vignette.texture = vignette_tex
	vignette.position = Vector2(MAP_WIDTH / 2, MAP_HEIGHT / 2)
	vignette.scale = Vector2(MAP_WIDTH / 256.0 * 1.3, MAP_HEIGHT / 256.0 * 1.3)
	vignette.z_index = 15
	# 暖色暗角，不是纯黑
	vignette.modulate = Color(0.15, 0.1, 0.05, 0.35)
	add_child(vignette)

func _create_vignette_texture() -> ImageTexture:
	"""暗角纹理"""
	var size = 256
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var max_dist = size / 2.0 * 1.2

	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(dist / max_dist, 0.0, 1.0)
			var alpha = smoothstep(0.35, 1.0, t)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))

	return ImageTexture.create_from_image(image)
