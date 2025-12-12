extends Area2D
class_name ExperienceGem

# ExperienceGem - 经验球拾取物

@export var xp_value: int = 10
@export var attract_radius: float = 150.0  # 吸引范围
@export var attract_speed: float = 400.0   # 吸引速度

var is_attracted: bool = false
var player: Node2D = null

@onready var visual = $ColorRect
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("pickup")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

	# 设置碰撞层
	collision_layer = 32  # Layer 6: Pickup
	collision_mask = 1     # 只检测玩家 (Layer 1)

	# 找到玩家
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)

	# 进入吸引范围
	if distance < attract_radius:
		is_attracted = true

	# 吸引向玩家
	if is_attracted:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * attract_speed * delta

		# 如果非常接近玩家，自动拾取
		if distance < 20.0:
			_pickup()

func _on_area_entered(area):
	if area.get_parent() and area.get_parent().is_in_group("player"):
		_pickup()

func _on_body_entered(body):
	if body.is_in_group("player"):
		_pickup()

func _pickup():
	# 通知经验管理器
	SignalBus.xp_pickup.emit(xp_value)

	# 播放拾取音效（如果有）
	# SignalBus.play_sound.emit("pickup_xp")

	# 销毁经验球
	queue_free()
