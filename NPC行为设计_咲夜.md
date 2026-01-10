# 咲夜（Sakuya）- 行为流程设计

## 核心哲学
- 作为纯粹人类，选择服侍妖怪（蕾米莉亚）
- 用完美执行任务来证明人类的价值
- 时间能力象征：为他人奉献自己的时间

---

## 出现机制

### 日程触发
```gdscript
# 每日固定日程
const SAKUYA_SCHEDULE = [
    {
        "time_start": 6,
        "time_end": 9,
        "location": "scarlet_mansion",
        "action": "morning_duties",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 9,
        "time_end": 11,
        "location": "village_center",  # 买菜时段
        "action": "shopping",
        "state": NPCState.WALKING,
        "interruptible": true
    },
    {
        "time_start": 11,
        "time_end": 22,
        "location": "scarlet_mansion",
        "action": "mansion_duties",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 22,
        "time_end": 6,
        "location": "scarlet_mansion",
        "action": "sleep",
        "state": NPCState.SLEEPING,
        "interruptible": false
    }
]
```

### 出现条件
- **可交互时段**: 仅在9:00-11:00的人之里中心
- **可交互次数**: 每日1次（工作日程紧张）
- **特殊出现**: 完成特定羁绊任务后，晚上20:00-22:00短暂休息时可访问红魔馆

---

## 行为状态机

### 状态1: 购物中（9:00-11:00）
- **位置**: village_center
- **行为模式**:
  - 在商店区域来回走动
  - 检查摊位上的物品
  - 动作精准，无多余动作
- **交互**: 允许
- **对话限制**: 每次对话限时30秒（她会看表）

### 状态2: 工作中（其他时段）
- **位置**: scarlet_mansion
- **交互**: 禁止
- **提示**: "咲夜现在正在执行女仆职责"

### 状态3: 短暂休息（20:00-22:00，bond >= 4）
- **解锁条件**: 羁绊等级4+
- **位置**: scarlet_mansion_garden（红魔馆庭院）
- **行为**: 静坐，整理银刀
- **交互**: 允许，无时间限制

### 状态4: 紧急任务（随机触发）
- **触发**: 红魔馆事件发生
- **行为**: 瞬移消失
- **玩家效果**: 对话强制中断

---

## 羁绊系统

### 羁绊点数获取规则
```gdscript
const SAKUYA_BOND_ACTIONS = {
    "talk": 10,
    "gift_tea_leaves": 80,      # 喜欢高级茶叶
    "gift_cleaning_tools": 50,  # 喜欢清洁工具
    "gift_knife": 100,          # 最爱：精美刀具
    "complete_shopping_quest": 120,  # 帮她采购
    "defend_mansion": 200,      # 保护红魔馆相关任务
}
```

### 特殊机制：时间奉献系统
```gdscript
class TimeDedicationSystem:
    # 玩家可以"献出时间"给咲夜
    func dedicate_time_to_sakuya(hours: int):
        # 玩家时间快进，咲夜获得羁绊点数
        TimeManager.advance_time(hours * 60)
        BondSystem.add_bond_points("sakuya", hours * 30)
        HumanitySystem.modify_humanity("help_others", hours * 1.0)
```

### 等级解锁内容

#### 等级0 → 1（100点）
- **机制解锁**: 可以观察她购物
- **行为变化**: 她会礼貌点头致意

#### 等级1 → 2（300点）
- **机制解锁**: 可以接取"帮忙采购"每日任务
- **任务**: 在她到达前收集指定物品交给她
- **奖励**: 时间节省，她会给予回报道具

#### 等级2 → 3（600点）
- **机制解锁**: 她会主动委托"寻找稀有材料"任务
- **行为变化**: 对话时不再频繁看表

#### 等级3 → 4（1000点）
- **机制解锁**: 解锁红魔馆庭院访问权限（20:00-22:00）
- **新地点**: scarlet_mansion_garden

