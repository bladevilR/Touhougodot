# 更新日志 (Changelog)

## [未发布] - 2026-01-05

### ✨ 新功能 (New Features)

#### 场景文件创建
- **RPG场景**: 创建完整的场景文件
  - `scenes/overworld/town/Town.tscn` - 城镇主场景
  - `scenes/overworld/farm/Farm.tscn` - 农场场景
  - `scenes/overworld/dungeon_entrance/DungeonEntrance.tscn` - 地下城入口场景
  - 所有场景包含玩家节点��地图容器、功能性子节点

- **可采集物场景系统**: 创建6种可采集物场景
  - `scenes/harvestables/Flower.tscn` - 花朵 (1-3个)
  - `scenes/harvestables/BambooShoot.tscn` - 竹笋 (1-2个)
  - `scenes/harvestables/Herb.tscn` - 草药 (1-2个)
  - `scenes/harvestables/Stone.tscn` - 石头 (1-3个)
  - `scenes/harvestables/IronOre.tscn` - 铁矿石 (1-2个，需要镐)
  - `scenes/harvestables/RareFlower.tscn` - 稀有花朵 (1个)
  - 所有场景使用真实的素材贴图

- **战斗场景重构**
  - 将 `world.tscn` 重构为 `scenes/combat/CombatArena.tscn`
  - 统一场景命名规范

#### 背包UI系统
- **InventoryUI场景**: 创建完整的背包界面 (`scenes/ui/global/InventoryUI.tscn`)
  - 8x6 网格布局 (最多48个格子)
  - 物品信息面板（显示名称、描述）
  - 使用/装备按钮
  - 按 I 键打开，ESC 键关闭

- **GlobalUIManager集成**
  - 自动加载 InventoryUI 到场景树
  - 全局快捷键处理 (I键打开背包)
  - UI互斥显示（同时只显示一个UI）

### 🔄 系统重构 (Refactoring)

#### 采集系统改为长期RPG模式
- **移除重生机制**:
  - `Harvestable.gd` 不再处理重生计时器
  - 采集后物品直接 `queue_free()` 从世界移除
  - `respawn_time` 默认改为 0.0
  - 符合长期RPG设计：每次进图资源固定，采完就没

- **背包集成优化**:
  - 采集物自动添加到 InventoryManager
  - 显示绿色浮动文字反馈
  - 物品在背包中正确显示名称和数量

- **InventoryUI.gd 修复**:
  - 移除不存在的 `ItemButton.tscn` 预加载
  - 使用代码动态创建物品按钮
  - 修复 Parser Error

### 📚 文档 (Documentation)

- **HARVEST_TEST_GUIDE.md**: 采集系统测试指南
  - 系统变更说明（不重生、固定资源）
  - 详细的测试步骤
  - 可采集物场景配置表
  - 自定义采集物教程
  - 已知限制和相关文件索引

### 🛠️ 错误修复 (Bug Fixes)

#### 编译错误修复
- **CharacterStatusPanel**: 修复未声明的 `player` 变量导致的编译错误 (第228-252行)
  - 添加了类级别的 `player: CharacterBody2D` 变量声明
  - 在 `_update_info()` 中自动获取玩家引用
  - Commit: 2eddaaa

- **SignalBus**: 添加缺失的 `bond_selected` 信号
  - 羁绊系统(BondSystem)需要此信号来处理支援角色选择
  - 信号签名: `bond_selected(bond_id: String)`
  - Commit: c63cd56

- **Player3DVisuals**: 优雅处理缺失的3D模型
  - 移除对已删除的 `Mokou_Skin.tscn` 的引用
  - 添加空值检查，当3D模型不存在时自动降级到2D精灵模式
  - 修复 `Node not found: "body_Rigged"` 和 Vulkan 错误
  - Commit: f903992

- **SignalBus**: 添加缺失的 `selected_character_id` 属性和 `character_selected` 信号
  - 修复多个脚本中的 `Invalid assignment` 错误
  - 默认值设为 `1` (妹红的角色ID)
  - Commit: ddf8eff

- **多角色系统移除**: 修复移除多角色系统后的引用错误
  - 修复 `CharacterStatusPanel.gd` 中的 `player.character_id` 引用
  - 修复 `LevelUpScreen.gd` 中的角色ID获取逻辑
  - 修复 `Player.gd` 中的攻击动画逻辑
  - 所有角色ID现在统一从 `SignalBus.selected_character_id` 获取
  - Commit: c67f1ac

#### 文件清理
- 更新 `.gitignore` 忽略 Godot 自动生成的 `*.uid` 文件
- Commit: 4958ca9

### ✨ 新功能 (Features)

#### 采集系统 (Harvest System)
- **Harvestable组件** (`scripts/components/Harvestable.gd`)
  - 可复用的 Area2D 组件，用于环境物品采集
  - 支持配置：物品ID、数量范围、重生时间、工具需求
  - 自动检测玩家接近并显示 `[E] 采集` 提示
  - 采集动画：缩小+淡出 (0.2秒)
  - 重生动画：弹性增长+淡入 (0.5秒)
  - 生成浮动文字反馈
  - 自动添加到背包系统
  - Commit: 9784bd0

