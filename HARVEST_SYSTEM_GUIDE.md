# 采集系统使用指南 (Harvest System Guide)

本指南介绍如何在游戏中创建和使用可采集的环境物体（花、竹笋、矿石等）。

## 📋 系统概述

采集系统允许玩家在游戏世界中收集各种材料，包括：
- 🌸 **植物类**：花朵、竹笋、草药、蘑菇
- ⛏️ **矿物类**：石头、铁矿石、魔法水晶
- ✨ **稀有材料**：稀有花朵、金色竹子

## 🏗️ 核心组件

### 1. Harvestable.gd（可采集物体基类）
**路径**: `scripts/components/Harvestable.gd`

**主要功能**:
- ✅ 自动检测玩家靠近
- ✅ 显示交互提示（[E] 采集）
- ✅ 采集动画和音效
- ✅ 自动添加物品到背包
- ✅ 漂浮文字反馈
- ✅ 重生系统
- ✅ 工具需求检测（可选）

**可配置属性**:
```gdscript
@export var item_id: String = "flower"  # 物品ID
@export var harvest_amount_min: int = 1  # 最小采集数量
@export var harvest_amount_max: int = 3  # 最大采集数量
@export var respawn_time: float = 30.0  # 重生时间（秒）
@export var require_tool: String = ""  # 需要的工具
```

### 2. ItemData.gd（物品数据库）
已添加以下可采集物品：

#### 植物类
- `flower` - 花朵（5金）
- `bamboo_shoot` - 竹笋（15金）
- `herb` - 草药（20金）
- `mushroom` - 蘑菇（12金）

#### 矿物类
- `stone` - 石头（3金）
- `bamboo` - 竹子（10金）
- `iron_ore` - 铁矿石（50金）
- `magic_crystal` - 魔法水晶（100金）

#### 稀有材料
- `rare_flower` - 稀有花朵（80金）
- `golden_bamboo` - 金色竹子（200金）

---

## 🎮 创建可采集物体

### 方法 1: 在 Godot 编辑器中创建

#### 步骤 1: 创建基础场景
1. 新建场景，选择 `Area2D` 作为根节点
2. 重命名为物体名称（如 `Flower`）

#### 步骤 2: 添加子节点
1. **Sprite2D** - 显示物体外观
   - 设置纹理（如 `res://assets/items/flower.png`）
   - 调整 `scale` 和 `position`

2. **CollisionShape2D** - 检测玩家靠近
   - 添加 `CircleShape2D` 或 `RectangleShape2D`
   - 设置合适的半径/大小（建议 30-50）

3. **Label** (可选) - 交互提示
   - 命名为 `InteractionLabel`
   - 设置文本为 `[E] 采集`
   - 调整位置到物体上方
   - 在 `Visibility → Modulate` 中设置颜色

#### 步骤 3: 附加脚本
1. 选中根节点 `Area2D`
2. 附加脚本 `scripts/components/Harvestable.gd`
3. 在 Inspector 中配置导出属性：
   ```
   Item Id: flower
   Harvest Amount Min: 1
   Harvest Amount Max: 2
   Respawn Time: 30.0
   Require Tool: (留空或填写工具ID)
   Sprite Normal: (选择正常纹理)
   Sprite Harvested: (可选，采集后纹理)
   Harvest Sound: (可选，音效)
   ```

#### 步骤 4: 保存场景
- 保存为 `scenes/harvestables/Flower.tscn`
- 可重复使用，实例化到各个场景中

---

### 方法 2: 通过代码创建（动态生成）

```gdscript
# 在场景脚本中动态创建采集物体
func create_flower(position: Vector2):
    # 加载场景
    var flower_scene = load("res://scenes/harvestables/Flower.tscn")
    var flower = flower_scene.instantiate()

    # 设置位置
    flower.global_position = position

    # 添加到场景
    add_child(flower)

    return flower
```

---

## 📦 预制场景示例

