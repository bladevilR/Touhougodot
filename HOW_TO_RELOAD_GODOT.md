# Godot 修改未生效 - 解决方案

## 🚨 问题：修改的代码没有生效

这是Godot缓存和热重载的常见问题。

---

## ✅ 解决步骤（按顺序执行）

### 步骤 1: 完全关闭游戏和Godot
1. **停止运行的游戏** - 点击Godot编辑器顶部的停止按钮（或按F8）
2. **完全关闭Godot编辑器** - 不是最小化，是完全退出程序

### 步骤 2: 清除Godot缓存
在项目文件夹中删除以下文件夹：
```
E:\touhou\game\touhou-godot\.godot\
```

**如何操作**：
1. 打开文件资源管理器
2. 进入 `E:\touhou\game\touhou-godot\`
3. 找到 `.godot` 文件夹（可能需要显示隐藏文件夹）
4. **删除整个 `.godot` 文件夹**
5. 这个文件夹是Godot的缓存，删除后会自动重建

### 步骤 3: 重新打开项目
1. 启动Godot编辑器
2. 打开项目 `E:\touhou\game\touhou-godot\project.godot`
3. **等待Godot完成导入** - 右下角会显示"正在导入资源"
4. 导入完成后，Godot会重新生成所有缓存

### 步骤 4: 验证修改
在Godot编辑器中检查：

#### 检查 1: 输入映射
1. 点击顶部菜单 `项目(Project)` → `项目设置(Project Settings)`
2. 点击 `输入映射(Input Map)` 标签
3. 查找 `ui_cancel`
4. ✅ **应该看到**: ESC键已绑定到ui_cancel

#### 检查 2: GameUI.gd
1. 在文件系统面板双击打开 `GameUI.gd`
2. 滚动到第113行
3. ✅ **应该看到**: `call_deferred("_apply_settings")`（而不是`_apply_settings()`）

#### 检查 3: PauseMenu.gd
1. 双击打开 `PauseMenu.gd`
2. 查看第1行
3. ✅ **应该看到**: `extends Control`（而不是`extends CanvasLayer`）

#### 检查 4: world.gd
1. 双击打开 `world.gd`
2. 滚动到第18-46行
3. ✅ **应该看到**: `_show_opening_dialogue()` 函数

### 步骤 5: 运行游戏
1. 按 **F5** 或点击 **播放按钮**
2. 观察控制台输出

---

## 🔍 预期的控制台日志

如果修改生效，你应该在控制台看到：

```
[GameUI] 暂停菜单已创建
[World] 开场对话已显示
[ExperienceGem] P点贴图加载成功
```

如果看不到这些日志，说明：
- ❌ 缓存未清除
- ❌ 脚本未重新加载
- ❌ 运行的是错误的场景

---

## 🎮 测试功能

### 必测项目
1. **游戏开始0.5秒后** → 应该看到妹红对话框
2. **按ESC键** → 应该暂停并显示菜单
3. **右上角** → 应该有DPS统计和房间地图
4. **左上角** → 应该有房间信息

---

## ⚠️ 如果还是不生效

### 方案A: 手动检查文件
用记事本或VS Code打开以下文件，确认修改确实保存了：
- `project.godot` - 搜索"ui_cancel"，应该存在
- `PauseMenu.gd` - 第1行应该是"extends Control"
- `GameUI.gd` - 第113行应该是"call_deferred"

### 方案B: 确认运行的场景
1. 在Godot编辑器中，点击顶部菜单 `项目` → `项目设置`
2. 查看 `应用程序` → `运行` → `主场景`
3. ✅ **应该是**: `res://world.tscn`

### 方案C: 重新保存场景
1. 在Godot编辑器中打开 `world.tscn`
2. 按 `Ctrl+S` 强制保存
3. 打开 `GameUI.tscn`（如果存在）并保存

---

## 🔧 Windows命令行清除缓存（高级）

如果手动删除有问题，可以用命令行：

```bash
# 打开CMD，切换到项目目录
cd E:\touhou\game\touhou-godot

# 删除缓存文件夹
rmdir /s /q .godot

# 删除导入文件夹
rmdir /s /q .import
```

---

## 📝 为什么会发生这种情况？

### Godot的缓存机制
- Godot会缓存编译的脚本（GDScript字节码）
- 场景文件(.tscn)也会被缓存
- 有时热重载失败，需要完全重启

### 特别是以下情况
- 修改了自动加载(Autoload)脚本
- 修改了类定义(class_name)
- 修改了project.godot配置
- 修改了继承关系(extends)

---

## ✅ 成功的标志

重启后，如果你看到：
1. ✅ 控制台有 `[GameUI] 暂停菜单已创建`
2. ✅ 控制台有 `[World] 开场对话已显示`
3. ✅ 游戏开始后0.5秒出现对话框
4. ✅ 按ESC可以暂停

**那么修改已经生效！**

---

## 🆘 如果以上都不行

请告诉我：
1. Godot编辑器版本（帮助 → 关于Godot）
2. 控制台有什么错误信息
3. 项目设置中ui_cancel是否存在
4. PauseMenu.gd第1行显示什么

我会进一步诊断问题。

---

*最后更新: 2025-12-14*
