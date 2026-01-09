extends Node

## QuestManager - 任务管理系统
## 管理主线任务、支线任务、每日任务等

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)
signal quest_objective_completed(quest_id: String, objective_index: int)
signal quest_progress_updated(quest_id: String, objective_index: int, current: int, required: int)

# 任务状态枚举
enum QuestStatus {
	NOT_STARTED,   # 未开始
	IN_PROGRESS,   # 进行中
	COMPLETED,     # 已完成
	FAILED         # 已失败
}

# 任务类型枚举
enum QuestType {
	MAIN,          # 主线
	SIDE,          # 支线
	DAILY,         # 每日
	REPEATABLE     # 可重复
}

# 当前任务数据
# quest_id: {status: QuestStatus, progress: [int], started_time: float}
var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var last_daily_reset_day: int = -1  # 上次每日任务重置的日期

func _ready():
	# 监听游戏事件来更新任务进度
	_connect_game_signals()
	print("QuestManager: 初始化完成")

## 连接游戏信号
func _connect_game_signals() -> void:
	# 监听击杀事件
	SignalBus.enemy_killed.connect(_on_enemy_killed)

	# 监听物品拾取
	if has_node("/root/InventoryManager"):
		InventoryManager.item_added.connect(_on_item_collected)

	# 监听日期变化（用于每日任务重置）
	if SignalBus.has_signal("day_started"):
		SignalBus.day_started.connect(_on_day_started)

## 开始任务
func start_quest(quest_id: String) -> bool:
	# 检查任务是否存在
	if not QuestData.has_quest(quest_id):
		push_error("[QuestManager] 任务不存在: %s" % quest_id)
		return false

	# 检查是否已经开始
	if active_quests.has(quest_id):
		push_warning("[QuestManager] 任务已经开始: %s" % quest_id)
		return false

	# 检查前置任务
	var quest_data = QuestData.get_quest(quest_id)
	var prerequisites = quest_data.get("prerequisites", [])
	for prereq in prerequisites:
		if not is_quest_completed(prereq):
			push_warning("[QuestManager] 前置任务未完成: %s" % prereq)
			return false

	# 初始化任务进度
	var objectives = quest_data.get("objectives", [])
	var progress = []
	for i in range(objectives.size()):
		progress.append(0)

	active_quests[quest_id] = {
		"status": QuestStatus.IN_PROGRESS,
		"progress": progress,
		"started_time": Time.get_ticks_msec() / 1000.0
	}

	quest_started.emit(quest_id)
	return true

