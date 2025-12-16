extends Node2D
class_name MapSystem

# Map constants from Room 1 (竹林入口)
const MAP_WIDTH = 2400
const MAP_HEIGHT = 1800
const PLAYER_SPAWN_X = 1200
const PLAYER_SPAWN_Y = 1500

# 玩家高度参考（用于计算竹子缩放）
const PLAYER_HEIGHT = 100.0
# 竹子目标高度（大幅增加以体现遮天蔽日感）
var BAMBOO_SHORT_HEIGHT = 100.0   # 改为var以便动态调整
var BAMBOO_MEDIUM_HEIGHT = 180.0
var BAMBOO_TALL_HEIGHT = 300.0

# 深度缩放因子
var depth_height_scale: float = 1.0

# 边界墙厚度（竹海深度）
const WALL_THICKNESS = 200

# Bamboo texture paths with metadata
# Format: {path, original_height (approx), type}
var bamboo_configs = [
	{"path": "res://bamboo/bamboo_cluster_xlarge_1.png", "height": 1200, "type": "xlarge"},
	{"path": "res://bamboo/bamboo_cluster_xlarge_2.png", "height": 1000, "type": "xlarge"},
	{"path": "res://bamboo/bamboo_cluster_large_1.png", "height": 800, "type": "large"},
	{"path": "res://bamboo/bamboo_cluster_large_2.png", "height": 750, "type": "large"},
	{"path": "res://bamboo/bamboo_cluster_large_3.png", "height": 850, "type": "large"},
	{"path": "res://bamboo/bamboo_cluster_large_4.png", "height": 780, "type": "large"},
	{"path": "res://bamboo/bamboo_cluster_large_5.png", "height": 760, "type": "large"},
	{"path": "res://bamboo/bamboo_cluster_medium_1.png", "height": 600, "type": "medium"},
	{"path": "res://bamboo/bamboo_cluster_medium_2.png", "height": 650, "type": "medium"},
	{"path": "res://bamboo/bamboo_cluster_medium_3.png", "height": 580, "type": "medium"},
	{"path": "res://bamboo/bamboo_cluster_small_1.png", "height": 500, "type": "small"},
	{"path": "res://bamboo/bamboo_cluster_small_2.png", "height": 520, "type": "small"},
	{"path": "res://bamboo/bamboo_single_straight_1.png", "height": 450, "type": "single"},
	{"path": "res://bamboo/bamboo_single_straight_2.png", "height": 460, "type": "single"},
	{"path": "res://bamboo/bamboo_single_broken_1.png", "height": 400, "type": "broken"},
	{"path": "res://bamboo/bamboo_single_broken_2.png", "height": 380, "type": "broken"},
	{"path": "res://bamboo/bamboo_single_broken_3.png", "height": 390, "type": "broken"},
	{"path": "res://bamboo/bamboo_single_broken_4.png", "height": 410, "type": "broken"},
]

# 保留旧数组以兼容
var bamboo_textures = [
	"res://bamboo/bamboo_cluster_large_1.png",
	"res://bamboo/bamboo_cluster_large_2.png",
	"res://bamboo/bamboo_cluster_large_3.png",
	"res://bamboo/bamboo_cluster_large_4.png",
	"res://bamboo/bamboo_cluster_large_5.png",
	"res://bamboo/bamboo_cluster_medium_1.png",
	"res://bamboo/bamboo_cluster_medium_2.png",
	"res://bamboo/bamboo_cluster_medium_3.png",
	"res://bamboo/bamboo_cluster_small_1.png",
	"res://bamboo/bamboo_cluster_small_2.png",
	"res://bamboo/bamboo_cluster_xlarge_1.png",
	"res://bamboo/bamboo_cluster_xlarge_2.png",
	"res://bamboo/bamboo_single_broken_1.png",
	"res://bamboo/bamboo_single_broken_2.png",
	"res://bamboo/bamboo_single_broken_3.png",
	"res://bamboo/bamboo_single_broken_4.png",
	"res://bamboo/bamboo_single_straight_1.png",
	"res://bamboo/bamboo_single_straight_2.png"
]

