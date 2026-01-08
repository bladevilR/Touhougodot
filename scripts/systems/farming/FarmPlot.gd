extends Node

class_name FarmPlot

# 单个农田地块的类
var id: int
var position: Vector2
var is_tilled: bool = false
var water_level: float = 0.0  # 0-1
var fertilizer_level: float = 0.0  # 0-1
var current_crop_id: int = -1
var growth_stage: int = 0  # 0-100%
var growth_time_remaining: int = 0
var is_watered_today: bool = false

const MAX_WATER = 100.0
const MAX_FERTILIZER = 100.0
const DAYS_PER_WATER = 3  # 几天需要浇一次水
const WATER_DECAY = 5.0  # 每天水分蒸发

func _ready() -> void:
	pass

func plant(crop_id: int, crop_data: Dictionary) -> void:
	current_crop_id = crop_id
	growth_stage = 0
	growth_time_remaining = crop_data["growth_time"]
	is_tilled = true
	is_watered_today = false

func harvest() -> int:
	if not is_ready_to_harvest():
		return 0

	# 计算产量：基础产量 * (水分状况 * 肥料状况)
	var yield_multiplier = (water_level / 100.0) * (0.5 + (fertilizer_level / 100.0) * 0.5)
	var yield_amount = int(4 * yield_multiplier)  # 基础产量为4

	# 收获后重置地块
	_reset_plot()
	return yield_amount

func water() -> void:
	water_level = min(water_level + 50.0, MAX_WATER)
	is_watered_today = true

func fertilize() -> void:
	fertilizer_level = min(fertilizer_level + 30.0, MAX_FERTILIZER)

func update_day(current_day: int) -> void:
	if not has_crop():
		return

	# 每天水分衰减
	water_level = max(water_level - WATER_DECAY, 0.0)

	# 肥料衰减（较慢）
	fertilizer_level = max(fertilizer_level - 1.5, 0.0)

	# 根据水和肥的充足程度计算生长速度
	var growth_speed = _calculate_growth_speed()

	if growth_speed > 0:
		growth_time_remaining -= growth_speed
		if growth_time_remaining <= 0:
			growth_time_remaining = 0
			growth_stage = 100
		else:
			growth_stage = int(100.0 * (1.0 - float(growth_time_remaining) / growth_time_remaining))

	is_watered_today = false

func _calculate_growth_speed() -> int:
	# 基础生长速度：每天1%
	var speed = 1

	# 缺水降低生长速度
	if water_level < 30.0:
		speed = 0  # 停止生长
	elif water_level < 60.0:
		speed = 0  # 生长缓慢

	# 肥料提高生长速度
	if fertilizer_level > 70.0:
		speed += 1

	return speed

func is_empty() -> bool:
	return current_crop_id == -1

func has_crop() -> bool:
	return current_crop_id != -1

func is_ready_to_harvest() -> bool:
	return growth_stage >= 100 and has_crop()

func get_health() -> float:
	# 计算地块的整体健康值 (0-1)
	var water_health = water_level / MAX_WATER
	var fertilizer_health = fertilizer_level / MAX_FERTILIZER
	return (water_health + fertilizer_health) / 2.0

func _reset_plot() -> void:
	current_crop_id = -1
	growth_stage = 0
	growth_time_remaining = 0
	water_level = 0.0
	fertilizer_level = 0.0
	is_tilled = false
	is_watered_today = false

func get_plot_data() -> Dictionary:
	return {
		"id": id,
		"position": position,
		"is_tilled": is_tilled,
		"water_level": water_level,
		"fertilizer_level": fertilizer_level,
		"current_crop_id": current_crop_id,
		"growth_stage": growth_stage,
		"is_watered_today": is_watered_today,
	}
