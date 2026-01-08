extends Control

## QuestUI - 任务日志界面
## 显示玩家的活动任务、已完成任务等

# UI 节点引用（需要在场景中创建对应节点）
@onready var quest_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/ScrollContainer/QuestList
@onready var quest_detail_panel: Panel = $Panel/MarginContainer/VBoxContainer/QuestDetailPanel
@onready var quest_title_label: Label = $Panel/MarginContainer/VBoxContainer/QuestDetailPanel/VBoxContainer/QuestTitle
@onready var quest_desc_label: Label = $Panel/MarginContainer/VBoxContainer/QuestDetailPanel/VBoxContainer/QuestDesc
@onready var quest_progress_container: VBoxContainer = $Panel/MarginContainer/VBoxContainer/QuestDetailPanel/VBoxContainer/ProgressContainer
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/CloseButton

# 当前选中的任务
var selected_quest_id: String = ""

# 显示模式：active（活动任务）、completed（已完成）
var display_mode: String = "active"

func _ready():
	# 注册到全局UI管理器
	GlobalUIManager.register_quest_ui(self)

	# 连接信号
	QuestManager.quest_started.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_changed)
	QuestManager.quest_failed.connect(_on_quest_changed)
	QuestManager.quest_progress_updated.connect(_on_quest_progress_updated)
	close_button.pressed.connect(_on_close_pressed)

	# 初始化界面
	visible = false
	quest_detail_panel.visible = false

	# 监听打开/关闭信号
	SignalBus.quest_log_opened.connect(_on_quest_log_opened)

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		close()
		get_viewport().set_input_as_handled()

## 打开任务日志
func open():
	visible = true
	SignalBus.quest_log_opened.emit()
	_refresh_quest_list()

	# 暂停游戏（可选）
	# get_tree().paused = true

## 关闭任务日志
func close():
	visible = false
	selected_quest_id = ""
	quest_detail_panel.visible = false
	SignalBus.quest_log_closed.emit()

	# 恢复游戏
	# get_tree().paused = false

## 切换任务日志显示
func toggle():
	if visible:
		close()
	else:
		open()

## 切换显示模式（活动任务 / 已完成任务）
func set_display_mode(mode: String):
	display_mode = mode
	_refresh_quest_list()

## 刷新任务列表
func _refresh_quest_list():
	# 清空当前列表
	for child in quest_list.get_children():
		child.queue_free()

	# 获取任务列表
	var quests = []
	if display_mode == "active":
		quests = QuestManager.get_active_quests()
	else:
		quests = QuestManager.get_completed_quests()

	# 显示空状态提示
	if quests.is_empty():
		var empty_label = Label.new()
		empty_label.text = "暂无任务" if display_mode == "active" else "暂无已完成任务"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quest_list.add_child(empty_label)
		return

	# 创建任务按钮
	for quest_id in quests:
		_create_quest_button(quest_id)

## 创建任务按钮
func _create_quest_button(quest_id: String):
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 48)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

	# 获取任务数据
	var quest_data = QuestData.get_quest(quest_id)
	var quest_title = quest_data.get("title", "未知任务")
	var quest_type = quest_data.get("type", "side")

	# 任务类型标签
	var type_prefix = ""
	match quest_type:
		"main":
			type_prefix = "[主线] "
		"side":
			type_prefix = "[支线] "
		"daily":
			type_prefix = "[每日] "

	# 显示任务标题
	button.text = type_prefix + quest_title

	# 连接点击信号
	button.pressed.connect(_on_quest_button_pressed.bind(quest_id))

	quest_list.add_child(button)

## 任务按钮被点击
func _on_quest_button_pressed(quest_id: String):
	selected_quest_id = quest_id
	_show_quest_detail(quest_id)

## 显示任务详情
func _show_quest_detail(quest_id: String):
	var quest_data = QuestData.get_quest(quest_id)

	if quest_data.is_empty():
		return

	quest_detail_panel.visible = true
	quest_title_label.text = quest_data.get("title", "未知任务")
	quest_desc_label.text = quest_data.get("description", "")

	# 清空进度容器
	for child in quest_progress_container.get_children():
		child.queue_free()

	# 显示任务目标进度
	var objectives = quest_data.get("objectives", [])
	var progress = QuestManager.get_quest_progress(quest_id)

	for i in range(objectives.size()):
		var objective = objectives[i]
		var current_progress = progress.get(i, 0)
		var required_progress = objective.get("required", 1)

		# 创建进度标签
		var progress_label = Label.new()
		var objective_desc = objective.get("description", "目标 %d" % (i + 1))
		var is_completed = current_progress >= required_progress

		if is_completed:
			progress_label.text = "✓ %s (%d/%d)" % [objective_desc, required_progress, required_progress]
			progress_label.add_theme_color_override("font_color", Color.GREEN)
		else:
			progress_label.text = "  %s (%d/%d)" % [objective_desc, current_progress, required_progress]

		quest_progress_container.add_child(progress_label)

	# 显示奖励信息
	var rewards = quest_data.get("rewards", {})
	if not rewards.is_empty():
		var reward_title = Label.new()
		reward_title.text = "\n任务奖励："
		reward_title.add_theme_color_override("font_color", Color.GOLD)
		quest_progress_container.add_child(reward_title)

		if rewards.has("exp"):
			var exp_label = Label.new()
			exp_label.text = "  经验：%d" % rewards.exp
			quest_progress_container.add_child(exp_label)

		if rewards.has("items"):
			for item_id in rewards.items:
				var amount = rewards.items[item_id]
				var item_data = ItemData.get_item(item_id)
				var item_name = item_data.get("name", item_id)
				var item_label = Label.new()
				item_label.text = "  物品：%s x%d" % [item_name, amount]
				quest_progress_container.add_child(item_label)

## 关闭按钮被点击
func _on_close_pressed():
	close()

## 任务变化回调
func _on_quest_changed(_quest_id: String):
	if visible:
		_refresh_quest_list()
		# 如果当前选中的任务发生变化，刷新详情
		if selected_quest_id != "":
			_show_quest_detail(selected_quest_id)

## 任务进度更新回调
func _on_quest_progress_updated(quest_id: String, _objective_index: int, _new_progress: int):
	if visible and selected_quest_id == quest_id:
		_show_quest_detail(quest_id)

## 任务日志打开回调
func _on_quest_log_opened():
	if not visible:
		open()
