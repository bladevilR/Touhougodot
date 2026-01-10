extends Node

## NPCScheduleManager - NPC日程管理器
## 管理所有NPC的每日日程，根据时间自动切换NPC状态和位置

# NPC状态枚举
enum NPCState {
	IDLE,           # 空闲
	WORKING,        # 工作
	EATING,         # 吃饭
	WALKING,        # 行走/散步
	SLEEPING,       # 睡觉
	SPECIAL         # 特殊活动
}

# NPC数据类
class NPCData:
	var npc_id: String
	var current_state: NPCState
	var current_location: String
	var daily_schedule: Array[Dictionary]  # 日程列表
	var current_schedule_index: int = 0
	var is_interruptible: bool = true

	func _init(id: String):
		npc_id = id
		current_state = NPCState.IDLE
		current_location = ""
		daily_schedule = []

# 所有NPC
var npcs: Dictionary = {}  # npc_id -> NPCData

func _ready():
	# 监听时间变化
	if SignalBus.has_signal("hour_changed"):
		SignalBus.hour_changed.connect(_on_hour_changed)

	# 监听日期变化（重置每日日程）
	if SignalBus.has_signal("day_started"):
		SignalBus.day_started.connect(_on_day_started)

	# 监听人性阈值变化（触发特殊日程）
	if SignalBus.has_signal("humanity_threshold_crossed"):
		SignalBus.humanity_threshold_crossed.connect(_on_humanity_threshold_crossed)

	# 初始化NPC日程
	_initialize_npc_schedules()

	print("[NPCScheduleManager] NPC日程系统已初始化")

## 初始化NPC日程数据
func _initialize_npc_schedules() -> void:
	# 慧音的日程
	_create_keine_schedule()

	# 灵梦的日程
	_create_reimu_schedule()

	# 魔理沙的日程
	_create_marisa_schedule()

	# 咲夜的日程
	_create_sakuya_schedule()

	# 恋恋的日程（特殊，雨天出现）
	_create_koishi_schedule()

	# 阿求的日程
	_create_akyuu_schedule()

## 创建慧音的日程
func _create_keine_schedule() -> void:
	var keine = NPCData.new("keine")

	keine.daily_schedule = [
		{
			"time_start": 6,
			"time_end": 8,
			"location": "keine_house",
			"action": "wake_up",
			"state": NPCState.IDLE,
			"interruptible": true
		},
		{
			"time_start": 8,
			"time_end": 12,
			"location": "temple_school",
			"action": "teaching",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 12,
			"time_end": 13,
			"location": "temple_school",
			"action": "lunch",
			"state": NPCState.EATING,
			"interruptible": true
		},
		{
			"time_start": 13,
			"time_end": 17,
			"location": "temple_school",
			"action": "teaching",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 17,
			"time_end": 19,
			"location": "town_plaza",
			"action": "walking",
			"state": NPCState.WALKING,
			"interruptible": true
		},
		{
			"time_start": 19,
			"time_end": 22,
			"location": "keine_house",
			"action": "relax",
			"state": NPCState.IDLE,
			"interruptible": true
		},
		{
			"time_start": 22,
			"time_end": 6,
			"location": "keine_house",
			"action": "sleep",
			"state": NPCState.SLEEPING,
			"interruptible": false
		}
	]

	keine.current_location = "keine_house"
	npcs["keine"] = keine

## 创建灵梦的日程
func _create_reimu_schedule() -> void:
	var reimu = NPCData.new("reimu")

	reimu.daily_schedule = [
		{
			"time_start": 7,
			"time_end": 9,
			"location": "hakurei_shrine",
			"action": "morning_routine",
			"state": NPCState.IDLE,
			"interruptible": true
		},
		{
			"time_start": 9,
			"time_end": 12,
			"location": "hakurei_shrine",
			"action": "shrine_duties",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 12,
			"time_end": 14,
			"location": "hakurei_shrine",
			"action": "lunch_and_tea",
			"state": NPCState.EATING,
			"interruptible": true
		},
		{
			"time_start": 14,
			"time_end": 17,
			"location": "town",
			"action": "patrol",
			"state": NPCState.WALKING,
			"interruptible": true
		},
		{
			"time_start": 17,
			"time_end": 20,
			"location": "hakurei_shrine",
			"action": "evening_duties",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 20,
			"time_end": 22,
			"location": "hakurei_shrine",
			"action": "relax",
			"state": NPCState.IDLE,
			"interruptible": true
		},
		{
			"time_start": 22,
			"time_end": 7,
			"location": "hakurei_shrine",
			"action": "sleep",
			"state": NPCState.SLEEPING,
			"interruptible": false
		}
	]

	reimu.current_location = "hakurei_shrine"
	npcs["reimu"] = reimu

