# 新模块配置说明

## 概述

本次添加了以下新模块：

1. **TitleScreen** - 游戏标题画面/主菜单入口
2. **SettingsMenu** - 设置菜单（音量、显示、游戏选项）
3. **MetaUpgradeMenu** - 局外升级界面
4. **MetaProgressionData** - 局外升级数据定义
5. **MetaProgressionManager** - 局外升级逻辑管理（Autoload）
6. **GameSaveManager** - 游戏存档管理（Autoload）

## 配置步骤

### 1. 添加 Autoload（自动加载）

在 Godot 编辑器中：
1. 打开 **项目 > 项目设置 > 自动加载**
2. 添加以下两个脚本（顺序重要）：

| 路径 | 节点名称 |
|------|----------|
| `res://GameSaveManager.gd` | GameSaveManager |
| `res://MetaProgressionManager.gd` | MetaProgressionManager |

**注意**：GameSaveManager 必须在 MetaProgressionManager 之前加载。

或者直接在 `project.godot` 的 `[autoload]` 部分添加：

```ini
[autoload]
SignalBus="*res://SignalBus.gd"
GameConstants="*res://GameConstants.gd"
GameSaveManager="*res://GameSaveManager.gd"
MetaProgressionManager="*res://MetaProgressionManager.gd"
```

### 2. 修改游戏入口场景

在 Godot 编辑器中：
1. 打开 **项目 > 项目设置 > 应用程序 > 运行**
2. 将 **主场景** 改为 `res://TitleScreen.tscn`

或者在 `project.godot` 中修改：

```ini
[application]
run/main_scene="res://TitleScreen.tscn"
```

## 新增文件清单

### 脚本文件 (.gd)
- `TitleScreen.gd` - 标题画面逻辑
- `SettingsMenu.gd` - 设置菜单逻辑
- `MetaUpgradeMenu.gd` - 局外升级界面逻辑
- `MetaProgressionData.gd` - 局外升级数据定义
- `MetaProgressionManager.gd` - 局外升级管理器（Autoload）
- `GameSaveManager.gd` - 存档管理器（Autoload）

### 场景文件 (.tscn)
- `TitleScreen.tscn` - 标题画面场景
- `SettingsMenu.tscn` - 设置菜单场景
- `MetaUpgradeMenu.tscn` - 局外升级界面场景

## 功能说明

### 标题画面 (TitleScreen)
- 显示游戏标题
- 提供四个菜单选项：开始游戏、局外升级、设置、退出
- 支持键盘导航（上下键 + 回车）

### 设置菜单 (SettingsMenu)
- 音频设置：主音量、背景音乐、音效
- 显示设置：全屏模式、垂直同步
- 游戏设置：屏幕震动、伤害数字显示
- 设置会自动保存到存档文件

### 局外升级系统 (Meta Progression)

#### 货币系统
- **灵魂碎片**：每局游戏结束后根据表现获得
  - 存活时间奖励
  - 击杀数奖励
  - Boss击败奖励
  - 等级奖励
  - 胜利奖励

#### 升级类别
1. **基础属性** (绿色)
   - 生命上限、生命回复、移动速度、拾取范围

2. **攻击属性** (红色)
   - 攻击力、攻击速度、暴击率、暴击伤害、弹幕数量、弹幕速度

3. **防御属性** (蓝色)
   - 护甲、闪避率、无敌时间

4. **辅助属性** (黄色)
   - 经验加成、金币加成、幸运、冷却缩减、范围、持续时间

5. **特殊解锁** (紫色)
   - 复活、初始武器、重选次数、禁选次数、跳过奖励

### 存档系统 (GameSaveManager)
- 自动保存到 `user://touhou_phantom_save.dat`
- 保存内容：
  - 局外货币和升级等级
  - 游戏设置
  - 游戏统计（总游戏次数、击杀数、最高等级等）
  - 解锁内容

## 集成说明

### 在游戏中应用局外升级加成

在 `Player.gd` 或角色初始化时，可以调用：

```gdscript
# 获取应用了局外升级的属性
var modified_stats = MetaProgressionManager.apply_bonuses_to_stats(base_stats)
```

### 游戏结束时发放奖励

在游戏结束逻辑中调用：

```gdscript
var run_stats = {
    "survival_time": survival_time,
    "kills": total_kills,
    "bosses_defeated": boss_kills,
    "level_reached": player_level,
    "won": victory
}
var reward = MetaProgressionManager.end_run(victory, character_id, run_stats)
```

## 游戏流程

```
TitleScreen（标题画面）
    ├── 开始游戏 → MainMenu（角色选择）→ world（游戏）
    ├── 局外升级 → MetaUpgradeMenu
    ├── 设置 → SettingsMenu
    └── 退出游戏
```
