extends Node2D

## BambooHouse - 竹林小屋场景
## 妹红的家，游戏主据点

func _ready():
	name = "BambooHouse"

	# 切换到家模式
	GameStateManager.change_mode(GameStateManager.GameMode.HOME)

	print("[BambooHouse] 进入竹林小屋")

	# 查找玩家
	var player = get_node_or_null("Player")
	if player:
		print("[BambooHouse] 玩家已生成")

	# 连接场景传送信号（如果需要）
	_setup_scene_transitions()

## 设置场景传送
func _setup_scene_transitions() -> void:
	# 查找传送点（Area2D节点）
	var to_village = get_node_or_null("ToVillageCenter")
	if to_village and to_village is Area2D:
		to_village.body_entered.connect(_on_to_village_entered)

## 前往人之里中心
func _on_to_village_entered(body: Node2D) -> void:
	if body.name == "Player":
		print("[BambooHouse] 前往人之里中心")
		SceneManager.change_scene("res://scenes/overworld/village/VillageCenter.tscn")
