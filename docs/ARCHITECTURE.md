# 项目架构文档

## 📁 目录结构

```
touhou-godot/
├── assets/                      # 美术资源（纹理、音频、字体等）
├── scenes/                      # 场景文件
│   ├── combat/                  # 战斗场景
│   └── overworld/               # 主世界场景
│       ├── town/
│       ├── farm/
│       └── dungeon_entrance/
│
├── scripts/                     # 脚本目录
│   ├── core/                    # 核心系统
│   │   ├── managers/            # 管理器类
│   │   │   └── GameplaySystem.gd
│   │   ├── autoloads/           # 全局服务（autoload）
│   │   │   ├── ServiceLocator.gd
│   │   │   ├── ResourceManager.gd
│   │   │   ├── SceneManager.gd（统一场景管理器）
│   │   │   ├── AudioManager.gd
│   │   │   └── Logger.gd -> GameLogger.gd
│   │   ├── GameStateManager.gd
│   │   ├── InventoryManager.gd
│   │   ├── QuestManager.gd
│   │   └── SaveSystem.gd
│   │
│   ├── gameplay/                # 游戏逻辑
│   │   ├── combat/              # 战斗系统
│   │   │   ├── player/
│   │   │   ├── enemies/
│   │   │   │   ├── EnemyAIHelper.gd（AI辅助类）
│   │   │   │   └── BossAttackPatterns.gd（Boss攻击模式库）
│   │   │   ├── weapons/
│   │   │   │   └── BulletFactory.gd（弹幕工厂）
│   │   │   └── effects/
│   │   │       ├── CameraShake.gd
│   │   │       ├── DamageNumberManager.gd
│   │   │       └── DeathParticleManager.gd
│   │   │
│   │   ├── dungeons/            # 地牢系统
│   │   │   ├── RoomManager.gd
│   │   │   ├── RoomLayoutManager.gd
│   │   │   ├── RoomLayoutGenerator.gd
│   │   │   ├── MapSystem.gd
│   │   │   ├── RoomMapCanvas.gd
│   │   │   └── WaveManager.gd
│   │   │
│   │   ├── overworld/           # 主世界���统
│   │   │   ├── shops/
│   │   │   ├── npcs/
│   │   │   └── farming/
│   │   │       ├── FarmingManager.gd
│   │   │       ├── FarmPlot.gd
│   │   │       ├── FarmingUI.gd
│   │   │       └── FarmingIntegration.gd
│   │   │
│   │   └── progression/         # 进度系统
│   │       ├── experience/
│   │       │   └── ExperienceManager.gd
│   │       ├── bonds/
│   │       ├── meta/
│   │       │   └── MetaProgressionManager.gd
│   │       └── quest/
│   │
│   ├── components/              # 可复用组件
│   │   ├── Harvestable.gd
│   │   ├── PunchSystem.gd
│   │   └── StatusEffectComponent.gd
│   │
│   ├── data/                    # 数据定义
│   │   ├── BondData.gd
│   │   ├── CharacterData.gd
│   │   ├── ElementData.gd
│   │   ├── EnemyData.gd
│   │   ├── WeaponData.gd
│   │   ├── ItemData.gd
│   │   ├── QuestData.gd
│   │   ├── MetaProgressionData.gd
│   │   ├── GameConstants.gd
│   │   ├── GameSettings.gd
│   │   └── SkillDatabase.gd（技能数据库）
│   │
│   ├── ui/                      # UI控制器
│   │   ├── menus/
│   │   │   ├── PauseMenu.gd
│   │   │   └── SettingsMenu.gd
│   │   ├── gameplay/
│   │   │   ├── CharacterStatusPanel.gd
│   │   │   └── DialoguePortrait.gd
│   │   └── screens/
│   │
│   ├── utils/                   # 工具类
│   │   └── DebugChecker.gd
│   │
│   └── systems/                 # 其他系统
│       └── farming/
│
├── entities/                    # 实体组件系统
│   └── components/
│       ├── GameComponent.gd
│       ├── MovementComponent.gd
│       ├── SpriteComponent.gd
│       └── ShadowComponent.gd
│
├── core/                        # 核心管理器（遗留）
│   ├── autoloads/               # Autoload服务
│   └── managers/
│
├── 根目录 .gd 文件              # 核心游戏逻辑（被.tscn引用）
│   ├── Player.gd（71KB - 玩家控制器）
│   ├── Enemy.gd（57KB - 敌人AI）
│   ├── Bullet.gd（41KB - 弹幕系统）
│   ├── GameUI.gd（36KB - 主HUD）
│   ├── CharacterSkills.gd（32KB - 技能系统）
│   └── ... 其他被.tscn引用的文件
│
└── project.godot                # 项目配置
```

## 🔧 架构模式

### 1. Signal-Driven Architecture（信号驱动）
- **SignalBus.gd**: 全局事件总线，连接所有系统
- 解耦系统间的依赖，便于扩展和维护

```gdscript
# 发送信号
SignalBus.enemy_killed.emit(enemy_type, position)

# 监听信号
SignalBus.enemy_killed.connect(_on_enemy_killed)
```

