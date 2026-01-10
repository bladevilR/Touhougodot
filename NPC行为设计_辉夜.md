# 辉夜（Kaguya）- 行为流程设计

## 核心哲学
- 外星人/蓬莱不死人，超越人类与妖怪的分类
- 永恒的时间中寻找意义
- 孤独与永生的代价

---

## 出现机制

### 隐藏NPC特性
```gdscript
class KaguyaDiscoverySystem:
    var is_discovered: bool = false
    var hint_triggers: int = 0

    func check_discovery_conditions() -> bool:
        return (
            bond_keine >= 3 and  # 慧音提示竹林深处的秘密
            bond_marisa >= 4 and  # 魔理沙提到"永生"
            explored_bamboo_forest_nights >= 5  # 夜晚探索竹林5次
        )

    func unlock_bamboo_deep():
        # 解锁隐藏地图：bamboo_forest_deep
        is_discovered = true
        SceneManager.unlock_scene("bamboo_forest_deep")
```

### 固定位置
```gdscript
const KAGUYA_LOCATION = {
    "default": "bamboo_forest_deep",  # 竹林深处·永远亭
    "never_leaves": true  # 永远不会离开永远亭
}
```

### 时间限制
```gdscript
class KaguyaAccessTime:
    func can_visit() -> bool:
        # 只在夜晚可以拜访（18:00-6:00）
        var hour = TimeManager.current_hour
        return hour >= 18 or hour < 6

    func on_daytime_visit():
        # 白天来访，门紧闭
        show_notification("永远亭的大门紧闭，似乎主人不接待访客")
```

---

## 行为状态机

### 状态1: 永恒的等待（默认状态）
- **位置**: bamboo_forest_deep（永远亭内）
- **行为模式**:
  - 静坐
  - 玩电子游戏（现代科技）
  - 望向窗外
- **交互**: 夜晚允许，白天禁止
- **氛围**: 时间停滞的感觉

### 状态2: 游戏对决（bond >= 2）
- **触发**: 玩家挑战辉夜玩游戏
- **机制**: 小游戏系统
- **奖励**: 获胜+bond, 失败+少量bond
- **特殊**: 她会故意让玩家，因为"输了也无所谓"

### 状态3: 哲学对话（bond >= 4）
- **触发**: 深夜访问（22:00-4:00）
- **行为**: 严肃模式
- **内容**: 探讨永生、时间、存在意义
- **效果**: 深层剧情解锁

### 状态4: 月之忆（满月夜，bond >= 5）
- **触发**: 满月夜晚访问
- **行为**: 站在庭院望月
- **情绪**: 哀伤
- **剧情**: 回忆月都往事

---

## 羁绊系统

### 羁绊点数获取规则
```gdscript
const KAGUYA_BOND_ACTIONS = {
    "talk": 15,  # 能找到她已经不易
    "talk_deep_night": 30,  # 深夜对话双倍
    "gift_moon_item": 120,  # 月亮相关道具
    "gift_game": 80,  # 电子游戏、棋盘游戏
    "gift_hourai_branch": 500,  # 蓬莱之枝（特殊剧情道具）
    "win_game": 50,  # 游戏对决获胜
    "lose_game_intentionally": 100,  # 故意输给她（她能看穿）
    "discuss_eternity": 150,  # 讨论永恒话题
    "accompany_moon_viewing": 200,  # 陪她赏月
}
```

### 永生诅咒系统
```gdscript
class EternalCurseSystem:
    func on_deep_bond():
        # 高羁绊时，辉夜会提到"永生的代价"
        if bond_level >= 5:
            unlock_eternity_quest()

    func offer_hourai_elixir():
        # 她可能提供蓬莱之药（极端选择）
        # 玩家选择：
        # 1. 接受 → 获得永生，但触发永恒孤独结局
        # 2. 拒绝 → bond +500, 继续正常路线
```

### 等级解锁内容

#### 等级0 → 1（100点）
- **机制解锁**: 首次进入永远亭
- **发现**: 辉夜的存在

#### 等级1 → 2（300点）
- **机制解锁**: 可以挑战游戏对决
- **游戏类型**: 五子棋、围棋、电子游戏
- **奖励**: 获胜可得稀有道具

#### 等级2 → 3（600点）
- **机制解锁**: 深夜对话解锁
- **内容**: 了解她的过去（月之公主）
- **氛围**: 悲伤基调

#### 等级3 → 4（1000点）
- **机制解锁**: 满月夜可以陪她赏月
- **剧情**: 她讲述月都往事
- **羁绊深化**: 情感连接加强

#### 等级4 → 5（1500点）
- **机制解锁**: 解锁"永恒的难题"任务链
- **哲学**: 探讨永生与有限生命的意义
- **特殊**: 她开始对玩家产生真正的情感

#### 等级5 → 6（2500点）
- **机制解锁**: 解锁同伴邀请
- **前提**: 必须拒绝蓬莱之药
- **条件**: 证明"有限的生命也有价值"
- **稀有**: 最难招募的同伴

---

## 任务流程

### 任务链1: 寻找辉夜（解锁前置）
**触发**: 多个NPC提示

