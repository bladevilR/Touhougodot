# NPC系统 - 核心机制总览

## 一、6个NPC的哲学主题

### 身份光谱
```
纯粹妖怪 ←──────────────────────→ 纯粹人类
   |              |           |           |              |
 恋恋          慧音        辉夜       魔理沙         咲夜/灵梦
(纯妖)      (人→妖)    (超越分类)   (人活得像妖)   (人管理妖/服侍妖)
```

### 核心矛盾
- **恋恋**: 想理解人类但永远无法理解（认知鸿沟）
- **咲夜**: 作为人类服侍妖怪（忠诚 vs 身份）
- **魔理沙**: 作为人类追求妖怪的永生（欲望 vs 本质）
- **慧音**: 变成妖怪后守护人类（身份 vs 职责）
- **灵梦**: 作为人类管理妖怪（职责 vs 感情）
- **辉夜**: 超越分类的永恒存在（永恒 vs 有限）

---

## 二、发现难度分级

### Tier 1: 日常可见（容易遇见）
- **慧音**: 寺子屋/人之里，每日固定时段
- **魔理沙**: 人之里，每日2次时段
- **咲夜**: 人之里，每日1次时段
- **灵梦**: 神社/人之里巡逻

### Tier 2: 条件触发（中等难度）
- **恋恋**: 雨天限定，人之里桥边
  - 触发条件: 天气=雨

### Tier 3: 隐藏NPC（高难度）
- **辉夜**: 竹林深处·永远亭
  - 解锁条件:
    1. bond_keine >= 3（慧音提示）
    2. bond_marisa >= 4（魔理沙提示）
    3. 夜探竹林5次
  - 访问限制: 仅夜晚（18:00-6:00）

---

## 三、羁绊难度排序

### 最容易（快速建立羁绊）
1. **慧音**: 固定出现，关心玩家，人性低时主动帮助
2. **魔理沙**: 一天2次，频繁对话机会

### 中等难度
3. **灵梦**: 巡逻时段可对话，但有职责冲突
4. **咲夜**: 仅9-11点可见，时间紧张

### 较难
5. **恋恋**: 雨天限定，玩家会忘记她

### 最难
6. **辉夜**: 隐藏NPC，夜晚限定，极高要求

---

## 四、同伴招募条件对比

### 基础条件
| NPC | 羁绊等级 | 人性要求 | 前置任务 | 特殊条件 |
|-----|---------|---------|---------|---------|
| 慧音 | 6 | ≥60 | 身份的答案 | 村庄声望≥500 |
| 魔理沙 | 6 | 无 | 永生之秘 | 学习≥5魔法, 魔法等级≥3 |
| 灵梦 | 6 | ≥50 | 平衡的守护者 | 解决≥3异变, 幻想乡声望≥1000 |
| 咲夜 | 6 | ≥70 | 保卫红魔馆 | 蕾米莉亚许可 |
| 恋恋 | 6 | <60 | 第三只眼 | 雨天, 特殊选择 |
| 辉夜 | 6 | 无 | 永恒的难题 | 拒绝永生, 智慧≥50 |

### 招募难度排序
1. **魔理沙**: 无人性要求，学魔法即可 ⭐⭐
2. **慧音**: 中等人性要求，村庄任务简单 ⭐⭐⭐
3. **灵梦**: 需要保持人性，解决异变较难 ⭐⭐⭐⭐
4. **咲夜**: 高人性要求，需要额外NPC许可 ⭐⭐⭐⭐
5. **恋恋**: 低人性要求（反向），雨天限制 ⭐⭐⭐⭐⭐
6. **辉夜**: 发现难+拒绝诱惑+哲学考验 ⭐⭐⭐⭐⭐⭐

---

## 五、同伴战斗特性

### 坦克型
- **慧音**: HP 150, Defense 90
  - 能力: 历史吞噬（消buff）, 满月翻倍
  - 定位: 保护型前排

- **辉夜**: HP 200（不死）, Defense 150
  - 能力: 蓬莱复活（队友复活）, 自动恢复
  - 定位: 不死肉盾

### DPS型
- **魔理沙**: HP 90, Attack 180
  - 能力: Master Spark（高伤害直线）
  - 定位: 后排魔法输出
  - 缺点: 低防御

- **咲夜**: HP 100, Attack 150
  - 能力: 时停（控制）, 飞刀群攻
  - 定位: 刺客型DPS

### 全能型
- **灵梦**: HP 120, Attack 140
  - 能力: 阴阳玉（自动追踪）, 梦想封印（削弱）
  - 定位: 攻守兼备

### 特殊型
- **恋恋**: HP 80, Attack 120
  - 能力: 无意识攻击（无法被锁定）, 瞬移
  - 定位: 闪避刺客