### 花朵 (Flower.tscn)
```
Flower (Area2D) [Harvestable.gd]
├── Sprite2D
│   └── texture: res://assets/items/flower.png
│   └── scale: (0.5, 0.5)
├── CollisionShape2D
│   └── shape: CircleShape2D (radius: 40)
└── InteractionLabel (Label)
    └── text: "[E] 采集"
    └── position: (0, -50)
    └── horizontal_alignment: Center

配置:
- item_id: "flower"
- harvest_amount_min: 1
- harvest_amount_max: 2
- respawn_time: 30.0
```

### 竹笋 (BambooShoot.tscn)
```
BambooShoot (Area2D) [Harvestable.gd]
├── Sprite2D
│   └── texture: res://assets/items/bamboo_shoot.png
│   └── scale: (0.6, 0.6)
├── CollisionShape2D
│   └── shape: CircleShape2D (radius: 35)
└── InteractionLabel (Label)

配置:
- item_id: "bamboo_shoot"
- harvest_amount_min: 1
- harvest_amount_max: 1
- respawn_time: 45.0
```

### 铁矿石 (IronOre.tscn)
```
IronOre (Area2D) [Harvestable.gd]
├── Sprite2D
│   └── texture: res://assets/items/iron_ore.png
├── CollisionShape2D
│   └── shape: RectangleShape2D
└── InteractionLabel (Label)

配置:
- item_id: "iron_ore"
- harvest_amount_min: 1
- harvest_amount_max: 3
- respawn_time: 120.0  # 2分钟
- require_tool: "pickaxe"  # 需要镐子
```

---

## 🗺️ 在场景中放置可采集物体

### 在 Town.tscn 中放置
1. 打开 `scenes/overworld/town/Town.tscn`
2. 右键点击场景树 → **Instantiate Child Scene**
3. 选择 `scenes/harvestables/Flower.tscn`
4. 调整位置到合适的地方
5. 重复步骤创建多个实例

### 批量放置
可以在 Town.gd 中动态生成：

```gdscript
# Town.gd
func _spawn_harvestables():
    # 在城镇随机位置生成花朵
    for i in range(10):
        var pos = Vector2(
            randf_range(100, 1000),
            randf_range(100, 1000)
        )
        _create_flower(pos)

func _create_flower(pos: Vector2):
    var flower_scene = load("res://scenes/harvestables/Flower.tscn")
    var flower = flower_scene.instantiate()
    flower.global_position = pos
    add_child(flower)
```

---

## 🎨 视觉和音效

### 推荐的资源
- **纹理尺寸**: 32x32 或 64x64 像素
- **格式**: PNG（透明背景）
- **音效格式**: WAV 或 OGG
- **音效时长**: 0.2-0.5 秒

### 采集动画
Harvestable 自带以下动画：
1. **采集动画**: 缩小 + 淡出（0.2秒）
2. **重生动画**: 放大 + 淡入（0.5秒，弹性效果）
3. **漂浮文字**: 绿色文字向上漂浮

### 自定义动画
可以覆盖 `_play_harvest_animation()` 方法：

```gdscript
# 继承 Harvestable 并覆盖动画
extends Harvestable

func _play_harvest_animation():
    # 自定义动画
    var tween = create_tween()
    tween.tween_property(sprite, "rotation", PI * 2, 0.5)
    tween.parallel().tween_property(sprite, "scale", Vector2.ZERO, 0.5)
```

---

## 🔧 高级功能

### 1. 工具需求系统
某些物体需要特定工具才能采集：

```gdscript
# 配置
require_tool = "pickaxe"  # 需要镐子采集矿石
```

**实现工具检测**��TODO）:
```gdscript
# 在 Player.gd 中添加
func has_tool(tool_id: String) -> bool:
    return InventoryManager.has_item(tool_id)
```

### 2. 稀有度系统
根据物品稀有度调整颜色：

