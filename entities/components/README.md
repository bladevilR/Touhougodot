# 游戏组件系统

本目录包含Entity-Component架构的组件实现，用于构建可复用、模块化的游戏实体。

## 目录结构

```
entities/components/
├── GameComponent.gd           # 组件基类
├── ShadowComponent.gd         # 阴影管理
├── MovementComponent.gd       # 移动和冲刺
├── StatusEffectComponent.gd   # 状态效果
└── SpriteComponent.gd         # 精灵渲染
```

## 设计理念

**Entity-Component模式**：将复杂的实体（如Player、Enemy）拆分为多个小的、可复用的组件。

### 优势

- ♻️ **代码复用**：同一组件可用于多个实体
- 🧩 **职责单一**：每个组件只负责一项功能
- 🔧 **易于维护**：修改一个组件不影响其他
- 🎯 **灵活组合**：通过组合不同组件创建新实体

## 组件基类

### GameComponent

所有组件的基类，定义统一接口。

```gdscript
extends GameComponent
class_name MyComponent

func _on_entity_ready() -> void:
    # 初始化逻辑

func _on_entity_process(delta: float) -> void:
    # 每帧更新逻辑

func cleanup() -> void:
    # 清理资源
```

**生命周期方法：**
- `_on_entity_ready()` - 实体准备完成时调用
- `_on_entity_process(delta)` - 每帧调用
- `_on_entity_physics_process(delta)` - 物理帧调用
- `cleanup()` - 组件销毁前清理

**通用方法：**
- `enable()` / `disable()` - 启用/禁用组件
- `toggle()` - 切换启用状态
- `get_component_type()` - 获取组件类型名

## 内置组件

### ShadowComponent
**为实体自动管理阴影**

```gdscript
var shadow = ShadowComponent.new()
shadow.entity = self
shadow.use_entity_texture = true  # 使用实体纹理
shadow.shadow_size = Vector2(40, 20)
add_child(shadow)
shadow._on_entity_ready()
```

**特性：**
- 自动同步阴影位置和纹理
- 支持实体纹理阴影或椭圆阴影
- 可配置阴影大小、偏移、倾斜

---

### MovementComponent
**处理移动、冲刺、击退**

```gdscript
var movement = MovementComponent.new()
movement.entity = self
movement.speed = 200.0
movement.friction = 0.85
movement.can_dash = true
add_child(movement)

# 移动
movement.move(Vector2(1, 0))

# 冲刺
movement.dash()

# 击退
movement.apply_knockback(Vector2(100, -50))
```

**特性：**
- 基于CharacterBody2D的移动
- 冲刺系统（带冷却）
- 击退效果（自动衰减）
- 摩擦力模拟

---

### StatusEffectComponent
**管理各种状态效果**

```gdscript
var status = StatusEffectComponent.new()
status.entity = self
add_child(status)

# 应用效果
status.apply_effect("burn", 3.0, 10.0)     # 燃烧
status.apply_effect("freeze", 2.0, 5.0)    # 冰冻
status.apply_effect("poison", 5.0, 8.0)    # 中毒

# 检查状态
if status.is_frozen():
    # 被冰冻，无法移动

# 获取速度修正
var speed_mod = status.get_speed_modifier()
```

**支持的效果：**
- `burn` - 燃烧（持续伤害）
- `freeze` - 冰冻（完全无法移动）
- `poison` - 中毒（持续伤害）
- `slow` - 减速（降低移动速度）
- `stun` - 眩晕
- `frost` - 霜冻叠层（3层触发冰冻）
- `vulnerability` - 易伤（增加受到的伤害）

**特性：**
- 自动Tick伤害（燃烧、中毒）
- 视觉反馈（粒子效果）
- 效果叠加和衰减
- 移动速度和伤害修正

---

### SpriteComponent
**管理精灵渲染**

```gdscript
var sprite = SpriteComponent.new()
sprite.entity = self
sprite.texture_path = "res://assets/player.png"
sprite.hframes = 4
sprite.vframes = 4
add_child(sprite)

sprite.set_frame(2)
sprite.set_flip_h(true)
```

**特性：**
- 自动加载纹理
- 帧动画支持
- 翻转和调制颜色

## 使用指南

### 为现有实体添加组件

```gdscript
# 在Player.gd或Enemy.gd中
extends CharacterBody2D

var components: Array[GameComponent] = []

func _ready():
    # 添加阴影
    var shadow = ShadowComponent.new()
    shadow.entity = self
    add_child(shadow)
    components.append(shadow)

    # 添加移动
    var movement = MovementComponent.new()
    movement.entity = self
    movement.speed = 180.0
    add_child(movement)
    components.append(movement)

    # 初始化所有组件
    for component in components:
        component._on_entity_ready()

func _process(delta):
    # 更新所有组件
    for component in components:
        if component.enabled:
            component._on_entity_process(delta)
```

### 创建自定义组件

```gdscript
# MyCustomComponent.gd
extends GameComponent
class_name MyCustomComponent

var my_property: float = 1.0

func _on_entity_ready() -> void:
    print("组件初始化完成")

func _on_entity_process(delta: float) -> void:
    if not entity:
        return

    # 自定义逻辑
    entity.position.x += my_property * delta

func cleanup() -> void:
    # 清理资源
    pass
```

### 组件间通信

```gdscript
# 方式1：通过entity访问其他组件
var movement = entity.get_node("MovementComponent")
if movement:
    movement.speed = 150.0

# 方式2：通过信号
signal component_event(data)

func _on_entity_ready():
    component_event.connect(_on_component_event)
```

## 最佳实践

1. **保持组件独立**：组件不应直接依赖其他组件
2. **通过entity通信**：需要访问其他组件时，通过entity节点查找
3. **使用信号**：组件间通信优先使用信号
4. **及时清理**：重写cleanup()方法清理资源
5. **合理粒度**：组件不宜过小（过度拆分）也不宜过大（失去复用性）

## 扩展建议

可以创建的其他组件：
- **AnimationComponent** - 动画管理
- **WeaponComponent** - 武器系统
- **AIComponent** - AI决策
- **HealthComponent** - 生命值管理
- **CollisionComponent** - 碰撞检测
- **AudioComponent** - 音效播放

## 性能考虑

- 组件数量适中（每个实体5-10个组件）
- 避免在_process中频繁查找组件（缓存引用）
- 禁用不需要的组件而非删除
- 使用对象池管理组件密集的实体

## 更多信息

- 完整架构说明：`/REFACTORING_SUMMARY.md`
- 快速参考：`/QUICK_REFERENCE.md`
- 核心系统：`/core/README.md`