#### 阶段1: 传闻收集
- **触发点1**: 慧音提到"竹林深处有不老的存在"（bond_keine >= 3）
- **触发点2**: 魔理沙谈论"永生的秘密"（bond_marisa >= 4）
- **触发点3**: 阿求的记录中的模糊记载
- **要求**: 收集3条线索

#### 阶段2: 夜探竹林
- **目标**: 夜晚（18:00-6:00）探索竹林5次
- **随机遭遇**: 妖怪兔（守卫）
- **提示**: 月圆之夜更容易找到线索

#### 阶段3: 发现永远亭
- **触发**: 满足条件后，竹林深处出现新路径
- **场景解锁**: bamboo_forest_deep
- **首次相遇**: 辉夜的初次对话

### 任务链2: 五个难题（致敬原作）
**解锁**: bond_level >= 2

#### 难题1: 佛御石之钵
- **目标**: 寻找传说中的钵（实际是仿品）
- **地点**: 神社、寺庙
- **奖励**: bond +100, 辉夜微笑

#### 难题2: 蓬莱玉枝
- **目标**: 制作或寻找蓬莱玉枝
- **难度**: 需要稀有材料
- **奖励**: bond +150

#### 难题3: 火鼠之裘
- **目标**: 获得耐火布料
- **来源**: 击败火属性Boss或高级商店
- **奖励**: bond +120

#### 难题4: 龙首之玉
- **目标**: 击败龙类敌人，获得龙珠
- **难度**: 高难度战斗
- **奖励**: bond +200

#### 难题5: 燕之子安贝
- **目标**: 捕捉稀有鸟类或完成特殊任务
- **创意**: 玩家自由发挥
- **奖励**: bond +250, 辉夜认真看待玩家

#### 完成全部五题
- **奖励**: bond +500, 解锁"永恒的难题"任务链

### 任务链3: 永恒的难题（同伴解锁前置）
**解锁**: bond_level >= 5, 完成五个难题

#### 阶段1: 永生的提议
- **剧情**: 辉夜提出可以给玩家蓬莱之药
- **描述**: 不老不死，与她一起度过永恒
- **压力**: 时间限制选择（3天）

#### 阶段2: 灵魂的拷问
- **内容**: 玩家必须思考永生的意义
- **NPC反应**:
  - 慧音: "永生会让你失去人性"
  - 魔理沙: "我想要永生！"（羡慕）
  - 灵梦: "那违背自然法则"
- **影响**: 玩家选择会影响所有NPC关系

#### 阶段3: 最终选择
- **选择1: 接受蓬莱之药**
  - 结果: 获得永生，humanity锁定为0
  - 后果: 灵梦敌对，慧音失望，大多NPC疏远
  - 辉夜: bond锁定为最大，但她会说"你会后悔的"
  - 结局: 特殊"永恒孤独"结局分支

- **选择2: 拒绝蓬莱之药**
  - 理由: "正因为生命有限，才有意义"
  - 辉夜反应: 先沉默，���微笑
  - 效果: bond +800, 解锁同伴邀请
  - 她的改变: 开始珍惜"有限的相遇"

---

## 同伴机制

### 招募条件
```gdscript
func can_recruit_kaguya() -> bool:
    return (
        BondSystem.get_bond_level("kaguya") >= 6 and
        QuestManager.is_quest_completed("eternity_dilemma") and
        refused_hourai_elixir == true and  # 必须拒绝永生
        has_all_five_treasures == true and
        player_wisdom >= 50  # 智慧属性要求
    )
```

### 招募限制
```gdscript
class KaguyaRecruitmentLimit:
    func on_recruit_attempt():
        # 她不会"跟随"玩家
        # 只在特定时刻"陪同"玩家
        # 每次陪同有时间限制（4小时）

    func summon_kaguya():
        # 玩家可以"邀请"她出永远亭
        # 每周1次
        # 只在夜晚
```

### 同伴特性
- **HP**: 200（极高，不死）
- **攻击**: 90（中等）
- **防御**: 150（极高）
- **特殊能力**: "须臾劫火"（火焰攻击）、"蓬莱之力"（复活队友，每战1次）

### 战斗行为
```gdscript
class KaguyaCombatAI:
    var resurrection_available: bool = true

    func get_action():
        if player_hp <= 0 and resurrection_available:
            return use_hourai_resurrection()  # 复活玩家
        elif enemy_count >= 5:
            return use_fire_aoe()  # 火焰范围攻击
        elif self_hp < 30:
            return regenerate()  # 自动恢复（不死特性）
        else:
            return flame_attack()

    func use_hourai_resurrection():
        # 蓬莱之力：复活倒下的队友
        PlayerStats.hp = PlayerStats.hp_max * 0.5
        resurrection_available = false
        show_notification("辉夜的蓬莱之力将你从死亡中救回")
```

### 跟随行为
- **跟随模式**: 优雅漫步，永不疲惫
- **时间限制**: 每次陪同最多4小时
- **夜晚限定**: 白天自动返回永远亭
- **特殊**: 她会评论"这是我几百年来第一次..."

---

## 特殊交互

