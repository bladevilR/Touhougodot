extends Node

class_name FarmingManager

# 种田系统的主管理器
signal farm_plot_planted(plot_id: int, crop_id: int)
signal farm_plot_harvested(plot_id: int, yield_amount: int)
signal crop_grown(plot_id: int, growth_stage: int)
signal season_changed(season: String)

var farm_plots: Dictionary = {}  # plot_id -> FarmPlot
var crops_database: Dictionary = {}  # crop_id -> CropData
var current_season: String = "spring"
var current_day: int = 0

const SEASONS = ["spring", "summer", "autumn", "winter"]
const SEASON_DURATION = 30  # 每个季节的天数

func _ready() -> void:
	_initialize_crops_database()
	_initialize_farm_plots()

func _initialize_crops_database() -> void:
	# 初始化作物数据库
	crops_database = {
		1: {
			"name": "番茄",
			"growth_time": 5,  # 天数
			"base_yield": 3,
			"seasons": ["spring", "summer"],
			"water_requirement": 2,
			"sunlight_requirement": 8,
		},
		2: {
			"name": "小麦",
			"growth_time": 7,
			"base_yield": 4,
			"seasons": ["summer", "autumn"],
			"water_requirement": 1.5,
			"sunlight_requirement": 10,
		},
		3: {
			"name": "南瓜",
			"growth_time": 10,
			"base_yield": 2,
			"seasons": ["autumn"],
			"water_requirement": 2.5,
			"sunlight_requirement": 9,
		},
		4: {
			"name": "红萝卜",
			"growth_time": 6,
			"base_yield": 3,
			"seasons": ["spring", "autumn", "winter"],
			"water_requirement": 1.8,
			"sunlight_requirement": 7,
		},
	}

func _initialize_farm_plots() -> void:
	# 初始化农田地块（示例：3x3网格）
	var plot_id = 0
	for x in range(3):
		for y in range(3):
			var plot = FarmPlot.new()
			plot.id = plot_id
			plot.position = Vector2(x * 64, y * 64)
			farm_plots[plot_id] = plot
			plot_id += 1

func plant_crop(plot_id: int, crop_id: int) -> bool:
	if not farm_plots.has(plot_id):
		return false

	if not crops_database.has(crop_id):
		return false

	var plot = farm_plots[plot_id]
	var crop_data = crops_database[crop_id]

	# 检查季节是否合适
	if not crop_data["seasons"].has(current_season):
		push_error("作物 %s 在 %s 季节不能种植" % [crop_data["name"], current_season])
		return false

	if not plot.is_empty():
		return false

	plot.plant(crop_id, crop_data)
	farm_plot_planted.emit(plot_id, crop_id)
	return true

func harvest_crop(plot_id: int) -> int:
	if not farm_plots.has(plot_id):
		return 0

	var plot = farm_plots[plot_id]
	if not plot.is_ready_to_harvest():
		return 0

	var yield_amount = plot.harvest()
	farm_plot_harvested.emit(plot_id, yield_amount)
	return yield_amount

func update_farm_day() -> void:
	current_day += 1

	# 检查季节变化
	var season_index = SEASONS.find(current_season)
	if current_day >= SEASON_DURATION:
		current_day = 0
		season_index = (season_index + 1) % SEASONS.size()
		current_season = SEASONS[season_index]
		season_changed.emit(current_season)

	# 更新所有地块
	for plot in farm_plots.values():
		if plot.has_crop():
			plot.update_day(current_day)
			crop_grown.emit(plot.id, plot.growth_stage)

func get_farm_plot(plot_id: int) -> FarmPlot:
	return farm_plots.get(plot_id)

func get_all_plots() -> Array:
	return farm_plots.values()

func water_plot(plot_id: int) -> bool:
	if not farm_plots.has(plot_id):
		return false

	var plot = farm_plots[plot_id]
	plot.water()
	return true

func fertilize_plot(plot_id: int) -> bool:
	if not farm_plots.has(plot_id):
		return false

	var plot = farm_plots[plot_id]
	plot.fertilize()
	return true