### 2. Component-Based Design（组件化设计）
- **GameComponent**: 基础组件类
- **StatusEffectComponent**: 状态效果组件
- **PunchSystem**: 拳击系统组件

```gdscript
# 添加组件
var status_component = StatusEffectComponent.new()
status_component.initialize(entity, sprite, health_comp)
entity.add_child(status_component)
```

### 3. Service Locator Pattern（服��定位器）
- **ServiceLocator.gd**: 注册和查找全局服务
- 避免频繁的 `get_tree().get_nodes_in_group()` 调用

```gdscript
# 注册服务
ServiceLocator.register_service("room_manager", self)

# 查找服务
var room_manager = ServiceLocator.get_service("room_manager")
```

### 4. Object Pooling（对象池）
- **ResourceManager.gd**: 管理可复用对象池
- 预分配：Bullets (100), Enemies (50), Damage Numbers (30), etc.

```gdscript
# 从对象池获取
var bullet = ResourceManager.get_pooled_bullet()

# 返回对象池
ResourceManager.return_to_pool(bullet)
```

### 5. Factory Pattern（工厂模式）
- **BulletFactory**: 统一弹幕创建接口
- **EnemyAIHelper**: AI行为计算
- **BossAttackPatterns**: Boss攻击模式库

```gdscript
# 使用工厂创建弹幕
var bullet = BulletFactory.create_bullet(bullet_scene, BulletFactory.BulletPreset.HOMING)

# 生成环形弹幕
var bullets = BulletFactory.spawn_ring(bullet_scene, position, 12)
```

## ⚠️ 已知问题和改进方向

### 大文件（需要进一步分解）
1. **Player.gd (71KB)**
   - 包含：移动、战斗、技能、交互、动画
   - 建议：提取到PlayerMovement, PlayerCombat, PlayerSkills

2. **Enemy.gd (57KB)**
   - 包含：AI、物理、攻击、状态、视觉
   - 建议：使用EnemyAIHelper和组件系统
   - 已提供：EnemyAIHelper.gd, BossAttackPatterns.gd

3. **Bullet.gd (41KB)**
   - 包含：所有弹幕类型和行为
   - 建议：使用BulletFactory
   - 已提供：BulletFactory.gd

4. **GameUI.gd (36KB)**
   - 包含：所有UI显示和交互
   - 建议：分解为多个UI面板

5. **CharacterSkills.gd (32KB)**
   - 包含：所有角色技能
   - 建议：使用SkillDatabase
   - 已提供：SkillDatabase.gd

### 根目录混乱
- 66个.gd文件在根目录
- 大部分被.tscn直接引用，无法轻易移动
- **解决方案**: 新代码使用scripts/目录，旧代码逐步重构

### 重复的组件系统
- `entities/components/` - 基于GameComponent的ECS
- `scripts/components/` - 独立组件
- **解决方案**: 统一使用scripts/components/

## ✅ 已完成的改进

### 1. 统一SceneManager
- 合并了两个版本的SceneManager
- 支持枚举和字符串两种API
- 统一的淡入淡出动画

### 2. 重命名Logger → GameLogger
- 避免与Godot内置Logger冲突

### 3. 删除重复文件
- 删除entities/components/StatusEffectComponent.gd
- 删除scripts/core/SceneManager.gd

### 4. 创建辅助类
- EnemyAIHelper.gd - AI计算辅助
- BossAttackPatterns.gd - Boss攻击模式
- BulletFactory.gd - 弹幕工厂
- SkillDatabase.gd - 技能数据库

### 5. 目录重组
- 数据文件 → scripts/data/
- 管理器 → scripts/gameplay/
- UI → scripts/ui/
- 工具 → scripts/utils/

## 📚 最佳实践

### 命名规范
- **Manager**: 管理多个实例（RoomManager, InventoryManager）
- **System**: 处理特定逻辑（WeaponSystem, BondSystem）
- **Component**: 可附加到实体（StatusEffectComponent）
- **Data**: 纯数据类（EnemyData, WeaponData）
- **Helper/Util**: 静态辅助方法（EnemyAIHelper）

### 文件组织
- 场景特定脚本放在scenes/对应目录
- 可复用脚本放在scripts/
- 数据类放在scripts/data/
- 全局服务放在scripts/core/autoloads/

### 依赖管理
- 优先使用信号通信
- 通过ServiceLocator查找服务
- 避免硬引用其他节点

### 性能优化
- 使用对象池（ResourceManager）
- 缓存频繁计算结果
- 限制查询频率（separation_calc_timer）

## 🎯 未来改进建议

1. **分解巨型文件**: 逐步将Player, Enemy, GameUI等大文件模块化
2. **统一组件系统**: 合并两套组件架构
3. **添加单元测试**: 为核心系统添加测试
4. **性能分析**: 使用Profiler找出瓶颈
5. **文档完善**: 为每个系统编写使用文档

## 📖 参考资源

- [Godot官方 - 项目组织](https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html)
- [Architecture Organization Advice](https://github.com/abmarnie/godot-architecture-organization-advice)
- [Godot Project Template](https://github.com/SamuelAsherRivello/godot-project-template)
