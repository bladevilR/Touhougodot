# 项目架构重构指南

## 📋 重构概述

本次重构将游戏从 **单场景弹幕 Roguelike** 转型为 **多场景 RPG + Roguelike 混合游戏**（类似符文工房）。

### 核心变化
- ✅ 固定主角为 **藤原妹红**（移除多角色选择系统）
- ✅ 引入 **多场景系统**（城镇、农场、地下城等）
- ✅ 添加 **RPG 标准系统**（背包、任务、存档）
- ✅ **充分解耦** UI 和场景，支持场景切换

---

## 🆕 新增核心系统

### 1. GameStateManager（游戏状态管理器）
**路径**: `scripts/core/GameStateManager.gd`

**职责**:
- 管理游戏模式（菜单、主世界、战斗、对话、过场）
- 区分 RPG 探索模式和 Roguelike 战斗模式
- 维护玩家持久化数据和临时战斗数据

**API 示例**:
```gdscript
# 切换游戏模式
GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

# 进入战斗
GameStateManager.start_combat(dungeon_level = 3)

# 结束战斗
GameStateManager.end_combat(victory = true)

# 检查是否可以移动
if GameStateManager.can_player_move():
    # 处理玩家输入
```

### 2. SceneManager（场景管理器）
**路径**: `scripts/core/SceneManager.gd`

**职责**:
- 处理场景切换（带淡入淡出过渡）
- 管理玩家位置和出生点
- 保存/恢复主世界状态

**API 示例**:
```gdscript
# 切换场景（带过渡动画）
SceneManager.change_scene("town", "spawn_from_farm")

# 进入战斗（保存主世界状态）
SceneManager.enter_combat(dungeon_level = 1)

# 退出战斗（返回主世界）
SceneManager.exit_combat(victory = true)

# 重新加载当前场景
SceneManager.reload_current_scene()
```

### 3. SaveSystem（存档系统）
**路径**: `scripts/core/SaveSystem.gd`

**职责**:
- 手动存档/读档（多槽位）
- 自动保存（5分钟间隔）
- 序列化所有游戏数据

**API 示例**:
```gdscript
# 保存游戏到槽位 1
SaveSystem.save_game(1)

# 加载游戏
SaveSystem.load_game(1)

# 检查存档是否存在
if SaveSystem.has_save(1):
    var info = SaveSystem.get_save_info(1)
    print(info.level, info.play_time)

# 删除存档
SaveSystem.delete_save(1)
```

### 4. InventoryManager（背包管理器）
**路径**: `scripts/core/InventoryManager.gd`

**职责**:
- 管理物品（添加、移除、使用）
- 装备管理（武器、护甲、饰品）
- 物品堆叠和背包容量

**API 示例**:
```gdscript
# 添加物品
InventoryManager.add_item("health_potion_small", 5)

# 移除物品
InventoryManager.remove_item("bamboo", 10)

# 使用物品
InventoryManager.use_item("health_potion_medium")

# 检查物品
if InventoryManager.has_item("magic_crystal", 3):
    print("拥有足够的魔法水晶")

# 监听背包变化
InventoryManager.inventory_changed.connect(func():
    update_inventory_ui()
)
```

### 5. QuestManager（任务管理器）
**路径**: `scripts/core/QuestManager.gd`

**职责**:
- 管理任务状态（未开始、进行中、已完成、失败）
- 自动追踪任务进度
- 发放任务奖励

**API 示例**:
```gdscript
# 开始任务
QuestManager.start_quest("main_001")

# 手动更新进度
QuestManager.update_quest_progress("side_001", 0, 5)  # 目标0 +5进度

# 查询任务
var active_quests = QuestManager.get_active_quests()
var progress = QuestManager.get_quest_progress("main_002")

# 监听任务事件
QuestManager.quest_completed.connect(func(quest_id):
    show_quest_complete_notification(quest_id)
)
```

### 6. ItemData（物品数据库）
**路径**: `scripts/data/ItemData.gd`

