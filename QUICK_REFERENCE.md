# 新模块化系统 - 快速参考

## 🚀 立即可用的新系统

### ServiceLocator - 服务定位器

**替代 get_nodes_in_group()**

```gdscript
# ❌ 旧方式（慢）
var players = get_tree().get_nodes_in_group("player")
var map_system = get_tree().root.get_node("MapSystem")

# ✅ 新方式（快）
var map_system = ServiceLocator.get_service("map_system")
var room_manager = ServiceLocator.get_service("room_manager")
```

**注册服务**（在系统的_ready()中）：
```gdscript
func _ready():
    ServiceLocator.register_service("map_system", self)
```

---

### ResourceManager - 对象池和资源缓存

**使用对象池（推荐用于频繁创建/销毁的对象）**

```gdscript
# ❌ 旧方式（频繁GC）
var bullet = preload("res://Bullet.tscn").instantiate()
add_child(bullet)
# ...使用后
bullet.queue_free()

# ✅ 新方式（对象池复用）
var bullet = ResourceManager.get_pooled_instance("bullet")
add_child(bullet)
# ...使用后
ResourceManager.return_to_pool(bullet, "bullet")
```

**已配置的对象池**：
- `"bullet"` - 子弹（100个）
- `"enemy"` - 敌人（50个）
- `"damage_number"` - 伤害数字（30个）
- `"death_particle"` - 死亡粒子（20个）
- `"fire_trail"` - 火焰轨迹（50个）

**加载资源（自动缓存）**：
```gdscript
var texture = ResourceManager.load_resource("res://assets/sprite.png")
```

---

### SceneManager - 场景切换

**切换场景（带转场动画）**

```gdscript
# ❌ 旧方式（无动画）
get_tree().change_scene_to_file("res://TownWorld.tscn")

# ✅ 新方式（淡入淡出）
SceneManager.change_scene(SceneManager.Scene.TOWN, "fade", 1.0)
```

**可用场景**：
```gdscript
SceneManager.Scene.MAIN_MENU
SceneManager.Scene.TOWN
SceneManager.Scene.BATTLE
SceneManager.Scene.SETTINGS
SceneManager.Scene.GAME_OVER
SceneManager.Scene.VICTORY
```

---

### AudioManager - 音频管理

**播放音乐**

```gdscript
# 带淡入效果
AudioManager.play_music("res://assets/music/battle.ogg", 1.0)

# 停止音乐（带淡出）
AudioManager.stop_music(0.5)
```

**播放音效**

```gdscript
# 基础播放
AudioManager.play_sfx("res://assets/sfx/shoot.wav")

# 带音量和音调控制
AudioManager.play_sfx("res://assets/sfx/shoot.wav", 0.8, 1.2)
```

**音量控制**

```gdscript
AudioManager.set_music_volume(0.7)  # 70%
AudioManager.set_sfx_volume(0.9)     # 90%
AudioManager.set_master_volume(1.0)  # 100%
```

**暂停/恢复**

```gdscript
AudioManager.pause_all()   # 暂停所有音频
AudioManager.resume_all()  # 恢复所有音频
```

---

### GameplaySystem - 游戏流程

**自动处理游戏事件**（无需手动调用）

GameplaySystem已自动监听以下事件：
- 玩家死亡 → 1.5秒后切换到GAME_OVER场景
- Boss击败 → 2秒后切换到VICTORY场景
- 房间清理 → 自动记录统计

**获取游戏统计**：
```gdscript
var stats = GameplaySystem.get_game_statistics()
print("游戏时长: ", stats["duration"])
print("击杀数: ", stats["enemies_killed"])
print("总伤害: ", stats["damage_dealt"])
```

---

### RenderSystem - 渲染和光照

**创建RenderSystem**（在场景中）

```gdscript
func _ready():
    var render_system = RenderSystem.new()
    add_child(render_system)
    render_system.set_map_size(2400, 1800)

    # 设置光照风格
    render_system.set_lighting_style(RenderSystem.LightingStyle.OUTSKIRTS)

    # 注册服务
    ServiceLocator.register_service("render_system", render_system)
```

**光照风格**：
```gdscript
RenderSystem.LightingStyle.OUTSKIRTS          # 明亮通透
RenderSystem.LightingStyle.DEEP_FOREST_MIST   # 浓雾
RenderSystem.LightingStyle.DEEP_FOREST_BEAM   # 光柱
```

**创建阴影**：
```gdscript
var render_system = ServiceLocator.get_service("render_system")
var shadow = render_system.create_shadow_for_entity(player_sprite)
```

**创建动态光源**：
```gdscript
var light = render_system.create_dynamic_light(Vector2(100, 100), Color.WHITE, 1.5)
```

---

## 🧩 组件系统

### ShadowComponent - 阴影组件

```gdscript
# 为实体添加阴影
var shadow = ShadowComponent.new()
shadow.entity = self
shadow.use_entity_texture = true  # 使用实体纹理阴影
shadow.shadow_size = Vector2(40, 20)
add_child(shadow)
shadow._on_entity_ready()

# 在_process中更新
shadow._on_entity_process(delta)
```

---

### MovementComponent - 移动组件

```gdscript
# 添加移动组件
var movement = MovementComponent.new()
movement.entity = self
movement.speed = 200.0
movement.friction = 0.85
movement.can_dash = true
add_child(movement)

# 移动
movement.move(Vector2(1, 0))  # 向右移动

# 冲刺
movement.dash(Vector2(1, 0))  # 向右冲刺

# 在_physics_process中更新
movement._on_entity_physics_process(delta)
```

---

### StatusEffectComponent - 状态效果组件

