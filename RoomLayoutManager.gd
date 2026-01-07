extends Node
class_name RoomLayoutManager

# RoomLayoutManager - 管理房间布局的动态生成和清理
# 为每个房间应用独特的装饰物和障碍物

var current_layout: Dictionary = {}
var spawned_objects: Array = []
var map_system: Node = null
var game_objects_parent: Node = null

func _ready():
	add_to_group("room_layout_manager")

	# 等待场景加载完成
	await get_tree().process_frame

	# 获取地图系统和游戏对象父节点
	map_system = get_tree().get_first_node_in_group("map_system")
	if map_system:
		var world = map_system.get_parent()
		if world and world.has_method("get_game_objects_parent"):
			game_objects_parent = world.get_game_objects_parent()
		else:
			game_objects_parent = world

	# 监听房间进入信号
	var room_manager = get_tree().get_first_node_in_group("room_manager")
	if room_manager:
		room_manager.room_entered.connect(_on_room_entered)

func _on_room_entered(room_type_name: String, room_index: int):
	"""进入新房间时应用布局"""
	# print("RoomLayoutManager: Applying layout for room ", room_index, " (", room_type_name, ")")
	pass

	# 清理旧布局
	_clear_current_layout()

	# 根据房间名称转换为类型枚举
	var room_type = _get_room_type_from_name(room_type_name)

	# 获取当前房间的连接方向（用于避让竹林）
	var active_directions = []
	var room_manager = get_tree().get_first_node_in_group("room_manager")
	if room_manager and room_manager.has_method("get_active_directions"):
		active_directions = room_manager.get_active_directions()

	# 生成新布局
	current_layout = RoomLayoutGenerator.generate_room_layout(room_type, room_index, map_system, active_directions)

	# 应用布局
	_apply_layout(current_layout)
	
	# [新增] 挖通门口的竹林
	_clear_bamboo_at_doors(active_directions)

func _clear_current_layout():
	"""清理当前房间的所有动态对象"""
	for obj in spawned_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	spawned_objects.clear()

func _apply_layout(layout: Dictionary):
	"""应用布局到场景中"""
	if not map_system or not game_objects_parent:
		return

	# 应用竹林布局
	if layout.has("bamboos"):
		for bamboo_data in layout.bamboos:
			_spawn_bamboo_cluster(bamboo_data.pos, bamboo_data.size)

	# 应用装饰物
	if layout.has("decorations"):
		for deco_data in layout.decorations:
			_spawn_decoration(deco_data.pos, deco_data.type)

func _clear_bamboo_at_doors(active_directions: Array):
	"""在有门的方向清除静态环境竹林"""
	var w = 2400
	var h = 1800
	if map_system:
		w = map_system.MAP_WIDTH
		h = map_system.MAP_HEIGHT
		
	var clear_zones = []
	var clear_size = Vector2(400, 300) # 足够大的清理范围
	
	if 0 in active_directions: # North
		clear_zones.append(Rect2(w/2 - clear_size.x/2, 0, clear_size.x, clear_size.y))
	if 1 in active_directions: # South
		clear_zones.append(Rect2(w/2 - clear_size.x/2, h - clear_size.y, clear_size.x, clear_size.y))
	if 2 in active_directions: # East
		clear_zones.append(Rect2(w - clear_size.y, h/2 - clear_size.x/2, clear_size.y, clear_size.x))
	if 3 in active_directions: # West
		clear_zones.append(Rect2(0, h/2 - clear_size.x/2, clear_size.y, clear_size.x))
		
	var env_bamboos = get_tree().get_nodes_in_group("environment_bamboo")
	var cleared_count = 0
	
	for body in env_bamboos:
		if not is_instance_valid(body): continue
		for zone in clear_zones:
			if zone.has_point(body.position):
				body.queue_free()
				cleared_count += 1
				break
				
	# print("RoomLayoutManager: Cleared ", cleared_count, " bamboos at doors.")
	pass