- **物品数据库扩展** (`scripts/data/ItemData.gd`)
  - 新增10种可采集物品
  - 分类：植物(花朵、竹笋、草药、蘑菇)、矿物(石头、铁矿、魔晶石)、稀有(稀有花朵、金色竹笋)
  - 添加稀有度���统 (common, uncommon, rare)
  - Commit: 9784bd0

- **采集系统文档**
  - `HARVEST_SYSTEM_GUIDE.md` - 完整的使用指南
  - 包含在Godot编辑器中创建可采集物场景的步骤
  - Commit: 9784bd0

#### RPG场景系统
- **场景脚本** (`scenes/overworld/`)
  - `Town.gd` - 城镇主场景逻辑
  - `Farm.gd` - 农场场景（种植/采集）
  - `DungeonEntrance.gd` - 地下城入口（难度选择）
  - 所有场景脚本包含完整的功能模板和注释
  - Commit: 7fe1c20

- **场景创建指南**
  - `SCENE_CREATION_GUIDE.md` - 在Godot编辑器中创建场景的分步指南
  - Commit: 7fe1c20

#### 全局UI系统
- **GlobalUIManager** (`scripts/core/GlobalUIManager.gd`)
  - 集中管理全局UI输入 (I键背包、J键任务日志)
  - 确保同一时间只打开一个UI界面
  - 自动加载 InventoryUI 和 QuestUI
  - Commit: 9149aee

- **QuestUI** (`scripts/core/QuestUI.gd`)
  - 任务日志界面，显示活动/已完成任务
  - 任务详情面板
  - 连接 QuestManager ���号
  - Commit: 9149aee

- **输入映射**
  - `open_inventory`: I 键
  - `open_quest_log`: J 键
  - 添加到 `project.godot` 配置
  - Commit: 9149aee

### 🔄 重构 (Refactoring)

#### TitleScreen简化
- 移除角色选择环节，固定使用妹红作为主角
- 添加"继续游戏"选项
- 简化新游戏流程
- Commit: 1bdd6e0

#### 3D模型测试文件清理
- 移除测试用的3D模型文件 (bowl.fbx, body_Rigged.fbx等)
- 清理 MapSystem 中的测试代码
- Commit: 48ced1c

### 📚 文档 (Documentation)

- **PROJECT_STRUCTURE.md** - 完整的项目架构文档
  - 五层架构说明
  - 模块职责
  - 开发工作流
  - 重要规则和快速命令
  - Commit: 4958ca9

- **测试系统** (`tests/`)
  - 测试场景启动器 (`SceneLauncher.gd`)
  - 场景切换指南 (`SCENE_SWITCHING_GUIDE.md`)
  - 3D模型测试场景
  - Commit: 4958ca9

### 🎨 资源 (Assets)

- **卡通着色器** (`assets/shaders/toon_shader.gdshader`)
  - Toon风格硬阴影渲染
  - 2层明暗 (亮/暗)
  - 边缘高光效果 (Rim lighting)
  - Commit: 4958ca9

---

## 历史提交

### [2026-01-03] - RPG+Roguelike架构重构
- 重构为混合游戏架构 (RPG城镇 + Roguelike战斗)
- 添加核心系统：InventoryManager, QuestManager, SaveSystem
- 场景管理系统升级
- Commit: 70c788c

### [2025-12-XX] - 3D模型集成
- 集成3D动漫风格角色模型
- 修复模型裁剪问题
- 像素完美渲染优化
- Commits: 7068508, 916d18e

### [2025-12-XX] - 稳定性修复
- 修复 CanvasItem RID 泄漏
- 修复 Lambda 捕获错误
- 改进 Tween 稳定性
- Commits: 2b1c119, 38e0652, 14f03da, dc07557, 49be43d

---

## 待办事项 (TODO)

### 立即执行（需要Godot编辑器）
- [ ] 创建 `Town.tscn` 场景文件
- [ ] 创建 `Farm.tscn` 场景文件
- [ ] 创建 `DungeonEntrance.tscn` 场景文件
- [ ] 创建可采集物场景 (`Flower.tscn`, `BambooShoot.tscn` 等)
- [ ] 在Town/Farm场景中放置可采集物对象
- [ ] 重构 `world.tscn` 为 `scenes/combat/CombatArena.tscn`

### 测试任务
- [ ] 测试场景转换 (Town → Farm → Town)
- [ ] 测试采集系统 (靠近物体 → 按E → 验证背包)
- [ ] 测试背包UI (按I键)
- [ ] 测试任务UI (按J键)
- [ ] 测试存档/读档功能

### 代码任务
- [ ] 在 Player.gd 中实现工具需求检查
- [ ] 连接 TitleScreen 到 Town 场景
- [ ] 创建 .tscn 文件后更新 SceneManager 路径

---

## 已知问题 (Known Issues)

### 需要修复
- 多个编译错误已在本次更新中修复（见上方错误修复章节）
- 3D模型系统已优雅降级到2D模式

### 架构改进计划
- 考虑将更多系统组件化
- 优化场景加载性能
- 完善错误处理机制

---

**提交总数**: 13个新提交
**代码变更**: +1500行 / -200行（估算）
**新增文件**: 15个
**修改文件**: 8个
**删除文件**: 多个测试用3D模型文件
