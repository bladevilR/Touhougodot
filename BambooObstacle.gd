extends StaticBody2D

var player: Node2D = null
var sprite: Sprite2D = null
var transparent_alpha = 0.4
var normal_alpha = 1.0
var fade_speed = 5.0

# 触发透视的范围
var detect_radius_x = 60.0 # 水平范围
var detect_radius_y = 100.0 # 垂直范围（主要是向上）

func _ready():
	# 尝试找到子节点的 Sprite2D
	for child in get_children():
		if child is Sprite2D:
			sprite = child
			break
			
	# 获取玩家引用
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _process(delta):
	if not player or not sprite:
		return
		
	var p_pos = player.global_position
	var my_pos = global_position
	
	var target_alpha = normal_alpha
	
	# 逻辑：如果玩家在竹子的"后面"（Y值更小）或者位置非常重叠
	# 且在水平范围内
	if p_pos.y < my_pos.y + 20 and p_pos.y > my_pos.y - detect_radius_y:
		if abs(p_pos.x - my_pos.x) < detect_radius_x:
			target_alpha = transparent_alpha
			
	sprite.modulate.a = move_toward(sprite.modulate.a, target_alpha, delta * fade_speed)
