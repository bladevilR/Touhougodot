# 魔理沙（Marisa）- 行为流程设计

## 核心哲学
- 作为纯粹人类，活得像妖怪
- 追求永生和力量，但用人类的方法
- "借"东西不算偷，知识应该共享

---

## 出现机制

### 日程触发
```gdscript
const MARISA_SCHEDULE = [
    {
        "time_start": 7,
        "time_end": 10,
        "location": "magic_forest",
        "action": "magic_research",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 10,
        "time_end": 12,
        "location": "village_center",  # 买道具
        "action": "shopping",
        "state": NPCState.WALKING,
        "interruptible": true
    },
    {
        "time_start": 12,
        "time_end": 13,
        "location": "magic_forest",
        "action": "lunch",
        "state": NPCState.EATING,
        "interruptible": true
    },
    {
        "time_start": 13,
        "time_end": 15,
        "location": "magic_forest",
        "action": "magic_practice",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 15,
        "time_end": 17,
        "location": "village_center",  # 闲逛
        "action": "wandering",
        "state": NPCState.WALKING,
        "interruptible": true
    },
    {
        "time_start": 17,
        "time_end": 22,
        "location": "magic_forest",
        "action": "research_late",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 22,
        "time_end": 7,
        "location": "magic_forest",
        "action": "sleep",
        "state": NPCState.SLEEPING,
        "interruptible": false
    }
]
```

### 出现条件
- **可交互时段1**: 10:00-12:00（人之里中心，买道具）
- **可交互时段2**: 15:00-17:00（人之里中心，闲逛）
- **高频NPC**: 一天出现2次
- **特殊**: bond >= 3后可访问魔法森林小屋（magic_forest_house）

---

## 行为状态机

### 状态1: 购物模式（10:00-12:00）
- **位置**: village_center（商店附近）
- **行为模式**:
  - 快速移动
  - 检查稀有道具
  - 会和商人讨价还价（动画）
- **交互**: 允许
- **特殊**: 如果玩家背包有稀有物品，她会"感兴趣"

### 状态2: 闲逛模式（15:00-17:00）
- **位置**: village_center（随机走动）
- **行为模式**:
  - 慢速移动
  - 观察周围
  - 偶尔停下来思考
- **交互**: 允许
- **特殊**: bond >= 2时会主动接近玩家

### 状态3: 研究模式（magic_forest）
- **位置**: magic_forest_house
- **解锁**: bond >= 3
- **行为**: 站在实验台前
- **交互**: 允许，但有特殊规则（见下文）

### 状态4: "借东西"模式（随机触发）
- **触发**: 低概率事件
- **行为**: 突然出现在特定场景（红魔馆、神社等）
- **玩家发现**: 可以选择阻止或无视
- **影响**: 影响与其他NPC的关系

---

## 羁绊系统

### 羁绊点数获取规则
```gdscript
const MARISA_BOND_ACTIONS = {
    "talk": 10,
    "gift_mushroom": 60,           # 喜欢蘑菇
    "gift_magic_book": 150,        # 最爱：魔法书
    "gift_rare_material": 80,      # 喜欢稀有材料
    "help_research": 100,          # 帮助魔法研究
    "cover_borrowing": 50,         # 帮她掩护"借东西"
    "learn_magic": 120,            # 向她学习魔法
}
```

### 特殊机制：知识交换系统
```gdscript
class KnowledgeExchangeSystem:
    func exchange_knowledge(player_knowledge: String):
        # 玩家提供情报/知识，魔理沙给予魔法技能
        if is_valuable_knowledge(player_knowledge):
            BondSystem.add_bond_points("marisa", 80)
            unlock_magic_skill()
        else:
            # 她会"借"走玩家的道具作为补偿
            steal_random_item()
```

### "借"东西系统
```gdscript
class BorrowingSystem:
    var borrowed_items: Dictionary = {}  # item_id -> borrow_date

    func on_marisa_borrow(item_id: String):
        borrowed_items[item_id] = TimeManager.current_day

    func can_request_return(item_id: String) -> bool:
        # 借了7天后可以要回来（也许）
        return TimeManager.current_day - borrowed_items[item_id] >= 7

    func request_return(item_id: String):
        if bond_level >= 4:
            return_item(item_id)  # 归还
            BondSystem.add_bond_points("marisa", 20)
        else:
            refuse_return()  # 拒绝
```

### 等级解锁内容

#### 等级0 → 1（100点）
- **机制解锁**: 可以向她询问魔法知识
- **UI变化**: 对话选项增加"魔法"分类

#### 等级1 → 2（300点）
- **机制解锁**: 她会主动接近玩家（15-17点）
- **行为变化**: 看到玩家会挥手打招呼

