extends Node2D
class_name MapSystem

# Map constants from Room 1 (竹林入口)
const MAP_WIDTH = 2400
const MAP_HEIGHT = 1800
const PLAYER_SPAWN_X = 1200
const PLAYER_SPAWN_Y = 1500

# 玩家高度参考（用于计算竹子缩放）
const PLAYER_HEIGHT = 100.0
# 竹子目标高度
var BAMBOO_SHORT_HEIGHT = 100.0
var BAMBOO_MEDIUM_HEIGHT = 180.0
var BAMBOO_TALL_HEIGHT = 300.0

# 深度缩放因子
var depth_height_scale: float = 1.0

# 边界墙厚度（竹海深度）
const WALL_THICKNESS = 200

# Bamboo texture paths with metadata
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

# Enemy spawn points
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
var lighting_layer: Node2D  # 光照层 (World Space)
var post_process_layer: CanvasLayer  # 后处理层 (Screen Space)
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

# Noise for bamboo generation
var bamboo_noise: FastNoiseLite = null

func _ready():
	add_to_group("map_system")

	# 初始化噪声
	bamboo_noise = FastNoiseLite.new()
	bamboo_noise.seed = randi()
	bamboo_noise.frequency = 0.003 # 降低频率，斑块更大更自然
	bamboo_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	bamboo_noise.fractal_octaves = 3

	# 获取游戏对象父节点（用于阴影系统）
	var world = get_parent()
	if world and world.has_method("get_game_objects_parent"):
		game_objects_parent = world.get_game_objects_parent()
	else:
		game_objects_parent = get_parent()
	
	if not game_objects_parent:
		game_objects_parent = self
		print("MapSystem WARNING: game_objects_parent not found, using self.")

	setup_layers()
	create_background()
	create_bamboo_sea_walls()
	
	# 生成内部竹子和装饰物 (确保调用)
	create_interior_bamboo()
	create_decorations_designed()
	
	# 初始化光照 (默认外围)
	create_lighting("outskirts")
	
	setup_camera_limits()
	spawn_nitori_npc() # 恢复河童
	print("DEBUG: MapSystem _ready finished")

func setup_layers():
	if lighting_layer: return

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
	decorations_layer.y_sort_enabled = true
	decorations_layer.z_index = 0
	add_child(decorations_layer)

	# ===== 竹子碰撞层（Y-sorted，与玩家同层）=====
	bamboo_collision_layer = Node2D.new()
	bamboo_collision_layer.name = "BambooCollisionLayer"
	bamboo_collision_layer.y_sort_enabled = true
	# 将在 _ready 完成后由 World 的 y_sort_enabled 处理排序

	# ===== 光照层 (World Space) =====
	# 放在最上层，用于绘制光柱、暗角等固定在地图上的光影
	lighting_layer = Node2D.new()
	lighting_layer.name = "LightingLayer"
	lighting_layer.z_index = 200 # 确保覆盖在所有物体之上
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
				# 稍微变暗一点地面，突出光照
				sprite.modulate = Color(0.9, 0.95, 0.9) 
				background_layer.add_child(sprite)
	else:
		var color_rect = ColorRect.new()
		color_rect.color = Color(0.2, 0.5, 0.2)
		color_rect.size = Vector2(MAP_WIDTH, MAP_HEIGHT)
		background_layer.add_child(color_rect)

# ==================== 竹海墙壁系统 ====================
func create_bamboo_sea_walls():
	"""创建地图边缘的竹林"""
	_create_organic_forest_edge()

func _get_edge_depth(pos_along: float, wall_length: float, side: String) -> float:
	var base_depth = WALL_THICKNESS
	var wave1 = sin(pos_along * 0.008) * 60
	var wave2 = sin(pos_along * 0.023 + 1.5) * 35
	var wave3 = sin(pos_along * 0.041 + 3.0) * 20
	var entrance_pos = wall_length * 0.5
	var entrance_influence = 0.0
	var dist_to_entrance = abs(pos_along - entrance_pos)
	if dist_to_entrance < 200:
		entrance_influence = exp(-dist_to_entrance * dist_to_entrance / 8000.0) * 120
	return base_depth + wave1 + wave2 + wave3 - entrance_influence

