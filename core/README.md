# 核心系统架构

本目录包含游戏的核心模块化架构，包括全局服务（Autoload）和管理器。

## 目录结构

```
core/
├── autoloads/          # 全局单例服务（已注册到project.godot）
│   ├── ServiceLocator.gd
│   ├── ResourceManager.gd
│   ├── SceneManager.gd
│   └── AudioManager.gd
└── managers/           # 游戏管理器
    └── GameplaySystem.gd
```

## Autoloads（全局服务）

所有autoload服务可在任何脚本中直接使用，无需引用或实例化。

### ServiceLocator
**服务定位器模式，替代get_nodes_in_group()**

```gdscript
# 注册服务
ServiceLocator.register_service("map_system", self)

# 获取服务
var map_system = ServiceLocator.get_service("map_system")
```

### ResourceManager
**资源缓存和对象池管理**

```gdscript
# 对象池（避免频繁GC）
var bullet = ResourceManager.get_pooled_instance("bullet")
ResourceManager.return_to_pool(bullet, "bullet")

# 资源缓存
var texture = ResourceManager.load_resource("res://assets/sprite.png")
```

预配置的对象池：bullet、enemy、damage_number、death_particle、fire_trail

### SceneManager
**场景切换和转场动画**

```gdscript
SceneManager.change_scene(SceneManager.Scene.BATTLE, "fade", 1.0)
```

支持场景：MAIN_MENU、TOWN、BATTLE、SETTINGS、GAME_OVER、VICTORY

### AudioManager
**音乐和音效统一管理**

```gdscript
AudioManager.play_music("res://assets/music/battle.ogg", 1.0)
AudioManager.play_sfx("res://assets/sfx/shoot.wav")
AudioManager.set_music_volume(0.7)
```

## Managers（管理器）

### GameplaySystem
**游戏流程协调器**

自动处理：
- 玩家死亡 → 切换到游戏结束场景
- Boss击败 → 切换到胜利场景
- 游戏统计收集

```gdscript
var stats = GameplaySystem.get_game_statistics()
```

## 设计原则

1. **单一职责**：每个服务/管理器只负责一项核心功能
2. **全局可访问**：通过Autoload机制，无需手动传递引用
3. **向后兼容**：不破坏现有代码，可逐步迁移
4. **性能优化**：对象池减少GC，ServiceLocator提升查询效率

## 使用建议

### 优先使用ServiceLocator
替代所有`get_tree().get_nodes_in_group()`调用

### 频繁创建/销毁的对象使用对象池
如：子弹、敌人、伤害数字、粒子效果

### 场景切换使用SceneManager
获得流畅的转场动画体验

### 音频播放使用AudioManager
统一管理，支持淡入淡出和音量控制

## 更多信息

- 完整文档：`/REFACTORING_SUMMARY.md`
- 快速参考：`/QUICK_REFERENCE.md`
