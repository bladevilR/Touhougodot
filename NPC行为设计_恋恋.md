# 恋恋（Koishi）- 行为流程设计

## 核心哲学
- 想要理解人类，但作为纯粹妖怪无法真正理解
- 第三只眼永久关闭，被动接收所有思想碎片
- 存在本身即矛盾：���被看见却无法被记住

---

## 出现机制

### 触发条件
```gdscript
# 特殊条件系统
class KoishiSpawnCondition:
    func check() -> bool:
        return (
            WeatherSystem.current_weather == "rain" and
            not is_already_met_today
        )
```

### 位置生成
- **固定地点**: village_bridge（人之里桥边）
- **时间段**: 全天（0:00-24:00）
- **天气限定**: 仅雨天
- **状态**: NPCState.IDLE
- **可打断**: true

### 记忆机制
```gdscript
# 特殊：每次离开后玩家会忘记她
class KoishiMemorySystem:
    var met_today: bool = false
    var total_meetings: int = 0
    var forgotten_times: int = 0

    func on_interaction_end():
        forgotten_times += 1
        # 玩家离开场景后，界面上移除她的存在痕迹
        # 但后台记录保留
```

---

## 行为状态机

### 状态1: 初次遇见（forgotten_times == 0）
- **触发**: 玩家首次在雨天靠近桥边
- **行为**: 静止站立
- **交互半径**: 标准80.0
- **可见性**: 特殊逻辑（玩家视线内才渲染）

### 状态2: 重复遇见（forgotten_times > 0）
- **触发**: 玩家再次在雨天靠近
- **行为**: 依然静止，但交互后解锁新内容
- **特殊**: 她"记得"玩家，但玩家不记得她

### 状态3: 羁绊深化（bond_level >= 3）
- **解锁**: 晴天也会罕见出现（概率5%）
- **位置**: 随机在村庄边缘
- **行为**: 短暂出现后消失

---

## 羁绊系统

### 羁绊点数获取规则
```gdscript
const KOISHI_BOND_ACTIONS = {
    "talk": 15,  # 比其他NPC多50%（因为难遇见）
    "gift": 0,   # 不接受礼物
    "remember_her": 100,  # 特殊：主动提起她的存在
}
```

### 等级解锁内容

#### 等级0 → 1（100点）
- **机制解锁**: 离开场景后，日志中会留下"模糊的记忆"
- **UI变化**: HUD短暂显示"？"图标

#### 等级1 → 2（300点）
- **机制解锁**: 可以在对话选项中选择"我好像见过你"
- **效果**: 她会有反应（行为变化，非对话）

#### 等级2 → 3（600点）
- **机制解锁**: 雨天遇见她时，BGM会有微妙变化
- **行为变化**: 玩家靠近时她会转身面向玩家

#### 等级3 → 4（1000点）
- **机制解锁**: 晴天罕见出现（5%概率）
- **新位置**: 除桥边外，竹林边缘也会出现

#### 等级4 → 5（1500点）
- **机制解锁**: 玩家可以主动"寻找"她（消耗行动点）
- **成功率**: 基于羁绊等级和天气

#### 等级5 → 6（2500点）
- **机制解锁**: 解锁同伴邀请
- **特殊条件**: 必须在雨天，且玩家人性值 < 60
- **同伴能力**: 见下文

---

## 任务流程

### 任务1: 雨中的影子
- **解锁条件**: bond_level >= 1
- **目标结构**:
  1. 在雨天找到她（3次）
  2. 每次选择"我记得你"选项
  3. 完成后获得道具"湿透的笔记"
- **奖励**: bond +200, 人性 +5

### 任务2: 被遗忘的存在
- **解锁条件**: bond_level >= 3
- **目标结构**:
  1. 收集"记忆碎片"（特殊道具，雨天随机掉落）
  2. 将5个碎片带给她
  3. 触发特殊剧情流程
- **奖励**: bond +300, 解锁"晴天出现"机制

