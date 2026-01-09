extends Node
## SceneManager - 统一场景管理器
## 合并了枚举式和字符串式两种API

signal scene_loading_started()
signal scene_loading_finished()
signal transition_started()
signal transition_finished()

# ==================== 场景枚举（向后兼容） ====================
enum Scene {
	MAIN_MENU,
	TOWN,
	BATTLE,
	SETTINGS,
	GAME_OVER,
	VICTORY,
	LOADING,
	FARM,
	DUNGEON_ENTRANCE
}

# ==================== 场景路径映射 ====================
# 枚举到路径映射
var scene_paths: Dictionary = {
	Scene.MAIN_MENU: "res://TitleScreen.tscn",
	Scene.TOWN: "res://scenes/overworld/town/Town.tscn",
	Scene.BATTLE: "res://scenes/combat/CombatArena.tscn",
	Scene.SETTINGS: "res://SettingsMenu.tscn",
	Scene.LOADING: "res://LoadingScreen.tscn",
	Scene.FARM: "res://scenes/overworld/farm/Farm.tscn",
	Scene.DUNGEON_ENTRANCE: "res://scenes/overworld/dungeon_entrance/DungeonEntrance.tscn"
}

# 字符串到路径映射
const SCENES: Dictionary = {
	"menu": "res://TitleScreen.tscn",
	"town": "res://scenes/overworld/town/Town.tscn",
	"farm": "res://scenes/overworld/farm/Farm.tscn",
	"dungeon_entrance": "res://scenes/overworld/dungeon_entrance/DungeonEntrance.tscn",
	"combat": "res://scenes/combat/CombatArena.tscn",
	"battle": "res://scenes/combat/CombatArena.tscn",
	"settings": "res://SettingsMenu.tscn",
	"loading": "res://LoadingScreen.tscn"
}

# ==================== 状态变量 ====================
var current_scene: Node = null
var current_scene_type: Scene = Scene.MAIN_MENU
var current_scene_name: String = ""
var previous_scene_name: String = ""

var is_transitioning: bool = false
var transition_duration: float = 0.5

# 场景状态保存
var scene_states: Dictionary = {}

# 过渡层
var transition_layer: CanvasLayer = null
var transition_rect: ColorRect = null

func _ready() -> void:
	print("[SceneManager] 初始化中...")
	_setup_transition_layer()

	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	print("[SceneManager] 初始化完成")

# ==================== 过渡层设置 ====================
func _setup_transition_layer() -> void:
	transition_layer = CanvasLayer.new()
	transition_layer.layer = 100
	transition_layer.name = "TransitionLayer"

	transition_rect = ColorRect.new()
	transition_rect.color = Color(0, 0, 0, 0)
	transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	transition_layer.add_child(transition_rect)
	get_tree().root.call_deferred("add_child", transition_layer)

# ==================== 场景切换（字符串API） ====================
## 使用字符串key切换场景
func change_scene(scene_key, spawn_point: String = "", transition_type: String = "fade", duration: float = 0.5) -> void:
	# 支持Scene枚举或字符串
	var scene_path: String = ""
	var scene_name: String = ""

	if scene_key is int:  # Scene枚举
		scene_path = scene_paths.get(scene_key, "")
		scene_name = get_scene_name(scene_key)
	elif scene_key is String:  # 字符串key
		scene_path = SCENES.get(scene_key, scene_key)  # 如果不在字典中，假设是路径
		scene_name = scene_key
	else:
		push_error("[SceneManager] 无效的场景key类型")
		return

	if scene_path.is_empty():
		push_error("[SceneManager] 场景不存在: %s" % str(scene_key))
		return

	if is_transitioning:
		push_warning("[SceneManager] 正在切换场景，忽略新请求")
		return

	is_transitioning = true
	previous_scene_name = current_scene_name
	current_scene_name = scene_name

	print("[SceneManager] 切换场景到: %s" % scene_name)

	# 过渡动画
	match transition_type:
		"fade":
			await _fade_out(duration)
		"instant":
			pass
		_:
			await _fade_out(duration)

	# 清理当前场景
	scene_loading_started.emit()
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await get_tree().process_frame

	# 加载新场景
	var new_scene_resource = load(scene_path)
	if not new_scene_resource:
		push_error("[SceneManager] 无法加载场景: %s" % scene_path)
		is_transitioning = false
		return

	current_scene = new_scene_resource.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

	# 更新枚举类型
	current_scene_type = _name_to_scene_type(scene_name)

	scene_loading_finished.emit()

	# 设置出生点
	if spawn_point != "":
		await get_tree().process_frame
		_set_player_spawn_point(spawn_point)

	# 淡入
	match transition_type:
		"fade":
			await _fade_in(duration)
		"instant":
			pass
		_:
			await _fade_in(duration)

	is_transitioning = false

	# 发送信号
	if SignalBus:
		SignalBus.scene_changed.emit(scene_name)

	print("[SceneManager] 场景切换完成")