**职责**:
- 定义所有物品的属性
- 物品分类（消耗品、装备、材料）

**已定义物品**:
- 治疗药（小、中、大）
- 食物（饭团、烤鱼）
- 装备（木剑、布甲、疾风护符）
- 材料（竹子、铁矿石、魔法水晶）

### 7. QuestData（任务数据库）
**路径**: `scripts/data/QuestData.gd`

**职责**:
- 定义所有任务信息
- 任务分类（主线、支线、每日）

**已定义任务**:
- 主线：`main_001`（初到幻想乡）、`main_002`（初次战斗）、`main_003`（农场之道）
- 支线：`side_001`（收集竹子）、`side_002`（魔法水晶研究）、`side_003`（料理大师）
- 每日：`daily_001`（每日狩猎）、`daily_002`（每日采集）、`daily_003`（地下城探险）

---

## 📁 新的文件夹结构

```
Touhougodot/
├── scenes/
│   ├── player/              # 玩家相关（固定妹红）
│   ├── combat/              # 战斗场景（Roguelike部分）
│   ├── overworld/           # 主世界场景（RPG部分）
│   │   ├── town/           # 城镇
│   │   ├── farm/           # 农场
│   │   └── dungeon_entrance/
│   ├── ui/                  # UI场景
│   │   ├── global/         # 全局UI（背包、任务、菜单）
│   │   └── scene_specific/ # 场景专属UI
│   └── enemies/
│
├── scripts/
│   ├── core/               # 核心管理系统（Autoload）✅ 已创建
│   │   ├── GameStateManager.gd
│   │   ├── SceneManager.gd
│   │   ├── SaveSystem.gd
│   │   ├── InventoryManager.gd
│   │   └── QuestManager.gd
│   ├── data/               # 数据类 ✅ 已创建
│   │   ├── ItemData.gd
│   │   └── QuestData.gd
│   └── components/         # 可复用组件
│
├── resources/              # Godot Resource 定义
│   ├── items/
│   └── quests/
│
└── assets/                 # 美术资源（保持不变）
```

---

## 🔧 后续重构步骤

### 第一阶段：UI 解耦（高优先级）

#### 1. 创建全局 UI
**需要创建的 UI**:
- `GlobalUI.tscn` - 包含所有全局 UI 容器
  - InventoryUI（背包界面，I 键）
  - QuestUI（任务日志，J 键）
  - PauseMenu（暂停菜单，ESC 键）
  - SaveLoadMenu（存档/读档界面）

**实现步骤**:
```gdscript
# 在 SceneManager 中添加全局 UI 层
var global_ui_layer: CanvasLayer

func _ready():
    _create_global_ui()

func _create_global_ui():
    global_ui_layer = CanvasLayer.new()
    global_ui_layer.layer = 100  # 最顶层
    get_tree().root.add_child(global_ui_layer)

    # 加载全局 UI
    var global_ui = load("res://scenes/ui/global/GlobalUI.tscn").instantiate()
    global_ui_layer.add_child(global_ui)
```

#### 2. 从 MapSystem 解耦游戏逻辑
**当前问题**: MapSystem 同时负责地图渲染和游戏逻辑

**解决方案**:
- 创建 `CombatArena.tscn` 作为战斗场景根节点
- MapSystem 只负责地图渲染
- 将 EnemySpawner、ExperienceManager 等移到 CombatArena

**重构示例**:
```
# 当前结构（耦合）
World (Node2D)
├── MapSystem          # 地图 + 游戏逻辑混在一起
├── Player
├── EnemySpawner
└── ExperienceManager

# 目标结构（解耦）
CombatArena (Node2D)
├── MapRenderer        # 纯地图渲染
├── Player
├── CombatManager      # 战斗逻辑
│   ├── EnemySpawner
│   ├── WaveManager
│   └── RoomManager
└── LootManager
    └── ExperienceManager
```

### 第二阶段：移除多角色系统

