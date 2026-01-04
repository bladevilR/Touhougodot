# 🎮 场景快速切换指南

## 方式1：修改 project.godot（推荐用于正式版本）

打开 `project.godot`，找到以下行并修改：

```ini
[application]
run/main_scene="res://world.tscn"  # 👈 直接修改这里
```

### 常用场景路径：
```ini
# 竹林战斗关卡（主关卡）
run/main_scene="res://world.tscn"

# 小镇场景
run/main_scene="res://TownWorld.tscn"

# 主菜单
run/main_scene="res://MainMenu.tscn"

# 3D模型测试场景
run/main_scene="res://tests/scenes/3d_model_test/player2_test.tscn"
```

---

## 方式2：使用 SceneLauncher（推荐用于开发测试）

### 步骤：

1. **修改 project.godot**:
   ```ini
   run/main_scene="res://tests/SceneLauncher.tscn"
   ```

2. **编辑 tests/SceneLauncher.gd**:
   ```gdscript
   # 改这一行快速切换！
   const DEFAULT_SCENE = "bamboo_forest"  # 👈 改这里！
   ```

3. **可选场景列表**:
   - `"bamboo_forest"` - 竹林战斗关卡 ✅ 稳定版
   - `"town"` - 小镇场景 ✅ 稳定版
   - `"main_menu"` - 主菜单
   - `"3d_model_test"` - 3D模型测试 🧪
   - `"shader_test"` - Shader测试 🧪
   - `"ui_test"` - UI测试 🧪

---

## 方式3：使用 Git 分支（推荐用于大型实验）

```bash
# 创建实验分支
git checkout -b experiment/3d-models

# 在实验分支自由修改
# ...

# 完成后切回主分支
git checkout main

# 如果满意，合并改动
git merge experiment/3d-models
```

---

## ⚠️ 重要规则

### ❌ 不要做的事：
- 不要为了测试而直接修改主关卡文件（world.tscn, TownWorld.tscn）
- 不要为了测试而修改核心脚本（Player.gd, MapSystem.gd, GameUI.gd）
- 不要在main分支做大量实验性改动

### ✅ 应该做的事：
1. 所有测试在 `tests/` 目录进行
2. 创建独立的测试场景
3. 测试成功后，再谨慎合并回主代码

---

## 📋 场景测试检查清单

每次测试前：
- [ ] 确认在 tests/ 目录下工作
- [ ] 备份了原始文件（如果修改）
- [ ] 知道如何恢复到稳定版本

测试后：
- [ ] 测试场景正常工作
- [ ] 没有破坏主关卡功能
- [ ] 提交时写清楚commit message

---

## 🔄 快速恢复命令

如果测试把主关卡改坏了，快速恢复：

```bash
# 恢复所有关键文件
git checkout GameUI.gd Player.gd MapSystem.gd PlayerViewport.gd PlayerViewport.tscn Player3DVisuals.gd

# 或恢复整个工作目录
git checkout .
```
