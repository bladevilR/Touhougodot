extends Node2D

class_name FarmingView

# 农场可视化脚本
# 负责将FarmingManager的数据渲染到屏幕上，并处理用户输入

@export var cell_size: Vector2 = Vector2(64, 64)
@export var grid_width: int = 6
@export var grid_height: int = 5
@export var spacing: int = 4

# 资源预加载
const TEX_SHOOT_SMALL = preload("res://shoot_small_1.png")
const TEX_SHOOT_MEDIUM = preload("res://shoot_medium_1.png")
# 成熟作物纹理
const TEX_CROP_TOMATO = preload("res://flower_red_tulip.png") # ID 1
const TEX_CROP_WHEAT = preload("res://flower_yellow_cluster_1.png") # ID 2
const TEX_CROP_PUMPKIN = preload("res://flower_red_cluster_1.png") # ID 3
const TEX_CROP_CARROT = preload("res://flower_white_daisy_single.png") # ID 4

# 工具定义
enum Tool {
	HAND,       # 手 (查看/收获)
	HOE,        # 锄头 (耕地)
	WATER_CAN,  # 水壶 (浇水)
	SEEDS_TOMATO, # 番茄种子
	SEEDS_WHEAT,  # 小麦种子
	SEEDS_PUMPKIN,# 南瓜种子
	SEEDS_CARROT, # 红萝卜种子
	FERTILIZER    # 肥料
}

var farming_manager: FarmingManager
var plot_nodes: Dictionary = {} # plot_id -> Node2D (Container)
var current_tool: Tool = Tool.HAND
var hover_rect: ColorRect

# UI 引用
var info_label: Label
var tool_label: Label
var season_label: Label

func _ready() -> void:
	# 初始化管理器
	farming_manager = FarmingManager.new()
	# 确保管理器中的网格设置与视图一致
	# 注意：目前的Manager硬编码了3x3，这里我们可能需要扩展Manager或者只是简单地匹配它
	# 为了演示，我们先使用默认的3x3
	add_child(farming_manager)
	
	# 连接信号
	farming_manager.farm_plot_planted.connect(_on_plot_update.unbind(2)) # unbind 2 args just to be safe or use bind
	farming_manager.farm_plot_harvested.connect(_on_plot_update.unbind(2))
	farming_manager.crop_grown.connect(_on_plot_update.unbind(2))
	farming_manager.season_changed.connect(_on_season_changed)
	
	# 初始化视觉网格
	_create_grid_visuals()
	
	# 初始化简单的UI
	_create_ui()
	
	# 初始更新
	_update_all_plots()
	_update_ui_labels()

func _create_grid_visuals() -> void:
	# 计算整个网格的中心偏移，使其居中
	var total_width = grid_width * (cell_size.x + spacing)
	var total_height = grid_height * (cell_size.y + spacing)
	var offset = Vector2(
		(get_viewport_rect().size.x - total_width) / 2,
		(get_viewport_rect().size.y - total_height) / 2
	)

	# 创建地块容器
	var plots_container = Node2D.new()
	plots_container.name = "PlotsContainer"
	plots_container.position = offset
	add_child(plots_container)

	var plot_id = 0
	for y in range(grid_height):
		for x in range(grid_width):
			var plot_node = Node2D.new()
			plot_node.position = Vector2(
				x * (cell_size.x + spacing),
				y * (cell_size.y + spacing)
			)
			plots_container.add_child(plot_node)

			# 1. 土地背景 (ColorRect) - 添加边框
			var soil = ColorRect.new()
			soil.name = "Soil"
			soil.custom_minimum_size = cell_size
			soil.size = cell_size
			soil.color = Color(0.3, 0.5, 0.3) # 默认草地颜色
			plot_node.add_child(soil)

			# 1.5 边框装饰
			var border = ColorRect.new()
			border.name = "Border"
			border.size = cell_size
			border.color = Color.TRANSPARENT
			plot_node.add_child(border)

			# 2. 作物 Sprite
			var crop_sprite = Sprite2D.new()
			crop_sprite.name = "CropSprite"
			crop_sprite.position = cell_size / 2 # 居中
			crop_sprite.scale = Vector2(0.8, 0.8)
			crop_sprite.visible = false
			plot_node.add_child(crop_sprite)

			# 3. 状态指示器 (例如：湿润的覆盖层)
			var wet_overlay = ColorRect.new()
			wet_overlay.name = "WetOverlay"
			wet_overlay.size = cell_size
			wet_overlay.color = Color(0.0, 0.0, 0.8, 0.2) # 半透明蓝色
			wet_overlay.visible = false
			plot_node.add_child(wet_overlay)

			# 4. 肥料指示器
			var fertilizer_overlay = ColorRect.new()
			fertilizer_overlay.name = "FertilizerOverlay"
			fertilizer_overlay.size = cell_size
			fertilizer_overlay.color = Color(0.8, 0.6, 0.2, 0.2) # 半透明棕色
			fertilizer_overlay.visible = false
			plot_node.add_child(fertilizer_overlay)

			# 5. 生长进度条容器
			var progress_container = Control.new()
			progress_container.name = "ProgressContainer"
			progress_container.offset_top = cell_size.y - 8
			progress_container.custom_minimum_size = Vector2(cell_size.x, 6)
			plot_node.add_child(progress_container)

			var progress_bg = ColorRect.new()
			progress_bg.size = Vector2(cell_size.x, 6)
			progress_bg.color = Color(0, 0, 0, 0.5)
			progress_container.add_child(progress_bg)

			var progress_bar = ColorRect.new()
			progress_bar.name = "ProgressBar"
			progress_bar.size = Vector2(cell_size.x, 6)
			progress_bar.color = Color(0.4, 0.8, 0.4, 0.8) # 绿色
			progress_bar.visible = false
			progress_container.add_child(progress_bar)

			# 6. 调试/信息 Label
			var debug_label = Label.new()
			debug_label.name = "DebugLabel"
			debug_label.scale = Vector2(0.5, 0.5)
			debug_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			plot_node.add_child(debug_label)

			plot_nodes[plot_id] = plot_node
			plot_id += 1

	# 创建鼠标悬停框
	hover_rect = ColorRect.new()
	hover_rect.size = cell_size
	hover_rect.color = Color(1, 1, 1, 0.15)
	hover_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_rect.visible = false
	plots_container.add_child(hover_rect)