---

## 六、关键系统机制

### 1. 人性值与NPC关系
```gdscript
# 人性影响NPC行为的阈值
const HUMANITY_NPC_REACTIONS = {
    80-100: {
        "reimu": "赞赏",
        "keine": "欣慰",
        "sakuya": "认可",
        "marisa": "无所谓",
        "koishi": "不理解",
        "kaguya": "好奇"
    },
    40-79: {
        "reimu": "正常",
        "keine": "正常",
        # ... 正常互动
    },
    20-39: {
        "reimu": "警告",
        "keine": "担心", # 主动关怀
        "sakuya": "保持距离",
        "marisa": "无所谓",
        "koishi": "接近", # 低人性反而吸引她
        "kaguya": "悲伤"
    },
    0-19: {
        "reimu": "退治", # 强制事件
        "keine": "强烈干预",
        "sakuya": "拒绝交流",
        "marisa": "无所谓",
        "koishi": "可招募",
        "kaguya": "理解"
    }
}
```

### 2. 时间系统与NPC日程冲突
```gdscript
# 同时可见的NPC组合（时段重叠）
const TIME_OVERLAP_NPCS = {
    "10:00-11:00": ["marisa", "sakuya"],  # 都在人之里购物
    "15:00-17:00": ["marisa", "reimu"],   # 闲逛+巡逻
    "17:00-19:00": ["keine"],             # 散步（独占）
    "13:00-15:00_temple": ["keine", "akyuu"]  # 寺子屋访问
}

# 同伴可用性冲突
func check_companion_availability(npc_id: String, hour: int) -> bool:
    match npc_id:
        "keine": return not (hour >= 8 and hour < 17)  # 教学时段不可用
        "reimu": return not (hour >= 9 and hour < 12 or hour >= 17 and hour < 20)
        "sakuya": return hour in [9, 10, 11, 20, 21]  # 仅特定时段
        "kaguya": return hour >= 18 or hour < 6  # 仅夜晚
        _: return true
```

### 3. 天气系统触发
```gdscript
class WeatherNPCTrigger:
    func on_weather_change(weather: String):
        match weather:
            "rain":
                spawn_koishi_at_bridge()  # 恋恋出现
            "full_moon":
                keine_transform_hakutaku()  # 慧音变身
                kaguya_moon_viewing_available()  # 辉夜赏月
            "incident":
                reimu_emergency_schedule()  # 灵梦异变日程
```

### 4. 礼物系统偏好
```gdscript
const GIFT_PREFERENCES = {
    "keine": {
        "loved": ["history_book"],
        "liked": ["food"],
        "neutral": ["flower"],
        "disliked": ["sake"]
    },
    "reimu": {
        "loved": ["sake"],
        "liked": ["tea", "offering"],
        "neutral": ["food"],
        "disliked": ["youkai_item"]
    },
    "marisa": {
        "loved": ["magic_book"],
        "liked": ["mushroom", "rare_material"],
        "neutral": ["food"],
        "disliked": ["normal_item"]
    },
    "sakuya": {
        "loved": ["silver_knife"],
        "liked": ["tea_leaves", "cleaning_tools"],
        "neutral": ["food"],
        "disliked": ["luxury_item"]  # 她不需要奢侈品
    },
    "koishi": {
        "loved": [],  # 不接受礼物（会忘记）
        "liked": [],
        "neutral": [],
        "disliked": []
    },
    "kaguya": {
        "loved": ["hourai_branch"],
        "liked": ["moon_item", "game"],
        "neutral": ["rare_item"],
        "disliked": ["common_item"]  # 她见过太多了
    }
}
```

---

## 七、NPC互动矩阵

### 友好关系
- **慧音 ↔ 阿求**: 历史学者，经常交流
- **灵梦 ↔ 慧音**: 都是守护者，互相尊重
- **咲夜 ↔ 灵梦**: 职责至上，惺惺相惜

### 竞争关系
- **灵梦 ↔ 魔理沙**: 异变解决竞争，但互相认可
- **魔理沙 ↔ 咲夜**: 偷书vs守护，敌对

### 特殊关系
- **恋恋 ↔ 所有NPC**: 其他NPC都无法记住她
- **辉夜 ↔ 魔理沙**: 永生诱惑，魔理沙极度渴望
- **辉夜 ↔ 慧音**: 哲学对立（永恒vs变化）

### 联合任务可能性
- **灵梦+魔理沙**: 异变解决（经典组合）
- **慧音+阿求**: 历史研究
- **咲夜+玩家**: 保卫红魔馆

---

## 八、分支结局影响

