extends Node

## ShopManager - 全局商店管理系统
## 管理所有商店的库存、交易、刷新

# ==================== 信号 ====================
signal shop_opened(shop_id: String)
signal shop_closed()
signal item_purchased(shop_id: String, item_id: String, amount: int, total_price: int)
signal item_sold(shop_id: String, item_id: String, amount: int, total_price: int)
signal purchase_failed(reason: String)
signal stock_refreshed(shop_id: String)

# ==================== 状态变量 ====================
var current_shop_id: String = ""
var is_shop_open: bool = false

# 运行时库存 (shop_id -> {item_id -> remaining_stock})
var runtime_stock: Dictionary = {}

# 自定义商店（运行时注册的）
var custom_shops: Dictionary = {}

# ==================== 初始化 ====================
func _ready() -> void:
	print("ShopManager: 初始化中...")
	_initialize_stock()

	# 监听日期变化刷新库存
	if SignalBus.has_signal("day_started"):
		SignalBus.day_started.connect(_on_day_started)

	print("ShopManager: 初始化完成")

func _initialize_stock() -> void:
	# 初始化所有商店的库存
	for shop_id in ShopData.get_all_shop_ids():
		_reset_shop_stock(shop_id)

func _reset_shop_stock(shop_id: String) -> void:
	var items = ShopData.get_shop_items(shop_id)
	runtime_stock[shop_id] = {}
	for item in items:
		runtime_stock[shop_id][item.id] = item.stock

# ==================== 商店操作 ====================

## 打开商店
func open_shop(shop_id: String) -> bool:
	# 检查商店是否存在
	if not ShopData.has_shop(shop_id) and not custom_shops.has(shop_id):
		push_error("[ShopManager] 商店不存在: %s" % shop_id)
		return false

	# 检查营业时间
	var current_hour = _get_current_hour()
	if not ShopData.is_shop_open(shop_id, current_hour):
		var shop = ShopData.get_shop(shop_id)
		var hours = shop.get("open_hours", {})
		push_warning("[ShopManager] 商店未营业: %s (营业时间 %d:00-%d:00)" % [
			shop_id, hours.get("start", 0), hours.get("end", 24)
		])
		purchase_failed.emit("商店未营业")
		return false

	current_shop_id = shop_id
	is_shop_open = true
	shop_opened.emit(shop_id)
	print("ShopManager: 打开商店 %s" % shop_id)
	return true

## 关闭商店
func close_shop() -> void:
	if is_shop_open:
		current_shop_id = ""
		is_shop_open = false
		shop_closed.emit()
		print("ShopManager: 关闭商店")

## 购买物品
func purchase_item(item_id: String, amount: int = 1) -> bool:
	if not is_shop_open:
		purchase_failed.emit("商店未打开")
		return false

	# 检查库存
	var stock = get_item_stock(current_shop_id, item_id)
	if stock < amount:
		purchase_failed.emit("库存不足")
		return false

	# 计算价格
	var unit_price = ShopData.get_item_price(current_shop_id, item_id)
	var total_price = unit_price * amount

	# 检查玩家金币
	if not _has_enough_coins(total_price):
		purchase_failed.emit("金币不足")
		return false

	# 扣除金币
	_deduct_coins(total_price)

	# 减少库存
	runtime_stock[current_shop_id][item_id] -= amount

	# 添加物品到背包
	_add_item_to_inventory(item_id, amount)

	item_purchased.emit(current_shop_id, item_id, amount, total_price)
	print("ShopManager: 购买 %s x%d，花费 %d 金币" % [item_id, amount, total_price])
	return true

## 出售物品
func sell_item(item_id: String, amount: int = 1) -> bool:
	if not is_shop_open:
		purchase_failed.emit("商店未打开")
		return false

	# 检查玩家是否有足够物品
	if not _has_item_in_inventory(item_id, amount):
		purchase_failed.emit("物品不足")
		return false

	# 计算收购价格
	var base_price = ShopData.get_item_price(current_shop_id, item_id)
	var buy_rate = ShopData.get_buy_rate(current_shop_id)
	var sell_price = int(base_price * buy_rate) * amount

	# 从背包移除物品
	_remove_item_from_inventory(item_id, amount)

	# 增加金币
	_add_coins(sell_price)

	# 增加商店库存
	if runtime_stock.has(current_shop_id):
		if runtime_stock[current_shop_id].has(item_id):
			runtime_stock[current_shop_id][item_id] += amount

	item_sold.emit(current_shop_id, item_id, amount, sell_price)
	print("ShopManager: 出售 %s x%d，获得 %d 金币" % [item_id, amount, sell_price])
	return true