#### 等级4 → 5（1500点）
- **机制解锁**: 她会教授玩家"时间管理技巧"
- **玩家buff**: 每日疲劳累积速度-10%
- **行为变化**: 休息时会主动找玩家聊天

#### 等级5 → 6（2500点）
- **机制解锁**: 解锁同伴邀请
- **特殊条件**:
  1. 必须完成"保卫红魔馆"任务链
  2. 获得蕾米莉亚的许可（隐藏剧情）
  3. 玩家人性值 >= 70（她只帮助"值得的人"）

---

## 任务流程

### 任务链1: 完美女仆的一天
**解锁**: bond_level >= 1

#### 阶段1: 晨间采购
- **目标**: 在9:00前收集"新鲜蔬菜x5"和"优质肉类x3"
- **交付**: 9:00-11:00交给咲夜
- **奖励**: bond +50, coins +100

#### 阶段2: 午餐准备
- **目标**: 采集"稀有香料x1"（需要探索竹林）
- **时间限制**: 必须在12:00前交付
- **奖励**: bond +80, 获得道具"咲夜的食谱"

#### 阶段3: 银器维护
- **目标**: 寻找"上等磨刀石x1"
- **来源**: 商店购买或打败特定敌人
- **奖励**: bond +100, 解锁"刀具保养"技能

### 任务链2: 时间的价值
**解锁**: bond_level >= 3

#### 阶段1: 观察时间
- **目标**: 在红魔馆庭院观察咲夜3次（不同日期）
- **要求**: 每次观察后记录她的动作
- **奖励**: bond +120, 解锁"时间感知"被动

#### 阶段2: 时间困境
- **触发**: 剧情事件，咲夜的时间能力失控
- **目标**: 收集"时间碎片x10"（特殊掉落物）
- **选择分支**:
  1. 立即交付 → 快速解决，bond +150
  2. 研究后交付 → 额外奖励，bond +200，解锁特殊对话

#### 阶段3: 女仆的誓言
- **目标**: 完成蕾米莉亚的委托任务（危险任务）
- **难度**: 高难度战斗
- **奖励**: bond +300, 咲夜正式承认玩家为"同等价值的存在"

### 任务链3: 保卫红魔馆（同伴解锁前置）
**解锁**: bond_level >= 5

#### 阶段1: 情报收集
- **目标**: 调查"可疑人物"（在村庄多个NPC处打听）
- **线索**: 至少3条不同线索

#### 阶段2: 防御准备
- **目标**: 制作"防护结界x5"
- **材料**: 需要炼金系统或购买

#### 阶段3: 最终战
- **触发**: 红魔馆被袭击（战斗场景）
- **目标**: 保护蕾米莉亚，击败入侵者
- **同伴**: 咲夜会并肩作战（临时同伴）
- **奖励**: bond +500, 解锁正式同伴邀请

---

## 同伴机制

### 招募条件
```gdscript
func can_recruit_sakuya() -> bool:
    return (
        BondSystem.get_bond_level("sakuya") >= 6 and
        HumanitySystem.current_humanity >= 70 and
        QuestManager.is_quest_completed("defend_scarlet_mansion") and
        has_remilia_permission  # 特殊flag
    )
```

### 同伴特性
- **HP**: 100（中等）
- **攻击**: 150（极高）
- **防御**: 60（中等）
- **特殊能力**: "时停"（战斗中使用，冷却时间长）

### 战斗行为
```gdscript
class SakuyaCombatAI:
    var knife_count: int = 12
    var time_stop_cooldown: float = 60.0

    func get_action():
        if enemy_count >= 5 and time_stop_cooldown <= 0:
            return use_time_stop()  # 时停+飞刀群攻
        elif distance_to_enemy < 200:
            return throw_knife()  # 远程飞刀
        else:
            return reposition()  # 调整位置
```

### 跟随行为
- **跟随模式**: 精确跟随，始终在玩家身后2米
- **移动速度**: 与玩家完全同步
- **对话**: 每30分钟会提醒玩家当前时间和疲劳值