#### 1. 固定妹红为主角
**需要修改的文件**:
- `TitleScreen.tscn` - 移除角色选择界面
- `Player.gd` - 移除 `CharacterData.get_character()` 的动态加载
- `SignalBus.gd` - 移除 `character_selected` 信号

**重构步骤**:
```gdscript
# Player.gd - 移除动态角色
# 删除：
var character_data = CharacterData.get_character(SignalBus.selected_character_id)

# 改为：
const CHARACTER_DATA = {
    "id": GameConstants.CharacterId.MOKOU,
    "name": "藤原妹红",
    "max_hp": 100,
    "speed": 300,
    # ... 妹红的固定属性
}
```

#### 2. 简化 CharacterData.gd
保留妹红的数据，但作为常量而非动态查询：
```gdscript
# CharacterData.gd
const MOKOU = {
    "name": "藤原妹红",
    "max_hp": 100,
    "speed": 300,
    "base_damage": 10,
    # ...
}
```

### 第三阶段：创建场景

#### 1. 城镇场景（Town.tscn）
**包含**:
- TileMap（城镇地图）
- NPC 节点（灵梦、魔理沙等）
- 传送点（前往农场、地下城入口）
- 商店、道具店

#### 2. 农场场景（Farm.tscn）
**包含**:
- 农田系统（种植、收获）
- 家园建筑
- 动物饲养

#### 3. 地下城入口（DungeonEntrance.tscn）
**包含**:
- 难度选择界面
- 进入战斗的传送门

#### 4. 战斗场景（CombatArena.tscn）
**重构自当前的 world.tscn**:
- 保留战斗核心逻辑
- 移除 RPG 元素
- 添加战斗结束后返回主世界

---

## 🎮 游戏流程示例

### 典型玩家流程
```
1. 启动游戏 → TitleScreen.tscn
   ↓
2. 新游戏/继续游戏 → Town.tscn（城镇）
   ↓
3. 在城镇中：
   - 接任务（与 NPC 对话）
   - 购买物品（商店）
   - 查看背包/任务日志（按 I/J 键）
   ↓
4. 前往地下城入口 → DungeonEntrance.tscn
   ↓
5. 进入战斗 → CombatArena.tscn（Roguelike 战斗）
   - 保存主世界状态
   - 临时战斗数据生效
   ↓
6. 战斗结束：
   - 胜利：获得奖励，返回城镇
   - 失败：返回城镇
   ↓
7. 返回城镇 → Town.tscn
   - 恢复主世界状态
   - 提交任务
   - 继续探索
```

---

## 🔌 信号系统扩展

### 新增信号（添加到 SignalBus.gd）
```gdscript
# 场景切换信号
signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_finished()

# 背包信号
signal inventory_opened()
signal inventory_closed()

# 任务信号
signal quest_log_opened()
signal quest_log_closed()

# 对话信号
signal dialogue_line_displayed(npc_name: String, text: String)

# NPC 交互信号
signal npc_interaction_started(npc_id: String)
signal npc_interaction_ended()
```

---

## ⚠️ 注意事项

### 1. 兼容性问题
**现有存档**: 旧的 GameSaveManager 与新的 SaveSystem 不兼容
**解决方案**:
- 保留 GameSaveManager 用于元进度（局外升级）
- SaveSystem 处理游戏内存档
- 可选：编写迁移脚本

### 2. 性能考虑
**场景切换**: 使用 `change_scene_to_file()` 会卸载旧场景
**全局 UI**: CanvasLayer 常驻内存，注意释放不用的节点

### 3. 开发建议
- **逐步迁移**: 不要一次性删除所有旧代码
- **保留备份**: 使用 Git 分支管理重构
- **测试驱动**: 每完成一个系统就测试

---

## 📝 快速开始检查清单

