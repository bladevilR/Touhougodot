extends Node

## DayNightManager - 昼夜循环视觉效果
## 控制全局光照、色调、环境氛围

# ==================== 时段颜色配置 ====================
# 使用 TimeManager.TimePeriod 枚举值作为键
const TIME_COLORS := {
	0: Color(1.0, 0.85, 0.7, 1.0),    # DAWN - 暖橙色黎明
	1: Color(1.0, 1.0, 1.0, 1.0),     # MORNING - 正常白天
	2: Color(1.0, 0.98, 0.95, 1.0),   # NOON - 微暖中午
	3: Color(1.0, 0.95, 0.9, 1.0),    # AFTERNOON - 暖色下午
	4: Color(1.0, 0.7, 0.5, 1.0),     # EVENING - 橙红黄昏
	5: Color(0.4, 0.4, 0.6, 1.0),     # NIGHT - 深蓝夜晚
	6: Color(0.2, 0.2, 0.35, 1.0),    # MIDNIGHT - 深夜
}

# 亮度配置
const TIME_BRIGHTNESS := {
	0: 0.7,   # DAWN
	1: 1.0,   # MORNING
	2: 1.0,   # NOON
	3: 0.95,  # AFTERNOON
	4: 0.75,  # EVENING
	5: 0.4,   # NIGHT
	6: 0.25,  # MIDNIGHT
}

# ==================== 状态变量 ====================
var current_color: Color = Color.WHITE
var target_color: Color = Color.WHITE
var transition_speed: float = 2.0      # 颜色过渡速度
var is_indoor: bool = false            # 室内不受昼夜影响
var is_forced: bool = false            # 是否强制特定时段
var forced_period: int = 0             # 强制的时段

# ==================== 节点引用 ====================
var _canvas_modulate: CanvasModulate = null
var _tween: Tween = null

# ==================== 初始化 ====================
func _ready() -> void:
	print("DayNightManager: 初始化中...")
	_create_canvas_modulate()

	# 监听时段变化信号
	if SignalBus.has_signal("time_of_day_changed"):
		SignalBus.time_of_day_changed.connect(_on_time_period_changed)

	# 监听场景变化
	if SignalBus.has_signal("scene_changed"):
		SignalBus.scene_changed.connect(_on_scene_changed)

	# 初始化颜色
	_update_color_for_period(_get_current_period())
	print("DayNightManager: 初始化完成")

func _create_canvas_modulate() -> void:
	# 创建全局 CanvasModulate 节点
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "GlobalDayNightModulate"
	_canvas_modulate.color = Color.WHITE
	add_child(_canvas_modulate)

# ==================== 事件处理 ====================
func _on_time_period_changed(period: int) -> void:
	if is_indoor or is_forced:
		return
	_update_color_for_period(period)

func _on_scene_changed(_scene_name: String) -> void:
	# 重置为非室内模式
	is_indoor = false
	is_forced = false

# ==================== 颜色更新 ====================
func _update_color_for_period(period: int) -> void:
	target_color = TIME_COLORS.get(period, Color.WHITE)
	_start_color_transition()

func _start_color_transition() -> void:
	# 停止现有的 tween
	if _tween and _tween.is_valid():
		_tween.kill()

	# 创建新的颜色过渡
	_tween = create_tween()
	_tween.tween_property(_canvas_modulate, "color", target_color, transition_speed)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)

func _get_current_period() -> int:
	# 尝试从 TimeManager 获取当前��段
	if has_node("/root/TimeManager"):
		var time_manager = get_node("/root/TimeManager")
		return time_manager.get_time_period()
	return 1  # 默认返回 MORNING

# ==================== 公开方法 ====================

## 设置为室内模式（不受昼夜影响）
func set_indoor(value: bool) -> void:
	is_indoor = value
	if is_indoor:
		# 室内使用白天光照
		target_color = Color.WHITE
		_start_color_transition()
		print("DayNightManager: 进入室内模式")
	else:
		# 恢复正常昼夜
		is_forced = false
		_update_color_for_period(_get_current_period())
		print("DayNightManager: 退出室内模式")

## 强制设置时段（用于地下城等特殊场景）
func force_time_period(period: int) -> void:
	is_forced = true
	forced_period = period
	_update_color_for_period(period)
	print("DayNightManager: 强制时段为 %d" % period)

## 取消强制时段
func unforce_time_period() -> void:
	is_forced = false
	_update_color_for_period(_get_current_period())
	print("DayNightManager: 取消强制时段")

## 获取当前亮度
func get_current_brightness() -> float:
	var period = forced_period if is_forced else _get_current_period()
	return TIME_BRIGHTNESS.get(period, 1.0)

## 获取当前颜色
func get_current_color() -> Color:
	return _canvas_modulate.color if _canvas_modulate else Color.WHITE

## 立即设置颜色（无过渡）
func set_color_immediate(color: Color) -> void:
	if _canvas_modulate:
		_canvas_modulate.color = color
		current_color = color
		target_color = color

## 设置过渡速度
func set_transition_speed(speed: float) -> void:
	transition_speed = maxf(speed, 0.1)

## 禁用昼夜效果
func disable() -> void:
	if _canvas_modulate:
		_canvas_modulate.color = Color.WHITE
	is_indoor = true

## 启用昼夜效果
func enable() -> void:
	is_indoor = false
	is_forced = false
	_update_color_for_period(_get_current_period())

# ==================== 存档接口 ====================
func get_save_data() -> Dictionary:
	return {
		"is_indoor": is_indoor,
		"is_forced": is_forced,
		"forced_period": forced_period
	}

func load_save_data(data: Dictionary) -> void:
	is_indoor = data.get("is_indoor", false)
	is_forced = data.get("is_forced", false)
	forced_period = data.get("forced_period", 0)

	if is_forced:
		_update_color_for_period(forced_period)
	elif not is_indoor:
		_update_color_for_period(_get_current_period())
	print("DayNightManager: 存档加载完成")