func _create_ui() -> void:
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	# 顶部面板 - 季节信息
	var top_panel = Control.new()
	top_panel.offset_left = 20
	top_panel.offset_top = 20
	top_panel.offset_right = 400
	top_panel.offset_bottom = 80
	canvas_layer.add_child(top_panel)

	var top_bg = ColorRect.new()
	top_bg.offset_right = 380
	top_bg.offset_bottom = 60
	top_bg.color = Color(0, 0, 0, 0.7)
	top_panel.add_child(top_bg)

	season_label = Label.new()
	season_label.offset_left = 12
	season_label.offset_top = 8
	season_label.add_theme_font_size_override("font_size", 16)
	season_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3, 1)) # 金色
	top_panel.add_child(season_label)

	# 左下角面板 - 当前工具和地块信息
	var left_panel = Control.new()
	left_panel.offset_left = 20
	left_panel.offset_top = 900
	left_panel.offset_right = 420
	left_panel.offset_bottom = 1060
	canvas_layer.add_child(left_panel)

	var left_bg = ColorRect.new()
	left_bg.offset_right = 400
	left_bg.offset_bottom = 160
	left_bg.color = Color(0, 0, 0, 0.7)
	left_panel.add_child(left_bg)

	# 工具标签
	var tool_title = Label.new()
	tool_title.offset_left = 12
	tool_title.offset_top = 8
	tool_title.add_theme_font_size_override("font_size", 12)
	tool_title.add_theme_color_override("font_color", Color(0.6, 0.9, 1, 1)) # 蓝色
	tool_title.text = "当前工具:"
	left_panel.add_child(tool_title)

	tool_label = Label.new()
	tool_label.offset_left = 12
	tool_label.offset_top = 22
	tool_label.offset_right = 388
	tool_label.offset_bottom = 40
	tool_label.add_theme_font_size_override("font_size", 18)
	tool_label.add_theme_color_override("font_color", Color(1, 1, 1, 1)) # 白色
	left_panel.add_child(tool_label)

	# 地块信息
	info_label = Label.new()
	info_label.offset_left = 12
	info_label.offset_top = 50
	info_label.offset_right = 388
	info_label.offset_bottom = 150
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1)) # 浅灰色
	left_panel.add_child(info_label)

	# 右下角面板 - 控制说明
	var right_panel = Control.new()
	right_panel.offset_left = 430
	right_panel.offset_top = 900
	right_panel.offset_right = 1060
	right_panel.offset_bottom = 1060
	canvas_layer.add_child(right_panel)

	var right_bg = ColorRect.new()
	right_bg.offset_right = 630
	right_bg.offset_bottom = 160
	right_bg.color = Color(0, 0, 0, 0.7)
	right_panel.add_child(right_bg)

	var controls_title = Label.new()
	controls_title.offset_left = 12
	controls_title.offset_top = 8
	controls_title.add_theme_font_size_override("font_size", 12)
	controls_title.add_theme_color_override("font_color", Color(0.4, 1, 0.4, 1)) # 绿色
	controls_title.text = "控制说明:"
	right_panel.add_child(controls_title)

	var help_label = Label.new()
	help_label.offset_left = 12
	help_label.offset_top = 22
	help_label.offset_right = 618
	help_label.offset_bottom = 150
	help_label.add_theme_font_size_override("font_size", 11)
	help_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	help_label.text = "[1]手 [2]锄头 [3]水壶 [4]肥料 [5]番茄 [6]小麦 [7]南瓜 [8]红萝卜 | [SPACE]下一天"
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	right_panel.add_child(help_label)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_advance_day()
		elif event.keycode == KEY_1: _select_tool(Tool.HAND)
		elif event.keycode == KEY_2: _select_tool(Tool.HOE)
		elif event.keycode == KEY_3: _select_tool(Tool.WATER_CAN)
		elif event.keycode == KEY_4: _select_tool(Tool.FERTILIZER)
		elif event.keycode == KEY_5: _select_tool(Tool.SEEDS_TOMATO)
		elif event.keycode == KEY_6: _select_tool(Tool.SEEDS_WHEAT)
		elif event.keycode == KEY_7: _select_tool(Tool.SEEDS_PUMPKIN)
		elif event.keycode == KEY_8: _select_tool(Tool.SEEDS_CARROT)
	
	if event is InputEventMouseMotion:
		_handle_mouse_hover(event.position)
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_click(event.position)

