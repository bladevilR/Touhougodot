# 慧音（Keine）- 行为流程设计

## 核心哲学
- 从人类变成妖怪（白泽）
- 用妖怪的力量保护人类
- 身份认同的挣扎与超越

---

## 出现机制

### 日程触发
```gdscript
const KEINE_SCHEDULE = [
    {
        "time_start": 6,
        "time_end": 8,
        "location": "keine_house",
        "action": "wake_up",
        "state": NPCState.IDLE,
        "interruptible": true
    },
    {
        "time_start": 8,
        "time_end": 12,
        "location": "temple_school",  # 寺子屋
        "action": "teaching",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 12,
        "time_end": 13,
        "location": "temple_school",
        "action": "lunch",
        "state": NPCState.EATING,
        "interruptible": true
    },
    {
        "time_start": 13,
        "time_end": 17,
        "location": "temple_school",
        "action": "teaching",
        "state": NPCState.WORKING,
        "interruptible": false
    },
    {
        "time_start": 17,
        "time_end": 19,
        "location": "town_plaza",  # 散步（人之里中心）
        "action": "walking",
        "state": NPCState.WALKING,
        "interruptible": true
    },
    {
        "time_start": 19,
        "time_end": 22,
        "location": "keine_house",
        "action": "relax",
        "state": NPCState.IDLE,
        "interruptible": true
    },
    {
        "time_start": 22,
        "time_end": 6,
        "location": "keine_house",
        "action": "sleep",
        "state": NPCState.SLEEPING,
        "interruptible": false
    }
]
```

### 满月机制（白泽形态）
```gdscript
class KeineFullMoonTransform:
    func check_transform() -> bool:
        return CalendarManager.is_full_moon()

    func on_full_moon():
        # 满月夜变成白泽形态
        transform_to_hakutaku()
        # 日程改变
        override_schedule_to_night_patrol()

const HAKUTAKU_SCHEDULE = [
    {
        "time_start": 18,
        "time_end": 6,
        "location": "village_outskirts",  # 村庄外围巡逻
        "action": "protecting_village",
        "state": NPCState.SPECIAL,
        "interruptible": false  # 巡逻时不可打断
    }
]
```

### 出现条件
- **固定地点1**: temple_school（8:00-17:00）
- **固定地点2**: town_plaza（17:00-19:00，散步）
- **满月特殊**: village_outskirts（18:00-次日6:00）
- **可访问**: keine_house（19:00-22:00，bond >= 3）

---

## 行为状态机

### 状态1: 教师模式（8:00-17:00，寺子屋）
- **位置**: temple_school
- **行为模式**:
  - 站在讲台前
  - 偶尔翻阅书籍
  - 教书时严肃认真
- **交互**: 仅午餐时间（12:00-13:00）可交互
- **提示**: 工作时段显示"慧音正在教书，请勿打扰"

### 状态2: 散步模式（17:00-19:00，人之里中心）
- **位置**: town_plaza（人之里中心）
- **行为模式**:
  - 慢速移动
  - 观察村民
  - 偶尔停下思考
- **交互**: 完全开放
- **特殊**: 玩家人性<40时，她会主动接近玩家

### 状态3: 私人时间（19:00-22:00，自宅）
- **解锁**: bond >= 3
- **位置**: keine_house
- **行为**: 阅读历史书籍
- **交互**: 允许，更深入的对话

### 状态4: 白泽形态（满月夜，18:00-6:00）
- **触发**: 满月
- **位置**: village_outskirts（村庄外围）
- **行为**: 巡逻，保护村庄
- **交互**: 特殊规则（见下文）
- **战斗力**: 大幅提升

---

## 羁绊系统

### 羁绊点数获取规则
```gdscript
const KEINE_BOND_ACTIONS = {
    "talk": 10,
    "talk_during_walk": 15,  # 散步时对话额外奖励
    "gift_history_book": 100,  # 最爱：历史书
    "gift_food": 40,  # 喜欢：食物
    "help_teaching": 120,  # 帮助教学
    "protect_student": 200,  # 保护学生（触发事件）
    "understand_identity": 150,  # 理解她的身份挣扎
}
```

### 人性关怀系统
```gdscript
class HumanityConcernSystem:
    func check_player_humanity():
        if HumanitySystem.current_humanity < 40:
            trigger_keine_concern_event()

    func trigger_keine_concern_event():
        # 慧音会主动找玩家谈话
        # 提供任务"重拾人性"
        # 完成后恢复人性值
```

### 等级解锁内容

#### 等级0 → 1（100点）
- **机制解锁**: 可以在寺子屋旁听课程
- **玩家buff**: 每次旁听获得少量经验值