### 同伴限制
```gdscript
class SakuyaAvailability:
    func check_available(hour: int) -> bool:
        # 她有自己的职责，不能全天跟随
        return hour in [9, 10, 11, 20, 21]  # 只有特定时段可用
```

---

## 特殊交互

### 时间能力展示
```gdscript
class SakuyaTimeAbility:
    func on_player_nearby():
        if bond_level >= 3 and random() < 0.1:
            trigger_time_stop_cutscene()
            # 画面暂停，咲夜移动，然后恢复
            # 玩家会发现周围环境被"整理"过
```

### 与其他NPC的关系

#### 咲夜 & 魔理沙
```gdscript
func sakuya_marisa_interaction():
    # 魔理沙经常"借"红魔馆的东西
    # 如果两人在同一场景，咲夜会警惕地盯着魔理沙
    # 对话选项会出现"保护物品"的警告
```

#### 咲夜 & 灵梦
```gdscript
func sakuya_reimu_interaction():
    # 互相尊重但保持距离
    # 两人都是"职责至上"的人
    # 特殊事件：共同应对异变时会合作
```

### 礼物系统特化
```gdscript
const SAKUYA_GIFT_PREFERENCES = {
    "tea_leaves_premium": {
        "bond": 80,
        "reaction": "show_appreciation",  # 行为：微笑+鞠躬
    },
    "silver_knife": {
        "bond": 100,
        "reaction": "inspect_carefully",  # 行为：仔细检查刀具
        "effect": "unlock_knife_technique"  # 教授玩家飞刀技能
    },
    "cleaning_tools": {
        "bond": 50,
        "reaction": "practical_nod"  # 行为：实用主义点头
    },
    "luxury_item": {
        "bond": 5,
        "reaction": "polite_refuse"  # 行为：礼貌拒绝（不需要奢侈品）
    }
}
```

---

## 数据结构

### 存档数据
```gdscript
{
    "sakuya": {
        "bond_level": 5,
        "bond_points": 1800,
        "last_talk_day": 25,
        "daily_talks": 1,
        "time_dedicated_total": 15,  # 玩家献出的总时间（小时）
        "shopping_quests_completed": 8,
        "has_garden_access": true,
        "has_remilia_permission": false,
        "knife_technique_learned": true,
        "time_management_buff_active": true,
        "is_companion": false
    }
}
```

### 实时数据
```gdscript
class SakuyaRuntimeData:
    var is_watching_player: bool = false
    var seconds_until_work_leave: float = 0.0
    var current_shopping_list: Array[String] = []
    var time_stop_charges: int = 3  # 剧情事件中的时停次数
    var efficiency_mode: bool = true  # 永远处于高效状态
```

---

## 平衡性参数

### 时间奉献系统
- **每小时**: +30 bond points
- **人性变化**: +1.0 humanity per hour
- **上限**: 每日最多奉献8小时
- **风险**: 玩家跳过的时间会累积疲劳

### 同伴战斗平衡
- **时停技能**:
  - 持续时间: 5秒
  - 冷却: 60秒
  - 效果: 敌人完全静止，咲夜可自由攻击
- **飞刀攻击**:
  - 伤害: 30-50
  - 射程: 300像素
  - 速度: 极快

### 可用时段限制
- **可交互**: 9:00-11:00（每日）
- **庭院访问**: 20:00-22:00（bond >= 4）
- **同伴跟随**: 仅在上述时段
- **紧急召唤**: bond >= 6后，可消耗道具紧急召唤（每日1次）

---

## 实现优先级

### P0（核心机制）
1. 每日9-11点购物日程
2. 基础对话系统（带时间限制）
3. 羁绊点数获取

### P1（特色体验）
4. 时间奉献系统
5. 帮忙采购任务
6. 礼物系统特化

### P2（深度内容）
7. 红魔馆庭院场景
8. "保卫红魔馆"任务链
9. 同伴招募

### P3（高级内容）
10. 时停能力展示
11. 时间管理buff
12. 与其他NPC的特殊互动
