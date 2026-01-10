# 场景和NPC系统 - 使用文档

## 📦 已生成的文件清单

### 场景脚本（5个）
1. `scripts/scenes/BambooHouse.gd` - 竹林小屋
2. `scripts/scenes/VillageCenter.gd` - 人之里中心
3. `scripts/scenes/TempleSchool.gd` - 寺子屋
4. `scripts/scenes/HakureiShrine.gd` - 博丽神社
5. `scripts/scenes/BambooForestDeep.gd` - 竹林深处（隐藏）

### 交互区域脚本（4个）
1. `scripts/systems/home/SleepArea.gd` - 床铺/睡觉
2. `scripts/systems/home/TeaArea.gd` - 茶桌/喝茶
3. `scripts/systems/home/MealArea.gd` - 餐桌/吃饭
4. `scripts/systems/home/StorageArea.gd` - 存储箱

### 系统脚本（2个）
1. `scripts/systems/QuestBoard.gd` - 任务公告板系统
2. `scripts/npcs/NPCBase.gd` - NPC基类

### 更新的文件（1个）
- `scripts/core/autoloads/NPCScheduleManager.gd` - 添加了6个NPC的完整日程

---

## 🗺️ 场景结构和关系

```
场景关系图：

竹林小屋 (BambooHouse.tscn) ⭐主据点
  │
  ├─→ 人之里中心 (VillageCenter.tscn) ⭐社交枢纽
  │     ├─→ 寺子屋 (TempleSchool.tscn)
  │     └─→ 博丽神社 (HakureiShrine.tscn)
  │
  └─→ 竹林深处 (BambooForestDeep.tscn) 🔒隐藏场景
```

---

## 📋 NPC日程总览

### 慧音（keine）
| 时间 | 地点 | 活动 | 可打断 |
|------|------|------|--------|
| 6-8点 | keine_house | 起床 | ✅ |
| 8-12点 | temple_school | 教书 | ❌ |
| 12-13点 | temple_school | 午餐 | ✅ |
| 13-17点 | temple_school | 教书 | ❌ |
| **17-19点** | **town_plaza** | **散步** | ✅ |
| 19-22点 | keine_house | 放松 | ✅ |
| 22-6点 | keine_house | 睡觉 | ❌ |

**在人之里中心出现**：17-19点（散步）

---

### 灵梦（reimu）
| 时间 | 地点 | 活动 | 可打断 |
|------|------|------|--------|
| 7-9点 | hakurei_shrine | 早课 | ✅ |
| 9-12点 | hakurei_shrine | 神社事务 | ❌ |
| 12-14点 | hakurei_shrine | 午餐+茶 | ✅ |
| **14-17点** | **town** | **巡逻** | ✅ |
| 17-20点 | hakurei_shrine | 傍晚事务 | ❌ |
| 20-22点 | hakurei_shrine | 放松 | ✅ |
| 22-7点 | hakurei_shrine | 睡觉 | ❌ |

**在人之里中心出现**：14-17点（巡逻）
**特殊**：人性<20触发退治日程

---

### 魔理沙（marisa）
| 时间 | 地点 | 活动 | 可打断 |
|------|------|------|--------|
| 7-10点 | magic_forest | 魔法研究 | ❌ |
| **10-12点** | **village_center** | **买道具** | ✅ |
| 12-13点 | magic_forest | 午餐 | ✅ |
| 13-15点 | magic_forest | 魔法练习 | ❌ |
| **15-17点** | **village_center** | **闲逛** | ✅ |
| 17-22点 | magic_forest | 深夜研究 | ❌ |
| 22-7点 | magic_forest | 睡觉 | ❌ |

**在人之里中心出现**：10-12点、15-17点

---

### 咲夜（sakuya）
| 时间 | 地点 | 活动 | 可打断 |
|------|------|------|--------|
| 6-9点 | scarlet_mansion | 早间事务 | ❌ |
| **9-11点** | **village_center** | **买菜** | ✅ |
| 11-13点 | scarlet_mansion | 烹饪+午餐 | ❌ |
| 13-20点 | scarlet_mansion | 下午/傍晚事务 | ❌ |
| 20-22点 | scarlet_mansion | 休息 | ✅ |
| 22-6点 | scarlet_mansion | 睡觉 | ❌ |