#### 等级1 → 2（300点）
- **机制解锁**: 解锁"历史知识"对话选项
- **功能**: 可以询问幻想乡历史，获得世界观信息

#### 等级2 → 3（600点）
- **机制解锁**: 解锁keine_house访问权限（19:00-22:00）
- **行为变化**: 散步时会主动打招呼

#### 等级3 → 4（1000点）
- **机制解锁**: 可以参与教学任务
- **新功能**: 教学小游戏，提升智力属性
- **特殊**: 了解她的妖怪身份

#### 等级4 → 5（1500点）
- **机制解锁**: 满月夜可以陪她巡逻
- **战斗支援**: 巡逻时遇敌，她会协助战斗
- **剧情**: 深入探讨她的身份认同

#### 等级5 → 6（2500点）
- **机制解锁**: 解锁同伴邀请
- **特殊条件**:
  1. 完成"身份的答案"任务链
  2. 玩家人性值 >= 60
  3. 获得村民的信任（完成村庄任务x5）

---

## 任务流程

### 任务链1: 历史的守护者
**解锁**: bond_level >= 2

#### 阶段1: 失落的历史
- **触发**: 慧音委托寻找古代文献
- **目标**: 探索遗迹，找到"古代卷轴x3"
- **奖励**: bond +80, 历史知识+1

#### 阶段2: 历史的真相
- **内容**: 卷轴记载了人类与妖怪的战争历史
- **选择**:
  1. 告诉慧音真相 → bond +120, 触发深层剧情
  2. 隐瞒部分内容 → bond +60, 任务简化结束
- **影响**: 影响后续剧情走向

#### 阶段3: 历史的传承
- **目标**: 帮助慧音在寺子屋讲授历史课
- **玩家参与**: 教学小游戏（选择正确答案）
- **奖励**: bond +150, 解锁"历史学者"称号

### 任务链2: 人性的关怀（玩家人性<40触发）
**触发**: 玩家人性值跌破40，慧音主动触发

#### 阶段1: 慧音的担忧
- **内容**: 慧音察觉玩家状态异常
- **机制**: 强制对话事件

#### 阶段2: 重拾人性的道路
- **目标**: 完成慧音布置的3个善行任务
  1. 帮助村民修理房屋
  2. 保护孩子免受妖怪袭击
  3. 捐赠物资给村庄
- **奖励**: humanity +20, bond +200

#### 阶段3: 心灵的治愈
- **内容**: 慧音的开导和鼓励
- **效果**: 解锁"慧音的庇护"buff（人性衰减速度-30%）
- **奖励**: bond +180

### 任务链3: 身份的答案（同伴解锁前置）
**解锁**: bond_level >= 5

#### 阶段1: 满月的秘密
- **触发**: 第一次在满月夜遇见白泽形态的慧音
- **目标**: 陪她巡逻一整夜
- **遭遇**: 村庄被妖怪袭击

#### 阶段2: 人类还是妖怪
- **剧情**: 村民发现慧音的妖怪身份
- **危机**: 村民恐慌，要求驱逐慧音
- **玩家选择**:
  1. 支持慧音，说服村民 → 需要高声望
  2. 保持中立 → 慧音离开村庄
  3. 站在村民一边 → 关系破裂

#### 阶段3: 超越身份
- **条件**: 选择支持慧音
- **目标**: 帮助慧音证明自己（击退大规模妖怪入侵）
- **战斗**: 高难度防御战，慧音作为临时同伴
- **结局**: 村民接受慧音，她找到身份认同
- **奖励**: bond +500, 解锁正式同伴邀请

---

## 同伴机制

### 招募条件
```gdscript
func can_recruit_keine() -> bool:
    return (
        BondSystem.get_bond_level("keine") >= 6 and
        HumanitySystem.current_humanity >= 60 and
        QuestManager.is_quest_completed("identity_answer") and
        village_reputation >= 500  # 村庄声望要求
    )
```

### 同伴特性
- **HP**: 150（高）
- **攻击**: 100（中等）
- **防御**: 90（高）
- **特殊能力**: "历史吞噬"（消除敌人buff）、"白泽守护"（满月夜属性翻倍）

### 形态切换
```gdscript
class KeineFormSystem:
    enum Form {
        HUMAN,      # 人类形态（普通）
        HAKUTAKU    # 白泽形态（满月）
    }

    var current_form: Form = Form.HUMAN

    func on_full_moon():
        current_form = Form.HAKUTAKU
        hp_max *= 1.5
        attack *= 2.0
        defense *= 1.8

    func on_moon_wane():
        current_form = Form.HUMAN
        restore_normal_stats()
```

