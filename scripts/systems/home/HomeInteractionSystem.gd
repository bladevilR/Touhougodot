extends Node

## HomeInteractionSystem - 小屋交互系统
## 管理竹林小屋内的所有交互（睡觉、存储、喝茶、吃饭等）

# 交互类型枚举
enum InteractionType {
	SLEEP,       # 睡觉
	STORAGE,     # 存储箱
	TEA,         # 喝茶
	MEAL,        # 吃饭
	READ         # 读书
}

# 存储箱数据
var storage_items: Dictionary = {}  # item_id -> amount
const MAX_STORAGE_SLOTS = 200

func _ready():
	print("[HomeInteractionSystem] 小屋交互系统已初始化")

## 睡觉交互
func interact_sleep() -> void:
	# 检查是否已经在睡眠
	if GameStateManager.current_mode == GameStateManager.GameMode.SLEEPING:
		return

	print("[HomeInteractionSystem] 开始睡觉...")

	# 发送信号
	SignalBus.sleep_started.emit()

	# 切换到睡眠模式
	GameStateManager.change_mode(GameStateManager.GameMode.SLEEPING)

	# 等待淡出动画
	await get_tree().create_timer(0.5).timeout

	# 恢复疲劳
	if FatigueSystem:
		FatigueSystem.sleep_full_recovery()

	# 增加人性
	if HumanitySystem:
		HumanitySystem.modify_humanity("sleep_in_bed")

	# 推进时间到次日早上6点
	if TimeManager:
		TimeManager.set_time(6, 0)

	# 触发日期变化
	SignalBus.day_changed.emit(0)

	# 等待日期变化处理完成
	await get_tree().create_timer(0.5).timeout

	# 发送睡眠完成信号
	SignalBus.sleep_completed.emit()

	# 切换回家模式
	GameStateManager.change_mode(GameStateManager.GameMode.HOME)

	# 显示通知
	SignalBus.show_notification.emit("新的一天开始了！", Color.SKY_BLUE)

	print("[HomeInteractionSystem] 睡眠完成，新的一天开始")

## 喝茶交互
func interact_tea() -> void:
	print("[HomeInteractionSystem] 喝了一杯茶")

	# 增加人性
	if HumanitySystem:
		HumanitySystem.modify_humanity("drink_tea")

	# 略微恢复疲劳
	if FatigueSystem:
		FatigueSystem.rest_recovery(5.0)

	# 发送信号
	SignalBus.tea_interaction_completed.emit()

	# 显示通知
	SignalBus.show_notification.emit("喝了一杯茶，感觉放松了一些", Color.LIGHT_GREEN)

## 吃饭交互
func interact_meal() -> void:
	# 检查是否有食物（TODO: 从背包检查）
	# 这里简化处理，假设总是有食物

	print("[HomeInteractionSystem] 吃了一顿饭")

	# 增加人性
	if HumanitySystem:
		HumanitySystem.modify_humanity("eat_meal")

	# 恢复疲劳
	if FatigueSystem:
		FatigueSystem.rest_recovery(10.0)

	# TODO: 消耗食物

	# 发送信号
	SignalBus.meal_interaction_completed.emit()

	# 显示通知
	SignalBus.show_notification.emit("吃了一顿饭，恢复了体力", Color.LIGHT_GREEN)

## 读书交互
func interact_read_book() -> void:
	print("[HomeInteractionSystem] 读了一会儿书")

	# 增加人性
	if HumanitySystem:
		HumanitySystem.modify_humanity("read_book")

	# 轻微增加疲劳
	if FatigueSystem:
		FatigueSystem.add_fatigue(2.0)

	# 发送信号
	SignalBus.read_book_completed.emit()

	# 显示通知
	SignalBus.show_notification.emit("读了一会儿书，感觉更像人类了", Color.LIGHT_YELLOW)

## 打开存储箱
func open_storage() -> void:
	SignalBus.home_storage_opened.emit()
	print("[HomeInteractionSystem] 打开存储箱")

## 关闭存储箱
func close_storage() -> void:
	SignalBus.home_storage_closed.emit()
	print("[HomeInteractionSystem] 关闭存储箱")

## 存入物品到存储箱
func store_item(item_id: String, amount: int) -> bool:
	# 检查存储空间
	var total_items = _get_total_stored_items()
	if total_items >= MAX_STORAGE_SLOTS:
		push_warning("[HomeInteractionSystem] 存储箱已满")
		return false

	if storage_items.has(item_id):
		storage_items[item_id] += amount
	else:
		storage_items[item_id] = amount

	print("[HomeInteractionSystem] 存入 %s x%d" % [item_id, amount])
	return true

## 从存储箱取出物品
func retrieve_item(item_id: String, amount: int) -> bool:
	if not storage_items.has(item_id):
		push_warning("[HomeInteractionSystem] 存储箱中没有 %s" % item_id)
		return false

	if storage_items[item_id] < amount:
		push_warning("[HomeInteractionSystem] %s 数量不足" % item_id)
		return false

	storage_items[item_id] -= amount

	if storage_items[item_id] <= 0:
		storage_items.erase(item_id)

	print("[HomeInteractionSystem] 取出 %s x%d" % [item_id, amount])
	return true

## 获取存储箱中物品数量
func get_stored_amount(item_id: String) -> int:
	return storage_items.get(item_id, 0)

## 获取存储箱总物品数
func _get_total_stored_items() -> int:
	var total = 0
	for item_id in storage_items:
		total += storage_items[item_id]
	return total

## 获取存储箱所有物品
func get_all_stored_items() -> Dictionary:
	return storage_items.duplicate()

## 保存数据
func get_save_data() -> Dictionary:
	return {
		"storage_items": storage_items.duplicate()
	}

## 读取数据
func load_save_data(data: Dictionary) -> void:
	storage_items = data.get("storage_items", {})
	print("[HomeInteractionSystem] 已读取存储数据，共 %d 种物品" % storage_items.size())