# 装饰物纹理路径
var decoration_textures = {
	"flowers": [
		"res://flower_white_daisy_single.png",
		"res://flower_blue_single_1.png",
		"res://flower_red_cluster_1.png",
		"res://flower_yellow_cluster_1.png",
		"res://flower_white_cluster_1.png",
	],
	"shoots": [
		"res://shoot_small_1.png",
		"res://shoot_small_2.png",
		"res://shoot_medium_1.png",
		"res://shoot_medium_2.png",
	],
	"rocks": [
		"res://rock_medium_grey.png",
		"res://rock_large_moss_1.png",
		"res://rock_medium_scattered.png",
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
var lighting_layer: Node2D  # 光照层
var post_process_layer: CanvasLayer  # 后处理层
var wall_bodies: Array = []
var border_bamboos: Array = []
var interior_bamboos: Array = []
var interior_decorations: Array = []

# CanvasGroup 引用（用于阴影系统）
var game_objects_parent: Node = null

# Shader 材质
var bamboo_sway_shader: Shader = null
var post_process_shader: Shader = null
var post_process_rect: ColorRect = null
var post_process_enabled: bool = false  # 默认禁用后处理

func _ready():
	print("DEBUG: MapSystem _ready started")
	# 加载 Shader
	bamboo_sway_shader = load("res://shaders/bamboo_sway.gdshader")
	if not bamboo_sway_shader:
		print("警告: 无法加载 bamboo_sway.gdshader")

	post_process_shader = load("res://shaders/post_process.gdshader")
	if not post_process_shader:
		print("警告: 无法加载 post_process.gdshader")

	add_to_group("map_system")

	# 获取游戏对象父节点（用于阴影系统）
	var world = get_parent()
	if world and world.has_method("get_game_objects_parent"):
		game_objects_parent = world.get_game_objects_parent()
	else:
		game_objects_parent = get_parent()

	setup_layers()
	print("DEBUG: setup_layers done")
	create_background()
	print("DEBUG: create_background done")
	create_bamboo_sea_walls()
	print("DEBUG: create_bamboo_sea_walls done")
	# create_interior_bamboo() # Removed: Handled by RoomLayoutManager
	# create_decorations_designed() # Removed: Handled by RoomLayoutManager
	create_lighting()
	print("DEBUG: create_lighting done")
	setup_camera_limits()
	spawn_nitori_npc()
	print("DEBUG: MapSystem _ready finished")

func _process(delta):
	# 强制移除残留的玩家光环（应玩家要求）
	if player_light and is_instance_valid(player_light):
		player_light.queue_free()
		player_light = null

	# 更新动态光照（玩家跟随光源）
	_update_dynamic_lighting(delta)

func _input(event):
	# 按 F3 键切换后处理效果
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		post_process_enabled = !post_process_enabled
		if post_process_rect:
			post_process_rect.visible = post_process_enabled

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

	# ===== 装饰层（花草石头）- 启用 Y-sorting =====
	decorations_layer = Node2D.new()
	decorations_layer.name = "DecorationsLayer"
	decorations_layer.y_sort_enabled = true  # 启用 Y-sorting 解决遮挡问题
	decorations_layer.z_index = 0  # 与其他对象同层参与排序
	add_child(decorations_layer)

	# ===== 竹子碰撞层（Y-sorted，与玩家同层）=====
	# 这一层添加到World父节点，以便与Player一起Y-sorting
	bamboo_collision_layer = Node2D.new()
	bamboo_collision_layer.name = "BambooCollisionLayer"
	bamboo_collision_layer.y_sort_enabled = true
	# 将在 _ready 完成后由 World 的 y_sort_enabled 处理排序

	# ===== 光照层 =====
	lighting_layer = Node2D.new()
	lighting_layer.name = "LightingLayer"
	lighting_layer.z_index = 100  # 在最上层
	add_child(lighting_layer)

	# ===== 后处理层（全屏效果）=====
	_create_post_process_layer()

func create_background():
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
				
				# 恢复正常颜色，交由CanvasModulate统一控制
				# sprite.modulate = Color(0.3, 0.35, 0.45)
				
				background_layer.add_child(sprite)
	else:
		var color_rect = ColorRect.new()
		color_rect.color = Color(0.2, 0.6, 0.2) # 恢复绿色
		color_rect.size = Vector2(MAP_WIDTH, MAP_HEIGHT)
		background_layer.add_child(color_rect)

# ==================== 竹海墙壁系统（边缘密集竹林）====================
func create_bamboo_sea_walls():
	"""创建地图边缘的竹林 - 自然有机的边界"""
	var bamboo_count = 0
	bamboo_count += _create_organic_forest_edge()

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
	"""创建有机形状的竹林边缘 - 增强版：更整齐的竹墙"""
	var count = 0

	# 四个方向的边缘 - 底部需要特别加强
	var sides = ["top", "bottom", "left", "right"]

	for side in sides:
		var is_horizontal = (side == "top" or side == "bottom")
		var wall_length = MAP_WIDTH if is_horizontal else MAP_HEIGHT

		# 底部边缘需要更密集、更深的竹子
		var is_bottom = (side == "bottom")
		var density_mult = 1.3 if is_bottom else 1.0  # 降低密度，从2.0/1.5降到1.3/1.0
		var depth_mult = 1.8 if is_bottom else 1.0

		# 沿边缘分布竹子（更规则的间距）
		var pos = 0.0
		while pos < wall_length:
			var edge_depth = _get_edge_depth(pos, wall_length, side) * depth_mult

			# 在边界深度范围内放置竹子
			var bamboo_in_depth = randi_range(3, 5) if is_bottom else randi_range(2, 4)  # 降低密度，从5-9/4-7降到3-5/2-4

			for d in range(bamboo_in_depth):
				# 深度位置（从边缘向内）- 更规则的分布
				var depth_step = edge_depth / float(bamboo_in_depth)
				var depth = depth_step * d + randf_range(-10, 10)  # 轻微随机偏移
				var along_offset = randf_range(-15, 15)  # 减小随机偏移，更整齐

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

				# 边界检查 - 底部允许更大范围
				var extend = 100 if is_bottom else 50
				if bamboo_pos.x < -extend or bamboo_pos.x > MAP_WIDTH + extend:
					continue
				if bamboo_pos.y < -50 or bamboo_pos.y > MAP_HEIGHT + 150:
					continue

				# 根据深度决定竹子特性
				var depth_ratio = depth / edge_depth
				var has_collision = depth_ratio > 0.7  # 靠近可行走区域的竹子有碰撞

				# 边缘竹子全部强制使用高大类型，形成竹墙效果
				var force_tall = true  # 全部使用高大竹子

				count += _create_forest_bamboo_enhanced(bamboo_pos, depth_ratio, has_collision, force_tall)

				# 边界竹林里不放竹笋（只在内部竹林放）

			# 规则的间距 - 保持整齐但降低密度
			var step = randf_range(25, 35) if is_bottom else randf_range(35, 50)  # 增大间距，从12-20/18-28改为25-35/35-50
			pos += step

	return count

func _create_forest_bamboo_enhanced(pos: Vector2, depth_ratio: float, has_collision: bool, force_tall: bool = false) -> int:
	"""创建竹林中的竹子 - 增强版"""
	# 根据深度选择竹子类型
	var suitable_types: Array
	if force_tall or depth_ratio < 0.2:
		suitable_types = ["xlarge"]  # 最外围用最大竹子
	elif depth_ratio < 0.4:
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

	# 根据竹子类型和深度决定高度 - cluster类型缩小，single类型放大
	var height_base = lerp(BAMBOO_TALL_HEIGHT, BAMBOO_SHORT_HEIGHT, depth_ratio)
	if force_tall:
		height_base = BAMBOO_TALL_HEIGHT * 1.3

	# 应用深度缩放因子 (越深越高)
	height_base *= depth_height_scale

	# 根据类型调整缩放系数 - cluster类型缩小以避免过粗
	var type_scale_mult: float
	match config.type:
		"xlarge":
			type_scale_mult = randf_range(0.35, 0.5)  # 减小，避免过粗
		"large":
			type_scale_mult = randf_range(0.32, 0.45)  # 减小，避免过粗
		"medium":
			type_scale_mult = randf_range(0.4, 0.55)  # 减小
		"small":
			type_scale_mult = randf_range(0.45, 0.6)  # 减小
		"single":
			type_scale_mult = randf_range(0.8, 1.1)  # 减小，避免过大
		"broken":
			type_scale_mult = randf_range(0.4, 0.6)  # 大幅减小，断竹太大
		_:
			type_scale_mult = 0.5

	var target_height = height_base * type_scale_mult
	var scale = target_height / texture.get_height()

	# 透明度 - 边界竹子不需要透明，全部不透明
	var alpha = 1.0
	# 颜色变化 - 增加层次感
	var color_var = randf_range(0.85, 1.0)
	var green_boost = randf_range(0.0, 0.08)

	if has_collision:
		var body = StaticBody2D.new()
		body.name = "BambooBody"
		body.position = pos
		body.collision_layer = 2
		body.collision_mask = 1  # 检测玩家碰撞

		# 添加阴影（在sprite之前，让阴影在下层）
		# 竹子的影子是细长的条状，下午斜阳效果
		var bamboo_base_width = texture.get_width() * scale
		# 下午的长影子：长度是竹子高度的1.2倍，模拟斜阳拉长效果
		var bamboo_height = texture.get_height() * scale
		var shadow_length = bamboo_height * 1.2  # 加长影子
		var shadow_width = bamboo_base_width * 0.5
		var shadow_size = Vector2(shadow_length, shadow_width)
		# 直接创建阴影精灵
		create_shadow_for_entity(body, shadow_size, Vector2(0, 0), 2.0) # 高度因子2.0，长影子

		var sprite = Sprite2D.new()
		sprite.name = "Sprite"
		sprite.texture = texture
		sprite.scale = Vector2(scale, scale)
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		sprite.modulate = Color(color_var, color_var + green_boost, color_var - 0.05, alpha)

		# 应用竹子摇曳 Shader（传入缩放值）
		_apply_bamboo_sway_shader(sprite, scale)

		body.add_child(sprite)

		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(texture.get_width() * scale * 0.25, 20)
		collision.shape = shape
		collision.position = Vector2(0, -10)
		body.add_child(collision)

		# 添加 Area2D 用于检测碰撞触发摇晃
		var area = Area2D.new()
		area.name = "ImpactArea"
		area.collision_layer = 0
		area.collision_mask = 1  # 检测玩家
		var area_collision = CollisionShape2D.new()
		var area_shape = RectangleShape2D.new()
		area_shape.size = Vector2(texture.get_width() * scale * 0.4, 30)
		area_collision.shape = area_shape
		area_collision.position = Vector2(0, -15)
		area.add_child(area_collision)
		area.body_entered.connect(_on_bamboo_impact.bind(sprite))
		body.add_child(area)

		game_objects_parent.call_deferred("add_child", body)
		border_bamboos.append(body)
		wall_bodies.append(body) # Keep compatible
	else:
		# 无碰撞竹子 - 需要容器来放置sprite和shadow
		var container = Node2D.new()
		container.position = pos

		# 添加阴影
		var bamboo_base_width = texture.get_width() * scale
		var bamboo_height = texture.get_height() * scale
		var shadow_length = bamboo_height * 1.2
		var shadow_width = bamboo_base_width * 0.5
		var shadow_size = Vector2(shadow_length, shadow_width)
		create_shadow_for_entity(container, shadow_size, Vector2(0, 0), 2.0) # 高度因子2.0

		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale, scale)
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		sprite.position = pos
		sprite.modulate = Color(color_var, color_var + green_boost, color_var - 0.05, alpha)

		# 应用竹子摇曳 Shader（传入缩放值）
		_apply_bamboo_sway_shader(sprite, scale)

		container.add_child(sprite)

		# 所有竹子都添加到World以参与Y-sorting，不再区分远近
		# 远景效果通过透明度和颜色变化实现
		game_objects_parent.call_deferred("add_child", container)

	return 1

# ==================== 内部装饰竹子 ====================
func create_interior_bamboo():
	"""在地图内部创建成片的高低错落竹子群"""
	var count = 0

	# 定义安全区域（玩家出生点附近不放置障碍）
	var spawn_safe_zone = Rect2(PLAYER_SPAWN_X - 200, PLAYER_SPAWN_Y - 200, 400, 400)

	# 定义多个竹林群落位置 - 更丰富的布局
	var grove_positions = [
		# 上半部分 - 大型竹林群
		{"pos": Vector2(350, 450), "size": 8, "types": ["large", "xlarge", "medium"]},
		{"pos": Vector2(750, 380), "size": 6, "types": ["xlarge", "large"]},
		{"pos": Vector2(1100, 320), "size": 5, "types": ["medium", "single", "broken"]},
		{"pos": Vector2(1500, 400), "size": 7, "types": ["large", "medium"]},
		{"pos": Vector2(1900, 350), "size": 6, "types": ["xlarge", "large"]},
		{"pos": Vector2(2150, 480), "size": 5, "types": ["medium", "small"]},

		# 中间区域 - 稀疏但多样
		{"pos": Vector2(500, 750), "size": 4, "types": ["single", "broken", "small"]},
		{"pos": Vector2(900, 850), "size": 5, "types": ["medium", "large"]},
		{"pos": Vector2(1300, 700), "size": 3, "types": ["single", "broken"]},
		{"pos": Vector2(1700, 800), "size": 5, "types": ["large", "medium"]},
		{"pos": Vector2(2100, 750), "size": 4, "types": ["medium", "small", "broken"]},

		# 中下区域
		{"pos": Vector2(400, 1100), "size": 6, "types": ["large", "xlarge"]},
		{"pos": Vector2(800, 1050), "size": 4, "types": ["medium", "single"]},
		{"pos": Vector2(1600, 1100), "size": 5, "types": ["large", "medium"]},
		{"pos": Vector2(2000, 1000), "size": 6, "types": ["xlarge", "large"]},

		# 下半部分（避开出生点）
		{"pos": Vector2(300, 1400), "size": 5, "types": ["large", "medium", "broken"]},
		{"pos": Vector2(600, 1550), "size": 4, "types": ["medium", "small"]},
		{"pos": Vector2(1800, 1380), "size": 5, "types": ["large", "xlarge"]},
		{"pos": Vector2(2150, 1500), "size": 6, "types": ["medium", "large", "single"]},
	]

	for grove in grove_positions:
		var grove_pos = grove.pos
		var grove_size = grove.size
		var grove_types = grove.types

		# 检查是否在安全区域
		if spawn_safe_zone.has_point(grove_pos):
			continue

		# 每个群落放置多棵高低错落的竹子
		for i in range(grove_size):
			var offset = Vector2(randf_range(-80, 80), randf_range(-50, 50))
			var pos = grove_pos + offset

			# 边界检查
			if pos.x < WALL_THICKNESS + 50 or pos.x > MAP_WIDTH - WALL_THICKNESS - 50:
				continue
			if pos.y < WALL_THICKNESS + 50 or pos.y > MAP_HEIGHT - WALL_THICKNESS - 50:
				continue

			count += create_interior_bamboo_varied(pos, grove_types)

			# 在部分竹子旁边放竹笋（减小尺寸）
			if randf() < 0.4:
				var shoot_offset = Vector2(randf_range(-20, 20), randf_range(5, 15))
				_create_shoot(pos + shoot_offset, randf_range(0.08, 0.12))

func create_interior_bamboo_varied(pos: Vector2, allowed_types: Array) -> int:
	"""创建单个内部竹子 - 支持指定类型"""
	var suitable_indices = []
	for i in range(bamboo_configs.size()):
		if bamboo_configs[i].type in allowed_types:
			suitable_indices.append(i)

	if suitable_indices.is_empty():
		# 默认使用所有中小型
		for i in range(bamboo_configs.size()):
			if bamboo_configs[i].type in ["medium", "small", "single"]:
				suitable_indices.append(i)

	if suitable_indices.is_empty():
		return 0

	var config = bamboo_configs[suitable_indices[randi() % suitable_indices.size()]]
	var texture = load(config.path)
	if not texture:
		return 0

	# 根据类型决定高度范围 - cluster类型缩小，single类型放大，让视觉更均匀
	var target_height: float
	match config.type:
		"xlarge":
			# 竹丛很宽，进一步缩小高度让它不那么粗大
			target_height = randf_range(BAMBOO_TALL_HEIGHT * 0.4, BAMBOO_TALL_HEIGHT * 0.6)
		"large":
			target_height = randf_range(BAMBOO_TALL_HEIGHT * 0.35, BAMBOO_TALL_HEIGHT * 0.55)
		"medium":
			target_height = randf_range(BAMBOO_MEDIUM_HEIGHT * 0.5, BAMBOO_MEDIUM_HEIGHT * 0.7)
		"small":
			target_height = randf_range(BAMBOO_MEDIUM_HEIGHT * 0.45, BAMBOO_MEDIUM_HEIGHT * 0.6)
		"single":
			# 单棵竹子比较细，但不要太大
			target_height = randf_range(BAMBOO_MEDIUM_HEIGHT * 0.7, BAMBOO_MEDIUM_HEIGHT * 0.95)
		"broken":
			target_height = randf_range(BAMBOO_SHORT_HEIGHT * 0.4, BAMBOO_SHORT_HEIGHT * 0.7)  # 大幅减小，断竹太大
		_:
			target_height = BAMBOO_MEDIUM_HEIGHT * 0.5

	var scale = target_height / texture.get_height()

	# 创建 StaticBody2D
	var body = StaticBody2D.new()
	body.name = "BambooBody"
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 1  # 检测玩家碰撞

	# 添加阴影 - 细长条状
	var bamboo_base_width = texture.get_width() * scale
	var bamboo_height = texture.get_height() * scale
	var shadow_length = bamboo_height * 1.2
	var shadow_width = bamboo_base_width * 0.5
	var shadow_size = Vector2(shadow_length, shadow_width)
	create_shadow_for_entity(body, shadow_size, Vector2(0, 0), 2.0) # 高度因子2.0

	# 精灵（底部锚点）+ 随机颜色变化
	var sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = texture
	sprite.scale = Vector2(scale, scale)
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())

	var color_var = randf_range(0.88, 1.0) * 0.7 # 乘以0.7压暗
	var green_boost = randf_range(0.0, 0.06)
	sprite.modulate = Color(color_var, color_var + green_boost, color_var - 0.03, 1.0)

	# 应用竹子摇曳 Shader（传入缩放值）
	_apply_bamboo_sway_shader(sprite, scale)

	body.add_child(sprite)

	# 底部碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	var collision_width = texture.get_width() * scale * 0.3
	var collision_height = 25
	shape.size = Vector2(collision_width, collision_height)
	collision.shape = shape
	collision.position = Vector2(0, -collision_height * 0.5)
	body.add_child(collision)

	# 添加 Area2D 用于检测碰撞触发摇晃
	var area = Area2D.new()
	area.name = "ImpactArea"
	area.collision_layer = 0
	area.collision_mask = 1  # 检测玩家
	var area_collision = CollisionShape2D.new()
	var area_shape = RectangleShape2D.new()
	area_shape.size = Vector2(collision_width * 1.5, 35)
	area_collision.shape = area_shape
	area_collision.position = Vector2(0, -17)
	area.add_child(area_collision)
	area.body_entered.connect(_on_bamboo_impact.bind(sprite))
	body.add_child(area)

	game_objects_parent.call_deferred("add_child", body)
	interior_bamboos.append(body)
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
		decorations_count += _create_shoot(pos, 0.1)

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
		var container = create_decoration_sprite(flower_tex, pos, base_scale + randf_range(-0.05, 0.05))

		if container:
			# 获取容器内的精灵并设置透明度
			for child in container.get_children():
				if child is Sprite2D:
					child.modulate.a = randf_range(0.7, 0.9)
					break
			# 直接添加到CanvasGroup以参与Y-sorting
			game_objects_parent.call_deferred("add_child", container)
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
		var container = create_decoration_sprite(rock_tex, pos, base_scale + randf_range(-0.1, 0.1))

		if container:
			# 直接添加到CanvasGroup以参与Y-sorting
			game_objects_parent.call_deferred("add_child", container)
			created += 1

	return created

