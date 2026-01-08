extends Node

## SceneManager - 场景管理器
## 处理场景切换、过渡动画、玩家位置保持

signal scene_loading_started()
signal scene_loading_finished()
signal transition_started()
signal transition_finished()

# 场景路径配置
const SCENES = {
	"menu": "res://TitleScreen.tscn",
	"town": "res://scenes/overworld/town/Town.tscn",
	"farm": "res://scenes/overworld/farm/Farm.tscn",
	"dungeon_entrance": "res://scenes/overworld/dungeon_entrance/DungeonEntrance.tscn",
	"combat": "res://scenes/combat/CombatArena.tscn"
}

# 当前场景信息
var current_scene_name: String = ""
var previous_scene_name: String = ""

# 场景切换参数
var transition_duration: float = 0.5
var is_transitioning: bool = false

# 过渡覆盖层
var transition_overlay: ColorRect

func _ready():
	# 创建过渡覆盖层
	_create_transition_overlay()

## 创建过渡覆盖层（淡入淡出效果）
func _create_transition_overlay() -> void:
	transition_overlay = ColorRect.new()
	transition_overlay.color = Color.BLACK
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_overlay.modulate.a = 0.0
	transition_overlay.z_index = 1000  # 最顶层

	# 设置为全屏
	transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 添加到场景树（但不添加到当前场景，而是作为根节点）
	get_tree().root.add_child(transition_overlay)

## 切换场景（带过渡动画）
func change_scene(scene_key: String, spawn_point: String = "") -> void:
	if is_transitioning:
		push_warning("[SceneManager] 正在切换场景，忽略新的请求")
		return

	if not SCENES.has(scene_key):
		push_error("[SceneManager] 场景不存在: %s" % scene_key)
		return

	is_transitioning = true
	previous_scene_name = current_scene_name
	current_scene_name = scene_key

	# 开始过渡
	await _fade_out()

	# 加载新场景
	scene_loading_started.emit()
	var scene_path = SCENES[scene_key]
	var result = get_tree().change_scene_to_file(scene_path)

	if result != OK:
		push_error("[SceneManager] 场景加载失败: %s" % scene_path)
		is_transitioning = false
		return

	# 等待一帧，确保新场景加载完成
	await get_tree().process_frame

	# 设置玩家位置（如果指定了出生点）
	if spawn_point != "":
		_set_player_spawn_point(spawn_point)

	scene_loading_finished.emit()

	# 结束过渡
	await _fade_in()

	is_transitioning = false

## 直接切换（无动画）
func change_scene_instant(scene_key: String) -> void:
	if not SCENES.has(scene_key):
		push_error("[SceneManager] 场景不存在: %s" % scene_key)
		return

	previous_scene_name = current_scene_name
	current_scene_name = scene_key

	var scene_path = SCENES[scene_key]
	get_tree().change_scene_to_file(scene_path)

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

## 进入战斗（保存主世界状态）
func enter_combat(dungeon_level: int = 1) -> void:
	# 保存主世界状态
	_save_overworld_state()

	# 通知 GameStateManager
	GameStateManager.start_combat(dungeon_level)

	# 切换到战斗场景
	change_scene("combat")

## 退出战斗（返回主世界）
func exit_combat(victory: bool) -> void:
	# 通知 GameStateManager
	GameStateManager.end_combat(victory)

	# 恢复主世界状态并返回
	_restore_overworld_state()

	# 返回到之前的主世界场景
	if previous_scene_name in ["town", "farm", "dungeon_entrance"]:
		change_scene(previous_scene_name)
	else:
		change_scene("town")  # 默认返回城镇

## 淡出动画
func _fade_out() -> void:
	transition_started.emit()
	transition_overlay.mouse_filter = Control.MOUSE_FILTER_STOP  # 阻止点击

	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 1.0, transition_duration)
	await tween.finished

## 淡入动画
func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration)
	await tween.finished

	transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 恢复点击
	transition_finished.emit()

## 设置玩家出生点
func _set_player_spawn_point(spawn_point: String) -> void:
	# 等待场景完全加载
	await get_tree().process_frame

	# 查找出生点节点
	var spawn_node = get_tree().current_scene.find_child(spawn_point, true, false)
	if spawn_node == null:
		push_warning("[SceneManager] 出生点不存在: %s" % spawn_point)
		return

	# 查找玩家节点
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player == null:
		push_warning("[SceneManager] 场景中没有玩家")
		return

	# 设置玩家位置
	player.global_position = spawn_node.global_position

## 保存主世界状态
func _save_overworld_state() -> void:
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		GameStateManager.player_data.position = player.global_position
		GameStateManager.player_data.current_scene = "res://scenes/overworld/%s/%s.tscn" % [previous_scene_name.capitalize(), previous_scene_name.capitalize()]

## 恢复主世界状态
func _restore_overworld_state() -> void:
	# 恢复玩家位置在场景加载后处理
	pass
