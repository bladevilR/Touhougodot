extends Node2D
class_name MapSystem

# Map constants from Room 1 (竹林入口)
const MAP_WIDTH = 2400
const MAP_HEIGHT = 1800
const PLAYER_SPAWN_X = 1200
const PLAYER_SPAWN_Y = 1500

# Bamboo texture paths (18 textures, indices 0-17)
var bamboo_textures = [
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_1.png",      # 0
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_2.png",      # 1
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_3.png",      # 2
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_4.png",      # 3
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_large_5.png",      # 4
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_1.png",     # 5
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_2.png",     # 6
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_medium_3.png",     # 7
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_small_1.png",      # 8
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_small_2.png",      # 9
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_xlarge_1.png",     # 10
	"res://assets/SUCAI/images_resized/bamboo/bamboo_cluster_xlarge_2.png",     # 11
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_1.png",      # 12
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_2.png",      # 13
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_3.png",      # 14
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_broken_4.png",      # 15
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_1.png",    # 16
	"res://assets/SUCAI/images_resized/bamboo/bamboo_single_straight_2.png"     # 17
]

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
var walls_layer: Node2D
var wall_bodies: Array = []

func _ready():
	print("MapSystem: Initializing bamboo forest map...")
	setup_layers()
	create_background()
	create_walls()
	setup_camera_limits()
	print("MapSystem: Map initialization complete!")

func setup_layers():
	# Create layered rendering system
	background_layer = Node2D.new()
	background_layer.name = "BackgroundLayer"
	background_layer.z_index = -10
	add_child(background_layer)

	walls_layer = Node2D.new()
	walls_layer.name = "WallsLayer"
	walls_layer.z_index = 0
	add_child(walls_layer)

func create_background():
	print("MapSystem: Creating grass background...")
	# Create tiled grass background
	var grass_texture = load("res://assets/grassnew.png")

	if grass_texture:
		# Calculate how many tiles we need
		var texture_width = grass_texture.get_width()
		var texture_height = grass_texture.get_height()
		var tiles_x = ceil(MAP_WIDTH / float(texture_width)) + 1
		var tiles_y = ceil(MAP_HEIGHT / float(texture_height)) + 1

		# Create tiles
		for x in range(tiles_x):
			for y in range(tiles_y):
				var sprite = Sprite2D.new()
				sprite.texture = grass_texture
				sprite.position = Vector2(x * texture_width, y * texture_height)
				sprite.centered = false
				background_layer.add_child(sprite)

		print("MapSystem: Background created with %d tiles" % (tiles_x * tiles_y))
	else:
		print("MapSystem: ERROR - Could not load grass texture!")
		# Create a solid color rectangle as fallback
		var color_rect = ColorRect.new()
		color_rect.color = Color(0.2, 0.6, 0.2)  # Green grass color
		color_rect.size = Vector2(MAP_WIDTH, MAP_HEIGHT)
		background_layer.add_child(color_rect)

func create_walls():
	print("MapSystem: Creating %d bamboo walls..." % wall_data.size())
	var walls_created = 0

	for wall in wall_data:
		var texture_index = wall[0]
		var x = wall[1]
		var y = wall[2]
		var scale_factor = wall[3]

		# Ensure texture index is valid
		if texture_index >= bamboo_textures.size():
			texture_index = texture_index % bamboo_textures.size()

		var wall_node = create_wall(texture_index, x, y, scale_factor)
		if wall_node:
			walls_layer.add_child(wall_node)
			wall_bodies.append(wall_node)
			walls_created += 1

	print("MapSystem: Created %d bamboo walls with collision" % walls_created)

func create_wall(texture_index: int, x: float, y: float, scale_factor: float) -> StaticBody2D:
	# Create StaticBody2D for collision
	var wall_body = StaticBody2D.new()
	wall_body.position = Vector2(x, y)
	wall_body.collision_layer = 2  # Wall layer
	wall_body.collision_mask = 0   # Walls don't detect anything

	# Load and create sprite
	var texture_path = bamboo_textures[texture_index]
	var texture = load(texture_path)

	if not texture:
		print("MapSystem: WARNING - Could not load texture: %s" % texture_path)
		return null

	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Vector2(scale_factor, scale_factor)
	sprite.centered = true
	wall_body.add_child(sprite)

	# Create collision shape based on texture size and scale
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()

	# Calculate collision size based on texture dimensions and scale
	var texture_size = texture.get_size()
	var collision_width = texture_size.x * scale_factor * 0.5  # 50% of visual width for tighter fit
	var collision_height = texture_size.y * scale_factor * 0.6  # 60% of visual height

	shape.size = Vector2(collision_width, collision_height)
	collision_shape.shape = shape
	wall_body.add_child(collision_shape)

	return wall_body

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
	# Returns a random position within map boundaries
	var margin = 100  # Keep away from edges
	var x = randf_range(margin, MAP_WIDTH - margin)
	var y = randf_range(margin, MAP_HEIGHT - margin)
	return Vector2(x, y)

func is_position_valid(pos: Vector2) -> bool:
	# Check if position is within map boundaries
	return pos.x >= 0 and pos.x <= MAP_WIDTH and pos.y >= 0 and pos.y <= MAP_HEIGHT