### 游戏对决系统
```gdscript
class GameChallengeSystem:
    const GAMES = ["gomoku", "chess", "tic_tac_toe", "video_game"]
    var kaguya_skill_level: int = 100  # 她极其擅长

    func challenge_game(game_type: String):
        if game_type == "video_game":
            # 电子游戏她反而会输（现代产物）
            kaguya_skill_level = 50
        else:
            # 传统游戏她几乎必胜
            kaguya_skill_level = 100

    func on_player_win():
        BondSystem.add_bond_points("kaguya", 50)
        # 她会惊讶，然后开心

    func on_player_intentionally_lose():
        # 她能看穿玩家故意输
        if bond_level >= 3:
            BondSystem.add_bond_points("kaguya", 100)
            # 她会说"谢谢你的温柔"
```

### 时间对话系统
```gdscript
class EternityDialogueSystem:
    const PHILOSOPHY_TOPICS = [
        "meaning_of_life",
        "eternal_vs_finite",
        "loneliness_of_immortality",
        "beauty_of_transience",
        "curse_of_hourai"
    ]

    func discuss_philosophy(topic: String):
        # 深夜（22:00-4:00）可用
        # 每个话题增加大量羁绊
        BondSystem.add_bond_points("kaguya", 150)
        PlayerStats.wisdom += 2
```

### 与其他NPC的关系

#### 辉夜 & 魔理沙
```gdscript
func kaguya_marisa_interaction():
    # 魔理沙得知辉夜的存在后，会疯狂想找她
    # 如果玩家带魔理沙来（未实现功能）
    # 魔理沙会请求永生之法
    # 辉夜会冷淡拒绝
```

#### 辉夜 & 慧音
```gdscript
func kaguya_keine_interaction():
    # 两人都涉及"改变身份"的主题
    # 但立场相反：
    # 慧音：人变妖，用妖力守护人类
    # 辉夜：超越人妖，孤独永恒
    # 如果两人见面（特殊事件），会有哲学辩论
```

#### 辉夜 & 妹红（玩家）
```gdscript
func kaguya_mokou_interaction():
    # 如果玩家选择接受蓬莱之药
    # 辉夜会说"现在我们是同类了"
    # 但语气是悲伤的
```

---

## 数据结构

### 存档数据
```gdscript
{
    "kaguya": {
        "is_discovered": true,
        "bond_level": 5,
        "bond_points": 1900,
        "last_visit_day": 32,
        "games_won": 3,
        "games_lost": 12,
        "five_treasures_completed": [true, true, true, true, true],
        "hourai_elixir_offered": true,
        "hourai_elixir_accepted": false,  # 关键选择
        "philosophy_discussions": 8,
        "moon_viewings": 4,
        "is_companion": false,
        "time_spent_together": 25.5,  # 小时
        "resurrection_used_count": 0
    }
}
```

### 实时数据
```gdscript
class KaguyaRuntimeData:
    var current_game: String = ""
    var game_progress: float = 0.0
    var mood: String = "melancholy"  # melancholy/amused/sad/hopeful
    var hours_since_last_visit: float = 0.0
    var is_outside_eientei: bool = false  # 是否离开永远亭
    var time_limit_remaining: float = 4.0  # 剩余陪同时间
```

---

## 平衡性参数

### 发现难度
- **NPC羁绊要求**: keine >= 3, marisa >= 4
- **探索要求**: 夜探竹林5次
- **隐藏度**: 最高（隐藏NPC）

### 羁绊难度
- **对话频率**: 受夜晚限制
- **礼物偏好**: 极其挑剔
- **任务难度**: 五个难题需要大量时间
- **最终选择**: 拒绝永生（反直觉）

### 同伴平衡
- **优点**:
  - 不会死（HP为0时自动复活）
  - 可以复活玩家（每战1次）
  - 高防御
- **限制**:
  - 每周只能召唤1次
  - 每次只能陪同4小时
  - 只在夜晚可用
  - 白天强制返回

### 蓬莱之药选择
- **接受永生**:
  - 永久buff: 不会老死
  - 永久debuff: humanity = 0（锁定）
  - 社交惩罚: 大多NPC关系恶化
  - 结局: 特殊"永恒孤独"分支
- **拒绝永生**:
  - 羁绊: +800
  - 解锁: 同伴邀请
  - 成就: "珍惜有限"

---

## 实现优先级

### P0（发现机制）
1. bamboo_forest_deep隐藏场景
2. 夜晚时间限制
3. NPC提示系统

### P1（核心体验）
4. 游戏对决系统
5. 深夜哲学对话
6. 满月赏月事件

### P2（深度内容）
7. 五个难题任务链
8. 永生选择剧情
9. 同伴招募（极难）

### P3（终极内容）
10. 多NPC联动事件
11. 永恒孤独特殊结局
12. 蓬莱复活机制

---

## 特殊说明

辉夜是整个游戏中**最难获得、最难理解、最具哲学性**的NPC。她的存在是对"人性"主题的终极拷问：

- **永生 vs 有限生命**
- **孤独 vs 羁绊**
- **永恒 vs 瞬间**

玩家与她的互动，应该让玩家深刻思考"活着的意义"。
