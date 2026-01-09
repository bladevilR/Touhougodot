extends Node2D

class_name FarmingWorldSystem

# 负责将农场逻辑实体化到游戏世界中
# 应当作为关卡场景的一部分被实例化

@export var plot_scene: PackedScene
@export var grid_start_pos: Vector2 = Vector2(0, 0)
@export var grid_width: int = 6
@export var grid_height: int = 5
@export var cell_size: int = 64
@export var spacing: int = 4

var farming_manager: FarmingManager
var plot_nodes: Dictionary = {} # plot_id -> FarmPlotNode

func _ready() -> void:
	if not plot_scene:
		plot_scene = preload("res://scenes/farming/FarmPlotNode.tscn")
		
	# 初始化逻辑管理器
	farming_manager = FarmingManager.new()
	add_child(farming_manager)
	
	# 连接信号
	farming_manager.farm_plot_planted.connect(_on_plot_updated.unbind(2))
	farming_manager.farm_plot_harvested.connect(_on_plot_updated.unbind(2))
	farming_manager.crop_grown.connect(_on_plot_updated.unbind(2))
	
	# 初始化显示
	_spawn_plots()

func _spawn_plots() -> void:
	# 确保管理器有正确数量的地块 (Manager 目前硬编码了 6x5 在之前的修改中)
	# 如果以后支持动态大小，这里可能需要调整 Manager 的初始化逻辑
	
	var plots = farming_manager.get_all_plots()
	for plot_data in plots:
		var node = plot_scene.instantiate() as FarmPlotNode
		add_child(node)
		
		# 计算世界坐标
		# 假设 plot_data.id 是连续的，我们根据 grid_width 计算行列
		# 或者直接使用 plot_data.position 如果它已经被正确设置
		
		# 重新计算位置以确保对齐
		var col = plot_data.id % grid_width
		var row = plot_data.id / grid_width
		
		node.position = grid_start_pos + Vector2(
			col * (cell_size + spacing),
			row * (cell_size + spacing)
		)
		
		node.setup(plot_data)
		plot_nodes[plot_data.id] = node

func _on_plot_updated(_a=0, _b=0) -> void:
	# 刷新所有地块的显示
	for id in plot_nodes:
		plot_nodes[id].refresh_visuals()

# API 供玩家交互
func get_plot_at_position(world_pos: Vector2) -> FarmPlotNode:
	# 简单的距离/网格检测
	# 将世界坐标转换为本地网格坐标
	var local_pos = world_pos - global_position - grid_start_pos
	
	# 考虑到中心点可能在左上角
	# 假设每个格子中心在 (cell_size/2, cell_size/2)
	# 实际上 FarmPlotNode 的原点是中心 (Area2D default)
	
	# 反向查找最近的节点
	# 对于小规模网格，直接遍历距离是可以的
	var closest_node: FarmPlotNode = null
	var closest_dist = 99999.0
	
	for node in plot_nodes.values():
		var dist = node.global_position.distance_to(world_pos)
		if dist < (cell_size / 1.5): # 必须在一定范围内
			if dist < closest_dist:
				closest_dist = dist
				closest_node = node
				
	return closest_node

func interact_at(world_pos: Vector2, tool_type: String) -> bool:
	var node = get_plot_at_position(world_pos)
	if not node:
		return false
		
	var plot_id = node.plot_data.id
	var success = false
	
	match tool_type:
		"hand":
			if node.plot_data.is_ready_to_harvest():
				var amount = farming_manager.harvest_crop(plot_id)
				return amount > 0
		"hoe":
			# 手动修改数据状态，因为 Manager 默认 Plant 才耕地，或者我们需要添加 till_plot 方法
			# 这里为了演示，我们直接修改数据
			if not node.plot_data.is_tilled:
				node.plot_data.is_tilled = true
				node.refresh_visuals()
				return true
		"water_can":
			success = farming_manager.water_plot(plot_id)
		"fertilizer":
			success = farming_manager.fertilize_plot(plot_id)
		"seeds_tomato": success = farming_manager.plant_crop(plot_id, 1)
		"seeds_wheat": success = farming_manager.plant_crop(plot_id, 2)
		"seeds_pumpkin": success = farming_manager.plant_crop(plot_id, 3)
		"seeds_carrot": success = farming_manager.plant_crop(plot_id, 4)
			
	if success:
		node.refresh_visuals()
		
	return success

func advance_day() -> void:
	farming_manager.update_farm_day()
