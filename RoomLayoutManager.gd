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
	print("RoomLayoutManager: Applying layout for room ", room_index, " (", room_type_name, ")")

	# 清理旧布局
	_clear_current_layout()

	# 根据房间名称转换为类型枚举
	var room_type = _get_room_type_from_name(room_type_name)

	# 生成新布局
	current_layout = RoomLayoutGenerator.generate_room_layout(room_type, room_index, map_system)

	# 应用布局
	_apply_layout(current_layout)

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
		"res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_1.png",
		"res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_2.png",
		"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_1.png",
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
	var texture_path = ""
	var scale = 0.1

	match type:
		"flower":
			var flower_textures = [
				"res://assets/SUCAI/images_resized/flower_white_daisy_single.png",
				"res://assets/SUCAI/images_resized/flower_blue_single_1.png",
				"res://assets/SUCAI/images_resized/flower_red_cluster_1.png",
			]
			if flower_textures.size() > 0:
				texture_path = flower_textures[randi() % flower_textures.size()]
			scale = 0.08
		"rock":
			var rock_textures = [
				"res://assets/SUCAI/images_resized/rock_medium_grey.png",
				"res://assets/SUCAI/images_resized/rock_large_moss_1.png",
			]
			if rock_textures.size() > 0:
				texture_path = rock_textures[randi() % rock_textures.size()]
			scale = 0.15
		"shoot":
			var shoot_textures = [
				"res://assets/SUCAI/images_resized/shoot_small_1.png",
				"res://assets/SUCAI/images_resized/shoot_medium_1.png",
			]
			if shoot_textures.size() > 0:
				texture_path = shoot_textures[randi() % shoot_textures.size()]
			scale = 0.08

	if texture_path == "" or not ResourceLoader.exists(texture_path):
		return

	var texture = load(texture_path)
	if not texture:
		return

	# 创建简单的精灵容器
	var container = Node2D.new()
	container.name = "DynamicDecoration"
	container.position = pos

	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale, scale)
	sprite.centered = false
	sprite.offset = Vector2(-texture.get_width() * 0.5, -texture.get_height())
	sprite.modulate.a = randf_range(0.7, 0.9)
	container.add_child(sprite)

	# 添加到场景
	game_objects_parent.call_deferred("add_child", container)
	spawned_objects.append(container)

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
