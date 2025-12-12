extends Node
class_name AimSystem

# AimSystem - 半自动瞄准系统
# 根据策划稿实现：默认自动瞄准最近敌人，鼠标点击可手动指定方向

enum AimMode { AUTO, MANUAL }

var aim_mode: AimMode = AimMode.AUTO
var aim_direction: Vector2 = Vector2.RIGHT
var manual_aim_timer: float = 0.0
var lock_direction: Vector2 = Vector2.ZERO
var is_direction_locked: bool = false

# 双击检测
var last_click_time: float = 0.0
const DOUBLE_CLICK_THRESHOLD: float = 0.3  # 300ms

# 锁定持续时间
const LOCK_DURATION: float = 3.0

# 引用
var player: Node2D = null

func _ready():
	player = get_parent()

func _process(delta):
	_update_aim(delta)

func _input(event):
	if not player:
		return

	# 鼠标按下 - 进入手动瞄准模式
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_mouse_pressed(event.position)
			else:
				_on_mouse_released()

	# 鼠标移动 - 手动模式下更新方向
	if event is InputEventMouseMotion:
		if aim_mode == AimMode.MANUAL and not is_direction_locked:
			_update_manual_direction(event.position)

func _on_mouse_pressed(screen_pos: Vector2):
	var world_pos = _screen_to_world(screen_pos)
	var direction = (world_pos - player.global_position).normalized()

	# 检测双击
	var current_time = Time.get_ticks_msec() / 1000.0
	var is_double_click = (current_time - last_click_time) < DOUBLE_CLICK_THRESHOLD
	last_click_time = current_time

	if is_double_click:
		# 双击：锁定方向3秒
		lock_direction = direction
		is_direction_locked = true
		aim_mode = AimMode.MANUAL
		manual_aim_timer = LOCK_DURATION
	else:
		# 单击：进入手动模式
		aim_direction = direction
		aim_mode = AimMode.MANUAL
		manual_aim_timer = 0.0
		is_direction_locked = false

func _on_mouse_released():
	if not is_direction_locked:
		aim_mode = AimMode.AUTO

func _update_manual_direction(screen_pos: Vector2):
	if not player:
		return
	var world_pos = _screen_to_world(screen_pos)
	aim_direction = (world_pos - player.global_position).normalized()

func _update_aim(delta):
	# 更新锁定计时器
	if is_direction_locked:
		manual_aim_timer -= delta
		if manual_aim_timer <= 0:
			is_direction_locked = false
			aim_mode = AimMode.AUTO

	# 自动瞄准模式：瞄准最近敌人
	if aim_mode == AimMode.AUTO:
		var nearest = _find_nearest_enemy()
		if nearest and player:
			aim_direction = (nearest.global_position - player.global_position).normalized()

func _find_nearest_enemy() -> Node2D:
	if not player:
		return null

	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return null

	var nearest = null
	var min_dist = INF

	for enemy in enemies:
		var dist = player.global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy

	return nearest

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	# 将屏幕坐标转换为世界坐标
	var camera = get_viewport().get_camera_2d()
	if camera:
		var viewport_size = Vector2(get_viewport().size)  # 转换 Vector2i 到 Vector2
		return camera.get_global_transform().affine_inverse() * (screen_pos - viewport_size / 2) + camera.global_position
	return screen_pos

# 公开接口
func get_aim_direction() -> Vector2:
	if is_direction_locked:
		return lock_direction
	return aim_direction

func is_manual_mode() -> bool:
	return aim_mode == AimMode.MANUAL

func get_target_enemy() -> Node2D:
	if aim_mode == AimMode.AUTO:
		return _find_nearest_enemy()
	return null
