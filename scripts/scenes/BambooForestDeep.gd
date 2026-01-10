extends Node2D

## BambooForestDeep - 竹林深处
## 隐藏场景，辉夜的居所（一周目通关后解锁）

var is_unlocked: bool = false

func _ready():
	name = "BambooForestDeep"

	GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

	print("[BambooForestDeep] 进入竹林深处")

	# 检查是否解锁
	_check_unlock_status()

	if is_unlocked:
		_setup_kaguya()
	else:
		_show_locked_message()

	_setup_scene_transitions()

## 检查解锁状态
func _check_unlock_status() -> void:
	# TODO: 从存档或游戏进度检查
	# 这里简化处理
	is_unlocked = false

	# 检查条件示例：
	# - 主线通关
	# - 找到特殊道具
	# - 人性达到一定值

## 设置辉夜
func _setup_kaguya() -> void:
	print("[BambooForestDeep] 辉夜出现")
	# TODO: 显示辉夜NPC

## 显示未解锁提示
func _show_locked_message() -> void:
	print("[BambooForestDeep] 竹林深处被神秘力量封锁着...")
	SignalBus.show_notification.emit("这里似乎被某种力量封锁着...", Color.GRAY)

	# 2秒后强制退出
	await get_tree().create_timer(2.0).timeout
	SceneManager.change_scene("res://scenes/home/BambooHouse.tscn")

## 设置场景传送
func _setup_scene_transitions() -> void:
	if not is_unlocked:
		return

	var to_bamboo = get_node_or_null("ToBambooHouse")
	if to_bamboo and to_bamboo is Area2D:
		to_bamboo.body_entered.connect(_on_to_bamboo_entered)

func _on_to_bamboo_entered(body: Node2D) -> void:
	if body.name == "Player":
		SceneManager.change_scene("res://scenes/home/BambooHouse.tscn")