### 战斗行为
```gdscript
class KeineCombatAI:
    func get_action():
        if current_form == Form.HAKUTAKU:
            return hakutaku_combat_ai()
        else:
            return human_combat_ai()

    func human_combat_ai():
        # 防守型，保护玩家
        if player_hp < 30:
            return shield_player()
        elif enemy_has_buff:
            return use_history_eater()  # 消除buff
        else:
            return normal_attack()

    func hakutaku_combat_ai():
        # 攻守兼备，主动进攻
        if enemy_count >= 4:
            return use_aoe_attack()
        else:
            return use_powerful_strike()
```

### 跟随行为
- **跟随模式**: 贴身保护，在玩家侧后方
- **防御优先**: 敌人接近玩家时自动拦截
- **教导**: 每隔1小时会分享历史知识（小幅经验值奖励）

### 时间限制
```gdscript
class KeineAvailability:
    func check_available(hour: int, day: int) -> bool:
        # 她有教学职责
        if hour >= 8 and hour < 17:
            return false  # 工作时间不可用
        else:
            return true
```

---

## 特殊交互

### 满月事件
```gdscript
class FullMoonEvent:
    func on_full_moon_start():
        # 当晚18:00自动触发
        Keine.transform_to_hakutaku()
        trigger_cutscene_transformation()

    func on_full_moon_patrol():
        # 玩家可选择陪同巡逻（bond >= 4）
        if bond_level >= 4:
            unlock_patrol_quest()
            # 巡逻中随机遭遇妖怪袭击
            # 慧音会展现强大战斗力
```

### 历史教学系统
```gdscript
class HistoryTeachingSystem:
    const HISTORY_TOPICS = [
        "human_youkai_war",
        "hakurei_barrier",
        "gensokyo_creation",
        "lunar_capital",
        "hourai_elixir"
    ]

    func attend_class(topic: String):
        # 玩家旁听课程
        PlayerStats.add_exp(50)
        PlayerStats.knowledge += 1
        BondSystem.add_bond_points("keine", 5)
```

### 与其他NPC的关系

#### 慧音 & 妹红（玩家）
```gdscript
func keine_mokou_interaction():
    # 慧音对妹红（玩家）有特殊关心
    # 如果玩家人性低，慧音会特别担心
    # 对话选项会有更多关怀内容
```

#### 慧音 & 阿求
```gdscript
func keine_akyuu_interaction():
    # 阿求会在13:00-15:00访问寺子屋
    # 两人会讨论历史
    # 玩家可以同时与两人对话，获得双倍羁绊
```

#### 慧音 & 灵梦
```gdscript
func keine_reimu_interaction():
    # 互相尊重的关系
    # 慧音会请灵梦帮忙驱除威胁村庄的妖怪
    # 玩家可以接取联合任务
```

---

## 数据结构

### 存档数据
```gdscript
{
    "keine": {
        "bond_level": 5,
        "bond_points": 1650,
        "last_talk_day": 28,
        "daily_talks": 1,
        "has_house_access": true,
        "knows_youkai_identity": true,
        "village_acceptance": true,  # 村民是否接受她的身份
        "full_moon_patrols": 3,  # 陪同巡逻次数
        "history_classes_attended": 12,
        "identity_quest_completed": true,
        "is_companion": false,
        "current_form": "human"  # human/hakutaku
    }
}
```

### 实时数据
```gdscript
class KeineRuntimeData:
    var is_in_class: bool = false
    var students_present: int = 0
    var current_teaching_topic: String = ""
    var transformation_timer: float = 0.0  # 满月倒计时
    var protection_range: float = 500.0  # 保护范围
```

---

## 平衡性参数

### 满月形态加成
- **HP**: +50%
- **攻击**: +100%
- **防御**: +80%
- **持续时间**: 满月夜（18:00-次日6:00）
- **频率**: 每月1次

### 教学系统收益
- **每次旁听**: +50 exp
- **完成教学任务**: +150 exp, +5 bond
- **知识点**: 每10点知识提升1%魔法伤害

### 同伴战斗数值
- **历史吞噬**:
  - 效果: 移除敌人所有正面buff
  - 冷却: 20秒
  - 成功率: 90%
- **白泽守护**（满月形态）:
  - 效果: 玩家受到的伤害-40%
  - 范围: 200像素
  - 持续: 被动

---

## 实现优先级

### P0（核心机制）
1. 寺子屋场景和教师日程
2. 散步时段出现（17-19点）
3. 基础羁绊系统

### P1（特色体验）
4. 满月变身机制
5. 人性关怀系统（humanity < 40触发）
6. 历史教学小游戏

### P2（深度内容）
7. keine_house场景
8. "身份的答案"任务链
9. 同伴招募

### P3（高级内容）
10. 满月巡逻系统
11. 与阿求的联动事件
12. 村庄防御战