## 更新任务进度
func update_quest_progress(quest_id: String, objective_index: int, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return

	var quest_state = active_quests[quest_id]
	if quest_state.status != QuestStatus.IN_PROGRESS:
		return

	var quest_data = QuestData.get_quest(quest_id)
	var objectives = quest_data.get("objectives", [])

	if objective_index < 0 or objective_index >= objectives.size():
		push_error("[QuestManager] 任务目标索引无效: %d" % objective_index)
		return

	# 更新进度
	var current_progress = quest_state.progress[objective_index]
	var required = objectives[objective_index].get("required", 1)
	quest_state.progress[objective_index] = min(current_progress + amount, required)

	quest_updated.emit(quest_id, objective_index)

	# 发送详细进度信号
	quest_progress_updated.emit(quest_id, objective_index, quest_state.progress[objective_index], required)

	# 检查目标是否完成
	if quest_state.progress[objective_index] >= required:
		quest_objective_completed.emit(quest_id, objective_index)

	# 检查整个任务是否完成
	_check_quest_completion(quest_id)

## 完成任务
func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	var quest_state = active_quests[quest_id]
	quest_state.status = QuestStatus.COMPLETED

	# 移到已完成列表
	completed_quests.append(quest_id)

	# 发放奖励
	_grant_quest_rewards(quest_id)

	quest_completed.emit(quest_id)

	# 从活动列表移除（延迟移除，让UI有时间显示）
	await get_tree().create_timer(0.5).timeout
	active_quests.erase(quest_id)

## 任务失败
func fail_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	var quest_state = active_quests[quest_id]
	quest_state.status = QuestStatus.FAILED

	quest_failed.emit(quest_id)

	# 移除任务
	active_quests.erase(quest_id)

## 检查任务是否完成
func _check_quest_completion(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	var quest_state = active_quests[quest_id]
	var quest_data = QuestData.get_quest(quest_id)
	var objectives = quest_data.get("objectives", [])

	# 检查所有目标是否完成
	for i in range(objectives.size()):
		var required = objectives[i].get("required", 1)
		if quest_state.progress[i] < required:
			return  # 还有未完成的目标

	# 所有目标完成，完成任务
	complete_quest(quest_id)

## 发放任务奖励
func _grant_quest_rewards(quest_id: String) -> void:
	var quest_data = QuestData.get_quest(quest_id)
	var rewards = quest_data.get("rewards", {})

	# 经验奖励
	if rewards.has("exp"):
		var exp_amount = rewards.exp
		# 尝试通过 ExperienceManager 添加经验
		var exp_manager = get_tree().get_first_node_in_group("experience_manager")
		if exp_manager and exp_manager.has_method("gain_xp"):
			exp_manager.gain_xp(exp_amount)
		# 发送通知
		if SignalBus.has_signal("show_notification"):
			SignalBus.show_notification.emit("获得 %d 经验!" % exp_amount, Color.YELLOW)
		print("QuestManager: 发放经验奖励 %d" % exp_amount)

	# 金币奖励
	if rewards.has("coins"):
		GameStateManager.player_data.coins += rewards.coins
		SignalBus.coins_changed.emit(GameStateManager.player_data.coins)
		print("QuestManager: 发放金币奖励 %d" % rewards.coins)

	# 物品奖励
	if rewards.has("items"):
		for item_id in rewards.items:
			var amount = rewards.items[item_id]
			if has_node("/root/InventoryManager"):
				InventoryManager.add_item(item_id, amount)
		print("QuestManager: 发放物品奖励")

## 事件处理
func _on_enemy_killed(enemy: Node2D, xp_value: float, position: Vector2) -> void:
	# 更新所有"击杀敌人"类型的任务目标
	for quest_id in active_quests:
		var quest_data = QuestData.get_quest(quest_id)
		var objectives = quest_data.get("objectives", [])

		for i in range(objectives.size()):
			var objective = objectives[i]
			if objective.get("type") == "kill":
				update_quest_progress(quest_id, i, 1)

func _on_item_collected(item_id: String, amount: int) -> void:
	# 更新所有"收集物品"类型的任务目标
	for quest_id in active_quests:
		var quest_data = QuestData.get_quest(quest_id)
		var objectives = quest_data.get("objectives", [])

		for i in range(objectives.size()):
			var objective = objectives[i]
			if objective.get("type") == "collect" and objective.get("item_id") == item_id:
				update_quest_progress(quest_id, i, amount)

## 每日任务重置（日期变化时触发）
func _on_day_started(day: int, _weekday: String, _season: String) -> void:
	if day != last_daily_reset_day:
		_reset_daily_quests()
		last_daily_reset_day = day

## 重置每日任务
func _reset_daily_quests() -> void:
	print("QuestManager: 正在重置每日任务...")
	var daily_quests_reset_count = 0

	# 获取所有每日任务ID
	var all_quests = QuestData.get_all_quests()
	for quest_id in all_quests:
		var quest_data = QuestData.get_quest(quest_id)
		if quest_data.get("type") == "daily":
			# 从已完成列表移除
			if quest_id in completed_quests:
				completed_quests.erase(quest_id)
				daily_quests_reset_count += 1

			# 从活动列表移除
			if active_quests.has(quest_id):
				active_quests.erase(quest_id)

	if daily_quests_reset_count > 0:
		print("QuestManager: 重置了 %d 个每日任务" % daily_quests_reset_count)
		SignalBus.daily_quests_reset.emit()

## 查询方法
func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

func get_quest_progress(quest_id: String) -> Array:
	if not active_quests.has(quest_id):
		return []
	return active_quests[quest_id].progress

func get_active_quests() -> Array[String]:
	var result: Array[String] = []
	result.assign(active_quests.keys())
	return result

func get_completed_quests() -> Array[String]:
	return completed_quests.duplicate()

## 存档相关
func get_save_data() -> Dictionary:
	return {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(),
		"last_daily_reset_day": last_daily_reset_day
	}

func load_save_data(data: Dictionary) -> void:
	active_quests = data.get("active_quests", {})
	completed_quests = data.get("completed_quests", [])
	last_daily_reset_day = data.get("last_daily_reset_day", -1)
