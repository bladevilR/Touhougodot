extends Node

## QuestBoard - 任务公告板系统
## 管理任务公告板，玩家可以接取每日任务和支线任务

signal quest_board_opened()
signal quest_board_closed()
signal quest_accepted(quest_id: String)

# 可用任务列表
var available_quests: Array[Dictionary] = []

# 每日任务池
var daily_quest_pool: Array[Dictionary] = [
	{
		"id": "daily_gather_bamboo",
		"title": "采集竹笋",
		"description": "收集10个竹笋",
		"type": "daily",
		"objectives": [{"type": "gather", "target": "bamboo_shoot", "amount": 10}],
		"rewards": {"coins": 50, "exp": 20}
	},
	{
		"id": "daily_defeat_fairies",
		"title": "清理妖精",
		"description": "击败5只妖精",
		"type": "daily",
		"objectives": [{"type": "defeat", "target": "fairy", "amount": 5}],
		"rewards": {"coins": 80, "exp": 30}
	},
	{
		"id": "daily_fishing",
		"title": "钓鱼任务",
		"description": "钓3条鱼",
		"type": "daily",
		"objectives": [{"type": "gather", "target": "fish", "amount": 3}],
		"rewards": {"coins": 60, "exp": 25}
	}
]

# 主线/支线任务
var story_quests: Array[Dictionary] = [
	{
		"id": "main_keine_intro",
		"title": "初识慧音",
		"description": "前往寺子屋拜访慧音老师",
		"type": "main",
		"objectives": [{"type": "talk", "target": "keine", "amount": 1}],
		"rewards": {"coins": 100, "exp": 50},
		"unlock_condition": ""
	},
	{
		"id": "side_keine_scrolls",
		"title": "失落的卷轴",
		"description": "帮慧音寻找古代历史卷轴",
		"type": "side",
		"objectives": [
			{"type": "探索", "target": "old_ruins", "amount": 1},
			{"type": "gather", "target": "ancient_scroll", "amount": 1}
		],
		"rewards": {"coins": 200, "exp": 100, "bond": {"keine": 150}},
		"unlock_condition": "bond_keine_level_2"
	}
]

func _ready():
	# 监听日期变化，刷新每日任务
	if SignalBus.has_signal("day_started"):
		SignalBus.day_started.connect(_on_day_started)

	# 初始化任务
	_refresh_daily_quests()

	print("[QuestBoard] 任务公告板系统已初始化")

## 刷新每日任务
func _refresh_daily_quests() -> void:
	# 清空旧的每日任务
	available_quests = available_quests.filter(func(q): return q.type != "daily")

	# 从池中随机选择3个每日任务
	var selected_quests = daily_quest_pool.duplicate()
	selected_quests.shuffle()

	for i in range(min(3, selected_quests.size())):
		available_quests.append(selected_quests[i])

	print("[QuestBoard] 每日任务已刷新，共 %d 个任务可接" % available_quests.size())

## 每日重置
func _on_day_started(_day: int, _weekday: String, _season: String) -> void:
	_refresh_daily_quests()

## 获取所有可用任务
func get_available_quests() -> Array[Dictionary]:
	return available_quests

## 接取任务
func accept_quest(quest_id: String) -> bool:
	for quest in available_quests:
		if quest.id == quest_id:
			# 检查是否已经接取
			if QuestManager and QuestManager.has_quest(quest_id):
				print("[QuestBoard] 任务已接取: %s" % quest_id)
				return false

			# 添加到任务管理器
			if QuestManager:
				QuestManager.add_quest(quest)
				quest_accepted.emit(quest_id)
				print("[QuestBoard] 接取任务: %s" % quest.title)
				return true

	return false

## 打开任务公告板
func open_board() -> void:
	quest_board_opened.emit()
	print("[QuestBoard] 打开任务公告板")
	# TODO: 显示UI

## 关闭任务公告板
func close_board() -> void:
	quest_board_closed.emit()
	print("[QuestBoard] 关闭任务公告板")