func _create_shoot(pos: Vector2, scale: float) -> int:
	"""创建单个竹笋"""
	var shoot_types = decoration_textures["shoots"]
	var shoot_tex = shoot_types[randi() % shoot_types.size()]
	var container = create_decoration_sprite(shoot_tex, pos, scale)

	if container:
		# 直接添加到CanvasGroup以参与Y-sorting
		game_objects_parent.call_deferred("add_child", container)
		return 1
	return 0

func create_decoration_sprite(texture_path: String, pos: Vector2, scale: float) -> Node2D:
	"""创建装饰物精灵 - 底部锚点以正确参与Y-sorting，包含影子"""
	var texture = load(texture_path)
	if not texture:
		return null

	# 创建容器来放置精灵和影子
	var container = Node2D.new()
	container.position = pos

	# 添加影子
	var decoration_width = texture.get_width() * scale
	var decoration_height = texture.get_height() * scale
	var shadow_length = decoration_height * 1.0
	var shadow_width = decoration_width * 0.4
	var shadow_size = Vector2(shadow_length, shadow_width)
	create_shadow_for_entity(container, shadow_size, Vector2(0, 0), 0.2) # 花草影子

	# 创建精灵
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale, scale)
	# 使用底部锚点，与竹子一致，确保Y-sorting正确
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	container.add_child(sprite)

	game_objects_parent.call_deferred("add_child", container) # 自动添加到场景
	interior_decorations.append(container)
	return container

