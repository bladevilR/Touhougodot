# 灵梦（Reimu）- 行为流程设计

## 核心哲学
- 作为纯粹人类，管理妖怪
- 维持幻想乡的平衡
- 职责与个人感情的冲突

---

## 出现机制

### 日程触发
```gdscript
const REIMU_SCHEDULE = [
    {
        "time_start": 7,
        "time_end": 9,
        "location": "hakurei_shrine",
        "action": "morning_routine",
        "state": NPCState.IDLE,
        "interruptible": true
    },
    {
        "time_start": 9,
        "time_end": 12,
        "location": "hakurei_shrine",
        "action": "shrine_duties",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 12,
        "time_end": 14,
        "location": "hakurei_shrine",
        "action": "lunch_and_tea",
        "state": NPCState.EATING,
        "interruptible": true
    },
    {
        "time_start": 14,
        "time_end": 17,
        "location": "town",  # 人之里巡逻
        "action": "patrol",
        "state": NPCState.WALKING,
        "interruptible": true
    },
    {
        "time_start": 17,
        "time_end": 20,
        "location": "hakurei_shrine",
        "action": "evening_duties",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 20,
        "time_end": 22,
        "location": "hakurei_shrine",
        "action": "relax",
        "state": NPCState.IDLE,
        "interruptible": true
    },
    {
        "time_start": 22,
        "time_end": 7,
        "location": "hakurei_shrine",
        "action": "sleep",
        "state": NPCState.SLEEPING,
        "interruptible": false
    }
]
```

### 人性阈值触发特殊日程
```gdscript
class ReimuExterminationSchedule:
    func on_humanity_critical_low():
        if HumanitySystem.current_humanity < 20:
            activate_extermination_mode()

    func activate_extermination_mode():
        # 灵梦切换到"退治"日程
        override_schedule_to_extermination()

const EXTERMINATION_SCHEDULE = [
    {
        "time_start": 10,
        "time_end": 12,
        "location": "bamboo_house",  # 妹红的家
        "action": "extermination_standby",
        "state": NPCState.SPECIAL,
        "interruptible": false  # 不可打断
    }
]
```

### 出现条件
- **固定地点1**: hakurei_shrine（大部分时间）
- **固定地点2**: town/village_center（14:00-17:00，巡逻）
- **特殊触发**: bamboo_house（人性<20，退治事件）

---

## 行为状态机

### 状态1: 神社职责（9:00-12:00, 17:00-20:00）
- **位置**: hakurei_shrine
- **行为模式**:
  - 打扫神社
  - 维护结界
  - 处理异变报告
- **交互**: 禁止
- **提示**: "灵梦正在履行巫女职责"

### 状态2: 茶休时间（12:00-14:00）
- **位置**: hakurei_shrine（庭院）
- **行为模式**:
  - 坐在廊下喝茶
  - 悠闲状态
- **交互**: 完全开放
- **特殊**: 最容易接近的时段

### 状态3: 巡逻模式（14:00-17:00）
- **位置**: town/village_center
- **行为模式**:
  - 中速移动
  - 观察周围异常
  - 偶尔停下询问村民
- **交互**: 允许，但对话简短
- **随机事件**: 可能遭遇妖怪袭击，触发战斗

### 状态4: 退治模式（humanity < 20触发）
- **触发**: 玩家人性值跌破20
- **位置**: bamboo_house门口
- **行为**: 严肃站立，等待玩家
- **交互**: 强制对话触发
- **后果**: 见任务流程"退治的抉择"

### 状态5: 异变解决模式（随机触发）
- **触发**: 幻想乡发生异变
- **行为**: 暂时离开常规日程
- **玩家影响**: 无法找到灵梦（持续1-3天）
- **结束**: 异变解决后恢复日程

---

## 羁绊系统

