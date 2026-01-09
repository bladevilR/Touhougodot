extends Node

## CalendarManager - 全局日历管理
## 管理日期、周、季节、年份，与 TimeManager 联动

# ==================== 配置常量 ====================
const DAYS_PER_WEEK := 7
const DAYS_PER_SEASON := 28          # 每季节28天
const SEASONS := ["spring", "summer", "autumn", "winter"]
const SEASON_NAMES := {"spring": "春", "summer": "夏", "autumn": "秋", "winter": "冬"}
const WEEKDAYS := ["月", "火", "水", "木", "金", "土", "日"]

# ==================== 状态变量 ====================
var current_day: int = 1           # 1-28
var current_season_index: int = 0  # 0-3
var current_year: int = 1
var total_days_played: int = 0     # 游戏总天数

# ==================== 节日配置 ====================
var festivals: Dictionary = {
	# 格式: "季节_日期": {"id": "...", "name": "..."}
	"spring_1": {"id": "new_year", "name": "新年祭"},
	"spring_14": {"id": "flower_festival", "name": "花见祭"},
	"summer_7": {"id": "tanabata", "name": "七夕祭"},
	"summer_15": {"id": "obon", "name": "盂兰盆节"},
	"autumn_15": {"id": "moon_festival", "name": "中秋祭"},
	"winter_24": {"id": "christmas", "name": "圣诞祭"},
}

# ==================== 初始化 ====================
func _ready() -> void:
	print("CalendarManager: 初始化中...")
	# 监听 TimeManager 的日期变化信号
	if SignalBus.has_signal("day_changed"):
		SignalBus.day_changed.connect(_on_time_day_changed)
	print("CalendarManager: 初始化完成 - %s" % get_date_string())

# ==================== 事件处理 ====================
func _on_time_day_changed(_unused: int) -> void:
	# TimeManager 通知一天结束，推进日历
	advance_day()

# ==================== 日期推进 ====================
func advance_day() -> void:
	var old_day = current_day
	var old_season = get_current_season()
	var old_year = current_year

	current_day += 1
	total_days_played += 1

	# 检查是否需要换季
	if current_day > DAYS_PER_SEASON:
		current_day = 1
		current_season_index += 1

		# 检查是否需要换年
		if current_season_index >= SEASONS.size():
			current_season_index = 0
			current_year += 1
			SignalBus.year_changed.emit(current_year)
			print("CalendarManager: 新年！第 %d 年" % current_year)

		var new_season = get_current_season()
		SignalBus.season_changed.emit(old_season, new_season)
		print("CalendarManager: 季节变化 %s -> %s" % [old_season, new_season])

	# 检查周变化
	var old_week = (old_day - 1) / DAYS_PER_WEEK + 1
	var new_week = (current_day - 1) / DAYS_PER_WEEK + 1
	if new_week != old_week or current_day == 1:
		SignalBus.week_changed.emit(new_week)

	# 发送日期变化信号（带完整参数）
	SignalBus.day_started.emit(current_day, get_weekday(), get_current_season())
	print("CalendarManager: 日期推进到 %s" % get_date_string())

	# 检查节日
	var festival_key = "%s_%d" % [get_current_season(), current_day]
	if festivals.has(festival_key):
		var festival = festivals[festival_key]
		SignalBus.festival_started.emit(festival.id)
		print("CalendarManager: 节日开始 - %s" % festival.name)

	# 通知其他系统（如农场）
	_notify_farming_system()

# ==================== 公开方法 ====================

## 获取当前季节
func get_current_season() -> String:
	return SEASONS[current_season_index]

## 获取当前季节中文名
func get_season_name() -> String:
	return SEASON_NAMES[get_current_season()]

## 获取星期几
func get_weekday() -> String:
	var weekday_index = (current_day - 1) % DAYS_PER_WEEK
	return WEEKDAYS[weekday_index]

## 获取完整日期字符串
func get_date_string() -> String:
	return "%s %d日 (%s)" % [get_season_name(), current_day, get_weekday()]

## 获取简短日期
func get_short_date() -> String:
	return "%s%d" % [get_season_name(), current_day]

## 检查是否是节日
func is_festival() -> bool:
	var festival_key = "%s_%d" % [get_current_season(), current_day]
	return festivals.has(festival_key)

## 获取节日ID
func get_festival_id() -> String:
	var festival_key = "%s_%d" % [get_current_season(), current_day]
	if festivals.has(festival_key):
		return festivals[festival_key].id
	return ""

## 获取节日名称
func get_festival_name() -> String:
	var festival_key = "%s_%d" % [get_current_season(), current_day]
	if festivals.has(festival_key):
		return festivals[festival_key].name
	return ""

## 设置日期（用于调试或存档加载）
func set_date(day: int, season_index: int, year: int = 1) -> void:
	current_day = clampi(day, 1, DAYS_PER_SEASON)
	current_season_index = clampi(season_index, 0, SEASONS.size() - 1)
	current_year = maxi(year, 1)
	print("CalendarManager: 日期设置为 %s" % get_date_string())

## 跳过多天
func skip_days(days: int) -> void:
	for i in range(days):
		advance_day()

# ==================== 与 FarmingManager 同步 ====================
func _notify_farming_system() -> void:
	# 通知农场系统更新
	var farming_nodes = get_tree().get_nodes_in_group("farming_manager")
	for node in farming_nodes:
		if node.has_method("update_farm_day"):
			node.update_farm_day()

## 从 FarmingManager 同步数据（向后兼容）
func sync_from_farming_manager(farming_manager: Node) -> void:
	if farming_manager:
		current_day = farming_manager.current_day
		var season_str = farming_manager.current_season
		current_season_index = SEASONS.find(season_str)
		if current_season_index < 0:
			current_season_index = 0
		print("CalendarManager: 从 FarmingManager 同步数据完成")

# ==================== 存档接口 ====================
func get_save_data() -> Dictionary:
	return {
		"day": current_day,
		"season_index": current_season_index,
		"year": current_year,
		"total_days_played": total_days_played
	}

func load_save_data(data: Dictionary) -> void:
	current_day = data.get("day", 1)
	current_season_index = data.get("season_index", 0)
	current_year = data.get("year", 1)
	total_days_played = data.get("total_days_played", 0)
	print("CalendarManager: 存档加载完成 - %s" % get_date_string())
