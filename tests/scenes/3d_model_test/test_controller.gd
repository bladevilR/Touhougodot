extends Node3D

# 3D模型测试控制器
# 用于测试新的3D角色模型、动画、材质

@onready var player_visuals = $Player3DVisuals
@onready var camera = $Camera3D
@onready var info_label = $Label

var rotation_speed = 1.0
var zoom_speed = 20.0

func _ready():
	print("=== 3D模型测试场景已启动 ===")
	print("控制说明：")
	print("  WASD - 测试移动动画")
	print("  Q/E - 旋转模型")
	print("  Z/X - 缩放视角")
	print("  ESC - 返回主游戏")

	# 播放默认动画
	if player_visuals:
		player_visuals.play_animation("idle")

func _process(delta):
	# 模型旋转测试
	if Input.is_action_pressed("ui_focus_prev"):  # Q
		player_visuals.rotate_y(rotation_speed * delta)
	if Input.is_action_pressed("ui_focus_next"):  # E
		player_visuals.rotate_y(-rotation_speed * delta)

	# 摄像机缩放测试
	if Input.is_action_pressed("ui_page_up"):  # Page Up or custom
		camera.size = max(60.0, camera.size - zoom_speed * delta)
	if Input.is_action_pressed("ui_page_down"):  # Page Down or custom
		camera.size = min(200.0, camera.size + zoom_speed * delta)

	# 动画测试
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or \
	   Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		if player_visuals:
			player_visuals.play_animation("run")
	else:
		if player_visuals:
			player_visuals.play_animation("idle")

	# 返回主游戏
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://world.tscn")

func _update_info():
	info_label.text = "3D模型测试场景\n"
	info_label.text += "摄像机缩放: %.1f\n" % camera.size
	info_label.text += "模型旋转: %.1f°\n" % rad_to_deg(player_visuals.rotation.y)