#### 等级2 → 3（600点）
- **机制解锁**: 解锁魔法森林小屋访问权限
- **新地点**: magic_forest_house
- **可学习**: 初级魔法"火花"

#### 等级3 → 4（1000点）
- **机制���锁**: 可以参与她的"借东西"行动
- **选择**: 帮忙 or 阻止
- **可学习**: 中级魔法"迷你八卦炉"

#### 等级4 → 5（1500点）
- **机制解锁**: 她会"借"完东西后主动归还
- **可学习**: 高级魔法"恋符·Master Spark"
- **特殊道具**: 获得"八卦炉（装饰品）"

#### 等级5 → 6（2500点）
- **机制解锁**: 解锁同伴邀请
- **特殊条件**:
  1. 完成"永生之秘"任务链
  2. 向她学习至少5个魔法
  3. 玩家魔法技能等级 >= 3

---

## 任务流程

### 任务链1: 魔法学徒
**解锁**: bond_level >= 2

#### 阶段1: 基础魔力训练
- **目标**: 收集"魔力结晶x10"
- **来源**: 击败魔法系敌人或采集魔���点
- **奖励**: bond +80, 学习"魔力感知"被动

#### 阶段2: 火花练习
- **目标**: 在训练场使用魔法击中靶子20次
- **评分**: 准确度影响奖励
- **奖励**: bond +100, 学习"火花"主动技能

#### 阶段3: 实战测试
- **目标**: 使用魔法击败5只妖精
- **限制**: 必须用魔法击杀
- **奖励**: bond +150, 魔法威力+10%

### 任务链2: 借书大作战
**解锁**: bond_level >= 3

#### 阶段1: 情报收集
- **目标**: 调查红魔馆的藏书位置
- **方法**: 询问NPC或潜入侦查
- **奖励**: bond +60

#### 阶段2: 制定计划
- **选择**:
  1. 正面硬闯（战斗路线）
  2. 偷偷潜入（潜行路线）
  3. 谈判借阅（和平路线）
- **每条路线**: 不同挑战和奖励

#### 阶段3: 执行行动
- **正面硬闯**: 与咲夜战斗（高难度）
  - 成功: bond +200, 强制"借"到书
  - 失败: bond +50, 空手而归
- **偷偷潜入**: 潜行小游戏
  - 成功: bond +180, "借"到书且不被发现
  - 失败: 被咲夜抓到，关系恶化
- **谈判借阅**: 说服帕秋莉
  - 成功: bond +150, 正当借阅
  - 失败: bond +30, 改为偷偷潜入

#### 后续影响
- **如果被发现**: 咲夜的羁绊-50
- **如果成功**: 魔理沙教授高级魔法

### 任务链3: 永生之秘（同伴解锁前置）
**解锁**: bond_level >= 5

#### 阶段1: 人类的极限
- **触发**: 魔理沙主动找玩家谈心
- **内容**: 讨论人类寿命与妖怪永生
- **玩家选择**:
  1. 支持追求永生 → 继续任务
  2. 劝阻 → 任务中止，bond -200

#### 阶段2: 寻找蓬莱之枝
- **目标**: 探索竹林深处，找到辉夜
- **前置**: 需要先解锁隐藏地图
- **奖励**: bond +250

#### 阶段3: 不死之药的真相
- **剧情**: 了解蓬莱人的代价
- **玩家选择**:
  1. 帮她继续追求 → bond +300, 解锁同伴
  2. 劝她放弃 → bond +200, 特殊结局
- **影响**: 影响魔理沙的最终命运

---

## 同伴机制

### 招募条件
```gdscript
func can_recruit_marisa() -> bool:
    return (
        BondSystem.get_bond_level("marisa") >= 6 and
        PlayerStats.magic_skill_level >= 3 and
        QuestManager.is_quest_completed("eternal_life_secret") and
        learned_magic_count >= 5
    )
```

### 同伴特性
- **HP**: 90（偏低）
- **攻击**: 180（极高，魔法攻击）
- **防御**: 40（低）
- **特殊能力**: "Master Spark"（直线范围魔法炮）

### 战斗行为
```gdscript
class MarisaCombatAI:
    var magic_power: float = 100.0
    var spark_cooldown: float = 30.0

    func get_action():
        if enemy_count >= 3 and spark_cooldown <= 0:
            return use_master_spark()  # 范围群攻
        elif distance_to_enemy > 150:
            return cast_magic_missile()  # 中距离魔法弹
        elif magic_power < 20:
            return retreat_and_recover()  # 后退恢复魔力
        else:
            return cast_spark()  # 单体火花
```

