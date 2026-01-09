extends Node2D

class_name PlayerFarmingController

# 负责处理玩家的种田输入和交互反馈
# 这是一个挂载在 Player 身上或者跟随 Player 的控制器

@export var farming_system: FarmingWorldSystem
@export var player: CharacterBody2D

# 农具定义
enum Tool {
	HAND,       # 手 (查看/收获)
	HOE,        # 锄头 (耕地)
	WATER_CAN,  # 水壶 (浇水)
	FERTILIZER, # 肥料
	SEEDS_TOMATO,
	SEEDS_WHEAT,
	SEEDS_PUMPKIN,
	SEEDS_CARROT
}

var current_tool: Tool = Tool.HAND
var highlight_box: Line2D
var cell_size = 64

# UI 引用
var ui_layer: CanvasLayer
var tool_label: Label
var season_label: Label

func _ready() -> void:
	# 初始化高亮框
	highlight_box = Line2D.new()
	highlight_box.points = [
		Vector2(0, 0), Vector2(cell_size, 0), 
		Vector2(cell_size, cell_size), Vector2(0, cell_size), 
		Vector2(0, 0)
	]
	highlight_box.width = 2
	highlight_box.default_color = Color(1, 1, 0, 0.8) # 黄色高亮
	highlight_box.visible = false
	add_child(highlight_box)
	
	# 创建简单的UI
	_create_ui()

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(farming_system):
		return
		
	# 更新UI位置或信息
	_update_highlight()

func _input(event: InputEvent) -> void:
	if not is_instance_valid(player): return
	
	# 工具切换
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: _select_tool(Tool.HAND)
		elif event.keycode == KEY_2: _select_tool(Tool.HOE)
		elif event.keycode == KEY_3: _select_tool(Tool.WATER_CAN)
		elif event.keycode == KEY_4: _select_tool(Tool.FERTILIZER)
		elif event.keycode == KEY_5: _select_tool(Tool.SEEDS_TOMATO)
		elif event.keycode == KEY_6: _select_tool(Tool.SEEDS_WHEAT)
		elif event.keycode == KEY_7: _select_tool(Tool.SEEDS_PUMPKIN)
		elif event.keycode == KEY_8: _select_tool(Tool.SEEDS_CARROT)
		elif event.keycode == KEY_SPACE: 
			farming_system.advance_day()
			_update_ui()
			
	# 交互 (鼠标左键)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_interact()

func _select_tool(tool: Tool) -> void:
	current_tool = tool
	_update_ui()

func _update_ui() -> void:
	if tool_label:
		tool_label.text = "当前工具: %s" % Tool.keys()[current_tool]
	if season_label and farming_system:
		season_label.text = "季节: %s | 第 %d 天 (按空格进入下一天)" % [
			farming_system.farming_manager.current_season, 
			farming_system.farming_manager.current_day
		]

func _update_highlight() -> void:
	# 获取鼠标的世界坐标
	var mouse_pos = get_global_mouse_position()
	
	# 简单的网格吸附逻辑
	# 假设 grid_start_pos 是 (0,0) 且对齐
	var grid_x = floor(mouse_pos.x / cell_size)
	var grid_y = floor(mouse_pos.y / cell_size)
	
	var target_pos = Vector2(grid_x * cell_size, grid_y * cell_size)
	
	# 检查距离玩家是否足够近
	var dist = player.global_position.distance_to(mouse_pos)
	if dist < 150.0: # 交互范围
		highlight_box.visible = true
		highlight_box.global_position = target_pos
	else:
		highlight_box.visible = false

func _try_interact() -> void:
	if not highlight_box.visible: return
	
	# 目标中心点
	var target_pos = highlight_box.global_position + Vector2(cell_size/2, cell_size/2)
	
	# 转换工具类型为字符串
	var tool_str = "hand"
	match current_tool:
		Tool.HAND: tool_str = "hand"
		Tool.HOE: tool_str = "hoe"
		Tool.WATER_CAN: tool_str = "water_can"
		Tool.FERTILIZER: tool_str = "fertilizer"
		Tool.SEEDS_TOMATO: tool_str = "seeds_tomato"
		Tool.SEEDS_WHEAT: tool_str = "seeds_wheat"
		Tool.SEEDS_PUMPKIN: tool_str = "seeds_pumpkin"
		Tool.SEEDS_CARROT: tool_str = "seeds_carrot"
		
	var success = farming_system.interact_at(target_pos, tool_str)
	if success:
		# 播放音效或粒子反馈
		print("交互成功: " + tool_str)
	else:
		print("交互无效")

func _create_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 100) # 避开原本的UI
	ui_layer.add_child(vbox)
	
	season_label = Label.new()
	vbox.add_child(season_label)
	
	tool_label = Label.new()
	vbox.add_child(tool_label)
	
	_update_ui()
