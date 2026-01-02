extends Node2D
class_name TownMapSystem

# 小镇地图系统 - 专门用于 town1.png

var MAP_WIDTH = 5632
var MAP_HEIGHT = 3072

# 角色缩放系数（相对于默认值）
var character_scale_multiplier = 3.5

# 角色纹理过滤模式（LINEAR=柔化，NEAREST=锐利像素风）
var character_texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

var background_layer: Node2D
var game_objects_parent: Node = null

func _ready():
	add_to_group("map_system")

	var world = get_parent()
	if world and world.has_method("get_game_objects_parent"):
		game_objects_parent = world.get_game_objects_parent()
	else:
		game_objects_parent = get_parent()

	if not game_objects_parent:
		game_objects_parent = self

	setup_layers()
	create_town_background()

func setup_layers():
	background_layer = Node2D.new()
	background_layer.name = "BackgroundLayer"
	background_layer.z_index = -100
	add_child(background_layer)

func create_town_background():
	var town_texture = load("res://assets/map/town1.png")
	if town_texture:
		var tex_size = town_texture.get_size()
		MAP_WIDTH = tex_size.x
		MAP_HEIGHT = tex_size.y
		
		var sprite = Sprite2D.new()
		sprite.texture = town_texture
		sprite.centered = false
		sprite.position = Vector2.ZERO
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		background_layer.add_child(sprite)
		print("TownMapSystem: Loaded town1.png, size: ", tex_size)
		
		# 动态更新相机边界
		setup_camera_limits()
	else:
		print("TownMapSystem ERROR: Failed to load town1.png")

func setup_camera_limits():
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D")
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = MAP_WIDTH
		cam.limit_bottom = MAP_HEIGHT

# 影子参数
const SHADOW_ROTATION = 0.0
const SHADOW_SCALE_X = 1.0
const SHADOW_SCALE_Y = 0.25
const SHADOW_SKEW = -1.5

# 兼容接口
func create_shadow_for_entity(parent: Node2D, size: Vector2 = Vector2(40, 20), offset: Vector2 = Vector2(0, 0), height_factor: float = 1.0, force_ellipse: bool = false) -> Sprite2D:
	var source_sprite: Sprite2D = null
	if not force_ellipse:
		if parent is Sprite2D: source_sprite = parent
		else:
			for child in parent.get_children():
				if child is Sprite2D: source_sprite = child; break
	
	var shadow: Sprite2D = null
	if not force_ellipse and source_sprite and source_sprite.texture:
		shadow = Sprite2D.new()
		shadow.texture = source_sprite.texture
		shadow.hframes = source_sprite.hframes
		shadow.vframes = source_sprite.vframes
		shadow.frame = source_sprite.frame
		shadow.flip_h = source_sprite.flip_h 
		
		var frame_height = source_sprite.texture.get_height() / source_sprite.vframes
		var frame_width = source_sprite.texture.get_width() / source_sprite.hframes
		
		shadow.centered = false
		shadow.offset = Vector2(-frame_width / 2.0, -frame_height)
		
		var player_scale_y = abs(source_sprite.scale.y)
		var feet_y = (frame_height * player_scale_y) / 2.0 - 15.0
		shadow.position = Vector2(0, feet_y) + offset
		
		shadow.rotation = SHADOW_ROTATION
		shadow.scale = Vector2(abs(source_sprite.scale.x) * SHADOW_SCALE_X, abs(source_sprite.scale.y) * SHADOW_SCALE_Y)
		shadow.skew = SHADOW_SKEW
	else:
		shadow = Sprite2D.new()
		shadow.texture = _create_shadow_texture(int(size.x), int(size.y))
		shadow.position = offset
		shadow.skew = SHADOW_SKEW
		
	shadow.name = "Shadow"
	shadow.z_index = -10
	shadow.modulate = Color(0, 0, 0, 0.35)
	
	parent.call_deferred("add_child", shadow)
	return shadow

func _create_shadow_texture(width: int, height: int) -> ImageTexture:
	width = max(width, 2)
	height = max(height, 2)
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var cx = width / 2.0
	var cy = height / 2.0
	for x in range(width):
		for y in range(height):
			var dx = (x - cx) / (width / 2.0)
			var dy = (y - cy) / (height / 2.0)
			var d = dx*dx + dy*dy
			if d <= 1.0:
				var alpha = pow(1.0 - sqrt(d), 2.0) * 0.8
				image.set_pixel(x, y, Color(0, 0, 0, alpha))
			else:
				image.set_pixel(x, y, Color(0,0,0,0))
	return ImageTexture.create_from_image(image)

func get_player_spawn_position() -> Vector2:
	return Vector2(MAP_WIDTH / 2, MAP_HEIGHT / 2)

func get_map_size() -> Vector2:
	return Vector2(MAP_WIDTH, MAP_HEIGHT)