extends Node

# 种田系统集成示例
# 这个脚本展示如何将种田系统集成到你的游戏中

var farming_manager: FarmingManager
var farming_ui: FarmingUI

func _ready() -> void:
	_setup_farming_system()

func _setup_farming_system() -> void:
	# 创建FarmingManager作为全局单例
	farming_manager = FarmingManager.new()
	farming_manager.name = "FarmingManager"
	add_child(farming_manager)

	# 创建UI
	var farming_ui_instance = FarmingUI.new()
	farming_ui_instance.anchor_left = 0.5
	farming_ui_instance.anchor_top = 0.5
	farming_ui_instance.offset_left = -200
	farming_ui_instance.offset_top = -300
	add_child(farming_ui_instance)

	# 连接到其他系统（如果存在）
	_connect_to_other_systems()

	# 每天更新农场
	_setup_daily_timer()

func _connect_to_other_systems() -> void:
	# 连接到库存系统（示例）
	if has_node("/root/InventoryManager"):
		farming_manager.farm_plot_harvested.connect(
			func(plot_id: int, yield_amount: int):
				var plot = farming_manager.get_farm_plot(plot_id)
				if plot.current_crop_id != -1:
					# InventoryManager.add_item(plot.current_crop_id, yield_amount)
					pass
		)

	# 连接到游戏状态管理器（示例）
	if has_node("/root/GameStateManager"):
		# GameStateManager.day_changed.connect(farming_manager.update_farm_day)
		pass

func _setup_daily_timer() -> void:
	# 示例：每10秒推进一天（用于测试）
	# 在实际游戏中应该连接到游戏的日期系统
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.timeout.connect(farming_manager.update_farm_day)
	add_child(timer)
	# timer.start()  # 取消注释以启用自动日期推进

# 公共API示例
func plant_crop_at_location(world_pos: Vector2, crop_id: int) -> void:
	# 这个函数可以被玩家交互脚本调用
	# 根据世界坐标找到最近的地块
	var nearest_plot_id = _get_nearest_plot(world_pos)
	if nearest_plot_id != -1:
		farming_manager.plant_crop(nearest_plot_id, crop_id)

func interact_with_farm(world_pos: Vector2, interaction_type: String) -> void:
	# 基于交互类型（浇水、施肥等）与农场交互
	var nearest_plot_id = _get_nearest_plot(world_pos)
	if nearest_plot_id == -1:
		return

	match interaction_type:
		"water":
			farming_manager.water_plot(nearest_plot_id)
		"fertilize":
			farming_manager.fertilize_plot(nearest_plot_id)
		"harvest":
			farming_manager.harvest_crop(nearest_plot_id)

func get_farm_info() -> Dictionary:
	return {
		"current_season": farming_manager.current_season,
		"current_day": farming_manager.current_day,
		"total_plots": farming_manager.farm_plots.size(),
		"crops_database": farming_manager.crops_database,
	}

func _get_nearest_plot(world_pos: Vector2) -> int:
	# 根据世界坐标找到最近的地块
	var nearest_distance = INF
	var nearest_plot_id = -1

	for plot in farming_manager.get_all_plots():
		var distance = world_pos.distance_to(plot.position)
		if distance < nearest_distance and distance < 100:  # 交互范围100像素
			nearest_distance = distance
			nearest_plot_id = plot.id

	return nearest_plot_id
