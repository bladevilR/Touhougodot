extends Node2D

## HakureiShrine - 博丽神社
## 灵梦的神社，重要剧情场景

func _ready():
	name = "HakureiShrine"

	GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

	print("[HakureiShrine] 进入博丽神社")

	# 检查灵梦是否在场
	_check_reimu_presence()

	# 检查人性值，触发特殊剧情
	_check_humanity_event()

	_setup_scene_transitions()

## 检查灵梦是否在场
func _check_reimu_presence() -> void:
	var reimu_location = NPCScheduleManager.get_npc_location("reimu")

	if reimu_location == "hakurei_shrine":
		print("[HakureiShrine] 灵梦在神社")
		# TODO: 显示灵梦NPC
	else:
		print("[HakureiShrine] 灵梦外出了（当前在：%s）" % reimu_location)

## 检查人性事件
func _check_humanity_event() -> void:
	if not HumanitySystem:
		return

	# 人性极低时，灵梦会有特殊对话
	if HumanitySystem.current_humanity < 20:
		print("[HakureiShrine] 灵梦察觉到妖气...")
		# TODO: 触发退治剧情

## 设置场景传送
func _setup_scene_transitions() -> void:
	var to_village = get_node_or_null("ToVillageCenter")
	if to_village and to_village is Area2D:
		to_village.body_entered.connect(_on_to_village_entered)

func _on_to_village_entered(body: Node2D) -> void:
	if body.name == "Player":
		SceneManager.change_scene("res://scenes/overworld/village/VillageCenter.tscn")