## 创建魔理沙的日程
func _create_marisa_schedule() -> void:
	var marisa = NPCData.new("marisa")

	marisa.daily_schedule = [
		{
			"time_start": 7,
			"time_end": 10,
			"location": "magic_forest",  # 暂不实现该场景
			"action": "magic_research",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 10,
			"time_end": 12,
			"location": "village_center",  # 来人之里买道具
			"action": "shopping",
			"state": NPCState.WALKING,
			"interruptible": true
		},
		{
			"time_start": 12,
			"time_end": 13,
			"location": "magic_forest",
			"action": "lunch",
			"state": NPCState.EATING,
			"interruptible": true
		},
		{
			"time_start": 13,
			"time_end": 15,
			"location": "magic_forest",
			"action": "magic_practice",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 15,
			"time_end": 17,
			"location": "village_center",  # 闲逛
			"action": "wandering",
			"state": NPCState.WALKING,
			"interruptible": true
		},
		{
			"time_start": 17,
			"time_end": 22,
			"location": "magic_forest",
			"action": "research_late",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 22,
			"time_end": 7,
			"location": "magic_forest",
			"action": "sleep",
			"state": NPCState.SLEEPING,
			"interruptible": false
		}
	]

	marisa.current_location = "magic_forest"
	npcs["marisa"] = marisa

## 创建咲夜的日程
func _create_sakuya_schedule() -> void:
	var sakuya = NPCData.new("sakuya")

	sakuya.daily_schedule = [
		{
			"time_start": 6,
			"time_end": 9,
			"location": "scarlet_mansion",  # 暂不实现该场景
			"action": "morning_duties",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 9,
			"time_end": 11,
			"location": "village_center",  # 来人之里买菜
			"action": "shopping",
			"state": NPCState.WALKING,
			"interruptible": true
		},
		{
			"time_start": 11,
			"time_end": 12,
			"location": "scarlet_mansion",
			"action": "cooking",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 12,
			"time_end": 13,
			"location": "scarlet_mansion",
			"action": "serving_lunch",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 13,
			"time_end": 17,
			"location": "scarlet_mansion",
			"action": "afternoon_duties",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 17,
			"time_end": 20,
			"location": "scarlet_mansion",
			"action": "evening_duties",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 20,
			"time_end": 22,
			"location": "scarlet_mansion",
			"action": "rest",
			"state": NPCState.IDLE,
			"interruptible": true
		},
		{
			"time_start": 22,
			"time_end": 6,
			"location": "scarlet_mansion",
			"action": "sleep",
			"state": NPCState.SLEEPING,
			"interruptible": false
		}
	]

	sakuya.current_location = "scarlet_mansion"
	npcs["sakuya"] = sakuya

## 创建恋恋的日程（雨天特殊）
func _create_koishi_schedule() -> void:
	var koishi = NPCData.new("koishi")

	# 恋恋只在雨天出现，全天在桥边
	koishi.daily_schedule = [
		{
			"time_start": 0,
			"time_end": 24,
			"location": "village_bridge",  # 人之里的桥边
			"action": "waiting",
			"state": NPCState.IDLE,
			"interruptible": true,
			"weather_condition": "rain"  # 特殊：需要雨天
		}
	]

	koishi.current_location = "hidden"  # 默认不出现
	npcs["koishi"] = koishi

## 创建阿求的日程
func _create_akyuu_schedule() -> void:
	var akyuu = NPCData.new("akyuu")

	akyuu.daily_schedule = [
		{
			"time_start": 7,
			"time_end": 9,
			"location": "hieda_house",  # 稗田邸（暂不实现）
			"action": "wake_up",
			"state": NPCState.IDLE,
			"interruptible": true
		},
		{
			"time_start": 9,
			"time_end": 12,
			"location": "hieda_house",
			"action": "writing",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 12,
			"time_end": 13,
			"location": "hieda_house",
			"action": "lunch",
			"state": NPCState.EATING,
			"interruptible": true
		},
		{
			"time_start": 13,
			"time_end": 15,
			"location": "temple_school",  # 访问慧音（与慧音的羁绊剧情）
			"action": "visiting_keine",
			"state": NPCState.WALKING,
			"interruptible": true
		},
		{
			"time_start": 15,
			"time_end": 18,
			"location": "hieda_house",
			"action": "writing",
			"state": NPCState.WORKING,
			"interruptible": false
		},
		{
			"time_start": 18,
			"time_end": 20,
			"location": "hieda_house",
			"action": "reading",
			"state": NPCState.IDLE,
			"interruptible": true
		},
		{
			"time_start": 20,
			"time_end": 7,
			"location": "hieda_house",
			"action": "sleep",
			"state": NPCState.SLEEPING,
			"interruptible": false
		}
	]

	akyuu.current_location = "hieda_house"
	npcs["akyuu"] = akyuu

