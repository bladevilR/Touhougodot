extends Node2D

## TempleSchool - 寺子屋
## 慧音的教室，主要剧情场景

func _ready():
	name = "TempleSchool"

	GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

	print("[TempleSchool] 进入寺子屋")

	# 确保慧音在场
	_check_keine_presence()

	_setup_scene_transitions()

## 检查慧音是否应该在场
func _check_keine_presence() -> void:
	var keine_location = NPCScheduleManager.get_npc_location("keine")

	if keine_location == "temple_school":
		print("[TempleSchool] 慧音正在教书")
		# TODO: 显示慧音NPC
	else:
		print("[TempleSchool] 慧音不在寺子屋（当前在：%s）" % keine_location)
		# TODO: 隐藏慧音NPC

## 设置场景传送
func _setup_scene_transitions() -> void:
	var to_village = get_node_or_null("ToVillageCenter")
	if to_village and to_village is Area2D:
		to_village.body_entered.connect(_on_to_village_entered)

func _on_to_village_entered(body: Node2D) -> void:
	if body.name == "Player":
		SceneManager.change_scene("res://scenes/overworld/village/VillageCenter.tscn")
