extends CanvasLayer

# GameUI - 解耦后的 UI 系统
# 彻底不依赖 Player。哪怕场景里没有 Player，UI 也不会报错

@onready var hp_bar = $HealthBar # 血条节点
@onready var xp_bar = $ExpBar    # 经验条节点
@onready var level_label = $LevelLabel

func _ready():
	# UI 只监听总线，完全不知道 Player 的存在
	SignalBus.player_health_changed.connect(update_hp)
	SignalBus.xp_gained.connect(update_xp)
	SignalBus.level_up.connect(on_level_up)
	SignalBus.game_over.connect(on_game_over)

func update_hp(current, max_val):
	if hp_bar:
		hp_bar.value = (current / max_val) * 100

func update_xp(current, max_val, level):
	if xp_bar:
		xp_bar.value = (float(current) / float(max_val)) * 100
	if level_label:
		level_label.text = "Lv." + str(level)

func on_level_up(new_level):
	# 这里可以弹出一个升级选择窗口
	print("UI: 升级到 Lv.", new_level, "！")
	# TODO: 显示升级选择窗口

func on_game_over():
	print("UI: Game Over received")

	# 先暂停游戏处理
	get_tree().paused = false  # 确保不暂停，以便重启

	# Create Game Over UI overlay dynamically
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var label = Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 64)
	label.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(label)

	# 添加重启提示
	var restart_label = Label.new()
	restart_label.text = "正在重启游戏..."
	restart_label.add_theme_font_size_override("font_size", 32)
	restart_label.set_anchors_preset(Control.PRESET_CENTER)
	restart_label.position.y = 100
	overlay.add_child(restart_label)

	# 优化的重启逻辑：延迟更短，避免卡顿
	await get_tree().create_timer(1.5).timeout

	# 先清理敌人和子弹
	_cleanup_game_objects()

	# 使用更快的重启方式
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()

func _cleanup_game_objects():
	"""清理游戏对象以避免重启卡顿"""
	# 清理所有敌人
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()

	# 清理所有子弹
	var bullets = get_tree().get_nodes_in_group("bullet")
	for bullet in bullets:
		if is_instance_valid(bullet):
			bullet.queue_free()

	# 清理所有拾取物
	var pickups = get_tree().get_nodes_in_group("pickup")
	for pickup in pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()

