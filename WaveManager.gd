extends Node
class_name WaveManager

# WaveManager - 波次管理系统
# 跟踪波次进度、显示波次公告、触发波次间的商店

signal wave_started(wave_number: int, wave_name: String)
signal wave_completed(wave_number: int)
signal boss_wave_started(boss_name: String)
@warning_ignore("unused_signal")
signal all_waves_completed()

# 波次状态
var current_wave: int = 0
var game_time: float = 0.0
var is_boss_active: bool = false
var enemies_killed_this_wave: int = 0

# 波次里程碑（用于商店触发）
var wave_milestones = [60.0, 180.0, 360.0, 600.0, 900.0, 1200.0, 1500.0, 1800.0]
var triggered_milestones = []

# 波次定义（用于UI显示）
const WAVE_DEFINITIONS = {
	0: {"name": "序章", "description": "史莱姆出现！"},
	1: {"name": "第一波", "description": "精灵加入战场"},
	2: {"name": "第二波", "description": "史莱姆变强了"},
	3: {"name": "第三波", "description": "精灵军团"},
	4: {"name": "BOSS战", "description": "琪露诺登场！", "is_boss": true},
	5: {"name": "第四波", "description": "精灵精英"},
	6: {"name": "第五波", "description": "幽灵出没"},
	7: {"name": "BOSS战", "description": "魂魄妖梦登场！", "is_boss": true},
	8: {"name": "第六波", "description": "幽灵狂潮"},
	9: {"name": "最终BOSS", "description": "蓬莱山辉夜降临！", "is_boss": true}
}

# UI相关
var wave_announcement_label: Label = null
var time_label: Label = null

func _ready():
	# 监听信号
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.boss_defeated.connect(_on_boss_defeated)
	SignalBus.game_started.connect(_on_game_started)

	# 创建波次公告UI
	_create_wave_ui()

func _on_game_started():
	current_wave = 0
	game_time = 0.0
	is_boss_active = false
	enemies_killed_this_wave = 0
	triggered_milestones.clear()

	# 显示开场波次
	_announce_wave(0)

func _process(delta):
	game_time += delta

	# 更新时间显示
	_update_time_display()

	# 检查波次里程碑
	_check_milestones()

	# 检查波次变化
	_check_wave_progression()

func _check_milestones():
	"""检查是否到达商店里程碑"""
	for milestone in wave_milestones:
		if game_time >= milestone and not milestone in triggered_milestones:
			triggered_milestones.append(milestone)

			# 每个里程碑触发商店可用
			# 但只在非Boss战时触发
			if not is_boss_active:
				_trigger_shop_availability()

func _trigger_shop_availability():
	"""触发商店可用"""
	# 发送商店可用信号
	SignalBus.shop_available.emit()
	print("商店可用！按N键打开河童商店")

	# 显示提示
	_show_shop_hint()

func _check_wave_progression():
	"""检查波次进展"""
	var new_wave = _get_wave_for_time(game_time)

	if new_wave != current_wave:
		# 波次结束
		wave_completed.emit(current_wave)

		# 新波次开始
		current_wave = new_wave
		enemies_killed_this_wave = 0

		_announce_wave(new_wave)

func _get_wave_for_time(time: float) -> int:
	"""根据时间获取当前波次"""
	if time < 30.0:
		return 0  # 序章
	elif time < 60.0:
		return 1  # 第一波
	elif time < 180.0:
		return 2  # 第二波
	elif time < 300.0:
		return 3  # 第三波
	elif time < 360.0:
		return 4  # Boss 1
	elif time < 600.0:
		return 5  # 第四波
	elif time < 900.0:
		return 6  # 第五波
	elif time < 960.0:
		return 7  # Boss 2
	elif time < 1800.0:
		return 8  # 第六波
	else:
		return 9  # 最终Boss