## 每小时触发
func _on_hour_changed(hour: int) -> void:
	# 更新所有NPC的日程
	for npc_id in npcs:
		_update_npc_schedule(npc_id, hour)

## 更新NPC日程
func _update_npc_schedule(npc_id: String, hour: int) -> void:
	if not npcs.has(npc_id):
		return

	var npc = npcs[npc_id]

	# 查找当前时间对应的日程
	for i in range(npc.daily_schedule.size()):
		var schedule = npc.daily_schedule[i]
		var start = schedule.time_start
		var end = schedule.time_end

		# 处理跨夜的情况
		var is_in_schedule = false
		if end < start:  # 跨夜 (如22:00-6:00)
			is_in_schedule = (hour >= start or hour < end)
		else:
			is_in_schedule = (hour >= start and hour < end)

		if is_in_schedule:
			# 检查是否需要切换日程
			if npc.current_schedule_index != i:
				npc.current_schedule_index = i
				npc.current_state = schedule.state
				npc.current_location = schedule.location
				npc.is_interruptible = schedule.interruptible

				# 发送信号
				SignalBus.npc_schedule_changed.emit(npc_id, schedule)
				SignalBus.npc_arrived_at_location.emit(npc_id, schedule.location)

				print("[NPCScheduleManager] %s 进入新日程: %s 在 %s" % [npc_id, schedule.action, schedule.location])

			break

## 新的一天开始
func _on_day_started(_day: int, _weekday: String, _season: String) -> void:
	# 重置所有NPC的日程索引
	for npc_id in npcs:
		npcs[npc_id].current_schedule_index = 0

	print("[NPCScheduleManager] 新的一天，所有NPC日程已重置")

## 人性阈值变化（触发特殊日程）
func _on_humanity_threshold_crossed(threshold_name: String, is_rising: bool) -> void:
	# 人性极低时，灵梦会有特殊日程
	if threshold_name == "CRITICAL_LOW" and not is_rising:
		_trigger_reimu_extermination_schedule()

## 触发灵梦退治日程
func _trigger_reimu_extermination_schedule() -> void:
	if not npcs.has("reimu"):
		return

	var reimu = npcs["reimu"]

	# 插入特殊日程：灵梦会前往竹林小屋
	var special_schedule = {
		"time_start": 10,
		"time_end": 12,
		"location": "bamboo_house",
		"action": "extermination_standby",
		"state": NPCState.SPECIAL,
		"interruptible": false
	}

	# 在第2个日程后插入（9-12点之间）
	reimu.daily_schedule.insert(2, special_schedule)

	print("[NPCScheduleManager] ⚠️ 灵梦的特殊日程已触发：退治准备")

## 获取NPC当前位置
func get_npc_location(npc_id: String) -> String:
	if npcs.has(npc_id):
		return npcs[npc_id].current_location
	return ""

## 获取NPC当前状态
func get_npc_state(npc_id: String) -> NPCState:
	if npcs.has(npc_id):
		return npcs[npc_id].current_state
	return NPCState.IDLE

## 检查NPC是否可打断
func is_npc_interruptible(npc_id: String) -> bool:
	if npcs.has(npc_id):
		return npcs[npc_id].is_interruptible
	return false

## 保存数据
func get_save_data() -> Dictionary:
	var data = {}

	for npc_id in npcs:
		var npc = npcs[npc_id]
		data[npc_id] = {
			"current_schedule_index": npc.current_schedule_index,
			"current_location": npc.current_location
		}

	return data

## 读取数据
func load_save_data(data: Dictionary) -> void:
	for npc_id in data:
		if npcs.has(npc_id):
			var npc = npcs[npc_id]
			npc.current_schedule_index = data[npc_id].get("current_schedule_index", 0)
			npc.current_location = data[npc_id].get("current_location", "")

	print("[NPCScheduleManager] 已读取NPC日程数据")