## 直接切换（无动画）
func change_scene_instant(scene_key) -> void:
	var scene_path: String = ""
	var scene_name: String = ""

	if scene_key is int:
		scene_path = scene_paths.get(scene_key, "")
		scene_name = get_scene_name(scene_key)
	elif scene_key is String:
		scene_path = SCENES.get(scene_key, scene_key)
		scene_name = scene_key

	if scene_path.is_empty():
		push_error("[SceneManager] 场景不存在: %s" % str(scene_key))
		return

	previous_scene_name = current_scene_name
	current_scene_name = scene_name
	get_tree().change_scene_to_file(scene_path)

# ==================== 战斗场景专用 ====================
## 进入战斗
func enter_combat(dungeon_level: int = 1) -> void:
	_save_overworld_state()

	if GameStateManager:
		GameStateManager.start_combat(dungeon_level)

	change_scene("combat")

## 退出战斗
func exit_combat(victory: bool) -> void:
	if GameStateManager:
		GameStateManager.end_combat(victory)

	_restore_overworld_state()

	if previous_scene_name in ["town", "farm", "dungeon_entrance"]:
		change_scene(previous_scene_name)
	else:
		change_scene("town")

# ==================== 过渡动画 ====================
func _fade_out(duration: float = 0.5) -> void:
	if not transition_rect:
		return

	transition_started.emit()
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 1.0, duration)
	await tween.finished

func _fade_in(duration: float = 0.5) -> void:
	if not transition_rect:
		return

	var tween = create_tween()
	tween.tween_property(transition_rect, "color:a", 0.0, duration)
	await tween.finished

	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_finished.emit()

# 向后兼容的公共方法
func fade_out(duration: float = 0.5) -> void:
	await _fade_out(duration)

func fade_in(duration: float = 0.5) -> void:
	await _fade_in(duration)

# ==================== 辅助方法 ====================
func get_scene_path(scene_type: Scene) -> String:
	return scene_paths.get(scene_type, "")

func get_scene_name(scene_type: Scene) -> String:
	match scene_type:
		Scene.MAIN_MENU: return "menu"
		Scene.TOWN: return "town"
		Scene.BATTLE: return "battle"
		Scene.SETTINGS: return "settings"
		Scene.GAME_OVER: return "game_over"
		Scene.VICTORY: return "victory"
		Scene.LOADING: return "loading"
		Scene.FARM: return "farm"
		Scene.DUNGEON_ENTRANCE: return "dungeon_entrance"
		_: return "unknown"

func _name_to_scene_type(name: String) -> Scene:
	match name:
		"menu", "main_menu": return Scene.MAIN_MENU
		"town": return Scene.TOWN
		"battle", "combat": return Scene.BATTLE
		"settings": return Scene.SETTINGS
		"game_over": return Scene.GAME_OVER
		"victory": return Scene.VICTORY
		"loading": return Scene.LOADING
		"farm": return Scene.FARM
		"dungeon_entrance": return Scene.DUNGEON_ENTRANCE
		_: return Scene.MAIN_MENU

func _set_player_spawn_point(spawn_point: String) -> void:
	var spawn_node = get_tree().current_scene.find_child(spawn_point, true, false)
	if spawn_node == null:
		push_warning("[SceneManager] 出生点不存在: %s" % spawn_point)
		return

	var player = get_tree().current_scene.find_child("Player", true, false)
	if player == null:
		push_warning("[SceneManager] 场景中没有玩家")
		return

	player.global_position = spawn_node.global_position

func _save_overworld_state() -> void:
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player and GameStateManager:
		GameStateManager.player_data.position = player.global_position
		GameStateManager.player_data.current_scene = current_scene_name

func _restore_overworld_state() -> void:
	pass

## 重新加载当前场景
func reload_current_scene() -> void:
	if current_scene_name == "":
		push_warning("[SceneManager] 没有当前场景")
		return
	change_scene(current_scene_name)

## 返回上一个场景
func return_to_previous_scene() -> void:
	if previous_scene_name == "":
		push_warning("[SceneManager] 没有上一个场景")
		return
	change_scene(previous_scene_name)

## 注册自定义场景路径
func register_scene(scene_type: Scene, scene_path: String) -> void:
	scene_paths[scene_type] = scene_path

## 保存/恢复场景状态
func save_scene_state(scene_type: Scene) -> void:
	scene_states[scene_type] = {}

func restore_scene_state(scene_type: Scene) -> void:
	if scene_type in scene_states:
		pass
