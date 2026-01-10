extends Node

## FatigueSystem - 疲劳系统
## 管理玩家的疲劳值，过度疲劳会强制昏倒并减少人性

# 疲劳值 (0-100)
var current_fatigue: float = 0.0

# 疲劳累积速率
const FATIGUE_PER_HOUR_ACTIVE = 2.5        # 白天活动：每小时+2.5
const FATIGUE_PER_MINUTE_COMBAT = 1.0      # 战斗：每分钟+1
const FATIGUE_PER_HOUR_FARMING = 3.5       # 农业：每小时+3.5
const FATIGUE_PER_HOUR_MINING = 4.0        # 采矿：每小时+4

# 疲劳阈值
const FATIGUE_TIRED = 60.0        # 疲惫（提示）
const FATIGUE_EXHAUSTED = 80.0    # 精疲力竭（减人性）
const FATIGUE_COLLAPSE = 100.0    # 强制昏倒

# 状态
var _last_warning_level: String = "none"
var _is_exhausted: bool = false
var _has_collapsed: bool = false

# 疲劳按小时累积
var _fatigue_accumulator: float = 0.0

func _ready():
	# 监听时间变化
	if SignalBus.has_signal("hour_changed"):
		SignalBus.hour_changed.connect(_on_hour_changed)

	# 监听游戏模式变化
	if GameStateManager.has_signal("game_mode_changed"):
		GameStateManager.game_mode_changed.connect(_on_game_mode_changed)

	print("[FatigueSystem] 疲劳系统已初始化")

## 每小时触发
func _on_hour_changed(_hour: int) -> void:
	# 根据当前模式累积疲劳
	var mode = GameStateManager.current_mode

	match mode:
		GameStateManager.GameMode.OVERWORLD, GameStateManager.GameMode.HOME:
			add_fatigue(FATIGUE_PER_HOUR_ACTIVE)
		GameStateManager.GameMode.COMBAT:
			# 战斗疲劳在 _process 中按分钟累积
			pass

	# 精疲力竭时额外减人性
	if _is_exhausted and HumanitySystem:
		HumanitySystem.add_humanity(-3.0)

## 游戏模式变化
func _on_game_mode_changed(_old_mode: int, new_mode: int) -> void:
	# 进入战斗时开始按分钟累积
	if new_mode == GameStateManager.GameMode.COMBAT:
		_fatigue_accumulator = 0.0

func _process(delta):
	# 战斗模式下按分钟累积疲劳
	if GameStateManager.current_mode == GameStateManager.GameMode.COMBAT:
		_fatigue_accumulator += delta

		# 每游戏分钟累积一次（TimeManager: 现实1秒=游戏1分钟）
		if _fatigue_accumulator >= 1.0:
			_fatigue_accumulator -= 1.0
			add_fatigue(FATIGUE_PER_MINUTE_COMBAT)

## 增加疲劳值
func add_fatigue(amount: float) -> void:
	var old_value = current_fatigue
	current_fatigue = clampf(current_fatigue + amount, 0.0, 100.0)

	if old_value != current_fatigue:
		SignalBus.fatigue_changed.emit(old_value, current_fatigue)
		_check_fatigue_warnings()

## 检查疲劳警告
func _check_fatigue_warnings() -> void:
	var current_level = _get_fatigue_level()

	if current_level != _last_warning_level:
		match current_level:
			"tired":
				SignalBus.fatigue_warning.emit("tired")
				print("[FatigueSystem] 提示：感到疲惫")
			"exhausted":
				SignalBus.fatigue_warning.emit("exhausted")
				_is_exhausted = true
				print("[FatigueSystem] ⚠️ 警告：精疲力竭！必须休息！")
			"collapse":
				if not _has_collapsed:
					_trigger_collapse()

		_last_warning_level = current_level

## 获取疲劳等级
func _get_fatigue_level() -> String:
	if current_fatigue >= FATIGUE_COLLAPSE:
		return "collapse"
	elif current_fatigue >= FATIGUE_EXHAUSTED:
		return "exhausted"
	elif current_fatigue >= FATIGUE_TIRED:
		return "tired"
	else:
		return "none"

## 触发昏倒
func _trigger_collapse() -> void:
	if _has_collapsed:
		return

	_has_collapsed = true
	SignalBus.fatigue_warning.emit("collapse")
	SignalBus.player_collapsed.emit()

	print("[FatigueSystem] ⚠️⚠️⚠️ 玩家因过度疲劳昏倒！")

	# 减少大量人性
	if HumanitySystem:
		HumanitySystem.modify_humanity("fatigue_collapse")

	# 等待1秒后强制传送回家并睡觉
	await get_tree().create_timer(1.0).timeout
	_force_go_home_and_sleep()

## 强制回家睡觉
func _force_go_home_and_sleep() -> void:
	# 切换到过场模式
	GameStateManager.change_mode(GameStateManager.GameMode.CUTSCENE)

	# 传送回竹林小屋
	SceneManager.change_scene("res://scenes/home/BambooHouse.tscn")

	await get_tree().create_timer(0.5).timeout

	# 强制睡眠恢复
	sleep_full_recovery()

	# 显示通知
	SignalBus.show_notification.emit("你因过度疲劳昏倒了...", Color.ORANGE_RED)

	# 恢复正常模式
	GameStateManager.change_mode(GameStateManager.GameMode.HOME)

## 睡觉完全恢复
func sleep_full_recovery() -> void:
	var old_value = current_fatigue
	current_fatigue = 0.0
	_last_warning_level = "none"
	_is_exhausted = false
	_has_collapsed = false

	SignalBus.fatigue_changed.emit(old_value, current_fatigue)
	print("[FatigueSystem] 睡眠恢复，疲劳清零")

## 部分恢复（休息）
func rest_recovery(amount: float) -> void:
	var old_value = current_fatigue
	current_fatigue = maxf(current_fatigue - amount, 0.0)

	SignalBus.fatigue_changed.emit(old_value, current_fatigue)

	if current_fatigue < FATIGUE_EXHAUSTED:
		_is_exhausted = false

	_check_fatigue_warnings()

## 获取疲劳状态描述
func get_fatigue_description() -> String:
	if current_fatigue >= FATIGUE_COLLAPSE:
		return "即将昏倒"
	elif current_fatigue >= FATIGUE_EXHAUSTED:
		return "精疲力竭"
	elif current_fatigue >= FATIGUE_TIRED:
		return "疲惫"
	else:
		return "正常"

## 保存数据
func get_save_data() -> Dictionary:
	return {
		"current_fatigue": current_fatigue,
		"last_warning_level": _last_warning_level,
		"is_exhausted": _is_exhausted,
		"has_collapsed": _has_collapsed
	}

## 读取数据
func load_save_data(data: Dictionary) -> void:
	current_fatigue = data.get("current_fatigue", 0.0)
	_last_warning_level = data.get("last_warning_level", "none")
	_is_exhausted = data.get("is_exhausted", false)
	_has_collapsed = data.get("has_collapsed", false)

	SignalBus.fatigue_changed.emit(current_fatigue, current_fatigue)  # 触发UI更新
	print("[FatigueSystem] 已读取疲劳数据: %.1f (%s)" % [current_fatigue, get_fatigue_description()])
