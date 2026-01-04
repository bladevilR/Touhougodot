extends Control

## InventoryUI - 背包界面
## 显示玩家的物品、装备等

# UI 节点引用
@onready var item_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ItemGrid
@onready var item_info_panel: Panel = $Panel/MarginContainer/VBoxContainer/ItemInfoPanel
@onready var item_name_label: Label = $Panel/MarginContainer/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemName
@onready var item_desc_label: Label = $Panel/MarginContainer/VBoxContainer/ItemInfoPanel/VBoxContainer/ItemDesc
@onready var use_button: Button = $Panel/MarginContainer/VBoxContainer/ItemInfoPanel/VBoxContainer/UseButton
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CloseButton

# 物品按钮场景
const ITEM_BUTTON_SCENE = preload("res://scenes/ui/global/ItemButton.tscn")

# 当前选中的物品
var selected_item_id: String = ""

func _ready():
	# 注册到全局UI管理器
	GlobalUIManager.register_inventory_ui(self)

	# 连接信号
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	close_button.pressed.connect(_on_close_pressed)
	use_button.pressed.connect(_on_use_pressed)

	# 初始化界面
	visible = false
	item_info_panel.visible = false

	# 监听打开/关闭信号
	SignalBus.inventory_opened.connect(_on_inventory_opened)

	print("[InventoryUI] 背包界面初始化完成")

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close()
		get_viewport().set_input_as_handled()

## 打开背包
func open():
	visible = true
	SignalBus.inventory_opened.emit()
	_refresh_inventory()

	# 暂停游戏（可选）
	# get_tree().paused = true

## 关闭背包
func close():
	visible = false
	selected_item_id = ""
	item_info_panel.visible = false
	SignalBus.inventory_closed.emit()

	# 恢复游戏
	# get_tree().paused = false

## 切换背包显示
func toggle():
	if visible:
		close()
	else:
		open()

## 刷新背包显示
func _refresh_inventory():
	# 清空当前格子
	for child in item_grid.get_children():
		child.queue_free()

	# 获取所有物品
	var items = InventoryManager.get_all_items()

	for item_id in items:
		var amount = items[item_id]
		_create_item_button(item_id, amount)

	# 填充空格子（最多显示48个格子）
	var current_count = items.size()
	var max_slots = InventoryManager.MAX_SLOTS

	for i in range(max_slots - current_count):
		_create_empty_slot()

## ���建物品按钮
func _create_item_button(item_id: String, amount: int):
	# 简化版：使用 Button 代替场景实例化
	var button = Button.new()
	button.custom_minimum_size = Vector2(64, 64)

	# 获取物品数据
	var item_data = ItemData.get_item(item_id)
	var item_name = item_data.get("name", "未知")

	# 显示物品名称和数量
	button.text = "%s\nx%d" % [item_name, amount]
	button.tooltip_text = item_data.get("description", "")

	# 连接点击信号
	button.pressed.connect(_on_item_button_pressed.bind(item_id))

	item_grid.add_child(button)

## 创建空格子
func _create_empty_slot():
	var button = Button.new()
	button.custom_minimum_size = Vector2(64, 64)
	button.text = ""
	button.disabled = true
	button.modulate = Color(0.5, 0.5, 0.5, 0.5)

	item_grid.add_child(button)

## 物品按钮被点击
func _on_item_button_pressed(item_id: String):
	selected_item_id = item_id
	_show_item_info(item_id)

## 显示物品信息
func _show_item_info(item_id: String):
	var item_data = ItemData.get_item(item_id)

	if item_data.is_empty():
		return

	item_info_panel.visible = true
	item_name_label.text = item_data.get("name", "未知物品")
	item_desc_label.text = item_data.get("description", "")

	# 根据物品类型显示/隐藏使用按钮
	var item_type = item_data.get("type", "")
	use_button.visible = item_type in ["consumable", "equipment"]

	if use_button.visible:
		if item_type == "consumable":
			use_button.text = "使用"
		elif item_type == "equipment":
			use_button.text = "装备"

## 使用按钮被点击
func _on_use_pressed():
	if selected_item_id == "":
		return

	InventoryManager.use_item(selected_item_id)

	# 刷新界面
	_refresh_inventory()
	item_info_panel.visible = false
	selected_item_id = ""

## 关闭按钮被点击
func _on_close_pressed():
	close()

## 背包变化回调
func _on_inventory_changed():
	if visible:
		_refresh_inventory()

## 背包打开回调
func _on_inventory_opened():
	if not visible:
		open()
