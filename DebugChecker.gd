extends Node

# DebugChecker - 用于验证房间系统是否正确加载

func _ready():
	await get_tree().create_timer(2.0).timeout  # 等待所有系统初始化

	if not is_instance_valid(self):
		return

	print("\n========== 房间系统调试信息 ==========")

	# 检查RoomManager
	var room_manager = get_tree().get_first_node_in_group("room_manager")
	if room_manager:
		print("✓ RoomManager已找到")
		if room_manager.has_method("get_room_map_data"):
			var room_map = room_manager.get_room_map_data()
			print("  - 房间数量: ", room_map.size())
			print("  - 当前房间: ", room_manager.current_room_index)
			print("  - 房间类型: ", room_manager._get_room_type_name(room_manager.current_room_type))
		else:
			print("✗ RoomManager没有get_room_map_data方法")
	else:
		print("✗ 找不到RoomManager")

	# 检查ExperienceManager
	var exp_manager = get_tree().get_first_node_in_group("experience_manager")
	if exp_manager:
		print("✓ ExperienceManager已找到")
		print("  - 当前転流: ", exp_manager.tenryu)
	else:
		print("✗ 找不到ExperienceManager")

	# 检查EnemySpawner
	var spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if spawner:
		print("✓ EnemySpawner已找到")
		print("  - 使用房间系统: ", spawner.use_room_system)
	else:
		print("✗ 找不到EnemySpawner")

	# 检查GameUI
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		print("✓ GameUI已找到")
		var room_map_canvas = ui.get_node_or_null("RoomMapPanel/RoomMapCanvas")
		if room_map_canvas:
			print("  - 房间地图Canvas已创建")
		else:
			print("  - 房间地图Canvas未找到")

		var tenryu_label = ui.get_node_or_null("TenryuLabel")
		if tenryu_label:
			print("  - 転流标签已创建: ", tenryu_label.text)
		else:
			print("  - 転流标签未找到")
	else:
		print("✗ 找不到GameUI")

	print("======================================\n")
