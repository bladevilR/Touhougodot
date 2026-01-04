extends Node

## 场景配置管理器
## 方便开发时快速切换不同场景
##
## 使用方法：
##   在project.godot中设置 run/main_scene="res://tests/SceneLauncher.tscn"
##   然后在这里配置要启动的场景

# ==================== 场景路径配置 ====================

## 主游戏场景（Production）
const SCENES = {
	# 主要关卡
	"bamboo_forest": "res://world.tscn",              # 竹林战斗关卡（稳定版）
	"town": "res://TownWorld.tscn",                   # 小镇场景（稳定版）
	"main_menu": "res://MainMenu.tscn",               # 主菜单
	"title_screen": "res://TitleScreen.tscn",         # 标题画面

	# 测试场景（Development/Testing）
	"3d_model_test": "res://tests/scenes/3d_model_test/player2_test.tscn",   # 3D模型测试
	"shader_test": "res://tests/scenes/shader_test/shader_test.tscn",        # Shader测试
	"ui_test": "res://tests/scenes/ui_test/ui_test.tscn",                    # UI测试
	"performance_test": "res://tests/scenes/performance_test/perf_test.tscn", # 性能测试

	# 临时测试场景
	"simple_town": "res://SimpleTownTest.tscn",
	"town_test": "res://TownTestScene.tscn",
}

# ==================== 启动配置 ====================

## 🎯 在这里选择要启动的场景！
## 改这一行就可以快速切换场景
const DEFAULT_SCENE = "bamboo_forest"  # 👈 修改这里切换启动场景！

# 是否显示场景选择器（开发时设为true，发布时设为false）
const SHOW_LAUNCHER_UI = false

# ==================== 场景启动逻辑 ====================

func _ready():
	if SHOW_LAUNCHER_UI:
		_show_scene_selector()
	else:
		_launch_default_scene()

## 启动默认场景
func _launch_default_scene():
	var scene_path = SCENES.get(DEFAULT_SCENE, SCENES["bamboo_forest"])
	print("SceneLauncher: 启动场景 '%s' -> %s" % [DEFAULT_SCENE, scene_path])
	get_tree().change_scene_to_file(scene_path)

## 显示场景选择器UI（开发工具）
func _show_scene_selector():
	# TODO: 实现可视化场景选择器
	print("=== 场景选择器 ===")
	print("可用场景：")
	for key in SCENES:
		print("  - %s: %s" % [key, SCENES[key]])
	print("当前默认：%s" % DEFAULT_SCENE)
	_launch_default_scene()

## 切换到指定场景（供其他脚本调用）
func launch_scene(scene_key: String):
	if scene_key in SCENES:
		get_tree().change_scene_to_file(SCENES[scene_key])
	else:
		push_error("SceneLauncher: 未找到场景 '%s'" % scene_key)
