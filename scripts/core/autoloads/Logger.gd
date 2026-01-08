extends Node
class_name Logger

## Logger - 统一日志系统
## 提供分级日志输出，支持启用/禁用和过滤

enum LogLevel { DEBUG = 0, INFO = 1, WARNING = 2, ERROR = 3 }

# 配置
var current_level: LogLevel = LogLevel.DEBUG
var enabled: bool = true
var show_timestamp: bool = false

# 标签过滤（空数组表示不过滤）
var allowed_tags: Array[String] = []

func _ready() -> void:
	pass

## 调试级别日志
func debug(tag: String, message: String) -> void:
	_log(LogLevel.DEBUG, tag, message)

## 信息级别日志
func info(tag: String, message: String) -> void:
	_log(LogLevel.INFO, tag, message)

## 警告级别日志
func warning(tag: String, message: String) -> void:
	_log(LogLevel.WARNING, tag, message)

## 错误级别日志
func error(tag: String, message: String) -> void:
	_log(LogLevel.ERROR, tag, message)

## 内部日志方法
func _log(level: LogLevel, tag: String, message: String) -> void:
	if not enabled:
		return

	if level < current_level:
		return

	# 标签过滤
	if allowed_tags.size() > 0 and not tag in allowed_tags:
		return

	var level_str = _level_to_string(level)
	var timestamp_str = ""

	if show_timestamp:
		timestamp_str = "[%s]" % Time.get_time_string_from_system()

	var output = "%s[%s][%s] %s" % [timestamp_str, level_str, tag, message]

	match level:
		LogLevel.DEBUG, LogLevel.INFO:
			print(output)
		LogLevel.WARNING:
			push_warning(output)
		LogLevel.ERROR:
			push_error(output)

func _level_to_string(level: LogLevel) -> String:
	match level:
		LogLevel.DEBUG: return "DEBUG"
		LogLevel.INFO: return "INFO"
		LogLevel.WARNING: return "WARN"
		LogLevel.ERROR: return "ERROR"
		_: return "?"

## 设置日志级别
func set_level(level: LogLevel) -> void:
	current_level = level

## 仅显示指定标签的日志
func filter_tags(tags: Array[String]) -> void:
	allowed_tags = tags

## 清除标签过滤
func clear_filter() -> void:
	allowed_tags.clear()