# ==================== 光照系统 ====================

# 动态光照节点引用
var player_light: Node2D = null
var ambient_lights: Array = []
var flicker_timer: float = 0.0

func create_lighting(style: String = "outskirts"):
	"""光照系统入口"""
	_clear_lighting()
	
	if style == "outskirts":
		_create_lighting_outskirts()
	else:
		_create_lighting_deep_forest()

func update_environment(depth: int):
	"""根据房间深度更新环境（光照、竹子高度）"""
	print("MapSystem: Updating environment for depth ", depth)
	
	# 1. 调整竹子高度：越深越高
	if depth < 3:
		# 外围：标准高度
		depth_height_scale = 1.0
		BAMBOO_TALL_HEIGHT = 300.0
	else:
		# 深处：更高更密
		depth_height_scale = 1.5
		BAMBOO_TALL_HEIGHT = 700.0 # 巨型竹子
		
	# 2. 切换光照风格
	if depth < 3:
		create_lighting("outskirts")
	else:
		create_lighting("deep_forest")

func _clear_lighting():
	"""清理旧的光照组件"""
	for child in get_tree().root.get_children():
		if child.name == "AtmosphereLayer" and is_instance_valid(child):
			child.queue_free()
	for child in get_parent().get_children():
		if child is WorldEnvironment and is_instance_valid(child):
			child.queue_free()

