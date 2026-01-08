extends Control

class_name FarmingUI

# 种田系统的UI管理器
@onready var farming_manager: FarmingManager

var selected_plot_id: int = -1
var grid_cell_size: int = 64
var plot_buttons: Dictionary = {}

func _ready() -> void:
	# 从全局获取FarmingManager或创建新的
	if has_node("/root/FarmingManager"):
		farming_manager = get_node("/root/FarmingManager")
	else:
		farming_manager = FarmingManager.new()
		farming_manager.name = "FarmingManager"
		add_child(farming_manager)

	_setup_ui()
	_connect_signals()

func _setup_ui() -> void:
	# 创建UI面板
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.custom_minimum_size = Vector2(400, 600)
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# 标题
	var title = Label.new()
	title.text = "种田系统"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	# 季节和日期显示
	var season_label = Label.new()
	season_label.name = "SeasonLabel"
	season_label.text = "季节: %s | 日期: %d" % [farming_manager.current_season, farming_manager.current_day]
	vbox.add_child(season_label)

	# 农田网格
	var grid_container = GridContainer.new()
	grid_container.columns = 3
	grid_container.custom_minimum_size = Vector2(300, 300)

	for plot_id in range(9):
		var button = Button.new()
		button.custom_minimum_size = Vector2(grid_cell_size, grid_cell_size)
		button.text = str(plot_id)
		button.pressed.connect(_on_plot_button_pressed.bind(plot_id))
		grid_container.add_child(button)
		plot_buttons[plot_id] = button

	vbox.add_child(grid_container)

	# 控制按钮
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)

	var water_btn = Button.new()
	water_btn.text = "浇水"
	water_btn.pressed.connect(_on_water_pressed)
	hbox.add_child(water_btn)

	var fertilize_btn = Button.new()
	fertilize_btn.text = "施肥"
	fertilize_btn.pressed.connect(_on_fertilize_pressed)
	hbox.add_child(fertilize_btn)

	var harvest_btn = Button.new()
	harvest_btn.text = "收获"
	harvest_btn.pressed.connect(_on_harvest_pressed)
	hbox.add_child(harvest_btn)

	# 信息面板
	var info_panel = PanelContainer.new()
	info_panel.custom_minimum_size = Vector2(400, 150)
	vbox.add_child(info_panel)

	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "选择地块查看详情"
	info_label.custom_minimum_size = Vector2(400, 150)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_panel.add_child(info_label)

	# 推进日期按钮
	var next_day_btn = Button.new()
	next_day_btn.text = "下一天"
	next_day_btn.pressed.connect(_on_next_day_pressed)
	vbox.add_child(next_day_btn)

func _connect_signals() -> void:
	farming_manager.farm_plot_planted.connect(_on_plot_planted)
	farming_manager.farm_plot_harvested.connect(_on_plot_harvested)
	farming_manager.crop_grown.connect(_on_crop_grown)
	farming_manager.season_changed.connect(_on_season_changed)

func _on_plot_button_pressed(plot_id: int) -> void:
	selected_plot_id = plot_id
	_update_info_display()

func _on_water_pressed() -> void:
	if selected_plot_id == -1:
		return
	farming_manager.water_plot(selected_plot_id)
	_update_info_display()

func _on_fertilize_pressed() -> void:
	if selected_plot_id == -1:
		return
	farming_manager.fertilize_plot(selected_plot_id)
	_update_info_display()

func _on_harvest_pressed() -> void:
	if selected_plot_id == -1:
		return
	var yield_amount = farming_manager.harvest_crop(selected_plot_id)
	if yield_amount > 0:
		show_message("收获 %d 件产品！" % yield_amount)
	_update_info_display()

func _on_next_day_pressed() -> void:
	farming_manager.update_farm_day()
	_update_display()

func _update_display() -> void:
	# 更新季节标签
	if has_node("PanelContainer/VBoxContainer/SeasonLabel"):
		get_node("PanelContainer/VBoxContainer/SeasonLabel").text = "季节: %s | 日期: %d" % [
			farming_manager.current_season,
			farming_manager.current_day
		]

	# 更新所有地块的显示
	for plot_id in range(9):
		var plot = farming_manager.get_farm_plot(plot_id)
		var button = plot_buttons[plot_id]
		if plot.has_crop():
			button.text = "%d%%\n%d" % [plot.growth_stage, plot_id]
			button.modulate = Color.GREEN.lerp(Color.YELLOW, float(plot.growth_stage) / 100.0)
		else:
			button.text = str(plot_id)
			button.modulate = Color.WHITE

	_update_info_display()

func _update_info_display() -> void:
	if selected_plot_id == -1:
		return

	var plot = farming_manager.get_farm_plot(selected_plot_id)
	var info_text = "地块 #%d\n" % plot.id

	if plot.has_crop():
		info_text += "作物ID: %d\n" % plot.current_crop_id
		info_text += "生长阶段: %d%%\n" % plot.growth_stage
	else:
		info_text += "状态: 空地\n"

	info_text += "水分: %.0f/%.0f\n" % [plot.water_level, FarmPlot.MAX_WATER]
	info_text += "肥料: %.0f/%.0f\n" % [plot.fertilizer_level, FarmPlot.MAX_FERTILIZER]
	info_text += "健康值: %.1f%%\n" % [plot.get_health() * 100.0]

	if has_node("PanelContainer/VBoxContainer/InfoLabel"):
		get_node("PanelContainer/VBoxContainer/InfoLabel").text = info_text

func _on_plot_planted(plot_id: int, crop_id: int) -> void:
	show_message("在地块 #%d 种植了作物 %d" % [plot_id, crop_id])
	_update_display()

func _on_plot_harvested(plot_id: int, yield_amount: int) -> void:
	show_message("地块 #%d 收获了 %d 件产品" % [plot_id, yield_amount])
	_update_display()

func _on_crop_grown(plot_id: int, growth_stage: int) -> void:
	_update_display()

func _on_season_changed(season: String) -> void:
	show_message("季节变化: 进入 %s" % season)
	_update_display()

func show_message(message: String) -> void:
	print("[FarmingUI] %s" % message)

func _on_plant_crop(plot_id: int, crop_id: int) -> void:
	farming_manager.plant_crop(plot_id, crop_id)
	_update_display()