### 羁绊点数获取规则
```gdscript
const REIMU_BOND_ACTIONS = {
    "talk": 10,
    "talk_tea_time": 20,  # 茶休时间对话双倍
    "gift_offering": 70,  # 神社供奉
    "gift_tea": 50,  # 喜欢茶叶
    "gift_sake": 90,  # 最爱：酒
    "donate_shrine": 80,  # 捐款修缮神社
    "help_resolve_incident": 250,  # 帮助解决异变
    "maintain_humanity": 30,  # 保持人性值高于60（每周结算）
}
```

### 职责冲突系统
```gdscript
class DutyConflictSystem:
    func check_conflict():
        # 灵梦的职责：维持秩序
        # 玩家的身份：半妖怪化
        if player_humanity < 30 and bond_level >= 4:
            trigger_conflict_event()

    func trigger_conflict_event():
        # 她必须在职责和友情间选择
        # 高羁绊可以说服她放弃退治
        # 低羁绊会强制战斗
```

### 等级解锁内容

#### 等级0 → 1（100点）
- **机制解锁**: 可以在神社捐款
- **功能**: 捐款后获得临时祝福buff

#### 等级1 → 2（300点）
- **机制解锁**: 茶休时间可以一起喝茶
- **行为变化**: 她会主动招呼玩家

#### 等级2 → 3（600点）
- **机制解锁**: 可以请求灵梦协助战斗（每周1次）
- **战斗支援**: 临时同伴，持续30分钟

#### 等级3 → 4（1000点）
- **机制解锁**: 解锁"异变调查"联合任务
- **剧情**: 开始理解她的职责压力

#### 等级4 → 5（1500点）
- **机制解锁**: 人性<30时，灵梦会先警告而非直接退治
- **关键**: 职责与友情的平衡点

#### 等级5 → 6（2500点）
- **机制解锁**: 解锁同伴邀请
- **特殊条件**:
  1. 完成"平衡的守护者"任务链
  2. 玩家人性值 >= 50（必须维持在安全范围）
  3. 解决至少3次异变
  4. 获得幻想乡其他势力的认可

---

## 任务流程

### 任务链1: ���治的抉择（强制触发，humanity < 20）
**触发**: 玩家人性值跌破20

#### 阶段1: 巫女的警告
- **内容**: 灵梦出现在竹林小屋门口
- **机制**: 强制对话，无法逃避
- **选择**:
  1. 接受退治（Game Over bad ending）
  2. 请求宽限期
  3. 尝试战斗（极难）

#### 阶段2: 赎罪之路
- **条件**: 选择"请求宽限期"
- **目标**: 7天内将人性恢复到40以上
- **限制**: 灵梦会监视玩家
- **压力**: 每天灵梦会检查进度

#### 阶段3: 最终审判
- **成功**: 人性恢复到40+ → bond +300, 获得"第二次机会"成就
- **失败**: 人性仍<40 → 强制战斗或Bad Ending
- **特殊**: bond >= 4时，灵梦会帮助玩家恢复人性

### 任务链2: 神社的日常
**解锁**: bond_level >= 2

#### 阶段1: 神社修缮
- **触发**: 灵梦抱怨神社破损
- **目标**: 收集"木材x20"、"石材x15"
- **选择**:
  1. 自己采集材料 → bond +80
  2. 捐款雇人修缮 → bond +50
- **奖励**: 神社焕然一新，解锁神社祝福系统

#### 阶段2: 茶会招待
- **目标**: 准备茶会（收集高级茶叶x3）
- **时间**: 在茶休时间（12:00-14:00）举行
- **NPC**: 可能有其他NPC参加（魔理沙、咲夜等）
- **奖励**: bond +120, 多NPC羁绊同时提升

#### 阶段3: 供奉之礼
- **目标**: 连续7天每日捐款或供奉
- **累积**: 每天bond +10
- **奖励**: 解锁"博丽的庇护"永久buff（受伤时10%概率自动回复）