func _create_organic_forest_edge() -> int:
	var count = 0
	var sides = ["top", "bottom", "left", "right"]

	for side in sides:
		var is_horizontal = (side == "top" or side == "bottom")
		var wall_length = MAP_WIDTH if is_horizontal else MAP_HEIGHT
		var is_bottom = (side == "bottom")
		var density_mult = 1.3 if is_bottom else 1.0
		var depth_mult = 1.8 if is_bottom else 1.0
		var pos = 0.0
		
		while pos < wall_length:
			var edge_depth = _get_edge_depth(pos, wall_length, side) * depth_mult
			var bamboo_in_depth = randi_range(3, 5) if is_bottom else randi_range(2, 4)

			for d in range(bamboo_in_depth):
				var depth_step = edge_depth / float(bamboo_in_depth)
				var depth = depth_step * d + randf_range(-10, 10)
				var along_offset = randf_range(-15, 15)

				var bamboo_pos: Vector2
				match side:
					"top": bamboo_pos = Vector2(pos + along_offset, depth)
					"bottom": bamboo_pos = Vector2(pos + along_offset, MAP_HEIGHT - depth)
					"left": bamboo_pos = Vector2(depth, pos + along_offset)
					"right": bamboo_pos = Vector2(MAP_WIDTH - depth, pos + along_offset)

				if bamboo_pos.x < -100 or bamboo_pos.x > MAP_WIDTH + 100: continue
				if bamboo_pos.y < -50 or bamboo_pos.y > MAP_HEIGHT + 150: continue

				var depth_ratio = depth / edge_depth
				var has_collision = depth_ratio > 0.7
				count += _create_forest_bamboo_enhanced(bamboo_pos, depth_ratio, has_collision, true)

			pos += randf_range(25, 35) if is_bottom else randf_range(35, 50)
	return count

func _create_forest_bamboo_enhanced(pos: Vector2, depth_ratio: float, has_collision: bool, force_tall: bool = false) -> int:
	var suitable_types: Array
	if force_tall or depth_ratio < 0.2:
		suitable_types = ["xlarge"]
	elif depth_ratio < 0.4:
		suitable_types = ["xlarge", "large"]
	elif depth_ratio < 0.6:
		suitable_types = ["large", "medium"]
	else:
		suitable_types = ["medium", "small", "single", "broken"]

	var suitable_indices = []
	for i in range(bamboo_configs.size()):
		if bamboo_configs[i].type in suitable_types:
			suitable_indices.append(i)
	if suitable_indices.is_empty():
		suitable_indices = range(bamboo_configs.size())

	var config = bamboo_configs[suitable_indices[randi() % suitable_indices.size()]]
	var texture = load(config.path)
	if not texture: return 0

	var target_height: float
	match config.type:
		"xlarge": target_height = randf_range(200, 250)
		"large": target_height = randf_range(150, 200)
		"medium": target_height = randf_range(120, 150)
		"small": target_height = randf_range(100, 120)
		_: target_height = randf_range(80, 100)

	var scale = target_height / config.height
	var scale_x = scale * randf_range(0.9, 1.05)
	var scale_y = scale * randf_range(0.95, 1.1)
	if config.type == "xlarge": scale_x *= 0.9

	var color_var = randf_range(0.85, 1.0)
	var green_boost = randf_range(0.0, 0.08)

	if has_collision:
		var body = StaticBody2D.new()
		body.name = "BambooBody"
		body.position = pos
		body.collision_layer = 2
		body.collision_mask = 1

		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale_x, scale_y)
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		sprite.modulate = Color(color_var, color_var + green_boost, color_var - 0.05, 1.0)
		_apply_bamboo_sway_shader(sprite, scale_y)
		body.add_child(sprite)

		# 阴影 (在添加Sprite后调用，以支持基于Sprite的投影)
		var shadow_size = Vector2(texture.get_width() * scale_x * 0.5, texture.get_height() * scale_y * 1.5)
		create_shadow_for_entity(body, shadow_size, Vector2(0, 0), 2.5)

		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(texture.get_width() * scale_x * 0.25, 20)
		collision.shape = shape
		collision.position = Vector2(0, -10)
		body.add_child(collision)

		game_objects_parent.call_deferred("add_child", body)
		border_bamboos.append(body)
		wall_bodies.append(body)
	else:
		var container = Node2D.new()
		container.position = pos
		
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale_x, scale_y)
		sprite.centered = false
		sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
		sprite.position = Vector2(0, 0) # 修正位置
		
		sprite.modulate = Color(color_var, color_var + green_boost, color_var - 0.05, 1.0)
		_apply_bamboo_sway_shader(sprite, scale_y)
		container.add_child(sprite)

		# 阴影 (在添加Sprite后调用)
		var shadow_size = Vector2(texture.get_width() * scale_x * 0.5, texture.get_height() * scale_y * 1.2)
		create_shadow_for_entity(container, shadow_size, Vector2(0, 0), 2.0)

		game_objects_parent.call_deferred("add_child", container)
	return 1