### 已完成 ✅
- [x] 创建核心管理系统（GameStateManager, SceneManager, SaveSystem, InventoryManager, QuestManager）
- [x] 创建数据类（ItemData, QuestData）
- [x] 配置 Autoload
- [x] 创建文件夹结构
- [x] **重构 Player.gd - 固定妹红为主角**
- [x] **重构 SignalBus.gd - 移除多角色相关信号，添加 RPG 系统信号**
- [x] **重构 GameConstants.gd - 简化角色枚举**
- [x] **创建 InventoryUI.gd - 背包界面逻辑脚本**
- [x] **创建 QuestUI.gd - 任务日志界面逻辑脚本**
- [x] **创建 GlobalUIManager.gd - 全局UI输入管理器（Autoload）**
- [x] **添加输入映射 - I键打开背包，J键打开任务日志**

### 进行中 🔄
- [ ] 创建 GlobalUI.tscn - 全局 UI 容器场景（可选，已通过 GlobalUIManager 实现）

### 待完成 ⏳
- [ ] 重构 TitleScreen.tscn - 移除角色选择界面，直接开始游戏
- [ ] 创建城镇场景（Town.tscn）- 第一个主世界场景
- [ ] 创建农场场景（Farm.tscn）
- [ ] 创建地下城入口场景（DungeonEntrance.tscn）
- [ ] 重构战斗场景（CombatArena.tscn）- 从 world.tscn 改造
- [ ] 测试场景切换流程
- [ ] 测试存档/读档功能
- [ ] 测试背包和任务系统

---

## 🎯 下一步行动（按优先级排序）

### 立即可做（核心系统已就绪）

1. **完成 QuestUI.gd** - 参考 InventoryUI.gd 创建任务日志界面
   - 路径：`scripts/core/QuestUI.gd`
   - 显示活动任务列表
   - 显示任务目标进度
   - 任务完成提示

2. **创建 GlobalUI.tscn** - 全局 UI 容器
   - 在 Godot 编辑器中创建 CanvasLayer 场景
   - 添加 InventoryUI 和 QuestUI 节点
   - 配置输入处理（I键、J键）
   - 在 SceneManager._ready() 中加载

3. **简化 TitleScreen.tscn**
   - 移除角色选择面板
   - 直接"新游戏"/"继续游戏"按钮
   - 新游戏 → 调用 `SceneManager.change_scene("town")`

### 中期任务（场景系统）

4. **创建第一个主世界场景 Town.tscn**
   - 添加 TileMap（城镇地图）
   - 添加 Player 节点
   - 添加传送点（前往农场、地下城）
   - 测试场景切换

5. **重构战斗场景 CombatArena.tscn**
   - 复制 world.tscn 并重命名
   - 移除主世界相关元素
   - 确保 Roguelike 战斗逻辑完整

### 长期任务（内容填充）

6. **创建农场场景 Farm.tscn**
7. **创建地下城入口 DungeonEntrance.tscn**
8. **实现场景切换流程测试**
9. **实现存档/读档测试**

---

## 📋 重要代码位置速查

| 系统 | 文件路径 | 说明 |
|------|---------|------|
| 游戏状态管理 | `scripts/core/GameStateManager.gd` | 管理 RPG/战斗模式切换 |
| 场景管理 | `scripts/core/SceneManager.gd` | 场景切换、过渡动画 |
| 存档系统 | `scripts/core/SaveSystem.gd` | 自动/手动存档 |
| 背包系统 | `scripts/core/InventoryManager.gd` | 物品管理 |
| 任务系统 | `scripts/core/QuestManager.gd` | 任务追踪 |
| 物品数据 | `scripts/data/ItemData.gd` | 所有物品定义 |
| 任务数据 | `scripts/data/QuestData.gd` | 所有任务定义 |
| 背包 UI | `scripts/core/InventoryUI.gd` | 背包界面逻辑 |
| 玩家控制器 | `Player.gd` | 固定妹红为主角 |
| 信号总线 | `SignalBus.gd` | 全局事件系统 |

---

**文档版本**: 1.2
**创建日期**: 2026-01-04
**最后更新**: 2026-01-04 (完成 QuestUI + GlobalUIManager + 全局输入系统)
**作者**: Claude Code