func _select_tool(tool: Tool) -> void:
	current_tool = tool
	_update_ui_labels()

func _advance_day() -> void:
	farming_manager.update_farm_day()
	_update_all_plots()
	_update_ui_labels()

func _handle_mouse_hover(screen_pos: Vector2) -> void:
	var plot_id = _get_plot_id_at_position(screen_pos)
	if plot_id != -1 and plot_nodes.has(plot_id):
		var node = plot_nodes[plot_id]
		hover_rect.visible = true
		hover_rect.position = node.position
		
		# 更新即时信息
		var plot_data = farming_manager.get_farm_plot(plot_id)
		_update_info_label(plot_data)
	else:
		hover_rect.visible = false
		info_label.text = "请将鼠标悬停在地块上"

func _handle_click(screen_pos: Vector2) -> void:
	var plot_id = _get_plot_id_at_position(screen_pos)
	if plot_id == -1:
		return
		
	var plot = farming_manager.get_farm_plot(plot_id)
	if not plot: return
	
	match current_tool:
		Tool.HAND:
			if plot.is_ready_to_harvest():
				var yield_amt = farming_manager.harvest_crop(plot_id)
				print("收获了 %d 个作物" % yield_amt)
			else:
				print("这里没什么可收获的，或者还没成熟")
		
		Tool.HOE:
			if not plot.is_tilled:
				# 模拟耕地，虽然Manager里Plant会自动耕地，但我们可以手动设置属性
				# 由于FarmPlot.is_tilled是变量，我们需要在Manager里加个方法或者直接修改（如果它是Ref）
				plot.is_tilled = true
				_update_plot_visual(plot_id)
				print("耕地成功")
				
		Tool.WATER_CAN:
			farming_manager.water_plot(plot_id)
			_update_plot_visual(plot_id)
			
		Tool.FERTILIZER:
			farming_manager.fertilize_plot(plot_id)
			_update_plot_visual(plot_id)
			
		Tool.SEEDS_TOMATO: farming_manager.plant_crop(plot_id, 1)
		Tool.SEEDS_WHEAT: farming_manager.plant_crop(plot_id, 2)
		Tool.SEEDS_PUMPKIN: farming_manager.plant_crop(plot_id, 3)
		Tool.SEEDS_CARROT: farming_manager.plant_crop(plot_id, 4)

	# 刷新显示
	_update_plot_visual(plot_id)
	_update_info_label(plot)

func _get_plot_id_at_position(screen_pos: Vector2) -> int:
	# 将屏幕坐标转换为本地坐标（考虑到PlotsContainer的偏移）
	var container = get_node_or_null("PlotsContainer")
	if not container: return -1
	
	var local_pos = screen_pos - container.position
	
	if local_pos.x < 0 or local_pos.y < 0: return -1
	
	var col = int(local_pos.x / (cell_size.x + spacing))
	var row = int(local_pos.y / (cell_size.y + spacing))
	
	if col >= grid_width or row >= grid_height: return -1
	
	var id = row * grid_width + col
	# 检查是否存在
	if plot_nodes.has(id):
		return id
	return -1

