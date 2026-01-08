# 种田系统 (Farming System)

这是一个为Touhou Godot项目设计的完整的2D种田系统。

## 功能特性

### 核心机制
- **季节系统**: 4个季节，每个季节30天
- **作物系统**: 可扩展的作物数据库，支持季节限制
- **生长管理**: 基于水分和肥料的动态生长速度
- **地块管理**: 3x3农田网格，支持种植、浇水、施肥、收获

### 作物数据库
系统包含4种示例作物：
- **番茄**: 5天成熟，春夏季节
- **小麦**: 7天成熟，夏秋季节
- **南瓜**: 10天成熟，秋季
- **红萝卜**: 6天成熟，春秋冬季节

### 生长机制
- 作物需要充足的水分（>30%）才能生长
- 水分不足时停止生长
- 肥料充足（>70%）时加速生长
- 收获产量受水分和肥料状况影响
- 每天自动衰减水分（5点）和肥料（1.5点）

## 文件结构

```
scripts/systems/farming/
├── FarmingManager.gd      # 主管理器（处理逻辑）
├── FarmPlot.gd           # 单个地块类（数据模型）
├── FarmingUI.gd          # UI管理器（显示和交互）
└── README.md             # 本文件
```

## 使用方法

### 1. 添加到项目
将`scripts/systems/farming/`目录复制到你的项目中。

### 2. 创建场景
创建一个新的Control节点场景，添加FarmingUI脚本：

```gdscript
extends Control

func _ready() -> void:
	var farming_ui = FarmingUI.new()
	add_child(farming_ui)
```

### 3. API使用示例

#### 种植作物
```gdscript
# plot_id: 地块ID (0-8)
# crop_id: 作物ID (1-4)
farming_manager.plant_crop(0, 1)  # 在地块0种植番茄
```

#### 管理地块
```gdscript
farming_manager.water_plot(0)      # 浇水
farming_manager.fertilize_plot(0)  # 施肥
farming_manager.harvest_crop(0)    # 收获
```

#### 推进时间
```gdscript
farming_manager.update_farm_day()  # 推进一天
```

#### 获取数据
```gdscript
var plot = farming_manager.get_farm_plot(0)
var health = plot.get_health()
var crop_data = farming_manager.crops_database[plot.current_crop_id]
```

## 信号系统

系统提供以下信号供其他系统监听：

```gdscript
# 在地块上种植了作物
farm_plot_planted(plot_id: int, crop_id: int)

# 收获了作物
farm_plot_harvested(plot_id: int, yield_amount: int)

# 作物生长
crop_grown(plot_id: int, growth_stage: int)

# 季节变化
season_changed(season: String)
```

## 扩展指南

### 添加新作物
编辑`FarmingManager.gd`中的`_initialize_crops_database()`：

```gdscript
crops_database[5] = {
	"name": "玉米",
	"growth_time": 8,
	"base_yield": 3,
	"seasons": ["summer", "autumn"],
	"water_requirement": 2.0,
	"sunlight_requirement": 9,
}
```

### 自定义生长算法
修改`FarmPlot.gd`中的`_calculate_growth_speed()`方法。

### 集成库存系统
收获时的产品可以连接到`InventoryManager`：

```gdscript
func _on_plot_harvested(plot_id: int, yield_amount: int) -> void:
	var item_id = farming_manager.get_farm_plot(plot_id).current_crop_id
	InventoryManager.add_item(item_id, yield_amount)
```

## 性能优化

- 地块更新仅在有作物时执行
- 信号连接支持批量操作
- 可扩展到更大的农田（修改网格大小）

## 已知限制

- 目前为3x3固定网格（可修改`_initialize_farm_plots()`）
- 不包含土壤类型和天气系统（可作为未来扩展）
- UI为基础实现（可根据美术需求优化）

## 集成建议

1. 连接到`GameStateManager`进行日期同步
2. 连接到`InventoryManager`处理收获产品
3. 添加音效和粒子效果
4. 实现自定义UI主题

## 参考资源

基于以下开源项目的最佳实践：
- [godot-farming-prototype](https://github.com/oiblank/godot-farming-prototype)
- [Harvest-Moon-2.0](https://github.com/Kenny-Haworth/Harvest-Moon-2.0)
- [2d-farming-game](https://github.com/gadget-hq/2d-farming-game)