# ==================== 内部装饰竹子 (Perlin Noise) ====================
func create_interior_bamboo():
	"""使用柏林噪声生成自然分布的内部竹林"""
	print("MapSystem: Generating interior bamboo (Walls + Scatter)...")
	var count = 0
	var safe_radius = 250.0 # 出生点保护半径

	# 遍历地图网格点
	var step = 80 # 采样步长
	for x in range(WALL_THICKNESS, MAP_WIDTH - WALL_THICKNESS, step):
		for y in range(WALL_THICKNESS, MAP_HEIGHT - WALL_THICKNESS, step):
			var pos = Vector2(x + randf_range(-20, 20), y + randf_range(-20, 20))
			if pos.distance_to(Vector2(PLAYER_SPAWN_X, PLAYER_SPAWN_Y)) < safe_radius: continue
			# NPC 区域保护
			if pos.distance_to(Vector2(1800, 600)) < 300: continue

			var noise_val = bamboo_noise.get_noise_2d(pos.x, pos.y)
			
			# 逻辑修改：
			# 1. 噪声 > 0.4: 生成密集的竹墙 (Cluster)
			# 2. 噪声 < -0.3: 低概率生成单根竹子 (Scatter)
			
			if noise_val > 0.4:
				var types = ["xlarge", "large", "medium"]
				create_interior_bamboo_varied(pos, types)
				count += 1
				if randf() < 0.3: # 伴生竹笋
					_create_shoot(pos + Vector2(randf_range(-20, 20), randf_range(10, 20)), 0.1)
			
			elif noise_val < -0.3 and randf() < 0.01: # 稀疏散布 (1% 概率)
				create_interior_bamboo_varied(pos, ["single", "small"])
				count += 1
	
	print("MapSystem: Generated ", count, " interior bamboos.")

func create_interior_bamboo_varied(pos: Vector2, allowed_types: Array) -> int:
	# ... (逻辑与之前类似，这里简化重写以确保清晰) ...
	var suitable_indices = []
	for i in range(bamboo_configs.size()):
		if bamboo_configs[i].type in allowed_types:
			suitable_indices.append(i)
	if suitable_indices.is_empty(): return 0

	var config = bamboo_configs[suitable_indices[randi() % suitable_indices.size()]]
	var texture = load(config.path)
	if not texture: return 0

	# 尺寸逻辑保持一致
	var target_height: float
	match config.type:
		"xlarge": target_height = randf_range(200, 250)
		"large": target_height = randf_range(150, 200)
		"medium": target_height = randf_range(120, 150)
		"small": target_height = randf_range(100, 120)
		_: target_height = randf_range(80, 100)

	var scale = target_height / config.height
	var scale_x = scale * randf_range(0.9, 1.05)
	var scale_y = scale * randf_range(0.95, 1.1)
	if config.type == "xlarge": scale_x *= 0.9

	var body = StaticBody2D.new()
	body.name = "BambooBody"
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 1

	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale_x, scale_y)
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	var color_var = randf_range(0.85, 0.95)
	sprite.modulate = Color(color_var, color_var + 0.05, color_var - 0.05, 1.0)
	_apply_bamboo_sway_shader(sprite, scale_y)
	body.add_child(sprite)

	# Shadow (After sprite added)
	var shadow_size = Vector2(texture.get_width() * scale_x * 0.5, texture.get_height() * scale_y * 1.5)
	create_shadow_for_entity(body, shadow_size, Vector2(0, 0), 2.5)

	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(texture.get_width() * scale_x * 0.3, 20)
	collision.shape = shape
	collision.position = Vector2(0, -10)
	body.add_child(collision)
	
	# Impact Area
	var area = Area2D.new()
	area.collision_layer = 0; area.collision_mask = 1
	var area_col = CollisionShape2D.new()
	var area_shape = RectangleShape2D.new()
	area_shape.size = Vector2(texture.get_width() * scale_x * 0.5, 30)
	area_col.shape = area_shape
	area_col.position = Vector2(0, -15)
	area.add_child(area_col)
	area.body_entered.connect(_on_bamboo_impact.bind(sprite))
	body.add_child(area)

	if not game_objects_parent:
		game_objects_parent = get_parent()
		if not game_objects_parent: game_objects_parent = self

	game_objects_parent.call_deferred("add_child", body)
	interior_bamboos.append(body)
	return 1