**在人之里中心出现**：9-11点（买菜）

---

### 恋恋（koishi）
| 时间 | 地点 | 活动 | 可打断 | 条件 |
|------|------|------|--------|------|
| 全天 | village_bridge | 等待 | ✅ | ☔**雨天** |

**特殊NPC**：只在雨天出现在人之里的桥边

---

### 阿求（akyuu）
| 时间 | ���点 | 活动 | 可打断 |
|------|------|------|--------|
| 7-9点 | hieda_house | 起床 | ✅ |
| 9-12点 | hieda_house | 写作 | ❌ |
| 12-13��� | hieda_house | 午餐 | ✅ |
| **13-15点** | **temple_school** | **访问慧音** | ✅ |
| 15-18点 | hieda_house | 写作 | ❌ |
| 18-20点 | hieda_house | 阅读 | ✅ |
| 20-7点 | hieda_house | 睡觉 | ❌ |

**在寺子屋出现**：13-15点（与慧音的羁绊剧情）

---

## 🎬 场景创建指南

### 1. 创建竹��小屋场景

#### 步骤：
1. 在Godot中创建新场景：`scenes/home/BambooHouse.tscn`
2. 根节点：`Node2D`，附加脚本：`scripts/scenes/BambooHouse.gd`
3. 添加子节点：

```
BambooHouse (Node2D)
├── Background (ColorRect或Sprite2D) - 背景
├── Player (CharacterBody2D) - 玩家生成点
├── Interactions (Node2D) - 交互容器
│   ├── SleepArea (Area2D) - 床铺
│   │   ├── CollisionShape2D (CircleShape2D, radius=50)
│   │   └── 附加脚本：SleepArea.gd
│   ├── TeaArea (Area2D) - 茶桌
│   │   ├── CollisionShape2D
│   │   └── 附加脚本：TeaArea.gd
│   ├── MealArea (Area2D) - 餐桌
│   │   ├── CollisionShape2D
│   │   └── 附加脚本：MealArea.gd
│   └── StorageArea (Area2D) - 存储箱
│       ├── CollisionShape2D
│       └── 附加脚本：StorageArea.gd
└── ToVillageCenter (Area2D) - 传送点
    └── CollisionShape2D (RectangleShape2D)
```

#### 位置建议：
- SleepArea: (200, 300)
- TeaArea: (400, 350)
- MealArea: (600, 350)
- StorageArea: (800, 300)
- ToVillageCenter: (960, 1000) - 场景底部

---

### 2. 创建人之里中心场景

#### 步骤：
1. 创建场景：`scenes/overworld/village/VillageCenter.tscn`
2. 根节点：`Node2D`，附加脚本：`scripts/scenes/VillageCenter.gd`
3. 添加子节点：

```
VillageCenter (Node2D)
├── Background (Sprite2D或TileMap) - 街道背景
├── Player (CharacterBody2D)
├── NPCContainer (Node2D) - NPC动态生成容器
├── Facilities (Node2D) - 固定设施
│   ├── Shop (Area2D) - 道具商店
│   └── QuestBoard (Area2D) - 任务公告板
└── Transitions (Node2D) - 传送点容器
    ├── ToBambooHouse (Area2D)
    ├── ToTempleSchool (Area2D)
    └── ToHakureiShrine (Area2D)
```

**关键**：确保有 `NPCContainer` 节点，脚本会在此动态生成NPC

---

### 3. 创建寺子屋场景

#### 步骤：
1. 创建场景：`scenes/overworld/village/TempleSchool.tscn`
2. 根节点：`Node2D`，附加脚本：`scripts/scenes/TempleSchool.gd`
3. 添加子节点：

```
TempleSchool (Node2D)
├── Background (Sprite2D) - 教室背景
├── Player (CharacterBody2D)
├── KeineNPC (继承NPCBase) - 慧音NPC
│   ├── Sprite2D - 慧音立绘
│   └── CollisionShape2D
└── ToVillageCenter (Area2D) - 返回人之里
```

---

### 4. 创建博丽神社���景

类似寺子屋，替换为灵梦NPC。