### 人性路线
- **高人性（80+）**:
  - 可招募: 慧音、灵梦、咲夜
  - 结局: "人性的守护者"

- **中人性（40-79）**:
  - 可招募: 大多数NPC
  - 结局: "平衡的旅者"

- **低人性（<40）**:
  - 可招募: 恋恋、辉夜（如果拒绝永生）
  - 触发: 灵梦退治事件
  - 结局: "堕落之路" or "赎罪重生"

### 特殊选择
- **接受蓬莱之药（辉夜）**:
  - 获得: 永生
  - 失去: humanity永久=0
  - 后果: 大多NPC疏远
  - 结局: "永恒的孤独"

- **拒绝蓬莱之药**:
  - 辉夜羁绊+800
  - 解锁: 辉夜同伴
  - 成就: "珍惜有限"

---

## 九、实现优先级总表

### P0 - 核心框架（必须最先实现）
1. NPCScheduleManager（已生成）
2. BondSystem基础（已有，需扩展）
3. 时间系统集成
4. 基础场景：temple_school, hakurei_shrine, village_center

### P1 - 关键NPC（优先体验）
5. **慧音**完整实现
   - 寺子屋场景
   - 散步日程
   - 人性关怀系统
6. **灵梦**核心机制
   - 神社场景
   - 巡逻系统
   - 人性<20退治事件
7. **魔理沙**基础系统
   - 双时段出现
   - 魔法学习系统

### P2 - 扩展内容
8. **咲夜**时间奉献系统
9. **恋恋**雨天机制+记忆系统
10. 天气系统（为恋恋/满月事件）
11. 礼物系统

### P3 - 深���内容
12. **辉夜**隐藏发现机制
13. 所有同伴战斗AI
14. NPC互动事件
15. 分支结局

---

## 十、技术实现要点

### 信号系统扩展
```gdscript
# SignalBus.gd 需要添加的信号
signal weather_changed(weather_type: String)
signal full_moon_started()
signal full_moon_ended()
signal incident_triggered(incident_data: Dictionary)
signal npc_special_event(npc_id: String, event_type: String)
signal gift_given(npc_id: String, item_id: String, reaction: String)
signal companion_joined(npc_id: String)
signal companion_left(npc_id: String)
```

### 存档数据结构
```gdscript
# SaveSystem扩展
func get_npc_save_data() -> Dictionary:
    return {
        "npcs": {
            "keine": BondSystem.get_npc_data("keine"),
            "reimu": BondSystem.get_npc_data("reimu"),
            "marisa": BondSystem.get_npc_data("marisa"),
            "sakuya": BondSystem.get_npc_data("sakuya"),
            "koishi": BondSystem.get_npc_data("koishi"),
            "kaguya": BondSystem.get_npc_data("kaguya")
        },
        "special_flags": {
            "kaguya_discovered": false,
            "hourai_elixir_accepted": false,
            "reimu_extermination_triggered": false,
            "keine_hakutaku_seen": false
        }
    }
```

### 场景最低要求
- **temple_school.tscn**: 慧音固定位置，阿求访问点
- **hakurei_shrine.tscn**: 灵梦主场，神社系统
- **village_center.tscn**: NPCContainer（动态生成NPC）
- **magic_forest_house.tscn**: 魔理沙研究所（bond>=3解锁）
- **bamboo_forest_deep.tscn**: 辉夜永远亭（隐藏场景）

---

## 十一、测试检查清单

### 基础功能
- [ ] NPC按日程正确出现/消失
- [ ] 对话增加羁绊点数
- [ ] 礼物系统正常工作
- [ ] 存档/读档NPC数据正确

### 特殊机制
- [ ] 恋恋雨天出现，离开后玩家忘记
- [ ] 慧音满月变身白泽
- [ ] 灵梦人性<20触发退治
- [ ] 魔理沙"借"东西系统
- [ ] 咲夜时间奉献
- [ ] 辉夜夜晚限定访问

### 同伴系统
- [ ] 招募条件正确检查
- [ ] 同伴跟随玩家
- [ ] 战斗AI正常运作
- [ ] 时间限制正确（慧音工作时不可用等）
- [ ] 辉夜复活技能生效

### 剧情事件
- [ ] 慧音人性关怀（humanity<40）
- [ ] 灵梦退治抉择
- [ ] 辉夜永生选择
- [ ] 魔理沙借书大作战
- [ ] 咲夜保卫红魔馆

---

## 结语

这6个NPC设计围绕"人性"这一核心主题，通过不同的身份立场和哲学困境，为玩家提供丰富的互动体验和道德选择。

**记住**：所有对话文本需要后续由专业文案编写，当前文档仅提供行为流程和系统机制。