# ==================== 装饰物生成 ====================
func create_decorations_designed():
	"""使用噪声在空地生成装饰物"""
	var step = 100
	for x in range(WALL_THICKNESS, MAP_WIDTH - WALL_THICKNESS, step):
		for y in range(WALL_THICKNESS, MAP_HEIGHT - WALL_THICKNESS, step):
			var pos = Vector2(x, y)
			var noise_val = bamboo_noise.get_noise_2d(pos.x, pos.y)
			
			# 在空地 (noise < 0) 生成装饰物
			if noise_val < 0.0:
				if randf() < 0.2: # 20% 概率生成花簇
					_create_flower_cluster(pos + Vector2(randf_range(-30,30), randf_range(-30,30)), randi_range(3, 5), 0.1)
				elif randf() < 0.1: # 10% 概率生成石头
					_create_rock_group(pos + Vector2(randf_range(-20,20), randf_range(-20,20)), randi_range(1, 2), 0.2)

func _create_flower_cluster(center: Vector2, count: int, base_scale: float) -> int:
	var flower_types = decoration_textures["flowers"]
	var created = 0
	for i in range(count):
		var angle = (TAU / count) * i
		var radius = randf_range(20, 50)
		var pos = center + Vector2(cos(angle), sin(angle)) * radius
		var tex = flower_types[randi() % flower_types.size()]
		if create_decoration_sprite(tex, pos, base_scale + randf_range(-0.02, 0.02), -1, Vector2(0, 0)):
			created += 1
	return created

func _create_rock_group(center: Vector2, count: int, base_scale: float) -> int:
	var rock_types = decoration_textures["rocks"]
	var created = 0
	for i in range(count):
		var pos = center + Vector2(randf_range(-30, 30), randf_range(-20, 20))
		var tex = rock_types[randi() % rock_types.size()]
		create_solid_rock(tex, pos, base_scale + randf_range(-0.05, 0.05))
		created += 1
	return created

# 公开此方法供 RoomLayoutManager 使用，确保石头生成逻辑一致
func create_solid_rock(texture_path: String, pos: Vector2, scale: float) -> Node2D:
	var texture = load(texture_path)
	if not texture: return null
	
	var body = StaticBody2D.new()
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 1
	body.z_index = 0
	
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale, scale)
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	body.add_child(sprite)
	
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	# 增大碰撞体积覆盖底部
	shape.radius = texture.get_width() * scale * 0.45
	col.shape = shape
	col.position = Vector2(0, -10 * scale)
	body.add_child(col)
	
	var shadow_size = Vector2(texture.get_width() * scale * 0.8, texture.get_height() * scale * 0.4)
	# 统一使用吃进 -20 的阴影
	create_shadow_for_entity(body, shadow_size, Vector2(0, -20), 0.3)
	
	if not game_objects_parent:
		game_objects_parent = get_parent()
		if not game_objects_parent: game_objects_parent = self
		
	game_objects_parent.call_deferred("add_child", body)
	return body

func _create_shoot(pos: Vector2, scale: float) -> int:
	var shoot_types = decoration_textures["shoots"]
	var tex = shoot_types[randi() % shoot_types.size()]
	if create_decoration_sprite(tex, pos, scale, -1, Vector2(0, 0)): return 1
	return 0

func create_decoration_sprite(texture_path: String, pos: Vector2, scale: float, z_index: int = 0, shadow_offset: Vector2 = Vector2(0, -10)) -> Node2D:
	var texture = load(texture_path)
	if not texture: return null
	var container = Node2D.new()
	container.position = pos
	container.z_index = z_index
	
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale, scale)
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	container.add_child(sprite)
	
	# Shadow (After sprite added)
	var shadow_size = Vector2(texture.get_width() * scale * 0.8, texture.get_height() * scale * 0.4)
	create_shadow_for_entity(container, shadow_size, shadow_offset, 0.3)
	
	if not game_objects_parent:
		game_objects_parent = get_parent()
		if not game_objects_parent: game_objects_parent = self
		
	game_objects_parent.call_deferred("add_child", container)
	interior_decorations.append(container)
	return container