---

## 🧩 创建NPC预制体

### 示例：慧音NPC

#### 步骤：
1. 创建场景：`scenes/npcs/KeineNPC.tscn`
2. 根节点：`Area2D`，继承：`NPCBase`
3. 设置Inspector属性：
   - `Npc Id`: "keine"
   - `Npc Name`: "上白泽慧音"
   - `Interaction Radius`: 80.0
4. 添加子节点：

```
KeineNPC (Area2D, extends NPCBase)
├── Sprite2D - 慧音立绘
│   ├── Texture: 设置慧音图片
│   └── Scale: (0.5, 0.5) - 根据需要调整
└── CollisionShape2D
    └── Shape: CircleShape2D (radius=40)
```

#### 在场景中使用：
在寺子屋场景中实例化这个预制体，或在VillageCenter的NPCContainer中动态加载。

---

## 🎮 任务公告板使用

### 在VillageCenter中添加任务公告板

1. 创建 `QuestBoard` Area2D节点
2. 附加碰撞形状
3. 添加交互脚本：

```gdscript
# QuestBoardArea.gd
extends Area2D

var player_in_range: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		# 打开任务公告板UI
		var quest_board = get_node("/root/QuestBoard")  # 需要自动加载
		if quest_board:
			quest_board.open_board()
```

---

## 🔧 必须完成的配置

### 1. 修改 project.godot

添加 QuestBoard 自动加载（如果需要全局访问）：

```ini
[autoload]
QuestBoard="*res://scripts/systems/QuestBoard.gd"
```

### 2. 确保输入映射

在 project.godot 中确认有 "interact" 动作（E键）：

```ini
[input]
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
```

---

## 📊 NPC对话示例

### 设置NPC对话内容

在NPC的 `_ready()` 中：

```gdscript
# KeineNPC.gd (继承NPCBase)
extends NPCBase

func _ready():
	super._ready()  # 调用父类

	npc_id = "keine"
	npc_name = "上白泽慧音"

	# 设置对话
	set_dialogue([
		{
			"speaker": "妹红",
			"text": "慧音老师，今天教的是什么内容？"
		},
		{
			"speaker": "慧音",
			"text": "今天在讲幻想乡的历史。你也想听听吗？"
		},
		{
			"speaker": "妹红",
			"text": "好啊，我对历史也很感兴趣。"
		}
	])
```

---

## ✅ 测试清单

### 场景测试
- [ ] 竹林小屋场景可以正常加载
- [ ] 可以在床铺区域按E睡觉
- [ ] 睡觉后时间跳到次日，疲劳清零
- [ ] 可以喝茶、吃饭（显示通知）
- [ ] 传送到人之里中心正常

### NPC测试
- [ ] 在正确时段，NPC出现在人之里中心
- [ ] 可以与NPC对话（按E键）
- [ ] 对话结束后羁绊增加
- [ ] 慧音在8-17点在寺子屋可以找到

### 任务公告板测试
- [ ] 每日任务正确刷新（3个随机任务）
- [ ] 可以接取任务
- [ ] 接取后任务添加到QuestManager

---

## 🎨 美术资源建议

### 场景背景
- 竹林小屋：木制小屋内部，日式风格
- 人之里中心：简单的街道，2-3栋房子立绘即可
- 寺子屋：教室，黑板+桌椅
- 博丽神社：神社庭院，鸟居

### NPC立绘
- 慧音：教师装扮
- 灵梦：巫女服
- 魔理沙：魔法使帽子+围裙
- 咲夜：女仆装
- 恋恋：和服+嫉妒的表情
- 阿求：书卷气

尺寸建议：128x128 或 256x256像素

---

## 🚀 下一步开发

1. ✅ 创建简单的BambooHouse.tscn场景
2. ✅ 测试睡眠循环
3. ✅ 创建VillageCenter.tscn（简化版）
4. 创建至少1个NPC预制体（慧音）
5. 实现简单的对话UI
6. 实现任务公告板UI
7. 测试NPC动态出现/消失

---

**生成时间**: 2026-01-10
**版本**: 2.0.0
**状态**: ✅ 所有核心脚本已完成，等待场景创建和测试