### 任务链3: 异变解决（随机触发）
**触发**: 幻想乡发生异变

#### 阶段1: 异变侦测
- **内容**: 灵梦请求玩家协助调查
- **目标**: 前往3个地点收集线索
- **奖励**: bond +100

#### 阶段2: 追踪源头
- **目标**: 根据线索找到异变源头
- **战斗**: 中高难度战斗
- **支援**: 灵梦作为临时同伴

#### 阶段3: 彻底解决
- **最终战**: 高难度Boss战
- **机制**: 灵梦的符卡系统协助
- **奖励**: bond +300, 稀有道具, 幻想乡声望大幅提升

### 任务链4: 平衡的守护者（同伴解锁前置）
**解锁**: bond_level >= 5

#### 阶段1: 巫女的困惑
- **剧情**: 灵梦对"职责"产生疑问
- **内容**: 深度对话，探讨人类与妖怪的关系

#### 阶段2: 维持平衡
- **目标**: 协助灵梦处理3个"灰色地带"事件
  1. 妖怪伤害人类（但有正当理由）
  2. 人类挑衅妖怪（但受伤）
  3. 半妖怪的身份困境
- **选择**: 每个事件有多种解决方案
- **影响**: 灵梦的价值观会因玩家选择而变化

#### 阶段3: 超越职责
- **最终考验**: 大规模人妖冲突
- **目标**: 不偏袒任何一方，找到平衡解决方案
- **难度**: 极高（外交+战斗）
- **奖励**: bond +500, 灵梦承认玩家为"平衡的守护者"，解锁同伴邀请

---

## 同伴机制

### 招募条件
```gdscript
func can_recruit_reimu() -> bool:
    return (
        BondSystem.get_bond_level("reimu") >= 6 and
        HumanitySystem.current_humanity >= 50 and
        QuestManager.is_quest_completed("balance_keeper") and
        resolved_incidents >= 3 and
        gensokyo_reputation >= 1000
    )
```

### 同伴特性
- **HP**: 120（中高）
- **攻击**: 140（高）
- **防御**: 70（中）
- **特殊能力**: "阴阳玉"（自动追踪弹）、"梦想封印"（封印敌人技能）

### 战斗行为
```gdscript
class ReimuCombatAI:
    var yin_yang_orbs: int = 5
    var sealing_cooldown: float = 45.0

    func get_action():
        if enemy_is_boss and sealing_cooldown <= 0:
            return use_fantasy_seal()  # 梦想封印，削减Boss能力
        elif enemy_count >= 3:
            return release_yin_yang_orbs()  # 释放阴阳玉群攻
        elif distance_to_enemy < 100:
            return melee_gohei_attack()  # 近战御币攻击
        else:
            return throw_ofuda()  # 投掷符咒

    func use_fantasy_seal():
        # 强力封印技能
        # 敌人攻击-50%, 速度-30%, 持续15秒
        sealing_cooldown = 45.0
```

### 跟随行为
- **跟随模式**: 自由飞行，在玩家上方
- **战斗定位**: 全能型，攻守兼备
- **监督**: 会监视玩家行为，人性值下降时会警告

### 时间限制
```gdscript
class ReimuAvailability:
    func check_available(hour: int) -> bool:
        # 神社职责时间不可用
        if hour >= 9 and hour < 12:
            return false
        elif hour >= 17 and hour < 20:
            return false
        else:
            return true
```

### 特殊限制：人性监督
```gdscript
class HumanitySupervision:
    func on_player_humanity_drop():
        if HumanitySystem.current_humanity < 40:
            reimu_warning()
        if HumanitySystem.current_humanity < 30:
            reimu_leave_party()  # 强制离队
            trigger_extermination_event()
```

---

## 特殊交互

