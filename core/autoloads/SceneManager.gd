extends Node
## 场景管理器 - 统一管理场景切换和转换动画
##
## 功能:
## - 场景加载和卸载
## - 场景转换动画（淡入淡出）
## - 场景状态保存和恢复
## - 支持多地图架构
##
## 使用示例:
##   # 切换到战斗场景
##   SceneManager.change_scene(SceneManager.Scene.BATTLE)
##
##   # 切换到小镇场景（带淡出效果）
##   SceneManager.change_scene(SceneManager.Scene.TOWN, "fade", 0.5)

# 场景枚举
enum Scene {
	MAIN_MENU,
	TOWN,
	BATTLE,
	SETTINGS,
	GAME_OVER,
	VICTORY,
	LOADING
}

# 场景路径映射
var scene_paths: Dictionary = {
	Scene.MAIN_MENU: "res://MainMenu.tscn",
	Scene.TOWN: "res://TownWorld.tscn",
	Scene.BATTLE: "res://world.tscn",
	Scene.SETTINGS: "res://SettingsMenu.tscn",
	Scene.GAME_OVER: "res://GameOverScreen.tscn",
	Scene.VICTORY: "res://VictoryScreen.tscn",
	Scene.LOADING: "res://LoadingScreen.tscn"
}

# 当前场景
var current_scene: Node = null
var current_scene_type: Scene = Scene.MAIN_MENU

# 转换层
var transition_layer: CanvasLayer = null
var transition_rect: ColorRect = null

# 场景状态字典（用于保存和恢复场景状态）
var scene_states: Dictionary = {}

func _ready():
	print("SceneManager: 初始化中...")
	_setup_transition_layer()

	# 获取当前场景
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	print("SceneManager: 初始化完成")

## 设置转换层
func _setup_transition_layer() -> void:
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 100  # 最高层
	transition_layer.name = "TransitionLayer"

	transition_rect = ColorRect.new()
	transition_rect.color = Color(0, 0, 0, 0)
	transition_rect.anchor_right = 1.0
	transition_rect.anchor_bottom = 1.0
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	transition_layer.add_child(transition_rect)
	
	# Use call_deferred to avoid "Parent node is busy setting up children" error during initialization
	get_tree().root.call_deferred("add_child", transition_layer)

## 切换场景
## @param scene_type: Scene 枚举类型
## @param transition_type: 转换类型 ("fade", "instant", "slide")
## @param duration: 转换时长（秒）
## @param preserve_state: 是否保存当前场景状态
func change_scene(scene_type: Scene, transition_type: String = "fade", duration: float = 0.5, preserve_state: bool = false) -> void:
	print("SceneManager: 切换场景到 %s" % get_scene_name(scene_type))

	# 1. 保存状态（如需要）
	if preserve_state and current_scene:
		_save_scene_state(current_scene_type)

	# 2. 播放退出动画
	match transition_type:
		"fade":
			await fade_out(duration)
		"instant":
			pass
		_:
			await fade_out(duration)

	# 3. 清理当前场景
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await get_tree().process_frame

	# 4. 加载新场景
	var scene_path = get_scene_path(scene_type)
	if scene_path.is_empty():
		push_error("SceneManager: 场景类型 %d 没有对应的路径" % scene_type)
		return

	var new_scene_resource = load(scene_path)
	if not new_scene_resource:
		push_error("SceneManager: 无法加载场景 '%s'" % scene_path)
		return

	current_scene = new_scene_resource.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	current_scene_type = scene_type

	# 5. 播放进入动画
	match transition_type:
		"fade":
			await fade_in(duration)
		"instant":
			pass
		_:
			await fade_in(duration)

	# 6. 发送信号
	SignalBus.scene_changed.emit(get_scene_name(scene_type))
	print("SceneManager: 场景切换完成")

## 淡出动画
func fade_out(duration: float = 0.5) -> void:
	if not transition_rect:
		return

	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, duration)
	await tween.finished

## 淡入动画
func fade_in(duration: float = 0.5) -> void:
	if not transition_rect:
		return

	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 0.0, duration)
	await tween.finished
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

## 获取场景路径
func get_scene_path(scene_type: Scene) -> String:
	return scene_paths.get(scene_type, "")

## 获取场景名称
func get_scene_name(scene_type: Scene) -> String:
	match scene_type:
		Scene.MAIN_MENU: return "主菜单"
		Scene.TOWN: return "小镇"
		Scene.BATTLE: return "战斗"
		Scene.SETTINGS: return "设置"
		Scene.GAME_OVER: return "游戏结束"
		Scene.VICTORY: return "胜利"
		Scene.LOADING: return "加载中"
		_: return "未知场景"

## 保存场景状态
func _save_scene_state(scene_type: Scene) -> void:
	if not current_scene:
		return

	var state = {}
	# 这里可以添加保存逻辑，例如保存玩家位置、NPC状态等
	# 具体实现取决于游戏需求

	scene_states[scene_type] = state
	print("SceneManager: 已保存场景 %s 的状态" % get_scene_name(scene_type))

## 恢复场景状态
func restore_scene_state(scene_type: Scene) -> void:
	if scene_type in scene_states:
		var state = scene_states[scene_type]
		# 这里可以添加恢复逻辑
		print("SceneManager: 已恢复场景 %s 的状态" % get_scene_name(scene_type))

## 注册自定义场景路径
func register_scene(scene_type: Scene, scene_path: String) -> void:
	scene_paths[scene_type] = scene_path
	print("SceneManager: 已注册场景 %s -> %s" % [get_scene_name(scene_type), scene_path])