func _on_plot_update(_id = 0, _val = 0) -> void:
	# 简单起见，收到任何更新信号都刷新所有（或者是特定的ID，如果需要优化）
	# 由于信号参数不一致，我们这里简单地全量刷新或根据实际情况改进
	_update_all_plots()

func _on_season_changed(season: String) -> void:
	_update_ui_labels()
	print("季节变更为: " + season)

func _update_all_plots() -> void:
	for id in plot_nodes:
		_update_plot_visual(id)

func _update_plot_visual(plot_id: int) -> void:
	var plot = farming_manager.get_farm_plot(plot_id)
	var node = plot_nodes[plot_id]
	var soil: ColorRect = node.get_node("Soil")
	var crop_sprite: Sprite2D = node.get_node("CropSprite")
	var wet_overlay: ColorRect = node.get_node("WetOverlay")
	var fertilizer_overlay: ColorRect = node.get_node("FertilizerOverlay")
	var progress_container: Control = node.get_node("ProgressContainer")
	var progress_bar: ColorRect = progress_container.get_node("ProgressBar")
	var debug_label: Label = node.get_node("DebugLabel")

	# 1. 更新土地颜色
	if plot.is_tilled:
		soil.color = Color(0.55, 0.47, 0.35) # 耕地颜色 (土黄)
	else:
		soil.color = Color(0.3, 0.5, 0.3) # 草地颜色

	# 2. 更新湿润状态
	wet_overlay.visible = plot.water_level > 20.0 # 稍微有点水就显示湿润

	# 3. 更新肥料状态
	fertilizer_overlay.visible = plot.fertilizer_level > 20.0

	# 4. 更新作物 Sprite 和进度条
	if plot.has_crop():
		crop_sprite.visible = true
		progress_bar.visible = true

		# 根据生长阶段选择贴图
		if plot.growth_stage < 30:
			crop_sprite.texture = TEX_SHOOT_SMALL
		elif plot.growth_stage < 100:
			crop_sprite.texture = TEX_SHOOT_MEDIUM
		else:
			# 成熟
			match plot.current_crop_id:
				1: crop_sprite.texture = TEX_CROP_TOMATO
				2: crop_sprite.texture = TEX_CROP_WHEAT
				3: crop_sprite.texture = TEX_CROP_PUMPKIN
				4: crop_sprite.texture = TEX_CROP_CARROT
				_: crop_sprite.texture = TEX_SHOOT_MEDIUM # Fallback

		# 更新进度条
		var progress_ratio = float(plot.growth_stage) / 100.0
		var progress_width = cell_size.x * clamp(progress_ratio, 0.0, 1.0)
		progress_bar.size = Vector2(progress_width, 6)

		# 颜色根据生长阶段变化
		if plot.growth_stage < 50:
			progress_bar.color = Color(0.8, 0.6, 0.2, 0.8) # 黄色
		elif plot.growth_stage < 100:
			progress_bar.color = Color(0.4, 0.8, 0.4, 0.8) # 绿色
		else:
			progress_bar.color = Color(1, 0.8, 0.2, 0.8) # 金色（成熟）

		# 显示百分比
		debug_label.text = "%d%%" % plot.growth_stage
	else:
		crop_sprite.visible = false
		progress_bar.visible = false
		debug_label.text = ""

func _update_ui_labels() -> void:
	season_label.text = "季节: %s | 第 %d 天" % [farming_manager.current_season, farming_manager.current_day]

	var tool_names = {
		Tool.HAND: "手 (查看/收获)",
		Tool.HOE: "锄头 (耕地)",
		Tool.WATER_CAN: "水壶 (浇水)",
		Tool.SEEDS_TOMATO: "番茄种子",
		Tool.SEEDS_WHEAT: "小麦种子",
		Tool.SEEDS_PUMPKIN: "南瓜种子",
		Tool.SEEDS_CARROT: "红萝卜种子",
		Tool.FERTILIZER: "肥料"
	}

	tool_label.text = tool_names[current_tool]

func _update_info_label(plot: FarmPlot) -> void:
	if not plot: return

	var status = "未耕种"
	var crop_info = ""

	if plot.is_tilled:
		status = "已耕地"
		if plot.has_crop():
			var crop_name = farming_manager.crops_database[plot.current_crop_id]["name"]
			status = "%s" % crop_name
			crop_info = "生长: %d%% " % plot.growth_stage

	info_label.text = "%s %s\n水: %.0f  肥: %.0f" % [crop_info, status, plot.water_level, plot.fertilizer_level]