### 神社祝福系统
```gdscript
class ShrineBlessingSystem:
    const BLESSINGS = {
        "luck": {
            "cost": 100,
            "effect": "drop_rate +20%",
            "duration": 3600  # 1小时
        },
        "protection": {
            "cost": 200,
            "effect": "defense +15%",
            "duration": 7200
        },
        "purification": {
            "cost": 500,
            "effect": "humanity +10",
            "duration": 0  # 即时生效
        }
    }

    func request_blessing(blessing_id: String):
        if player_money >= cost:
            apply_blessing()
            BondSystem.add_bond_points("reimu", 10)
```

### 异变系统
```gdscript
class IncidentSystem:
    var active_incident: Dictionary = {}
    var incident_severity: int = 0  # 1-5级

    func trigger_random_incident():
        # 每30天有30%概率触发异变
        if random() < 0.3:
            generate_incident()
            notify_reimu()

    func generate_incident():
        # 随机生成异变类型
        # 雾之异变、花之异变、月之异变等
        active_incident = {
            "type": "mist",
            "source": "scarlet_mansion",
            "severity": 3,
            "deadline": TimeManager.current_day + 7
        }
```

### 与其他NPC的关系

#### 灵梦 & 魔理沙
```gdscript
func reimu_marisa_interaction():
    # 竞争又合作的关系
    # 异变时会一起行动
    # 特殊联合任务："红白黑的异变解决"
```

#### 灵梦 & 咲夜
```gdscript
func reimu_sakuya_interaction():
    # 互相尊重但保持距离
    # 两人都是职责至上
    # 红魔馆异变时会有特殊对话
```

#### 灵梦 & 慧音
```gdscript
func reimu_keine_interaction():
    # 都是守护者角色
    # 村庄遇袭时会联手
    # 联合任务："守护人之里"
```

---

## 数据结构

### 存档数据
```gdscript
{
    "reimu": {
        "bond_level": 5,
        "bond_points": 1700,
        "last_talk_day": 30,
        "daily_talks": 1,
        "shrine_donations": 5000,
        "blessings_received": 15,
        "incidents_resolved": 3,
        "extermination_triggered": false,
        "extermination_resolved": false,
        "humanity_warnings": 2,
        "is_companion": false,
        "trust_level": "high"  # low/medium/high/absolute
    }
}
```

### 实时数据
```gdscript
class ReimuRuntimeData:
    var is_on_duty: bool = false
    var patrol_progress: float = 0.0
    var current_incident: Dictionary = {}
    var yin_yang_orbs_count: int = 5
    var sealing_charges: int = 3
    var mood: String = "calm"  # calm/alert/angry
```

---

## 平衡性参数

### 人性监督阈值
- **40-100**: 正常状态
- **30-39**: 警告状态（灵梦会提醒）
- **20-29**: 威胁状态（灵梦施压，要求改善）
- **0-19**: 退治状态（强制触发退治事件）

### 退治事件难度
- **bond < 2**: 无法说服，强制战斗（极难）
- **bond 2-3**: 可以请求宽限，7天时间
- **bond 4-5**: 灵梦会帮助恢复人性
- **bond 6**: 灵梦会违背职责，选择相信玩家

### 同伴战斗数值
- **梦想封印**:
  - 敌人攻击-50%
  - 敌人速度-30%
  - 持续: 15秒
  - 冷却: 45秒
- **阴阳玉**:
  - 5颗自动追踪弹
  - 每颗伤害: 40
  - 每10秒恢复1颗

---

## 实现优先级

### P0（核心机制）
1. hakurei_shrine场景和基础日程
2. 巡逻时段出现（14-17点）
3. 人性<20触发退治事件

### P1（关键体验）
4. 退治的抉择任务链（强制剧情）
5. 茶休时间交互
6. 神社祝福系统

### P2（深度内容）
7. 异变系统
8. "平衡的守护者"任务链
9. 同伴招募

### P3（高级内容）
10. 复杂的职责冲突系统
11. 多NPC联动异变
12. 人性监督系统优化
