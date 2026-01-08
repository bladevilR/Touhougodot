extends Node

## InventoryManager - 背包管理系统
## 管理玩家的物品、装备、消耗品等

signal inventory_changed()
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal item_used(item_id: String)
signal inventory_full()

# 背包配置
const MAX_SLOTS = 48  # 最大格子数
const MAX_STACK = 99  # 单格最大堆叠数

# 背包数据结构
# items = {"item_id": amount}
var items: Dictionary = {}

# 装备栏
var equipped_weapon: String = ""
var equipped_armor: String = ""
var equipped_accessory: String = ""

func _ready():
	pass

## 添加物品
func add_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		push_warning("[InventoryManager] 添加物品数量无效: %d" % amount)
		return false

	# 检查物品是否存在
	if not ItemData.has_item(item_id):
		push_error("[InventoryManager] 物品不存在: %s" % item_id)
		return false

	# 获取物品数据
	var item_data = ItemData.get_item(item_id)
	var max_stack = item_data.get("max_stack", MAX_STACK)

	# 如果物品已存在，增加数量
	if items.has(item_id):
		var current_amount = items[item_id]
		var new_amount = current_amount + amount

		# 检查是否超过堆叠上限
		if new_amount > max_stack:
			push_warning("[InventoryManager] 物品堆叠超过上限: %s" % item_id)
			items[item_id] = max_stack
			inventory_full.emit()
		else:
			items[item_id] = new_amount
	else:
		# 检查是否有空格子
		if get_used_slots() >= MAX_SLOTS:
			push_warning("[InventoryManager] 背包已满")
			inventory_full.emit()
			return false

		items[item_id] = min(amount, max_stack)

	item_added.emit(item_id, amount)
	inventory_changed.emit()
	return true

## 移除物品
func remove_item(item_id: String, amount: int = 1) -> bool:
	if amount <= 0:
		push_warning("[InventoryManager] 移除物品数量无效: %d" % amount)
		return false

	if not items.has(item_id):
		push_warning("[InventoryManager] 物品不存在于背包: %s" % item_id)
		return false

	var current_amount = items[item_id]
	if current_amount < amount:
		push_warning("[InventoryManager] 物品数量不足: %s (需要%d，当前%d)" % [item_id, amount, current_amount])
		return false

	items[item_id] -= amount

	# 如果数量归零，删除该物品
	if items[item_id] <= 0:
		items.erase(item_id)

	item_removed.emit(item_id, amount)
	inventory_changed.emit()
	return true

## 使用物品
func use_item(item_id: String) -> bool:
	if not items.has(item_id):
		push_warning("[InventoryManager] 物品不存在于背包: %s" % item_id)
		return false

	var item_data = ItemData.get_item(item_id)
	if item_data == null:
		push_error("[InventoryManager] 物品数据无效: %s" % item_id)
		return false

	# 根据物品类型执行效果
	var item_type = item_data.get("type", "consumable")
	match item_type:
		"consumable":
			_use_consumable(item_id, item_data)
		"equipment":
			_equip_item(item_id, item_data)
		_:
			push_warning("[InventoryManager] 不可使用的物品类型: %s" % item_type)
			return false

	item_used.emit(item_id)
	inventory_changed.emit()
	return true

## 使用消耗品
func _use_consumable(item_id: String, item_data: Dictionary) -> void:
	# 应用效果
	var effects = item_data.get("effects", {})
	for effect_type in effects:
		var value = effects[effect_type]
		match effect_type:
			"heal_hp":
				_heal_player(value)
			"restore_mp":
				pass  # TODO: MP系统
			"buff":
				pass  # TODO: Buff系统

	# 消耗物品
	remove_item(item_id, 1)
	pass

## 装备物品
func _equip_item(item_id: String, item_data: Dictionary) -> void:
	var equipment_slot = item_data.get("slot", "weapon")

	# 卸下当前装备
	match equipment_slot:
		"weapon":
			if equipped_weapon != "":
				add_item(equipped_weapon, 1)
			equipped_weapon = item_id
		"armor":
			if equipped_armor != "":
				add_item(equipped_armor, 1)
			equipped_armor = item_id
		"accessory":
			if equipped_accessory != "":
				add_item(equipped_accessory, 1)
			equipped_accessory = item_id

	# 从背包移除
	remove_item(item_id, 1)
	pass

## 治疗玩家
func _heal_player(amount: int) -> void:
	var player_data = GameStateManager.player_data
	player_data.current_hp = min(player_data.current_hp + amount, player_data.max_hp)
	SignalBus.player_health_changed.emit(player_data.current_hp, player_data.max_hp)
	pass

## 检查是否拥有物品
func has_item(item_id: String, amount: int = 1) -> bool:
	if not items.has(item_id):
		return false
	return items[item_id] >= amount

## 获取物品数量
func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)

## 获取已使用的格子数
func get_used_slots() -> int:
	return items.size()

## 获取所有物品
func get_all_items() -> Dictionary:
	return items.duplicate()

## 清空背包
func clear_inventory() -> void:
	items.clear()
	equipped_weapon = ""
	equipped_armor = ""
	equipped_accessory = ""
	inventory_changed.emit()
	pass

## 存档相关
func get_save_data() -> Dictionary:
	return {
		"items": items.duplicate(),
		"equipped_weapon": equipped_weapon,
		"equipped_armor": equipped_armor,
		"equipped_accessory": equipped_accessory
	}

func load_save_data(data: Dictionary) -> void:
	items = data.get("items", {})
	equipped_weapon = data.get("equipped_weapon", "")
	equipped_armor = data.get("equipped_armor", "")
	equipped_accessory = data.get("equipped_accessory", "")
	inventory_changed.emit()
