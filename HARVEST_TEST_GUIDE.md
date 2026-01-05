# 采集系统测试说明

## 🎯 系统变更总结

### 1. 采集机制改为长期RPG模式
- ✅ **不再重生**：采集后物品直接从世界中移除（`queue_free()`）
- ✅ **固定资源**：每次进入场景，资源固定在地图上
- ✅ **采完就没**：采集后物品消失，需要重新进入场景才会刷新

### 2. 背包系统集成
- ✅ 采集的物品会自动添加到背包（InventoryManager）
- ✅ 按 **I 键** 打开背包界面查看物品
- ✅ 背包UI显示物品名称、数量、描述
- ✅ 可以在背包中使用/装备物品

### 3. 已创建的可采集物场景

| 场景文件 | 物品ID | 数量 | 需要工具 |
|---------|--------|------|---------|
| `Flower.tscn` | flower | 1-3 | 无 |
| `BambooShoot.tscn` | bamboo_shoot | 1-2 | 无 |
| `Herb.tscn` | herb | 1-2 | 无 |
| `Stone.tscn` | stone | 1-3 | 无 |
| `IronOre.tscn` | iron_ore | 1-2 | **镐子** |
| `RareFlower.tscn` | rare_flower | 1 | 无 |

## 🎮 测试步骤

### 步骤 1: 在场景中放置可采集物
1. 打开 Godot 编辑器
2. 打开 `Town.tscn` 或 `Farm.tscn`
3. 从文件系统拖拽可采集物场景到场景中（例如 `scenes/harvestables/Flower.tscn`）
4. 调整位置
5. 保存场景

### 步骤 2: 测试采集功能
1. 运行游戏，进入场景
2. 走近可采集物，会显示 `[E] 采集` 提示
3. 按 **E 键** 采集
4. 观察：
   - 物品缩小消失动画
   - 屏幕上方显示"获得 XXX x数量"的绿色浮动文字
   - 物品从场景中完全移除

### 步骤 3: 检查背包
1. 按 **I 键** 打开背包
2. 查看采集到的物品
3. 点击物品查看详细信息
4. 按 **ESC** 关闭背包

### 步骤 4: 验证不重生
1. 采集一个物品后
2. 在场景中走动，观察该位置
3. 确认物品不会重新出现
4. 退出并重新进入场景
5. 确认物品重新出现在原位置（因为重新加载了场景）

## 📝 注意事项

### 工具需求系统
- `IronOre.tscn`（铁矿石）需要镐子才能采集
- 目前工具检查功能**尚未实现**（代码中是 TODO）
- 需要在 Player.gd 中添加工具系统

### 物品ID对应
所有物品ID都在 `scripts/data/ItemData.gd` 中定义：
- 植物类: `flower`, `bamboo_shoot`, `herb`, `mushroom`
- 矿物类: `stone`, `bamboo`, `iron_ore`, `magic_crystal`
- 稀有类: `rare_flower`, `golden_bamboo`

### 自定义新的可采集物
复制现有场景文件，修改：
1. `item_id` - 对应 ItemData 中的物品ID
2. `harvest_amount_min/max` - 采集数量范围
3. `require_tool` - 需要的工具（空字符串 = 不需要）
4. Sprite2D 的 texture - 更换贴图

## 🐛 已知限制

1. **工具系统未实现** - 即使设置了 `require_tool`，目前也能直接采集
2. **ItemButton场景不存在** - 背包UI使用代码创建按钮，而不是预制场景
3. **采集音效未配置** - `harvest_sound` 设置为空，需要添加音效资源

## 🔗 相关文件

- 采集组件: `scripts/components/Harvestable.gd`
- 背包管理: `scripts/core/InventoryManager.gd`
- 背包UI: `scripts/core/InventoryUI.gd`
- 背包场景: `scenes/ui/global/InventoryUI.tscn`
- 物品数据: `scripts/data/ItemData.gd`
- 可采集物场景: `scenes/harvestables/*.tscn`
