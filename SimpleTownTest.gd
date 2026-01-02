extends Node2D

# 超简单测试场景 - 只显示地图和一个可移动的方块

var player_body: CharacterBody2D
var speed = 300.0

func _ready():
	# 创建背景
	var bg = Sprite2D.new()
	bg.name = "Background"
	var town_texture = load("res://assets/map/town1.png")
	if town_texture:
		bg.texture = town_texture
		bg.centered = false
		bg.position = Vector2.ZERO
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -100
		add_child(bg)
		print("Town map loaded: ", town_texture.get_size())
	else:
		print("ERROR: Failed to load town1.png")

	# 创建简单的玩家（红色方块）
	player_body = CharacterBody2D.new()
	player_body.name = "SimplePlayer"
	player_body.position = Vector2(1024, 512)  # 地图中心
	add_child(player_body)

	# 添加可见的矩形
	var rect = ColorRect.new()
	rect.size = Vector2(40, 60)
	rect.position = Vector2(-20, -60)
	rect.color = Color(1.0, 0.3, 0.3)  # 红色
	player_body.add_child(rect)

	# 添加碰撞箱
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 20)
	collision.shape = shape
	player_body.add_child(collision)

	# 添加相机
	var camera = Camera2D.new()
	camera.enabled = true
	player_body.add_child(camera)

	print("Simple player created at: ", player_body.position)

func _physics_process(_delta):
	if not player_body:
		return

	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1

	if input_dir.length() > 0:
		input_dir = input_dir.normalized()

	player_body.velocity = input_dir * speed
	player_body.move_and_slide()
