extends Node

## GlobalUIManager - 全局UI管理器
## 管理全局UI的输入处理和显示/隐藏

# UI 引用（需要在运行时加载）
var inventory_ui: Control = null
var quest_ui: Control = null

func _ready():
	print("[GlobalUIManager] 全局UI管理器初始化完成")
	# 延迟加载UI，确保其他系统先初始化
	call_deferred("_load_global_ui")

func _load_global_ui():
	# 这里暂时不加载，等GlobalUI.tscn创建后再启用
	# 或者直接通过代码创建InventoryUI和QuestUI实例
	pass

func _input(event):
	# 处理全局UI快捷键
	if event.is_action_pressed("open_inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_quest_log"):
		toggle_quest_log()
		get_viewport().set_input_as_handled()

## 切换背包显示
func toggle_inventory():
	if inventory_ui == null:
		push_warning("[GlobalUIManager] InventoryUI 未加载")
		return

	# 如果任务日志打开，先关闭它
	if quest_ui and quest_ui.visible:
		quest_ui.close()

	inventory_ui.toggle()

## 切换任务日志显示
func toggle_quest_log():
	if quest_ui == null:
		push_warning("[GlobalUIManager] QuestUI 未加载")
		return

	# 如果背包打开，先关闭它
	if inventory_ui and inventory_ui.visible:
		inventory_ui.close()

	quest_ui.toggle()

## 关闭所有全局UI
func close_all():
	if inventory_ui and inventory_ui.visible:
		inventory_ui.close()
	if quest_ui and quest_ui.visible:
		quest_ui.close()

## 设置UI引用（由场景在加载时调用）
func register_inventory_ui(ui: Control):
	inventory_ui = ui
	print("[GlobalUIManager] InventoryUI 已注册")

func register_quest_ui(ui: Control):
	quest_ui = ui
	print("[GlobalUIManager] QuestUI 已注册")