func _spawn_bamboo_cluster(pos: Vector2, size: int):
	"""在指定位置生成竹林簇"""
	if not map_system or not map_system.has_method("_create_interior_bamboo_varied"):
		return

	# 生成多棵竹子形成一簇
	for i in range(size):
		var offset = Vector2(randf_range(-40, 40), randf_range(-40, 40))
		var bamboo_pos = pos + offset

		# 使用地图系统的竹子生成方法
		# 注意：需要访问私有方法，这里我们创建自己的简化版本
		_create_simple_bamboo(bamboo_pos)

func _create_simple_bamboo(pos: Vector2):
	"""创建简单的竹子障碍物"""
	var bamboo_textures = [
		"res://bamboo/bamboo_single_straight_1.png",
		"res://bamboo/bamboo_single_straight_2.png",
		"res://bamboo/bamboo_cluster_medium_1.png",
	]

	var texture_path = bamboo_textures[randi() % bamboo_textures.size()]
	var texture = load(texture_path)
	if not texture:
		return

	# 创建StaticBody2D
	var body = StaticBody2D.new()
	body.name = "DynamicBamboo"
	body.position = pos
	body.collision_layer = 2
	body.collision_mask = 1
	
	# 附加透视脚本
	body.set_script(load("res://BambooObstacle.gd"))

	# 添加精灵
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(0.12, 0.12)
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.modulate = Color(randf_range(0.85, 1.0), randf_range(0.9, 1.0), randf_range(0.85, 0.95), 1.0)
	body.add_child(sprite)

	# 添加碰撞
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	collision.shape = shape
	collision.position = Vector2(0, -10)
	body.add_child(collision)

	# 添加到场景
	game_objects_parent.call_deferred("add_child", body)
	spawned_objects.append(body)

func _spawn_decoration(pos: Vector2, type: String):
	"""生成装饰物"""
	if not map_system: return

	var obj = null
	match type:
		"flower":
			# 加载可采集花场景
			var flower_scene = load("res://scenes/harvestables/Flower.tscn")
			if flower_scene:
				obj = flower_scene.instantiate()
				obj.global_position = pos

				# 随机选择花的贴图
				var flower_types = map_system.decoration_textures.get("flowers", [])
				if not flower_types.is_empty():
					var tex_path = flower_types[randi() % flower_types.size()]
					var tex = load(tex_path)
					if tex:
						var sprite = obj.get_node("Sprite2D")
						if sprite:
							sprite.texture = tex
							# 根据目标高度 30 像素计算缩放
							var target_h = 30.0 * randf_range(0.9, 1.1)
							var s = target_h / float(tex.get_height())
							sprite.scale = Vector2(s, s)
							sprite.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height())

				game_objects_parent.add_child(obj)
		"rock":
			var textures = map_system.decoration_textures.get("rocks", [])
			if not textures.is_empty():
				var tex = textures[randi() % textures.size()]
				if map_system.has_method("create_solid_rock"):
					obj = map_system.create_solid_rock(tex, pos, 60.0 * randf_range(0.85, 1.15))
		"shoot":
			var textures = map_system.decoration_textures.get("shoots", [])
			if not textures.is_empty():
				var tex = textures[randi() % textures.size()]
				obj = map_system.create_decoration_sprite(tex, pos, 0.08, -1, Vector2(0, 0))

	if obj:
		spawned_objects.append(obj)

func _get_room_type_from_name(room_type_name: String) -> int:
	"""将房间类型名称转换为枚举"""
	match room_type_name:
		"普通":
			return 0  # NORMAL
		"商店":
			return 1  # SHOP
		"BOSS":
			return 2  # BOSS
		"附魔":
			return 3  # ENCHANT
		"休息":
			return 4  # REST
		"宝箱":
			return 5  # TREASURE
		_:
			return 0  # Default to NORMAL