func _create_lighting_outskirts():
	"""竹林外围风格 - 强烈的树影光照对比 (无光柱，靠环境光和影子)"""
	print("MapSystem: Creating OUTSKIRTS lighting (High Contrast)...")
	
	# CanvasLayer (用于滤镜) - Layer 1 确保覆盖在物体上进行压暗
	var atmosphere_layer = CanvasLayer.new()
	atmosphere_layer.name = "AtmosphereLayer"
	atmosphere_layer.layer = 1 
	get_tree().root.add_child(atmosphere_layer)

	# 1. 基础压暗 (Multiply)
	# 使用 0.6 的亮度，配合高对比度，亮部会亮，暗部会暗
	var darkness_overlay = ColorRect.new()
	darkness_overlay.color = Color(0.6, 0.6, 0.65) 
	darkness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	darkness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var mat_mul = CanvasItemMaterial.new()
	mat_mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	darkness_overlay.material = mat_mul
	atmosphere_layer.add_child(darkness_overlay)

	# 2. WorldEnvironment (Glow & Contrast)
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_strength = 0.8
	env.glow_bloom = 0.05
	
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.35 # 高对比度
	env.adjustment_saturation = 1.1
	
	world_env.environment = env
	get_parent().add_child(world_env)

func _create_lighting_deep_forest():
	"""竹林深处风格 - 斑斓光影 (高对比度 + 噪声光斑 + 中心聚光)"""
	print("MapSystem: Creating DEEP FOREST lighting...")
	
	# CanvasLayer
	var atmosphere_layer = CanvasLayer.new()
	atmosphere_layer.name = "AtmosphereLayer"
	atmosphere_layer.layer = 1 
	get_tree().root.add_child(atmosphere_layer)

	# 1. 基础压暗 (Multiply)
	var darkness_overlay = ColorRect.new()
	darkness_overlay.color = Color(0.35, 0.35, 0.45) # 较暗
	darkness_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	darkness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var mat_mul = CanvasItemMaterial.new()
	mat_mul.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	darkness_overlay.material = mat_mul
	atmosphere_layer.add_child(darkness_overlay)

	# 2. 斑驳阳光层 (Add)
	var sunlight_overlay = TextureRect.new()
	sunlight_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	sunlight_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sunlight_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.002
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 512
	noise_tex.height = 512
	noise_tex.seamless = true
	
	sunlight_overlay.texture = noise_tex
	sunlight_overlay.modulate = Color(0.6, 0.5, 0.3, 0.2)
	
	var mat_add = CanvasItemMaterial.new()
	mat_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sunlight_overlay.material = mat_add
	atmosphere_layer.add_child(sunlight_overlay)
	
	# 3. 中心上帝光
	var center_beam = TextureRect.new()
	center_beam.texture = _create_light_texture(512, 2.5)
	center_beam.set_anchors_preset(Control.PRESET_CENTER)
	center_beam.position = Vector2(get_viewport_rect().size.x/2 - 1000, get_viewport_rect().size.y/2 - 1000)
	center_beam.size = Vector2(2000, 2000)
	center_beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	center_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center_beam.modulate = Color(1.0, 0.9, 0.7, 0.3)
	center_beam.material = mat_add
	atmosphere_layer.add_child(center_beam)

	# WorldEnvironment
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_strength = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 0.8
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.2
	env.adjustment_saturation = 1.1
	world_env.environment = env
	get_parent().add_child(world_env)

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
	lighting_layer.call_deferred("add_child", vignette)

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