```gdscript
# 添加状态效果组件
var status = StatusEffectComponent.new()
status.entity = self
add_child(status)
status._on_entity_ready()

# 应用效果
status.apply_effect("burn", 3.0, 10.0)     # 燃烧3秒，强度10
status.apply_effect("freeze", 2.0, 5.0)    # 冰冻2秒
status.apply_effect("poison", 5.0, 8.0)    # 中毒5秒

# 检查效果
if status.has_effect("freeze"):
    print("被冰冻了！")

# 获取速度修正
var speed_modifier = status.get_speed_modifier()
var actual_speed = base_speed * speed_modifier

# 在_process中更新
status._on_entity_process(delta)
```

**可用效果**：
- `"burn"` - 燃烧（持续伤害）
- `"freeze"` - 冰冻（完全减速）
- `"poison"` - 中毒（持续伤害）
- `"slow"` - 减速（降低移动速度）
- `"stun"` - 眩晕
- `"frost"` - 霜冻叠层（3层触发冰冻）
- `"vulnerability"` - 易伤（增加受到的伤害）

---

### SpriteComponent - 精灵组件

```gdscript
# 添加精灵组件
var sprite = SpriteComponent.new()
sprite.entity = self
sprite.texture_path = "res://assets/player.png"
sprite.hframes = 4
sprite.vframes = 4
add_child(sprite)
sprite._on_entity_ready()

# 设置帧
sprite.set_frame(2)

# 翻转
sprite.set_flip_h(true)

# 修改颜色
sprite.set_modulate(Color(1, 0, 0, 1))  # 红色
```

---

## 📝 常见使用场景

### 场景1：创建新敌人时使用对象池

```gdscript
# 在EnemySpawner.gd中
func spawn_enemy(position: Vector2):
    # 使用对象池
    var enemy = ResourceManager.get_pooled_instance("enemy")
    enemy.position = position
    get_parent().add_child(enemy)

    # 当敌人死亡时（在Enemy.gd中）
    func die():
        # 归还到对象池
        ResourceManager.return_to_pool(self, "enemy")
```

---

### 场景2：注册系统为服务并使用

```gdscript
# 在RoomManager.gd中
func _ready():
    # 注册服务
    ServiceLocator.register_service("room_manager", self)

# 在其他脚本中
func some_function():
    var room_manager = ServiceLocator.get_service("room_manager")
    if room_manager:
        var current_room = room_manager.current_room_index
```

---

### 场景3：为新角色添加完整的组件系统

```gdscript
extends CharacterBody2D

var components: Array[GameComponent] = []

func _ready():
    # 添加所有组件
    var shadow = ShadowComponent.new()
    shadow.entity = self
    add_child(shadow)
    components.append(shadow)

    var movement = MovementComponent.new()
    movement.entity = self
    movement.speed = 180.0
    add_child(movement)
    components.append(movement)

    var status = StatusEffectComponent.new()
    status.entity = self
    add_child(status)
    components.append(status)

    # 初始化所有组件
    for component in components:
        component._on_entity_ready()

func _process(delta):
    # 更新所有组件
    for component in components:
        if component.enabled:
            component._on_entity_process(delta)

func _physics_process(delta):
    # 物理更新
    for component in components:
        if component.enabled:
            component._on_entity_physics_process(delta)
```

---

### 场景4：切换关卡时管理资源

```gdscript
func start_new_level():
    # 清空对象池（可选）
    # ResourceManager.clear_cache()

    # 切换场景
    SceneManager.change_scene(SceneManager.Scene.BATTLE, "fade", 1.0)

    # 播放关卡音乐
    AudioManager.play_music("res://assets/music/level1.ogg", 2.0)
```

---

## ⚡ 性能优化建议

### 1. 使用对象池替代频繁实例化

**适用于：**
- 子弹（每秒可能生成数十个）
- 伤害数字（每次攻击都生成）
- 粒子效果（频繁出现和消失）

**不适用于：**
- 玩家、Boss等单例对象
- 场景节点（如UI面板）

### 2. 使用ServiceLocator替代树查询

**适用于：**
- 需要频繁访问的系统（MapSystem、RoomManager）
- 全局管理器

**步骤：**
1. 在系统的_ready()中注册
2. 在需要时通过ServiceLocator获取
3. 缓存引用（如果频繁使用）

### 3. 资源预加载

```gdscript
# 在游戏启动时预加载常用资源
func preload_resources():
    ResourceManager.load_resource("res://assets/player.png")
    ResourceManager.load_resource("res://assets/enemy1.png")
    # ...
```

---

## 🐛 调试技巧

### 检查服务注册状态

```gdscript
print(ServiceLocator.get_service_names())
# 输出所有已注册的服务
```

### 查看对象池状态

```gdscript
print(ResourceManager.get_all_pool_status())
# 输出：[{name: "bullet", available: 95, config: {...}}, ...]
```

### 查看音频状态

```gdscript
print(AudioManager.get_audio_status())
# 输出当前播放的音乐、活跃音效数量等
```

### 查看游戏统计

```gdscript
print(GameplaySystem.get_game_statistics())
# 输出游戏时长、击杀数等
```

---

## 📚 更多信息

完整文档请查看：
- `REFACTORING_SUMMARY.md` - 完整重构报告和迁移指南
- 各系统文件顶部的注释文档

**新创建的系统文件位置：**
- `core/autoloads/*.gd` - 全局服务
- `core/managers/*.gd` - 管理器
- `entities/components/*.gd` - 组件
- `scenes/battle/RenderSystem.gd` - 渲染系统

---

*快速参考 | Claude Code生成 @ 2026-01-02*
