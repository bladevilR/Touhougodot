extends Node2D

# TownWorld - 小镇场景的 World 包装器

func _enter_tree():
	# 在子节点初始化前设置角色ID
	SignalBus.selected_character_id = 1
	CharacterData.initialize()

func _ready():
	print("TownWorld: Initialized with Mokou (ID:", SignalBus.selected_character_id, ")")

	# 使用全局管理器显示UI (延迟一帧以确保安全)
	call_deferred("_show_ui_safe")

	# 设置相机缩放和角色速度
	await get_tree().create_timer(0.1).timeout
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_node("Camera2D"):
			var camera = player.get_node("Camera2D")
			camera.zoom = Vector2(0.6, 0.6)

		# 调整移动速度（小镇场景速度更快）
		if "speed" in player:
			player.speed = 400.0  # 原来是 200-300，现在提高到 400
			print("TownWorld: Player speed set to ", player.speed)

func get_game_objects_parent() -> Node:
	return self

func _show_ui_safe():
	# 确保UIManager存在
	if has_node("/root/UIManager"):
		# 强制转换类型或直接动态调用，防止脚本解析问题
		var ui_manager = get_node("/root/UIManager")
		if ui_manager.has_method("show_game_ui"):
			ui_manager.show_game_ui()
		
		# 启用简洁模式：隐藏地图、DPS等，只留头像血条
		if ui_manager.has_method("set_ui_minimal"):
			ui_manager.set_ui_minimal(true)
	else:
		print("TownWorld: UIManager not found (Autoload may need restart)")