```gdscript
# 在 Harvestable._ready() 中
var item_data = ItemData.get_item(item_id)
var rarity = item_data.get("rarity", "common")

match rarity:
    "common":
        sprite.modulate = Color.WHITE
    "uncommon":
        sprite.modulate = Color(0.5, 1, 0.5)  # 绿色
    "rare":
        sprite.modulate = Color(0.5, 0.5, 1)  # 蓝色
    "epic":
        sprite.modulate = Color(1, 0.5, 1)   # 紫色
```

### 3. 季节系统（进阶）
不同季节出现不同物品：

```gdscript
# 示例
func should_spawn_in_season(season: String) -> bool:
    match item_id:
        "flower":
            return season in ["spring", "summer"]
        "bamboo_shoot":
            return season == "spring"
        _:
            return true
```

---

## 🧪 测试采集系统

### 测试步骤
1. 运行游戏（Town 场景）
2. 走近可采集物体
3. 看到 `[E] 采集` 提示
4. 按 `E` 键采集
5. 查看漂浮文字 "获得 花朵 x2"
6. 按 `I` 键打开背包，确认物���已添加
7. 等待重生时间，物体应重新出现

### 调试技巧
```gdscript
# 在 Harvestable.gd 中启用调试日志
print("[Harvestable] 采集 %s x%d" % [item_id, amount])
print("[Harvestable] 玩家进入范围")
```

---

## 📝 快速创建检查清单

### 创建新的可采集物体
- [ ] 在 ItemData.gd 中定义物品数据
- [ ] 准备物体纹理图片
- [ ] 在 Godot 编辑器中创建场景
- [ ] 添加 Area2D + Sprite2D + CollisionShape2D + Label
- [ ] 附加 Harvestable.gd 脚本
- [ ] 配置导出属性（item_id, amount, respawn_time）
- [ ] 保存场景到 scenes/harvestables/
- [ ] 在地图场景中实例化
- [ ] 测试采集功能

---

## 🎯 示例：完整的花朵采集场景

```
# scenes/harvestables/Flower.tscn 节点结构

Flower (Area2D)
├── Script: res://scripts/components/Harvestable.gd
├── Collision Layer: 8 (Harvestable)
├── Collision Mask: 1 (Player)
│
├── Sprite2D
│   ├── Texture: res://assets/items/flower.png
│   ├── Scale: (0.5, 0.5)
│   └── Z Index: 0
│
├── CollisionShape2D
│   ├── Shape: CircleShape2D
│   └── Radius: 40
│
└── InteractionLabel (Label)
    ├── Text: "[E] 采集"
    ├── Position: (0, -50)
    ├── Horizontal Alignment: Center
    ├── Font Size: 16
    └── Modulate: (1, 1, 1, 0.8)

# Inspector - Harvestable 脚本配置
Item Id: "flower"
Harvest Amount Min: 1
Harvest Amount Max: 2
Respawn Time: 30.0
Require Tool: ""
Sprite Normal: res://assets/items/flower.png
Sprite Harvested: null
Harvest Sound: null
```

---

## 🐛 常见问题

### Q: 采集时没有反应？
A: 检查：
1. 玩家是否在组 `player` 中
2. CollisionShape2D 是否正确设置
3. `item_id` 是否在 ItemData 中定义
4. 控制台是否有错误日志

### Q: 交互提示不显示？
A: 确保：
1. Label 节点命名为 `InteractionLabel`
2. Label 的 `visible` 初始为 false
3. Harvestable 脚本正确附加

### Q: 采集后物品没有添加到背包？
A: 检查：
1. InventoryManager 是否为 Autoload
2. ItemData 中物品定义是否正确
3. 控制台日志确认采集事件触发

---

**文档版本**: 1.0
**创建日期**: 2026-01-04
**作者**: Claude Code
**相关文件**:
- `scripts/components/Harvestable.gd`
- `scripts/data/ItemData.gd`
- `SignalBus.gd`