func _create_player_light():
	"""创建跟随玩家的动态光源"""
	# 已移除，保持纯净
	pass

func _create_native_2d_lights():
	"""创建Godot原生2D光源增强效果"""
	pass # 移除所有额外光源

func _update_dynamic_lighting(delta: float):
	"""更新动态光照效果 - 禁用呼吸效果"""
	pass

# ==================== 后处理层 ====================
func _create_post_process_layer():
	"""创建后处理层 - 色调映射、辉光、暗角"""
	if not post_process_shader:
		return

	# 创建 CanvasLayer 用于全屏后处理
	post_process_layer = CanvasLayer.new()
	post_process_layer.name = "PostProcessLayer"
	post_process_layer.layer = 100  # 最高层
	get_parent().call_deferred("add_child", post_process_layer)

	# 创建全屏 ColorRect 应用 Shader
	post_process_rect = ColorRect.new()
	post_process_rect.name = "PostProcessRect"
	post_process_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post_process_rect.color = Color(1, 1, 1, 1)  # 白色基底，shader会覆盖

	# 使用锚点确保全屏覆盖
	post_process_rect.anchor_left = 0
	post_process_rect.anchor_top = 0
	post_process_rect.anchor_right = 1
	post_process_rect.anchor_bottom = 1

	# 创建 ShaderMaterial
	var material = ShaderMaterial.new()
	material.shader = post_process_shader

	# 检查 shader 是否有效
	if not material.shader:
		print("MapSystem: ERROR - Shader not valid, disabling post-process")
		post_process_rect.queue_free()
		post_process_rect = null
		return

	# 设置默认参数 - 午后竹林氛围
	material.set_shader_parameter("glow_intensity", 0.4)
	material.set_shader_parameter("glow_threshold", 0.65)
	material.set_shader_parameter("glow_blur_size", 3.5)
	material.set_shader_parameter("tonemap_mode", 1)  # ACES
	material.set_shader_parameter("exposure", 1.05)
	material.set_shader_parameter("contrast", 1.08)
	material.set_shader_parameter("saturation", 1.12)
	material.set_shader_parameter("vignette_intensity", 0.25)
	material.set_shader_parameter("vignette_smoothness", 0.45)
	material.set_shader_parameter("color_tint", Vector3(1.0, 0.98, 0.94))  # 微暖色调
	material.set_shader_parameter("color_temperature", 0.08)

	post_process_rect.material = material
	post_process_layer.call_deferred("add_child", post_process_rect)

	# 默认禁用，按 F3 启用
	post_process_rect.visible = post_process_enabled