# ==================== 查询方法 ====================

## 获取商店信息
func get_shop_info(shop_id: String) -> Dictionary:
	if custom_shops.has(shop_id):
		return custom_shops[shop_id]
	return ShopData.get_shop(shop_id)

## 获取物品库存
func get_item_stock(shop_id: String, item_id: String) -> int:
	if runtime_stock.has(shop_id) and runtime_stock[shop_id].has(item_id):
		return runtime_stock[shop_id][item_id]
	return 0

## 获取商店所有商品（带当前库存）
func get_shop_items_with_stock(shop_id: String) -> Array:
	var items = ShopData.get_shop_items(shop_id)
	var result = []
	for item in items:
		var item_copy = item.duplicate()
		item_copy["current_stock"] = get_item_stock(shop_id, item.id)
		result.append(item_copy)
	return result

## 检查商店是否营业
func is_shop_currently_open(shop_id: String) -> bool:
	return ShopData.is_shop_open(shop_id, _get_current_hour())

# ==================== 库存刷新 ====================

## 每日刷新库存
func _on_day_started(_day: int, _weekday: String, _season: String) -> void:
	refresh_all_stock()

## 刷新所有商店库存
func refresh_all_stock() -> void:
	for shop_id in ShopData.get_all_shop_ids():
		_reset_shop_stock(shop_id)
		stock_refreshed.emit(shop_id)
	print("ShopManager: 所有商店库存已刷新")

## 刷新指定商店库存
func refresh_shop_stock(shop_id: String) -> void:
	_reset_shop_stock(shop_id)
	stock_refreshed.emit(shop_id)

# ==================== 自定义商店 ====================

## 注册自定义商店
func register_custom_shop(shop_id: String, config: Dictionary) -> void:
	custom_shops[shop_id] = config
	runtime_stock[shop_id] = {}
	for item in config.get("items", []):
		runtime_stock[shop_id][item.id] = item.get("stock", 99)
	print("ShopManager: 注册自定义商店 %s" % shop_id)

## 移除自定义商店
func unregister_custom_shop(shop_id: String) -> void:
	custom_shops.erase(shop_id)
	runtime_stock.erase(shop_id)

# ==================== 内部方法 ====================

func _get_current_hour() -> int:
	if has_node("/root/TimeManager"):
		return get_node("/root/TimeManager").current_hour
	return 12  # 默认中午

func _has_enough_coins(amount: int) -> bool:
	return GameStateManager.player_data.coins >= amount

func _deduct_coins(amount: int) -> void:
	GameStateManager.player_data.coins -= amount
	SignalBus.coins_changed.emit(GameStateManager.player_data.coins)

func _add_coins(amount: int) -> void:
	GameStateManager.player_data.coins += amount
	SignalBus.coins_changed.emit(GameStateManager.player_data.coins)

func _add_item_to_inventory(item_id: String, amount: int) -> void:
	if has_node("/root/InventoryManager"):
		InventoryManager.add_item(item_id, amount)

func _remove_item_from_inventory(item_id: String, amount: int) -> void:
	if has_node("/root/InventoryManager"):
		InventoryManager.remove_item(item_id, amount)

func _has_item_in_inventory(item_id: String, amount: int) -> bool:
	if has_node("/root/InventoryManager"):
		return InventoryManager.get_item_count(item_id) >= amount
	return false

# ==================== 存档接口 ====================
func get_save_data() -> Dictionary:
	return {
		"runtime_stock": runtime_stock.duplicate(true),
		"custom_shops": custom_shops.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	runtime_stock = data.get("runtime_stock", {})
	custom_shops = data.get("custom_shops", {})
	print("ShopManager: 存档加载完成")