func _announce_wave(wave_number: int):
	"""显示波次公告 - 仅控制台输出"""
	var wave_info = WAVE_DEFINITIONS.get(wave_number, {"name": "波次 " + str(wave_number), "description": ""})

	var wave_name = wave_info.name
	var description = wave_info.description
	var is_boss = wave_info.get("is_boss", false)

	if is_boss:
		is_boss_active = true
		boss_wave_started.emit(description)
	else:
		is_boss_active = false

	wave_started.emit(wave_number, wave_name)

	# 禁用UI显示，只在控制台打印
	# if wave_announcement_label:
	# 	wave_announcement_label.text = wave_name + "\n" + description
	# 	wave_announcement_label.modulate = Color.WHITE
	# 	wave_announcement_label.visible = true

	# 	# 动画效果
	# 	var tween = create_tween()
	# 	tween.tween_property(wave_announcement_label, "modulate:a", 1.0, 0.3)
	# 	tween.tween_interval(2.0)
	# 	tween.tween_property(wave_announcement_label, "modulate:a", 0.0, 0.5)
	# 	tween.tween_callback(func(): wave_announcement_label.visible = false)

	# 精简的控制台输出
	if is_boss:
		print("⚔️ ", description)
	# 不再打印普通波次信息

func _on_enemy_killed(xp_amount: int, pos: Vector2):
	"""敌人被击杀"""
	enemies_killed_this_wave += 1

func _on_boss_defeated():
	"""Boss被击败"""
	is_boss_active = false

	# Boss击败后触发商店
	await get_tree().create_timer(1.0).timeout
	_trigger_shop_availability()

func _create_wave_ui():
	"""创建波次UI元素"""
	# 波次公告标签
	wave_announcement_label = Label.new()
	wave_announcement_label.name = "WaveAnnouncement"
	wave_announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_announcement_label.add_theme_font_size_override("font_size", 48)
	wave_announcement_label.add_theme_color_override("font_color", Color("#FFD700"))
	wave_announcement_label.visible = false

	# 时间标签
	time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.add_theme_color_override("font_color", Color.WHITE)

	# 延迟添加到UI层
	call_deferred("_add_ui_to_canvas")

func _add_ui_to_canvas():
	"""添加UI到画布层"""
	var game_ui = get_tree().get_first_node_in_group("game_ui")
	if not game_ui:
		# 查找CanvasLayer类型的节点
		for node in get_tree().get_nodes_in_group(""):
			if node is CanvasLayer and node.name == "GameUI":
				game_ui = node
				break

	if game_ui:
		# 波次公告（屏幕中央）
		var announcement_container = CenterContainer.new()
		announcement_container.set_anchors_preset(Control.PRESET_CENTER)
		announcement_container.add_child(wave_announcement_label)
		game_ui.add_child(announcement_container)

		# 时间标签（右上角）
		var viewport_size = Vector2(get_viewport().size)  # 转换 Vector2i 到 Vector2
		time_label.position = Vector2(viewport_size.x - 150, 20)
		game_ui.add_child(time_label)
	else:
		# 如果找不到GameUI，创建自己的CanvasLayer
		var canvas = CanvasLayer.new()
		canvas.layer = 100
		add_child(canvas)

		var announcement_container = CenterContainer.new()
		announcement_container.set_anchors_preset(Control.PRESET_CENTER)
		announcement_container.add_child(wave_announcement_label)
		canvas.add_child(announcement_container)

		time_label.position = Vector2(500, 20)
		canvas.add_child(time_label)

func _update_time_display():
	"""更新时间显示"""
	if time_label:
		var minutes = int(game_time / 60)
		var seconds = int(game_time) % 60
		time_label.text = "%02d:%02d" % [minutes, seconds]

func _show_shop_hint():
	"""显示商店提示"""
	if wave_announcement_label:
		wave_announcement_label.text = "河童商店开门啦！\n按 N 键购物"
		wave_announcement_label.modulate = Color("#4ecdc4")
		wave_announcement_label.visible = true

		var tween = create_tween()
		tween.tween_property(wave_announcement_label, "modulate:a", 1.0, 0.3)
		tween.tween_interval(3.0)
		tween.tween_property(wave_announcement_label, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func():
			if is_instance_valid(self) and is_instance_valid(wave_announcement_label):
				wave_announcement_label.visible = false
		)

# ==================== 公共接口 ====================

func get_current_wave() -> int:
	return current_wave

func get_game_time() -> float:
	return game_time

func get_formatted_time() -> String:
	var minutes = int(game_time / 60)
	var seconds = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]

func is_boss_wave() -> bool:
	return is_boss_active

func get_wave_info(wave_number: int) -> Dictionary:
	return WAVE_DEFINITIONS.get(wave_number, {})
