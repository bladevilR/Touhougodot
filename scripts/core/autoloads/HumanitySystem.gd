extends Node

## HumanitySystem - 人性系统
## 管理玩家的"人性"数值，影响剧情走向和NPC反应

# 人性值 (0-100)
var current_humanity: float = 50.0

# 人性变化触发器
const ACTIONS = {
	"sleep_in_bed": 2.0,           # 睡觉 +2
	"drink_tea": 1.5,              # 喝茶 +1.5
	"eat_meal": 2.5,               # 吃饭 +2.5
	"read_book": 1.0,              # 读书 +1
	"skip_sleep": -5.0,            # 跳过睡眠 -5
	"fatigue_collapse": -10.0,     # 疲劳昏倒 -10
	"kill_enemy_cruel": -2.0,      # 残忍杀敌 -2
	"refuse_help_npc": -8.0,       # 见死不救 -8
	"help_npc": 3.0,               # 帮助NPC +3
	"complete_good_quest": 5.0,    # 完成善良任务 +5
}

# 阈值定义
const THRESHOLD_CRITICAL_LOW = 20.0   # 严重低人性（灵梦退治触发）
const THRESHOLD_LOW = 40.0            # 低人性（慧音关心触发）
const THRESHOLD_MEDIUM = 60.0         # 普通人性
const THRESHOLD_HIGH = 80.0           # 高人性

# 上次触发的阈值
var _last_threshold: String = "MEDIUM"

func _ready():
	# 初始化时检查阈值
	_check_thresholds()
	print("[HumanitySystem] 人性系统已初始化，当前人性: %.1f" % current_humanity)

## 修改人性值（通过预定义的行为）
func modify_humanity(action: String) -> void:
	if not ACTIONS.has(action):
		push_warning("[HumanitySystem] 未定义的行为: %s" % action)
		return

	var change = ACTIONS[action]
	add_humanity(change)

## 直接增加/减少人性值
func add_humanity(amount: float) -> void:
	var old_value = current_humanity
	current_humanity = clampf(current_humanity + amount, 0.0, 100.0)

	if old_value != current_humanity:
		SignalBus.humanity_changed.emit(old_value, current_humanity)
		print("[HumanitySystem] 人性变化: %.1f -> %.1f (变化: %+.1f)" % [old_value, current_humanity, amount])
		_check_thresholds()

## 检查是否跨越阈值
func _check_thresholds() -> void:
	var current_threshold = _get_current_threshold()

	if current_threshold != _last_threshold:
		var is_rising = _is_threshold_higher(current_threshold, _last_threshold)
		SignalBus.humanity_threshold_crossed.emit(current_threshold, is_rising)

		# 发送特定警告
		match current_threshold:
			"CRITICAL_LOW":
				SignalBus.humanity_warning.emit("critical_low")
				print("[HumanitySystem] ⚠️ 警告：人性极低！灵梦可能会来退治！")
			"LOW":
				SignalBus.humanity_warning.emit("low")
				print("[HumanitySystem] 提示：人性偏低，慧音可能会关心你")
			"HIGH":
				if is_rising:
					print("[HumanitySystem] ✨ 人性很高，妹红保持着人类的生活方式")

		_last_threshold = current_threshold

## 获取当前人性等级
func _get_current_threshold() -> String:
	if current_humanity < THRESHOLD_CRITICAL_LOW:
		return "CRITICAL_LOW"
	elif current_humanity < THRESHOLD_LOW:
		return "LOW"
	elif current_humanity < THRESHOLD_MEDIUM:
		return "MEDIUM"
	elif current_humanity < THRESHOLD_HIGH:
		return "MEDIUM_HIGH"
	else:
		return "HIGH"

## 比较两个阈值的高低
func _is_threshold_higher(threshold1: String, threshold2: String) -> bool:
	const THRESHOLD_ORDER = ["CRITICAL_LOW", "LOW", "MEDIUM", "MEDIUM_HIGH", "HIGH"]
	var index1 = THRESHOLD_ORDER.find(threshold1)
	var index2 = THRESHOLD_ORDER.find(threshold2)
	return index1 > index2

## 获取人性状态描述
func get_humanity_description() -> String:
	if current_humanity < THRESHOLD_CRITICAL_LOW:
		return "妖怪化"
	elif current_humanity < THRESHOLD_LOW:
		return "人性低"
	elif current_humanity < THRESHOLD_MEDIUM:
		return "普通"
	elif current_humanity < THRESHOLD_HIGH:
		return "人性高"
	else:
		return "完全人类"

## 检查是否满足特定条件
func meets_condition(condition: String, value: float) -> bool:
	match condition:
		"humanity_above":
			return current_humanity >= value
		"humanity_below":
			return current_humanity <= value
		_:
			return false

## 保存数据
func get_save_data() -> Dictionary:
	return {
		"current_humanity": current_humanity,
		"last_threshold": _last_threshold
	}

## 读取数据
func load_save_data(data: Dictionary) -> void:
	current_humanity = data.get("current_humanity", 50.0)
	_last_threshold = data.get("last_threshold", "MEDIUM")
	SignalBus.humanity_changed.emit(current_humanity, current_humanity)  # 触发UI更新
	_check_thresholds()
	print("[HumanitySystem] 已读取人性数据: %.1f (%s)" % [current_humanity, get_humanity_description()])