# ==================== 竹子摇曳 Shader ====================
func _apply_bamboo_sway_shader(sprite: Sprite2D, bamboo_scale: float = 1.0, random_phase: bool = true) -> void:
	"""为竹子精灵应用摇曳 Shader - 间歇性微风效果
	bamboo_scale: 竹子的缩放值，越大的竹子摇晃幅度越小
	"""
	if not bamboo_sway_shader:
		return

	var material = ShaderMaterial.new()
	material.shader = bamboo_sway_shader

	# 根据竹子大小调整摇晃幅度（大竹子摇晃小，小竹子摇晃大）
	var size_factor = clamp(1.0 / (bamboo_scale * 2.0 + 0.5), 0.3, 1.5)
	var base_sway = randf_range(8.0, 12.0) * size_factor

	# 风阵参数 - 间歇性摇晃
	material.set_shader_parameter("wind_cycle", randf_range(12.0, 20.0))
	material.set_shader_parameter("wind_duration", randf_range(2.5, 4.0))
	material.set_shader_parameter("sway_amount", base_sway)
	material.set_shader_parameter("sway_speed", randf_range(2.0, 3.0) * size_factor + 1.0)

	# 随机相位让每棵竹子不同步
	if random_phase:
		material.set_shader_parameter("sway_phase", randf() * TAU)
	else:
		material.set_shader_parameter("sway_phase", 0.0)

	# 碰撞摇晃初始为 0
	material.set_shader_parameter("impact_sway", 0.0)
	material.set_shader_parameter("impact_decay", 0.0)

	# 颜色参数
	material.set_shader_parameter("tint_color", Color(1.0, 1.0, 1.0, 1.0))
	material.set_shader_parameter("brightness", 1.0)

	sprite.material = material