### 任务3: 第三只眼
- **解锁条件**: bond_level >= 5, humanity < 40
- **目标结构**:
  1. 在人性值<40时与她对话
  2. 她会"看到"玩家内心的黑暗
  3. 选择：拥抱黑暗 or 拒绝面对
- **分支奖励**:
  - 拥抱: bond +500, humanity -10, 解锁特殊能力
  - 拒绝: bond -100, humanity +5

---

## 同伴机制

### 招募条件
```gdscript
func can_recruit_koishi() -> bool:
    return (
        BondSystem.get_bond_level("koishi") >= 6 and
        HumanitySystem.current_humanity < 60 and
        WeatherSystem.current_weather == "rain"
    )
```

### 同伴特性
- **HP**: 80（较低）
- **攻击**: 120（高）
- **防御**: 40（低）
- **特殊能力**: "无意识攻击"（敌人无法锁定她）

### 战斗行为
```gdscript
class KoishiCombatAI:
    func get_action():
        # 随机移动，无视敌人仇恨
        # 30%概率瞬移到敌人身后攻击
        # 不会被群体攻击技能命中
```

### 跟随行为
- **跟随模式**: 不固定跟随玩家
- **出现位置**: 玩家周围随机位置，瞬间出现又消失
- **对话**: 玩家离开场景后会暂时忘记她在队伍里，但她依然在

---

## 特殊交互

### 与其他NPC的关系
```gdscript
# 恋恋与慧音
func keine_koishi_interaction():
    # 如果慧音在场景中，慧音会突然停顿
    # 慧音的对话选项会出现"刚才好像有什么..."
    # 但不会真正"看见"恋恋

# 恋恋与灵梦
func reimu_koishi_interaction():
    # 灵梦完全察觉不到她的存在
    # 即使恋恋就在旁边
```

### 环境影响
```gdscript
class KoishiEnvironmentEffects:
    func on_koishi_appear():
        # 场景亮度轻微降低
        # 环境音效变得"空洞"
        # 其他NPC的移动速度减慢10%

    func on_koishi_disappear():
        # 所有效果立即消失
        # 玩家UI上移除她的头像
```

---

## 数据结构

### 存档数据
```gdscript
{
    "koishi": {
        "total_meetings": 15,
        "forgotten_times": 15,
        "met_today": false,
        "last_meeting_day": 23,
        "bond_level": 4,
        "bond_points": 1200,
        "memory_fragments_collected": 5,
        "special_quests_completed": ["rain_shadow"],
        "can_appear_sunny": true,
        "is_companion": false
    }
}
```

### 实时数据
```gdscript
class KoishiRuntimeData:
    var is_visible_to_player: bool = false
    var seconds_since_last_vanish: float = 0.0
    var current_emotion_state: String = "curious"  # curious/sad/empty
    var thought_fragments: Array[String] = []  # 她听到的思想碎片
```

---

## 平衡性参数

### 出现概率
- **雨天**: 100%（在桥边）
- **晴天**（bond < 3）: 0%
- **晴天**（bond >= 3）: 5%
- **晴天**（bond >= 5）: 15%

### 记忆衰减
- **对话后离开场景**: 玩家忘记100%
- **对话后1小时内**: 玩家会有"模糊印象"（UI提示）
- **bond >= 3**: 离开后12小时内可以"回忆起来"

### 互动限制
- **每日对话次数**: 1次（因为会忘记，可以重复遇见但不重复奖励）
- **任务接取**: 必须在同一次对话中完成，否则忘记任务内容

---

## 实现优先级

### P0（核心机制）
1. 雨天生成逻辑
2. 玩家记忆清除机制
3. 基础对话交互

### P1（独特体验）
4. 离开场景后UI变化
5. 环境效果（亮度/音效）
6. 羁绊等级解锁

### P2（深度内容）
7. 特殊任务流程
8. 晴天罕见出现
9. 同伴招募

### P3（锦上添花）
10. 与其他NPC的特殊交互
11. 思想碎片收集系统
12. 深层剧情分支