# ==================== 光照系统 (核心修改 - 修复灰色蒙版) ====================
func create_lighting(style: String = "outskirts"):
	if not is_inside_tree(): return
	if not lighting_layer: setup_layers()
	
	_clear_lighting()
	
	if style == "outskirts":
		_create_lighting_outskirts()
	elif style == "deep_forest_mist":
		_create_lighting_deep_forest_mist()
	elif style == "deep_forest_beam":
		_create_lighting_deep_forest_beam()
	else:
		_create_lighting_outskirts()

func _clear_lighting():
	# Clear CanvasLayer based lighting
	for child in get_tree().root.get_children():
		if child.name == "AtmosphereLayer" and is_instance_valid(child):
			child.queue_free()
	# Clear CanvasModulate
	for child in get_children():
		if child is CanvasModulate:
			child.queue_free()
	# Clear WorldEnvironment
	for child in get_parent().get_children():
		if child is WorldEnvironment and is_instance_valid(child):
			child.queue_free()
	# Clear Node2D based lighting (God Rays in World Space)
	if lighting_layer:
		for child in lighting_layer.get_children():
			child.queue_free()

func _create_lighting_outskirts():
	"""竹林外围 - 明亮通透，高对比度"""
	print("MapSystem: Creating OUTSKIRTS lighting (CanvasModulate)...")
	
	# 1. CanvasModulate (替代原来的 AtmosphereLayer Multiply)
	# 这是 Godot 标准的场景染色方式，不会产生蒙版问题
	var modulate = CanvasModulate.new()
	modulate.color = Color(0.95, 0.94, 0.92) # 极浅的暖色，保持明亮
	add_child(modulate)
	
	# 2. WorldEnvironment - 核心调整
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	
	env.glow_enabled = true
	env.glow_intensity = 0.2
	env.glow_strength = 0.6
	env.glow_bloom = 0.05
	
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.35 # 强对比度
	env.adjustment_saturation = 1.1  # 色彩鲜艳
	env.adjustment_brightness = 1.1  # 整体提亮
	
	world_env.environment = env
	get_parent().call_deferred("add_child", world_env)

func _create_lighting_deep_forest_beam():
	"""竹林深处 - 幽暗，世界空间固定光柱"""
	print("MapSystem: Creating DEEP FOREST BEAM lighting...")
	
	# 1. CanvasModulate (压暗)
	var modulate = CanvasModulate.new()
	modulate.color = Color(0.4, 0.45, 0.55) # 蓝调黑暗
	add_child(modulate)
	
	# 2. 世界空间光柱 (Node2D)
	# 在 LightingLayer 上生成
	var beam_count = 12
	var mat_add = CanvasItemMaterial.new()
	mat_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	
	for i in range(beam_count):
		# 随机位置
		var pos = Vector2(
			randf_range(100, MAP_WIDTH - 100),
			randf_range(100, MAP_HEIGHT - 100)
		)
		
		# 光柱 Sprite
		var beam = Sprite2D.new()
		beam.texture = _create_light_beam_texture(512)
		beam.position = pos
		# 极度拉长：Y轴拉长，X轴压扁
		beam.scale = Vector2(randf_range(0.8, 1.2), randf_range(6.0, 9.0)) 
		beam.modulate = Color(1.0, 0.95, 0.8, 0.25) # 淡金光，低透明度
		beam.material = mat_add
		# 角度与影子匹配：从左上射向右下
		beam.rotation = -0.5 # 与影子一致
		beam.offset = Vector2(0, 256) # 锚点在顶部
		
		lighting_layer.add_child(beam)
		
		# 地面光斑 (光柱落地处)
		var spot = Sprite2D.new()
		spot.texture = _create_light_texture(256, 2.0)
		spot.position = pos + Vector2(150, 400) # 根据角度偏移落点
		spot.scale = Vector2(2.0, 1.0) # 压扁的椭圆
		spot.modulate = Color(1.0, 0.9, 0.7, 0.3)
		spot.material = mat_add
		lighting_layer.add_child(spot)

	# 3. WorldEnvironment
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 0.9
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.3
	env.adjustment_saturation = 1.0
	world_env.environment = env
	get_parent().call_deferred("add_child", world_env)