# 碰撞摇晃回调
func _on_bamboo_impact(body: Node2D, sprite: Sprite2D) -> void:
	"""玩家撞到竹子时触发摇晃"""
	if not sprite or not is_instance_valid(sprite):
		return

	var mat = sprite.material as ShaderMaterial
	if not mat:
		return

	# 设置碰撞摇晃强度
	mat.set_shader_parameter("impact_sway", 25.0)
	mat.set_shader_parameter("impact_decay", 0.0)

	# 创建衰减动画
	var tween = create_tween()
	tween.tween_method(
		func(value: float): mat.set_shader_parameter("impact_decay", value),
		0.0, 1.0, 0.8
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# 动画结束后重置
	tween.tween_callback(func():
		mat.set_shader_parameter("impact_sway", 0.0)
		mat.set_shader_parameter("impact_decay", 0.0)
	)

# ==================== Shader 参数调整接口 ====================
func toggle_post_processing(enabled: bool) -> void:
	"""开关后处理效果"""
	if post_process_rect:
		post_process_rect.visible = enabled

func set_post_process_params(params: Dictionary) -> void:
	"""动态调整后处理参数"""
	if not post_process_rect or not post_process_rect.material:
		return

	var material = post_process_rect.material as ShaderMaterial
	for param_name in params:
		material.set_shader_parameter(param_name, params[param_name])

func get_post_process_material() -> ShaderMaterial:
	"""获取后处理材质以供外部调整"""
	if post_process_rect:
		return post_process_rect.material as ShaderMaterial
	return null

# ==================== 阴影系统 ====================
# 全局阴影方向（模拟下午2-3点的阳光）
const SHADOW_DIRECTION = Vector2(12, 12)  # 更倾斜
const SHADOW_ANGLE = 0.5  # 角度加大

func create_shadow_for_entity(parent: Node2D, size: Vector2 = Vector2(40, 20), offset: Vector2 = Vector2(0, 0), height_factor: float = 1.0) -> Sprite2D:
	"""为实体创建统一方向的阴影 - 斜长浓烈风格"""
	var shadow = Sprite2D.new()
	shadow.name = "Shadow"
	shadow.texture = _create_shadow_texture(int(size.x), int(size.y))

	# 影子偏移 = 基础方向 * 高度因子
	var shadow_offset = SHADOW_DIRECTION * height_factor * 2.0 + offset # 影子更长
	
	shadow.position = shadow_offset
	shadow.rotation = SHADOW_ANGLE
	shadow.scale = Vector2(1.0, 2.5) # 拉长影子，制造斜长感
	shadow.z_index = -10
	shadow.centered = true
	shadow.modulate = Color(0, 0, 0, 0.7) # 浓烈的黑影

	parent.call_deferred("add_child", shadow)
	return shadow

func add_dynamic_shadow(node: Node2D, scale_mult: float = 1.0):
	"""为动态角色（玩家/敌人）添加影子"""
	var size = Vector2(50, 25) * scale_mult
	# 动态角色通常有碰撞体，影子应该在脚下中心
	create_shadow_for_entity(node, size, Vector2(0, 5), 0.5)

func _create_shadow_texture(width: int, height: int) -> ImageTexture:
	"""创建椭圆形阴影纹理，形状根据宽高比调整"""
	# 确保尺寸至少为2
	width = max(width, 2)
	height = max(height, 2)

	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var center_x = width / 2.0
	var center_y = height / 2.0

	for x in range(width):
		for y in range(height):
			# 计算到椭圆中心的归一化距离
			var dx = (x - center_x) / (width / 2.0)
			var dy = (y - center_y) / (height / 2.0)
			var dist_sq = dx * dx + dy * dy  # 椭圆距离平方

			if dist_sq <= 1.0:
				# 在椭圆内，计算柔和的alpha渐变
				var dist = sqrt(dist_sq)
				var alpha = 1.0 - dist  # 从中心1.0到边缘0.0

				# 使用柔和的衰减曲线（还原）
				alpha = pow(alpha, 1.5)  # 还原到1.5
				alpha = alpha * 0.4  # 稍微加深一点点

				# 设置为深蓝紫色半透明（环境阴影色），而不是纯黑
				# 这样在草地上看起来更自然，像是有天空光漫射
				image.set_pixel(x, y, Color(0.1, 0.1, 0.25, alpha))
			else:
				# 在椭圆外，完全透明
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)

# ==================== 河童NPC生成 ====================
func spawn_nitori_npc():
	"""在地图中生成河童NPC"""
	var nitori_scene = load("res://NitoriNPC.tscn")
	if not nitori_scene:
		print("MapSystem: 无法加载 NitoriNPC.tscn")
		return

	var nitori = nitori_scene.instantiate()
	# 放置在地图中心偏右上的位置，远离玩家出生点
	nitori.position = Vector2(1800, 600)

	# 添加到游戏对象父节点以参与Y-sorting
	game_objects_parent.call_deferred("add_child", nitori)