extends Node2D

# TownTestScene - 小镇测试场景
# 快速测试 town1.png 地图效果

var player = null
var background_sprite = null

func _ready():
	print("========== TownTestScene: Starting ==========")

	# 设置默认角色为妹红 (ID=1)
	SignalBus.selected_character_id = 1
	print("Set character ID to: ", SignalBus.selected_character_id)

	# 初始化 CharacterData
	CharacterData.initialize()
	print("CharacterData initialized, MOKOU data: ", CharacterData.CHARACTERS.get(1))

	# 获取背景精灵
	background_sprite = $Background
	print("Background sprite: ", background_sprite)
	if background_sprite:
		# 加载 town1.png
		var town_texture = load("res://assets/map/town1.png")
		print("Town texture loaded: ", town_texture)
		if town_texture:
			background_sprite.texture = town_texture
			background_sprite.centered = false
			background_sprite.position = Vector2.ZERO
			background_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			background_sprite.visible = true
			print("TownTestScene: Town map loaded, size: ", town_texture.get_size())
			print("Background sprite visible: ", background_sprite.visible)
		else:
			print("ERROR: Failed to load town1.png")

	# 获取玩家
	player = $Player
	print("Player node: ", player)
	if player:
		var player_sprite = player.get_node_or_null("Sprite2D")
		print("Player Sprite2D: ", player_sprite)
		if player_sprite:
			print("  - visible: ", player_sprite.visible)
			print("  - texture: ", player_sprite.texture)
			print("  - scale: ", player_sprite.scale)
		print("Player position: ", player.position)

	print("========== TownTestScene: Ready! ==========")
	print("Use WASD to move, Space to dash")

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if player:
			print("Player position: ", player.position)
