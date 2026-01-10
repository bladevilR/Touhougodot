extends Area2D
class_name NPCBase

## NPCBase - NPC基类
## 所有NPC的通用功能：对话、交互、羁绊

signal dialogue_started(npc_id: String)
signal dialogue_ended()
signal bond_increased(npc_id: String, points: int)

@export var npc_id: String = "unknown"  # NPC ID（keine, reimu, marisa等）
@export var npc_name: String = "未知NPC"  # 显示名称
@export var interaction_radius: float = 80.0  # 交互范围

var player_in_range: bool = false
var player: Node2D = null
var prompt_label: Label = null

# 对话数据（由子类或外部配置）
var dialogue_lines: Array[Dictionary] = []

# 当前对话索引
var current_dialogue_index: int = 0

func _ready():
	add_to_group("npc")

	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 创建交互提示
	_create_prompt_label()

	# 检查NPC是否应该显示（根据日程）
	_check_schedule_visibility()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		player_in_range = true

		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		player_in_range = false

		if prompt_label:
			prompt_label.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):  # E键
		_interact()

## 交互
func _interact() -> void:
	# 检查NPC是否可打断
	if NPCScheduleManager and not NPCScheduleManager.is_npc_interruptible(npc_id):
		SignalBus.show_notification.emit("%s 现在很忙，无法交谈" % npc_name, Color.ORANGE)
		return

	# 开始对话
	_start_dialogue()

## 开始对话
func _start_dialogue() -> void:
	if dialogue_lines.is_empty():
		SignalBus.show_notification.emit("（%s 没有可说的话）" % npc_name, Color.GRAY)
		return

	current_dialogue_index = 0
	dialogue_started.emit(npc_id)
	SignalBus.npc_interaction_started.emit(npc_id)

	# 切换到对话模式
	GameStateManager.change_mode(GameStateManager.GameMode.DIALOGUE)

	print("[NPCBase] 与 %s 开始对话" % npc_name)

	# TODO: 显示对话UI
	_show_next_dialogue_line()

## 显示下一句对话
func _show_next_dialogue_line() -> void:
	if current_dialogue_index >= dialogue_lines.size():
		_end_dialogue()
		return

	var line = dialogue_lines[current_dialogue_index]
	var speaker = line.get("speaker", npc_name)
	var text = line.get("text", "...")

	SignalBus.dialogue_line_displayed.emit(speaker, text)
	print("[对话] %s: %s" % [speaker, text])

	current_dialogue_index += 1

	# TODO: 等待玩家按键继续
	# 这里简化处理，直接显示下一句
	await get_tree().create_timer(2.0).timeout
	_show_next_dialogue_line()

## 结束对话
func _end_dialogue() -> void:
	dialogue_ended.emit()
	SignalBus.npc_interaction_ended.emit()

	# 增加羁绊
	if BondSystem:
		BondSystem.add_bond_points(npc_id, "talk")
		bond_increased.emit(npc_id, 10)

	# 恢复模式
	GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

	print("[NPCBase] 与 %s 的对话结束" % npc_name)

## 检查日程可见性
func _check_schedule_visibility() -> void:
	if not NPCScheduleManager:
		return

	# 监听日程变化
	if SignalBus.has_signal("npc_schedule_changed"):
		SignalBus.npc_schedule_changed.connect(_on_schedule_changed)

	# 初始检查
	_update_visibility()

## 日程变化时
func _on_schedule_changed(changed_npc_id: String, _schedule_entry: Dictionary) -> void:
	if changed_npc_id == npc_id:
		_update_visibility()

## 更新可见性
func _update_visibility() -> void:
	if not NPCScheduleManager:
		return

	var location = NPCScheduleManager.get_npc_location(npc_id)
	var current_scene_name = get_tree().current_scene.name

	# 简化匹配逻辑
	var should_visible = false

	match current_scene_name:
		"TempleSchool":
			should_visible = (location == "temple_school")
		"HakureiShrine":
			should_visible = (location == "hakurei_shrine")
		"VillageCenter":
			should_visible = (location == "village_center")

	visible = should_visible

	if visible:
		print("[NPCBase] %s 出现在 %s" % [npc_name, current_scene_name])

## 设置对话内容
func set_dialogue(lines: Array[Dictionary]) -> void:
	dialogue_lines = lines

## 创建提示标签
func _create_prompt_label() -> void:
	prompt_label = Label.new()
	prompt_label.text = "[E] 对话"
	prompt_label.position = Vector2(-30, -100)
	prompt_label.visible = false
	add_child(prompt_label)