func _create_lighting_deep_forest_mist():
	"""竹林深处 - 雾气"""
	print("MapSystem: Creating DEEP FOREST MIST lighting...")
	
	# 1. CanvasModulate (压暗)
	var modulate = CanvasModulate.new()
	modulate.color = Color(0.6, 0.65, 0.7)
	add_child(modulate)
	
	# 2. 雾气 (使用 CanvasLayer Add 模式，覆盖在场景之上)
	var atmosphere_layer = CanvasLayer.new()
	atmosphere_layer.name = "AtmosphereLayer"
	atmosphere_layer.layer = 1
	get_tree().root.add_child(atmosphere_layer)
	
	var mist = TextureRect.new()
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.003
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.seamless = true
	mist.texture = noise_tex
	mist.modulate = Color(0.8, 0.9, 1.0, 0.15)
	mist.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mist.set_anchors_preset(Control.PRESET_FULL_RECT)
	mist.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var mat_add = CanvasItemMaterial.new()
	mat_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mist.material = mat_add
	atmosphere_layer.add_child(mist)
	
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	world_env.environment = env
	get_parent().call_deferred("add_child", world_env)

# ... (纹理生成辅助函数保持不变) ...
func _create_light_beam_texture(size: int) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center_x = size / 2.0
	for x in range(size):
		for y in range(size):
			var dist_x = abs(x - center_x) / (size / 2.0)
			var dist_y = abs(y - size/2.0) / (size/2.0)
			
			# 恢复亮度：只在边缘淡出
			var alpha_x = 1.0
			if dist_x > 0.7: # 只在最后30%处淡出
				alpha_x = smoothstep(1.0, 0.7, dist_x)
				
			var alpha_y = 1.0
			if dist_y > 0.8: # 纵向边缘淡出
				alpha_y = smoothstep(1.0, 0.8, dist_y)
			
			# 核心亮度曲线
			var beam_profile = pow(1.0 - dist_x * 0.5, 2.0) # 中心亮，慢慢衰减
			
			var brightness = beam_profile * alpha_x * alpha_y
			
			image.set_pixel(x, y, Color(brightness, brightness, brightness, 1.0))
	return ImageTexture.create_from_image(image)

func _create_light_texture(size: int, falloff: float) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center) / (size / 2.0)
			var b = pow(max(0, 1.0 - dist), falloff)
			image.set_pixel(x, y, Color(b, b, b, 1.0))
	return ImageTexture.create_from_image(image)

func _create_shadow_texture(width: int, height: int) -> ImageTexture:
	width = max(width, 2); height = max(height, 2)
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var cx = width / 2.0; var cy = height / 2.0
	for x in range(width):
		for y in range(height):
			var dx = (x - cx) / (width / 2.0)
			var dy = (y - cy) / (height / 2.0)
			var d = dx*dx + dy*dy
			if d <= 1.0:
				var alpha = pow(1.0 - sqrt(d), 0.8) * 0.6 # 更黑一点
				image.set_pixel(x, y, Color(0, 0, 0, alpha))
			else:
				image.set_pixel(x, y, Color(0,0,0,0))
	return ImageTexture.create_from_image(image)

# ==================== 阴影系统 (公共接口) ====================
const SHADOW_DIRECTION = Vector2(5, 0) # 阴影根部微调
const SHADOW_ANGLE = -0.5 # 配合FlipY，指向右下

