extends Node

## QuestData - 任务数据库
## 定义所有任务的信息、目标、奖励等

# 任务数据库
var quests: Dictionary = {}

func _ready():
	initialize()

func initialize() -> void:
	_define_main_quests()
	_define_side_quests()
	_define_daily_quests()
	print("[QuestData] 任务数据库初始化完成，共 %d 个任务" % quests.size())

## 定义主线任务
func _define_main_quests() -> void:
	# 第一个主线任务
	quests["main_001"] = {
		"id": "main_001",
		"type": "main",
		"title": "初到幻想乡",
		"description": "刚刚苏醒的妹红，需要熟悉周围的环境",
		"objectives": [
			{
				"type": "explore",
				"description": "探索城镇",
				"required": 1
			},
			{
				"type": "talk",
				"description": "与灵梦对话",
				"npc_id": "reimu",
				"required": 1
			}
		],
		"rewards": {
			"exp": 100,
			"coins": 50,
			"items": {
				"health_potion_small": 3
			}
		},
		"prerequisites": [],
		"next_quest": "main_002"
	}

	quests["main_002"] = {
		"id": "main_002",
		"type": "main",
		"title": "初次战斗",
		"description": "附近的妖怪们变得活跃起来，需要进行第一次战斗训练",
		"objectives": [
			{
				"type": "enter_dungeon",
				"description": "进入竹林地下城",
				"required": 1
			},
			{
				"type": "kill",
				"description": "击败 10 个敌人",
				"required": 10
			},
			{
				"type": "complete_dungeon",
				"description": "完成第1层",
				"required": 1
			}
		],
		"rewards": {
			"exp": 200,
			"coins": 100,
			"items": {
				"health_potion_medium": 2
			}
		},
		"prerequisites": ["main_001"],
		"next_quest": "main_003"
	}

	quests["main_003"] = {
		"id": "main_003",
		"type": "main",
		"title": "农场之道",
		"description": "战斗之余，也要学会经营农场来维持生活",
		"objectives": [
			{
				"type": "visit",
				"description": "前往农场",
				"location": "farm",
				"required": 1
			},
			{
				"type": "plant",
				"description": "种植 5 个作物",
				"required": 5
			}
		],
		"rewards": {
			"exp": 150,
			"coins": 80,
			"items": {
				"bamboo": 10
			}
		},
		"prerequisites": ["main_002"],
		"next_quest": ""
	}

## 定义支线任务
func _define_side_quests() -> void:
	quests["side_001"] = {
		"id": "side_001",
		"type": "side",
		"title": "收集竹子",
		"description": "河童需要一些竹子来制作道具",
		"objectives": [
			{
				"type": "collect",
				"description": "收集竹子",
				"item_id": "bamboo",
				"required": 20
			}
		],
		"rewards": {
			"exp": 50,
			"coins": 100,
			"items": {
				"health_potion_small": 5
			}
		},
		"prerequisites": [],
		"next_quest": ""
	}

	quests["side_002"] = {
		"id": "side_002",
		"type": "side",
		"title": "魔法水晶研究",
		"description": "魔理沙想要研究魔法水晶",
		"objectives": [
			{
				"type": "collect",
				"description": "收集魔法水晶",
				"item_id": "magic_crystal",
				"required": 5
			},
			{
				"type": "talk",
				"description": "将水晶交给魔理沙",
				"npc_id": "marisa",
				"required": 1
			}
		],
		"rewards": {
			"exp": 150,
			"coins": 200,
			"items": {
				"speed_amulet": 1
			}
		},
		"prerequisites": ["main_001"],
		"next_quest": ""
	}

	quests["side_003"] = {
		"id": "side_003",
		"type": "side",
		"title": "料理大师",
		"description": "制作美味的食物",
		"objectives": [
			{
				"type": "craft",
				"description": "制作烤鱼",
				"item_id": "grilled_fish",
				"required": 3
			}
		],
		"rewards": {
			"exp": 80,
			"coins": 50,
			"items": {
				"rice_ball": 10
			}
		},
		"prerequisites": ["main_003"],
		"next_quest": ""
	}

## 定义每日任务
func _define_daily_quests() -> void:
	quests["daily_001"] = {
		"id": "daily_001",
		"type": "daily",
		"title": "每日狩猎",
		"description": "每天击败一定数量的敌人",
		"objectives": [
			{
				"type": "kill",
				"description": "击败 50 个敌人",
				"required": 50
			}
		],
		"rewards": {
			"exp": 100,
			"coins": 150
		},
		"prerequisites": ["main_002"],
		"next_quest": ""
	}

	quests["daily_002"] = {
		"id": "daily_002",
		"type": "daily",
		"title": "每日采集",
		"description": "收集材料",
		"objectives": [
			{
				"type": "collect",
				"description": "收集任意材料",
				"required": 30
			}
		],
		"rewards": {
			"exp": 80,
			"coins": 100
		},
		"prerequisites": ["main_001"],
		"next_quest": ""
	}

	quests["daily_003"] = {
		"id": "daily_003",
		"type": "daily",
		"title": "地下城探险",
		"description": "完成一次地下城探险",
		"objectives": [
			{
				"type": "complete_dungeon",
				"description": "完成任意层数的地下城",
				"required": 1
			}
		],
		"rewards": {
			"exp": 150,
			"coins": 200,
			"items": {
				"health_potion_medium": 3
			}
		},
		"prerequisites": ["main_002"],
		"next_quest": ""
	}

## 查询方法
func has_quest(quest_id: String) -> bool:
	return quests.has(quest_id)

func get_quest(quest_id: String) -> Dictionary:
	if not quests.has(quest_id):
		push_error("[QuestData] 任务不存在: %s" % quest_id)
		return {}
	return quests[quest_id]

func get_quest_title(quest_id: String) -> String:
	var quest = get_quest(quest_id)
	return quest.get("title", "未知任务")

func get_quest_description(quest_id: String) -> String:
	var quest = get_quest(quest_id)
	return quest.get("description", "")

func get_all_quests() -> Dictionary:
	return quests.duplicate()

func get_quests_by_type(quest_type: String) -> Array[String]:
	var result: Array[String] = []
	for quest_id in quests:
		if quests[quest_id].get("type") == quest_type:
			result.append(quest_id)
	return result

func get_main_quests() -> Array[String]:
	return get_quests_by_type("main")

func get_side_quests() -> Array[String]:
	return get_quests_by_type("side")

func get_daily_quests() -> Array[String]:
	return get_quests_by_type("daily")
