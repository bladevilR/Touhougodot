extends Node

## TimeManager - 全局时间管理引擎
## 游戏世界的时间核心，驱动日历、昼夜、季节等所有时间相关系统

# ==================== 时段枚举 ====================
enum TimePeriod {
	DAWN,       # 黎明 (5:00-7:00)
	MORNING,    # 上午 (7:00-12:00)
	NOON,       # 中午 (12:00-14:00)
	AFTERNOON,  # 下午 (14:00-17:00)
	EVENING,    # 黄昏 (17:00-20:00)
	NIGHT,      # 夜晚 (20:00-24:00)
	MIDNIGHT    # 深夜 (0:00-5:00)
}

# ==================== 配置常量 ====================
const MINUTES_PER_HOUR := 60
const HOURS_PER_DAY := 24
const REAL_SECONDS_PER_GAME_MINUTE := 1.0  # 现实1秒 = 游戏1分钟

# ==================== 状态变量 ====================
var current_minute: int = 0     # 0-59
var current_hour: int = 6       # 0-23, 默认早上6点
var is_time_paused: bool = false
var time_scale: float = 1.0     # 时间流速倍率

var _accumulated_time: float = 0.0
var _last_period: TimePeriod = TimePeriod.DAWN

# ==================== 初始化 ====================
func _ready() -> void:
	print("TimeManager: 初始化中...")
	_last_period = get_time_period()
	print("TimeManager: 初始化完成 - 当前时间 %s" % get_formatted_time())

# ==================== 时间推进 ====================
func _process(delta: float) -> void:
	if is_time_paused:
		return

	_accumulated_time += delta * time_scale

	# 每达到一个游戏分钟，推进时间
	while _accumulated_time >= REAL_SECONDS_PER_GAME_MINUTE:
		_accumulated_time -= REAL_SECONDS_PER_GAME_MINUTE
		_advance_one_minute()

func _advance_one_minute() -> void:
	current_minute += 1

	# 发送每分钟信号
	SignalBus.time_tick.emit(get_total_minutes())

	# 检查是否跨小时
	if current_minute >= MINUTES_PER_HOUR:
		current_minute = 0
		_advance_one_hour()

func _advance_one_hour() -> void:
	var old_hour = current_hour
	current_hour += 1

	# 检查是否跨天
	if current_hour >= HOURS_PER_DAY:
		current_hour = 0
		_on_day_end()

	# 发送整点信号
	SignalBus.hour_changed.emit(current_hour)
	print("TimeManager: 时间推进到 %s" % get_formatted_time())

	# 检查时段变化
	var new_period = get_time_period()
	if new_period != _last_period:
		_last_period = new_period
		SignalBus.time_of_day_changed.emit(new_period)
		print("TimeManager: 时段变化为 %s" % TimePeriod.keys()[new_period])

func _on_day_end() -> void:
	# 通知日历系统推进一天
	SignalBus.day_changed.emit(0)  # 参数由CalendarManager填充

# ==================== 公开方法 ====================

## 手动推进时间（分钟）
func advance_time(minutes: int) -> void:
	for i in range(minutes):
		_advance_one_minute()

## 设置具体时间
func set_time(hour: int, minute: int = 0) -> void:
	current_hour = clampi(hour, 0, 23)
	current_minute = clampi(minute, 0, 59)
	_last_period = get_time_period()
	SignalBus.hour_changed.emit(current_hour)
	SignalBus.time_of_day_changed.emit(_last_period)
	print("TimeManager: 时间设置为 %s" % get_formatted_time())

## 暂停时间
func pause_time() -> void:
	is_time_paused = true
	print("TimeManager: 时间已暂停")

## 恢复时间
func resume_time() -> void:
	is_time_paused = false
	print("TimeManager: 时间已恢复")

## 设置时间流速
func set_time_scale(scale: float) -> void:
	time_scale = maxf(scale, 0.0)

## 获取当前时段
func get_time_period() -> TimePeriod:
	if current_hour >= 5 and current_hour < 7:
		return TimePeriod.DAWN
	elif current_hour >= 7 and current_hour < 12:
		return TimePeriod.MORNING
	elif current_hour >= 12 and current_hour < 14:
		return TimePeriod.NOON
	elif current_hour >= 14 and current_hour < 17:
		return TimePeriod.AFTERNOON
	elif current_hour >= 17 and current_hour < 20:
		return TimePeriod.EVENING
	elif current_hour >= 20 and current_hour < 24:
		return TimePeriod.NIGHT
	else:  # 0-5
		return TimePeriod.MIDNIGHT

## 获取格式化时间字符串
func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

## 获取当天总分钟数
func get_total_minutes() -> int:
	return current_hour * MINUTES_PER_HOUR + current_minute

## 检查是否是白天
func is_daytime() -> bool:
	return current_hour >= 6 and current_hour < 20

## 检查是否是夜晚
func is_nighttime() -> bool:
	return not is_daytime()

# ==================== 存档接口 ====================
func get_save_data() -> Dictionary:
	return {
		"hour": current_hour,
		"minute": current_minute,
		"time_scale": time_scale
	}

func load_save_data(data: Dictionary) -> void:
	current_hour = data.get("hour", 6)
	current_minute = data.get("minute", 0)
	time_scale = data.get("time_scale", 1.0)
	_last_period = get_time_period()
	print("TimeManager: 存档加载完成 - %s" % get_formatted_time())