func create_shadow_for_entity(parent: Node2D, size: Vector2 = Vector2(40, 20), offset: Vector2 = Vector2(0, 0), height_factor: float = 1.0) -> Sprite2D:
	var source_sprite: Sprite2D = null
	if parent is Sprite2D: source_sprite = parent
	else:
		for child in parent.get_children():
			if child is Sprite2D: source_sprite = child; break
	
	var shadow: Node2D = null
	if source_sprite and source_sprite.texture:
		shadow = Sprite2D.new()
		shadow.texture = source_sprite.texture
		shadow.hframes = source_sprite.hframes
		shadow.vframes = source_sprite.vframes
		shadow.frame = source_sprite.frame
		shadow.flip_h = source_sprite.flip_h 
		
		# --- Robust Shadow Connection Algorithm ---
		# Goal: Align the shadow's "visual bottom" exactly with the sprite's "visual bottom".
		
		var img = source_sprite.texture.get_image()
		var visible_bottom_y = float(source_sprite.texture.get_height()) # Default to full height
		var visible_center_x = float(source_sprite.texture.get_width()) / 2.0
		
		if img:
			var used = img.get_used_rect()
			visible_bottom_y = float(used.end.y)
			visible_center_x = float(used.get_center().x)
			
		# 1. Calculate Source Sprite's visual bottom in Local Space
		var source_local_bottom_y = visible_bottom_y
		
		# 额外向内"吃"一点距离 (40px)，解决底部凹陷/不规则图形的贴合问题
		# 增加到40.0以确保石头根部完全覆盖影子起点
		var contact_eat_in = 40.0 
		source_local_bottom_y -= contact_eat_in
		
		# Adjust for Source Centering/Offset
		if source_sprite.centered:
			source_local_bottom_y -= source_sprite.texture.get_height() / 2.0
		source_local_bottom_y += source_sprite.offset.y
		
		# Apply Source Scale
		var source_feet_offset = Vector2(0, source_local_bottom_y * source_sprite.scale.y)
		
		# 2. Configure Shadow to anchor at ITS visible bottom
		# We want pixel 'visible_bottom_y' to be at local (0,0) after offset
		shadow.centered = false
		shadow.offset = Vector2(-visible_center_x, -visible_bottom_y)
		
		# 3. Position Shadow at the calculated feet position
		shadow.position = source_sprite.position + source_feet_offset + offset
		
		# 4. Transform: Flip Y (Reflection) + Skew
		shadow.scale = Vector2(source_sprite.scale.x, source_sprite.scale.y * -0.5) 
		shadow.skew = 0.5 
		
	else:
		# Fallback: Generic Ellipse
		shadow = Sprite2D.new()
		shadow.texture = _create_shadow_texture(int(size.x), int(size.y))
		shadow.position = SHADOW_DIRECTION + offset
		shadow.rotation = 0.0
		shadow.skew = 0.6
		shadow.scale = Vector2(1.0, 1.0) 
		
	shadow.name = "Shadow"
	shadow.z_index = -10 
	shadow.modulate = Color(0, 0, 0, 0.5) 
	
	parent.call_deferred("add_child", shadow)
	return shadow

func ensure_entity_shadow(entity: Node2D, scale_mult: float = 1.0):
	"""供外部调用的安全接口"""
	if not is_instance_valid(entity): return
	if entity.has_node("Shadow"): return # 已有影子
	
	var size = Vector2(50, 20) * scale_mult
	if entity is CharacterBody2D: # Player/Enemy
		size = Vector2(60, 25) * scale_mult
	
	create_shadow_for_entity(entity, size, Vector2(0, -15), 0.5)

# ==================== 其他接口 ====================
func setup_camera_limits():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D")
		cam.limit_left = 0; cam.limit_top = 0
		cam.limit_right = MAP_WIDTH; cam.limit_bottom = MAP_HEIGHT

func update_environment(depth: int):
	# 兼容接口
	if depth < 3: create_lighting("outskirts")
	else: create_lighting("deep_forest_beam")

func spawn_nitori_npc():
	var scene = load("res://NitoriNPC.tscn")
	if scene:
		var npc = scene.instantiate()
		npc.position = Vector2(1800, 600)
		
		if not game_objects_parent:
			game_objects_parent = get_parent()
			if not game_objects_parent: game_objects_parent = self
			
		game_objects_parent.call_deferred("add_child", npc)

# Stub functions for compatibility
func _update_dynamic_lighting(delta): pass
func _apply_bamboo_sway_shader(sprite, scale, random=true): 
	if bamboo_sway_shader:
		var mat = ShaderMaterial.new()
		mat.shader = bamboo_sway_shader
		mat.set_shader_parameter("sway_amount", 5.0 / scale)
		mat.set_shader_parameter("sway_speed", 2.0)
		mat.set_shader_parameter("sway_phase", randf() * 6.28)
		sprite.material = mat
func _on_bamboo_impact(body, sprite): pass
func _create_post_process_layer(): pass # Simplified out for now
func get_player_spawn_position() -> Vector2: return Vector2(PLAYER_SPAWN_X, PLAYER_SPAWN_Y)
func get_enemy_spawn_points() -> Array: return enemy_spawn_points
func get_map_size() -> Vector2: return Vector2(MAP_WIDTH, MAP_HEIGHT)
func get_random_position_in_map() -> Vector2: return Vector2(randf_range(200, MAP_WIDTH-200), randf_range(200, MAP_HEIGHT-200))
func is_position_valid(pos: Vector2) -> bool: return true
