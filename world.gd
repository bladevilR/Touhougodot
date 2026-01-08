extends Node2D

# World - 主场景管理

var lighting_canvas_group: CanvasGroup = null
var canvas_group_ready: bool = false

func _ready():
	# 创建CanvasGroup用于Y-sorting
	_setup_canvas_group()

	# 初始化游戏系统
	initialize_game()

	# 实例化RoomLayoutManager（随机地图系统）
	var RoomLayoutManagerScript = load("res://scripts/gameplay/dungeons/RoomLayoutManager.gd")
	if RoomLayoutManagerScript:
		var room_layout_manager = RoomLayoutManagerScript.new()
		room_layout_manager.name = "RoomLayoutManager"
		add_child(room_layout_manager)
		print("[World] RoomLayoutManager 已实例化")

	# 实例化VictoryScreen
	var VictoryScreenScript = load("res://VictoryScreen.gd")
	if VictoryScreenScript:
		# VictoryScreen 继承自 Control，直接实例化脚本
		var victory_screen = VictoryScreenScript.new()
		victory_screen.name = "VictoryScreen"
		# 添加到UI层
		var ui_layer = get_node_or_null("GameUI")
		if ui_layer:
			ui_layer.add_child(victory_screen)
			print("[World] VictoryScreen 已实例化")
		else:
			add_child(victory_screen)
			print("[World] VictoryScreen 已实例化（添加到World）")

	# 发送游戏开始信号
	SignalBus.game_started.emit()

	# 延迟显示开场对话（确保UI系统已初始化）
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self):
		return
	_show_opening_dialogue()

func _show_opening_dialogue():
	"""显示开场对话"""
	print("[World] 开始显示开场对话...")

	# 检查是否有对话系统
	var game_ui = get_node_or_null("GameUI")
	if not game_ui:
		print("[World] 错误: 找不到GameUI节点")
		return

	print("[World] 找到GameUI节点")

	var dialogue_system = game_ui.get_node_or_null("DialoguePortrait")
	if not dialogue_system:
		print("[World] 创建DialoguePortrait...")
		# 创建对话系统
		var DialoguePortraitScript = load("res://scripts/ui/gameplay/DialoguePortrait.gd")
		if DialoguePortraitScript:
			dialogue_system = DialoguePortraitScript.new()
			dialogue_system.name = "DialoguePortrait"
			game_ui.add_child(dialogue_system)
			# 等待一帧确保_ready完成
			await get_tree().process_frame
			if not is_instance_valid(self):
				return
			print("[World] DialoguePortrait创建成功")
		else:
			print("[World] 错误: 无法加载DialoguePortrait.gd")
			return

	if dialogue_system and dialogue_system.has_method("show_dialogue"):
		print("[World] 调用show_dialogue...")
		# 显示妹红的开场白
		dialogue_system.show_dialogue(
			DialoguePortrait.CharacterPortrait.MOKOU,
			"希望这次来得及"
		)
		print("[World] 开场对话调用完成")
	else:
		print("[World] 错误: dialogue_system无效或没有show_dialogue方法")

func _setup_canvas_group():
	"""设置 CanvasGroup 用于 Y-sorting"""
	lighting_canvas_group = CanvasGroup.new()
	lighting_canvas_group.name = "LightingCanvasGroup"
	lighting_canvas_group.y_sort_enabled = true
	lighting_canvas_group.z_index = 0

	add_child(lighting_canvas_group)
	move_child(lighting_canvas_group, 0)

	# 延迟移动现有节点到CanvasGroup
	call_deferred("_move_existing_nodes_to_canvas_group")

func _move_existing_nodes_to_canvas_group():
	"""将场景中已有的节点移动到CanvasGroup"""
	var player = get_node_or_null("Player")
	if player:
		player.reparent(lighting_canvas_group, true)

	canvas_group_ready = true

func get_game_objects_parent() -> Node:
	"""获取游戏对象的父节点（用于MapSystem和EnemySpawner）"""
	if lighting_canvas_group and is_instance_valid(lighting_canvas_group):
		return lighting_canvas_group
	return self

func initialize_game():
	# 初始化所有游戏数据
	CharacterData.initialize()
	WeaponData.initialize()
	EnemyData.initialize()
	ElementData.initialize()
	BondData.initialize()