### 跟随行为
- **跟随模式**: 飞行跟随（在玩家上方）
- **移动速度**: 比玩家快20%
- **战斗定位**: 后排输出
- **特殊**: 会"借"玩家的魔法道具用（临时使用，战斗后归还）

---

## 特殊交互

### "借"东西系统详细规则
```gdscript
class BorrowingMechanic:
    const BORROWABLE_ITEMS = [
        "magic_book",
        "rare_mushroom",
        "mana_crystal",
        "ancient_artifact"
    ]

    func attempt_borrow():
        if player_nearby and has_borrowable_items():
            if player_inventory_open:
                # 玩家打开背包时，魔理沙有10%概率"借"走一件物品
                if random() < 0.1:
                    borrow_random_item()
                    show_notification("魔理沙'借'走了XXX")

    func on_player_confront():
        # 玩家质问时
        if bond_level < 3:
            deny_borrowing()  # 矢口否认
        else:
            admit_and_promise_return()  # 承认并承诺归还
```

### 魔法学习系统
```gdscript
class MagicLearningSystem:
    const TEACHABLE_MAGIC = {
        "spark": {
            "unlock_level": 2,
            "cost": 500,  # 金币
            "effect": "fire_damage_small"
        },
        "mini_hakkero": {
            "unlock_level": 4,
            "cost": 1500,
            "effect": "fire_damage_medium_aoe"
        },
        "master_spark": {
            "unlock_level": 5,
            "cost": 5000,
            "effect": "fire_damage_huge_line"
        },
        "light_sign": {
            "unlock_level": 6,
            "cost": 3000,
            "effect": "light_damage_star_pattern"
        }
    }

    func learn_magic(magic_id: String):
        if bond_level >= required_level and player_coins >= cost:
            PlayerStats.add_skill(magic_id)
            BondSystem.add_bond_points("marisa", 120)
```

### 与其他NPC的关系

#### 魔理沙 & 灵梦
```gdscript
func marisa_reimu_interaction():
    # 竞争关系，但互相尊重
    # 如果两人在同一场景，会有特殊对话
    # 玩家可以提议"一起去冒险"（解锁双人任务）
```

#### 魔理沙 & 咲夜
```gdscript
func marisa_sakuya_interaction():
    # 敌对关系（魔理沙经常偷书）
    # 咲夜的警戒值上升
    # 如果玩家同时与两人羁绊高，会有调解任务
```

#### 魔理沙 & 帕秋莉（未实现NPC）
```gdscript
func marisa_patchouli_interaction():
    # 复杂关系：对手但互相学习
    # 预留接口，未来扩展
```

---

## 数据结构

### 存档数据
```gdscript
{
    "marisa": {
        "bond_level": 4,
        "bond_points": 1100,
        "last_talk_day": 27,
        "daily_talks": 2,  # 一天可以见2次
        "borrowed_items": {
            "magic_book_fire": 15,  # 借走的日期
            "mana_crystal": 20
        },
        "returned_items": ["ancient_scroll"],
        "magic_learned": ["spark", "mini_hakkero"],
        "has_forest_house_access": true,
        "eternal_quest_choice": "support",  # support/discourage
        "is_companion": false
    }
}
```

### 实时数据
```gdscript
class MarisaRuntimeData:
    var is_in_borrowing_mode: bool = false
    var target_borrow_item: String = ""
    var magic_power_current: float = 100.0
    var research_progress: float = 0.0  # 当前研究进度
    var mood: String = "excited"  # excited/focused/frustrated
```

---

## 平衡性参数

### "借"东西概率
- **玩家背包打开时**: 10%
- **bond < 2**: 借走后不归还
- **bond >= 2**: 7天后可要求归还，80%成功率
- **bond >= 4**: 3天后自动归还

### 魔法学习成本
- **初级魔法**: 500 coins
- **中级魔法**: 1500 coins
- **高级魔法**: 5000 coins
- **终极魔法**: 10000 coins + 特殊材料

### 同伴战斗数值
- **Master Spark**:
  - 伤害: 300-500（单线范围）
  - 冷却: 30秒
  - 魔力消耗: 50
- **魔力回复**: 每秒+5
- **魔力上限**: 100

---

## 实现优先级

### P0（核心机制）
1. 每日10-12点、15-17点双时段出现
2. 基础对话系统
3. 羁绊点数获取

### P1（特色体验）
4. "借"东西系统
5. 魔法学习系统
6. 魔法森林小屋场景

### P2（深度内容）
7. "借书大作战"任务链
8. 知识交换系统
9. 同伴招募

### P3（高级内容）
10. "永生之秘"剧情线
11. 与其他NPC的复杂互动
12. 归还机制优化
