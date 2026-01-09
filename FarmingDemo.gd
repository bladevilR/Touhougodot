extends Node
## 农场系统演示脚本 - 用于测试种地功能

var farming_manager: FarmingManager
var current_season: String = "spring"
var current_day: int = 0

func _ready():
	var separator = "=================================================="
	print(separator)
	print("🌾 种地系统演示开始 🌾")
	print(separator)

	# 创建种地管理器
	farming_manager = FarmingManager.new()
	farming_manager._initialize_crops_database()
	farming_manager._initialize_farm_plots()

	# 设置初始季节
	farming_manager.current_season = current_season

	# 演示功能
	_demo_farming_system()

func _demo_farming_system():
	var separator = "=================================================="

	print("\n📋 农场信息：")
	print("当前季节: %s" % farming_manager.current_season)
	print("农田数量: %d" % farming_manager.farm_plots.size())
	print("可用作物: %d 种" % farming_manager.crops_database.size())

	print("\n🌱 可用作物列表：")
	for crop_id in farming_manager.crops_database:
		var crop = farming_manager.crops_database[crop_id]
		print("  - [%d] %s (生长天数: %d, 产量: %d)" % [crop_id, crop["name"], crop["growth_time"], crop["base_yield"]])

	print("\n🌾 示例1: 种植番茄")
	var planted = farming_manager.plant_crop(0, 1)  # 在地块0种植番茄(ID=1)
	if planted:
		print("✓ 成功在地块0种植了番茄！")
	else:
		print("✗ 种植失败")

	print("\n🌾 示例2: 种植小麦（错误的季节）")
	planted = farming_manager.plant_crop(1, 2)  # 在地块1种植小麦(ID=2)，但春季不能种
	if not planted:
		print("✓ 正确阻止了不符合季节的种植")

	print("\n🌾 示例3: 浇水和施肥")
	var watered = farming_manager.water_plot(0)
	var fertilized = farming_manager.fertilize_plot(0)
	print("浇水: %s, 施肥: %s" % ["成功" if watered else "失败", "成功" if fertilized else "失败"])

	print("\n📅 模拟时间推进...")
	# 模拟5天
	for day in range(5):
		farming_manager.current_day = day
		farming_manager.update_farm_day()
		print("  第 %d 天 - 季节: %s" % [day + 1, farming_manager.current_season])

	print("\n🌾 示例4: 检查作物生长状态")
	var plot = farming_manager.get_farm_plot(0)
	if plot and plot.has_crop():
		print("地块0 - 作物: %s, 生长阶段: %d/100" % [
			farming_manager.crops_database[plot.current_crop_id]["name"],
			plot.growth_stage
		])

	print("\n🌾 示例5: 收获作物")
	# 首先强制地块0的作物成熟（修改生长进度）
	if plot and plot.has_crop():
		plot.growth_stage = 100  # 设置为已成熟
		var harvest = farming_manager.harvest_crop(0)
		print("收获产量: %d 个" % harvest)
		if plot.is_empty():
			print("✓ 地块0已变空，可以重新种植")

	print("\n📊 农场统计：")
	var empty_plots = 0
	var planted_plots = 0
	for farm_plot in farming_manager.get_all_plots():
		if farm_plot.is_empty():
			empty_plots += 1
		else:
			planted_plots += 1
	print("已种植: %d 块, 空闲: %d 块" % [planted_plots, empty_plots])

	print("\n" + separator)
	print("🌾 种地系统演示完成！")
	print(separator)

	# 打印详细的地块信息
	print("\n📍 详细的地块信息：")
	for plot_id in farming_manager.farm_plots:
		var farm_plot = farming_manager.farm_plots[plot_id]
		var status = "空闲"
		if farm_plot.has_crop():
			var crop_name = farming_manager.crops_database[farm_plot.current_crop_id]["name"]
			status = "%s (生长: %d/100)" % [crop_name, farm_plot.growth_stage]
		print("  地块 #%d: %s | 水分: %.1f | 肥料: %.1f" % [plot_id, status, farm_plot.water_level, farm_plot.fertilizer_level])

func _on_farming_signals():
	"""连接信号的演示"""
	print("\n🔔 信号演示:")

	# 连接信号
	farming_manager.farm_plot_planted.connect(func(plot_id, crop_id):
		print("  [信号] 地块 %d 种植了作物 %d" % [plot_id, crop_id])
	)

	farming_manager.farm_plot_harvested.connect(func(plot_id, yield_amount):
		print("  [信号] 地块 %d 收获了 %d 个作物" % [plot_id, yield_amount])
	)

	farming_manager.season_changed.connect(func(season):
		print("  [信号] 季节变更为: %s" % season)
	)

	farming_manager.crop_grown.connect(func(plot_id, growth_stage):
		print("  [信号] 地块 %d 作物生长阶段: %d" % [plot_id, growth_stage])
	)

	print("✓ 信号连接成功！")
