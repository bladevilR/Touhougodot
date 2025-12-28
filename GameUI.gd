extends CanvasLayer

# GameUI - 解耦后的 UI 系统
# 彻底不依赖 Player。哪怕场景里没有 Player，UI 也不会报错

@onready var hp_bar = $HPPanel/HealthBar # 血条节点
@onready var xp_bar = $ExpPanel/ExpBar    # 经验条节点
@onready var level_label = $LevelLabel
@onready var coins_label = $CoinsLabel
@onready var hp_value_label = $HPPanel/HPValue  # HP数值显示
@onready var exp_value_label = $ExpPanel/ExpValue  # 经验值显示
@onready var character_portrait = $CharacterPortrait  # 角色头像

# 転流货币UI
var tenryu_label: Label = null

# 元素附魔UI节点（动态创建）
var enchant_panel: Control = null
var enchant_icon: ColorRect = null
var enchant_timer_bar: ProgressBar = null
var enchant_label: Label = null

# 技能冷却UI节点
var skill_cooldown_panel: Control = null
var skill_cooldown_bar: ProgressBar = null
var skill_name_label: Label = null

# Boss血条UI
var boss_panel: Control = null
var boss_name_label: Label = null
var boss_hp_bar: ProgressBar = null

# 房间/波次信息UI
var room_panel: Control = null
var room_label: Label = null
var wave_label: Label = null
var wave_progress_bar: ProgressBar = null
var zone_name_label: Label = null # 区域名称

# 任务目标UI
var mission_panel: Control = null
var mission_label: Label = null
var timer_label: Label = null
var mission_complete: bool = false
var mission_failed: bool = false

# 房间地图UI
var room_map_panel: Control = null
var room_map_canvas: Control = null  # 用于绘制房间地图的画布

# 伤害数字容器
var damage_numbers_container: Control = null

# DPS统计
var dps_panel: Control = null
var dps_label: Label = null
var weapon_dps_labels: Dictionary = {}  # {weapon_id: Label}
var damage_history: Dictionary = {}  # {weapon_id: [{damage: float, time: float}]}
const DPS_WINDOW: float = 5.0  # 统计最近5秒的伤害（魔兽风格）
const MAX_WEAPON_DISPLAY: int = 6  # 最多显示6个武器
const DPS_UPDATE_INTERVAL: float = 0.5  # 每0.5秒更新一次DPS显示（平滑更新）
var dps_update_timer: float = 0.0
var is_restarting: bool = false # 防止重复触发重启

# 元素颜色
const ELEMENT_COLORS = {
	0: Color("#ff4500"),  # FIRE
	1: Color("#00bfff"),  # ICE
	2: Color("#9370db"),  # POISON
	3: Color("#8b4513"),  # OIL
	4: Color("#ffd700"),  # LIGHTNING
	5: Color("#9932cc"),  # GRAVITY
}

const ELEMENT_NAMES = {
	0: "火鸟废羽",
	1: "琪露诺的水",
	2: "铃兰花毒",
	3: "地灵殿黑水",
	4: "衣玖披肩",
	5: "伊吹瓢",
}

func _load_character_portrait():
	"""根据选择的角色加载头像"""
	if not character_portrait:
		return
		
	var char_id = SignalBus.selected_character_id
	var portrait_path = ""
	
	# 根据角色ID选择对应的头像文件
	match char_id:
		GameConstants.CharacterId.REIMU:
			portrait_path = "res://assets/leimuF.png" # 灵梦使用立绘作为头像（或寻找专门的1C）
		GameConstants.CharacterId.MOKOU:
			portrait_path = "res://assets/characters/1C.png" # 妹红对应1C
		GameConstants.CharacterId.MARISA:
			portrait_path = "res://assets/characters/2C.png" # 魔理沙对应2C
		GameConstants.CharacterId.SAKUYA:
			portrait_path = "res://assets/characters/3C.png" # 咲夜对应3C
		_:
			# 默认尝试使用 ID+1 的规律
			portrait_path = "res://assets/characters/" + str(char_id + 1) + "C.png"

	if ResourceLoader.exists(portrait_path):
		character_portrait.texture = load(portrait_path)
		print("[GameUI] 角色头像加载成功: ", portrait_path)
	else:
		# 最后的保底
		if ResourceLoader.exists("res://assets/characters/1C.png"):
			character_portrait.texture = load("res://assets/characters/1C.png")
			print("[GameUI] 警告: 找不到指定头像，使用保底 1C.png")
		else:
			print("[GameUI] 严重警告: 找不到任何角色头像文件")

func _ready():
	add_to_group("ui")

	# 加载角色头像
	_load_character_portrait()
	
	# 进一步放大并美化头像显示
	if character_portrait:
		character_portrait.size = Vector2(350, 350)
		character_portrait.position = Vector2(10, 710) # 进一步提亮位置
		character_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		character_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		character_portrait.modulate = Color(1.1, 1.1, 1.1, 1.0)

	# UI 只监听总线，完全不知道 Player 的存在
	SignalBus.player_health_changed.connect(update_hp)
	SignalBus.xp_gained.connect(update_xp)
	SignalBus.level_up.connect(on_level_up)
	SignalBus.game_over.connect(on_game_over)
	SignalBus.coins_changed.connect(update_coins)

	# 新增信号监听
	SignalBus.element_enchant_applied.connect(_on_enchant_applied)
	SignalBus.element_enchant_expired.connect(_on_enchant_expired)
	SignalBus.boss_spawned.connect(_on_boss_spawned)
	SignalBus.boss_health_changed.connect(_on_boss_health_changed)
	SignalBus.boss_defeated.connect(_on_boss_defeated)
	SignalBus.damage_dealt.connect(_on_damage_dealt)
	SignalBus.wave_info_updated.connect(_on_wave_info_updated)
	SignalBus.room_info_updated.connect(_on_room_info_updated)
	SignalBus.boss_dialogue.connect(_on_boss_dialogue)
	SignalBus.tenryu_changed.connect(_on_tenryu_changed)

	# 设置系统信号
	SignalBus.settings_changed.connect(_on_settings_changed)

	# 创建UI元素
	_create_tenryu_ui()
	_create_enchant_ui()
	_create_skill_cooldown_ui()
	_create_boss_ui()
	_create_damage_numbers_container()
	_create_dps_ui()
	_create_room_ui()
	_create_mission_ui() # 创建任务UI
	_create_room_map_ui()

	# 初始化暂停菜单
	_create_pause_menu()

	# 初始化角色状态面板 (TAB键)
	_create_status_panel()

	# 延迟应用设置，确保GameSettings已经加载
	call_deferred("_apply_settings")

func _create_status_panel():
	"""创建角色状态面板"""
	var StatusPanelScript = load("res://CharacterStatusPanel.gd")
	if StatusPanelScript:
		var status_panel = StatusPanelScript.new()
		status_panel.name = "CharacterStatusPanel"
		add_child(status_panel)
		print("[GameUI] 角色状态面板已创建")
	else:
		print("[GameUI] 错误: 无法加载 CharacterStatusPanel.gd")

func _process(delta):
	# 更新元素附魔计时器显示
	_update_enchant_timer()
	# 更新技能冷却显示
	_update_skill_cooldown()
	# 更新DPS显示
	_update_dps_display(delta)
	# 更新任务计时器
	_update_mission_timer()

func _create_mission_ui():
	"""创建任务目标UI"""
	mission_panel = Control.new()
	mission_panel.name = "MissionPanel"
	mission_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	mission_panel.position = Vector2(20, 350) # 屏幕左侧，技能冷却下方
	mission_panel.size = Vector2(200, 80)
	add_child(mission_panel)
	
	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.size = Vector2(200, 80)
	mission_panel.add_child(bg)
	
	# 任务标题
	mission_label = Label.new()
	mission_label.text = "目标：找到辉夜"
	mission_label.position = Vector2(10, 10)
	mission_label.add_theme_font_size_override("font_size", 16)
	mission_label.add_theme_color_override("font_color", Color("#eeeeee"))
	mission_panel.add_child(mission_label)
	
	# 倒计时
	timer_label = Label.new()
	timer_label.text = "05:00"
	timer_label.position = Vector2(10, 35)
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", Color("#ffffff"))
	mission_panel.add_child(timer_label)

func _update_mission_timer():
	"""更新任务倒计时"""
	if mission_complete or mission_failed: return
	
	var room_manager = get_tree().get_first_node_in_group("room_manager")
	if not room_manager: return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - room_manager.game_start_time
	var remaining = 300.0 - elapsed # 5分钟
	
	if remaining <= 0:
		mission_failed = true
		remaining = 0
		if mission_label: mission_label.text = "任务失败：辉夜已离开"
		if timer_label: 
			timer_label.text = "00:00"
			timer_label.add_theme_color_override("font_color", Color.RED)
		return
	
	# 检查是否进入Boss房
	# RoomType.BOSS = 2
	if room_manager.current_room_type == 2:
		mission_complete = true
		if mission_label: mission_label.text = "任务完成！"
		if timer_label: 
			timer_label.text = "找到辉夜"
			timer_label.add_theme_color_override("font_color", Color.GREEN)
		return
		
	# 更新倒计时显示
	var mins = int(remaining) / 60
	var secs = int(remaining) % 60
	if timer_label:
		timer_label.text = "%02d:%02d" % [mins, secs]
		# 剩余1分钟变红
		if remaining < 60:
			timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)

func update_hp(current, max_val):
	if hp_bar:
		hp_bar.value = (current / max_val) * 100
	if hp_value_label:
		hp_value_label.text = str(int(current)) + "/" + str(int(max_val))

func update_xp(current, max_val, level):
	if xp_bar:
		xp_bar.value = (float(current) / float(max_val)) * 100
	if exp_value_label:
		exp_value_label.text = str(current) + "/" + str(max_val)
	if level_label:
		level_label.text = "Lv." + str(level)

func update_coins(amount: int):
	if coins_label:
		coins_label.text = "金币: " + str(amount)

func on_level_up(new_level):
	# 这里可以弹出一个升级选择窗口
	print("UI: 升级到 Lv.", new_level, "！")
	# TODO: 显示升级选择窗口

func on_game_over():
	if is_restarting: return
	is_restarting = true
	
	print("UI: Game Over received")

	# 获取 SceneTree 引用，防止 await 期间节点被移除导致 get_tree() 失败
	var tree = get_tree()
	if not tree:
		return

	# 先暂停游戏处理
	tree.paused = false  # 确保不暂停，以便重启

	# Create Game Over UI overlay dynamically
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# 添加妹红立绘（失败时的表情）
	var mokou_portrait = TextureRect.new()
	mokou_portrait.name = "MokouPortrait"
	var portrait_path = "res://assets/characters/1.png"
	if ResourceLoader.exists(portrait_path):
		mokou_portrait.texture = load(portrait_path)
		mokou_portrait.position = Vector2(100, 150)
		mokou_portrait.size = Vector2(400, 500)
		mokou_portrait.expand_mode = TextureRect.EXPAND_FIT_HEIGHT
		mokou_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mokou_portrait.modulate = Color(0.8, 0.8, 0.9, 1.0)  # 略微暗淡
		overlay.add_child(mokou_portrait)

	# Game Over文字容器（右侧）
	var text_container = Control.new()
	text_container.position = Vector2(550, 200)
	text_container.size = Vector2(600, 400)
	overlay.add_child(text_container)

	var label = Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	label.position = Vector2(0, 0)
	text_container.add_child(label)

	# 添加台词
	var dialogue_label = Label.new()
	dialogue_label.text = "不死鸟也有倒下的时候呢..."
	dialogue_label.add_theme_font_size_override("font_size", 24)
	dialogue_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	dialogue_label.position = Vector2(0, 100)
	dialogue_label.size = Vector2(600, 100)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_container.add_child(dialogue_label)

	# 添加重启提示
	var restart_label = Label.new()
	restart_label.text = "正在重启游戏..."
	restart_label.add_theme_font_size_override("font_size", 28)
	restart_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	restart_label.position = Vector2(0, 200)
	text_container.add_child(restart_label)

	# 优化的重启逻辑：延迟更短，避免卡顿
	await tree.create_timer(2.0).timeout

	# 先清理敌人和子弹
	_cleanup_game_objects()

	# 使用更快的重启方式
	await tree.create_timer(0.1).timeout
	
	if is_instance_valid(tree) and tree.current_scene:
		tree.reload_current_scene()
	else:
		# 如果当前场景已经没了（可能正在切换中），尝试强行加载主菜单作为保底
		if is_instance_valid(tree):
			tree.change_scene_to_file("res://MainMenu.tscn")

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

# ==================== 元素附魔 UI ====================
func _create_enchant_ui():
	"""创建元素附魔UI面板"""
	enchant_panel = Control.new()
	enchant_panel.name = "EnchantPanel"
	enchant_panel.visible = false
	enchant_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	enchant_panel.position = Vector2(20, 120)
	enchant_panel.size = Vector2(200, 50)
	add_child(enchant_panel)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.size = Vector2(200, 50)
	enchant_panel.add_child(bg)

	# 元素图标
	enchant_icon = ColorRect.new()
	enchant_icon.size = Vector2(40, 40)
	enchant_icon.position = Vector2(5, 5)
	enchant_panel.add_child(enchant_icon)

	# 元素名称标签
	enchant_label = Label.new()
	enchant_label.position = Vector2(50, 5)
	enchant_label.add_theme_font_size_override("font_size", 14)
	enchant_panel.add_child(enchant_label)

	# 计时器条
	enchant_timer_bar = ProgressBar.new()
	enchant_timer_bar.position = Vector2(50, 28)
	enchant_timer_bar.size = Vector2(145, 16)
	enchant_timer_bar.show_percentage = false
	enchant_timer_bar.value = 100
	enchant_panel.add_child(enchant_timer_bar)

func _on_enchant_applied(element_type: int, duration: float):
	"""元素附魔应用时更新UI"""
	if not enchant_panel:
		return

	enchant_panel.visible = true

	# 更新图标颜色
	var color = ELEMENT_COLORS.get(element_type, Color.WHITE)
	if enchant_icon:
		enchant_icon.color = color

	# 更新名称
	var name = ELEMENT_NAMES.get(element_type, "未知元素")
	if enchant_label:
		enchant_label.text = name
		enchant_label.add_theme_color_override("font_color", color)

	# 更新计时器条颜色
	if enchant_timer_bar:
		var style = StyleBoxFlat.new()
		style.bg_color = color
		enchant_timer_bar.add_theme_stylebox_override("fill", style)

func _on_enchant_expired():
	"""元素附魔过期时隐藏UI"""
	if enchant_panel:
		enchant_panel.visible = false

func _update_enchant_timer():
	"""更新元素附魔计时器显示"""
	if not enchant_panel or not enchant_panel.visible:
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var weapon_system = player.get_node_or_null("WeaponSystem")
	if not weapon_system:
		return

	if weapon_system.has_method("get_enchant_time_remaining"):
		var remaining = weapon_system.get_enchant_time_remaining()
		var max_time = 30.0  # 默认附魔时长
		if enchant_timer_bar:
			enchant_timer_bar.value = (remaining / max_time) * 100

# ==================== 技能冷却 UI ====================
func _create_skill_cooldown_ui():
	"""创建技能冷却UI"""
	skill_cooldown_panel = Control.new()
	skill_cooldown_panel.name = "SkillCooldownPanel"
	skill_cooldown_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	skill_cooldown_panel.position = Vector2(20, -30)  # 左中间
	skill_cooldown_panel.size = Vector2(150, 60)
	add_child(skill_cooldown_panel)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.size = Vector2(150, 60)
	skill_cooldown_panel.add_child(bg)

	# 技能名称
	skill_name_label = Label.new()
	skill_name_label.text = "[SPACE]"
	skill_name_label.position = Vector2(10, 5)
	skill_name_label.add_theme_font_size_override("font_size", 14)
	skill_cooldown_panel.add_child(skill_name_label)

	# 冷却条
	skill_cooldown_bar = ProgressBar.new()
	skill_cooldown_bar.position = Vector2(10, 30)
	skill_cooldown_bar.size = Vector2(130, 20)
	skill_cooldown_bar.show_percentage = false
	skill_cooldown_bar.value = 100
	skill_cooldown_panel.add_child(skill_cooldown_bar)

func _update_skill_cooldown():
	"""更新技能冷却显示"""
	if not skill_cooldown_panel:
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var char_skills = player.get_node_or_null("CharacterSkills")
	if not char_skills:
		return

	# 更新冷却条
	if skill_cooldown_bar and char_skills.has_method("get_cooldown_percent"):
		var percent = char_skills.get_cooldown_percent()
		skill_cooldown_bar.value = (1.0 - percent) * 100

		# 根据冷却状态改变颜色
		var style = StyleBoxFlat.new()
		if percent <= 0:
			style.bg_color = Color("#00ff00")  # 可用时绿色
		else:
			style.bg_color = Color("#ff6600")  # 冷却中橙色
		skill_cooldown_bar.add_theme_stylebox_override("fill", style)

# ==================== Boss血条 UI ====================
func _create_boss_ui():
	"""创建Boss血条UI"""
	boss_panel = Control.new()
	boss_panel.name = "BossPanel"
	boss_panel.visible = false
	boss_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_panel.position = Vector2(0, 10)
	boss_panel.size = Vector2(0, 60)
	add_child(boss_panel)

	# Boss名称
	boss_name_label = Label.new()
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	boss_name_label.position.y = 5
	boss_name_label.add_theme_font_size_override("font_size", 24)
	boss_name_label.add_theme_color_override("font_color", Color("#ff0000"))
	boss_panel.add_child(boss_name_label)

	# Boss血条容器
	var bar_container = Control.new()
	bar_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar_container.position = Vector2(100, 35)
	bar_container.size = Vector2(-200, 20)
	boss_panel.add_child(bar_container)

	# Boss血条背景
	var bar_bg = ColorRect.new()
	bar_bg.color = Color(0.1, 0.1, 0.1, 0.85)
	bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 添加圆角效果
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	bg_style.corner_radius_top_left = 12
	bg_style.corner_radius_top_right = 12
	bg_style.corner_radius_bottom_left = 12
	bg_style.corner_radius_bottom_right = 12
	bar_bg.add_theme_stylebox_override("panel", bg_style)
	bar_container.add_child(bar_bg)

	# Boss血条
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_hp_bar.show_percentage = false
	boss_hp_bar.value = 100
	# 美化血条样式
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(1.0, 0.2, 0.2, 0.9)  # 更鲜艳的红色
	fill_style.corner_radius_top_left = 10
	fill_style.corner_radius_top_right = 10
	fill_style.corner_radius_bottom_left = 10
	fill_style.corner_radius_bottom_right = 10
	# 添加渐变效果
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.3, 0.3, 1.0))
	gradient.add_point(0.5, Color(1.0, 0.15, 0.15, 0.95))
	gradient.add_point(1.0, Color(0.9, 0.1, 0.1, 0.9))
	boss_hp_bar.add_theme_stylebox_override("fill", fill_style)
	bar_container.add_child(boss_hp_bar)

func _on_boss_spawned(boss_name: String, _boss_hp: float, _boss_max_hp: float):
	"""Boss出现时显示血条"""
	if boss_panel:
		boss_panel.visible = true
	if boss_name_label:
		boss_name_label.text = boss_name

func _on_boss_health_changed(boss_hp: float, boss_max_hp: float):
	"""更新Boss血条"""
	if boss_hp_bar and boss_max_hp > 0:
		boss_hp_bar.value = (boss_hp / boss_max_hp) * 100

func _on_boss_defeated():
	"""Boss被击败时隐藏血条"""
	if boss_panel:
		boss_panel.visible = false

# ==================== 伤害数字 UI ====================
func _create_damage_numbers_container():
	"""创建伤害数字容器"""
	damage_numbers_container = Control.new()
	damage_numbers_container.name = "DamageNumbers"
	damage_numbers_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_numbers_container)

func _on_damage_dealt(damage_amount: float, pos: Vector2, is_critical: bool, weapon_id: String):
	"""显示伤害数字并记录到DPS统计（分武器）- 只显示暴击"""
	# 记录伤害到对应武器的历史
	var current_time = Time.get_ticks_msec() / 1000.0

	# 如果武器ID为空，使用"unknown"
	var wid = weapon_id if weapon_id != "" else "unknown"

	# 初始化武器的伤害历史数组
	if not damage_history.has(wid):
		damage_history[wid] = []

	damage_history[wid].append({"damage": damage_amount, "time": current_time})

	# 只在暴击时显示伤害数字
	if not is_critical or not damage_numbers_container:
		return

	# 暴击显示：红色感叹号
	var label = Label.new()
	label.text = "!"
	label.position = pos + Vector2(randf_range(-20, 20), randf_range(-10, 10))
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color("#ff0000"))

	damage_numbers_container.add_child(label)

	# 动画：向上飘动并淡出
	# [修复] 绑定 Tween 到 label 上，确保 label 销毁时 tween 停止，避免 Lambda 捕获已释放对象错误
	var tween = label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)

	# 动画结束后删除
	# [修复] 使用 Lambda 包装，避免 label 被提前释放导致的 C++ 错误
	tween.chain().tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)

# ==================== DPS统计 UI ====================
func _create_dps_ui():
	"""创建DPS统计面板（总DPS + 分武器DPS）"""
	dps_panel = Control.new()
	dps_panel.name = "DPSPanel"
	dps_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	dps_panel.position = Vector2(-540, 10)  # 在房间地图左边
	dps_panel.size = Vector2(210, 200)
	add_child(dps_panel)

	# 背景（更大的面板）
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = Vector2(210, 200)
	dps_panel.add_child(bg)

	# 标题（总DPS）
	var title_label = Label.new()
	title_label.text = "总DPS"
	title_label.position = Vector2(10, 5)
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color("#ffcc00"))
	dps_panel.add_child(title_label)

	# 总DPS数值
	dps_label = Label.new()
	dps_label.text = "0"
	dps_label.position = Vector2(10, 25)
	dps_label.add_theme_font_size_override("font_size", 24)
	dps_label.add_theme_color_override("font_color", Color("#ff6600"))
	dps_panel.add_child(dps_label)

	# 分隔线
	var separator = ColorRect.new()
	separator.color = Color(1, 1, 1, 0.3)
	separator.position = Vector2(5, 55)
	separator.size = Vector2(200, 1)
	dps_panel.add_child(separator)

	# 武器DPS子标题
	var weapon_title = Label.new()
	weapon_title.text = "武器DPS"
	weapon_title.position = Vector2(10, 60)
	weapon_title.add_theme_font_size_override("font_size", 12)
	weapon_title.add_theme_color_override("font_color", Color("#aaaaaa"))
	dps_panel.add_child(weapon_title)

func _update_dps_display(delta: float):
	"""更新DPS显示（总DPS + 分武器DPS）- 魔兽风格平滑更新"""
	if not dps_label:
		return

	# 更新计时器
	dps_update_timer += delta

	var current_time = Time.get_ticks_msec() / 1000.0

	# 清理所有武器的过期伤害记录
	for weapon_id in damage_history.keys():
		var history = damage_history[weapon_id]
		var i = 0
		while i < history.size():
			if current_time - history[i].time > DPS_WINDOW:
				history.remove_at(i)
			else:
				i += 1

	# 只在达到更新间隔时才更新UI显示（魔兽风格平滑更新）
	if dps_update_timer < DPS_UPDATE_INTERVAL:
		return

	dps_update_timer = 0.0  # 重置计时器

	# 计算各武器DPS
	var weapon_dps_data = {}
	var total_dps = 0.0

	for weapon_id in damage_history.keys():
		var history = damage_history[weapon_id]

		# 计算该武器的总伤害
		var weapon_total_damage = 0.0
		for record in history:
			weapon_total_damage += record.damage

		# 计算该武器的DPS
		var weapon_dps = 0.0
		if history.size() > 0:
			var time_span = min(DPS_WINDOW, current_time - history[0].time)
			if time_span > 0:
				weapon_dps = weapon_total_damage / time_span

		weapon_dps_data[weapon_id] = {
			"dps": weapon_dps,
			"total_damage": weapon_total_damage
		}

		total_dps += weapon_dps

	# 更新总DPS显示
	dps_label.text = str(int(total_dps))

	# 根据总DPS改变颜色
	if total_dps > 500:
		dps_label.add_theme_color_override("font_color", Color("#ff0000"))
	elif total_dps > 200:
		dps_label.add_theme_color_override("font_color", Color("#ff6600"))
	else:
		dps_label.add_theme_color_override("font_color", Color("#ffcc00"))

	# 更新分武器DPS标签
	_update_weapon_dps_labels(weapon_dps_data)

func _update_weapon_dps_labels(weapon_dps_data: Dictionary):
	"""更新武器DPS标签显示 - 条形图形式"""
	# 将武器按DPS排序
	var sorted_weapons = []
	for weapon_id in weapon_dps_data.keys():
		sorted_weapons.append({
			"id": weapon_id,
			"dps": weapon_dps_data[weapon_id].dps
		})

	# 按DPS降序排序
	sorted_weapons.sort_custom(func(a, b): return a.dps > b.dps)

	# 限制显示数量
	var display_count = min(sorted_weapons.size(), MAX_WEAPON_DISPLAY)

	# 移除所有旧的武器标签
	for weapon_id in weapon_dps_labels.keys():
		if weapon_dps_labels[weapon_id] and is_instance_valid(weapon_dps_labels[weapon_id]):
			weapon_dps_labels[weapon_id].queue_free()
	weapon_dps_labels.clear()

	# 计算最大DPS用于归一化条形图
	var max_dps = 0.0
	for weapon_data in sorted_weapons:
		if weapon_data.dps > max_dps:
			max_dps = weapon_data.dps

	# 创建新的武器DPS条形图
	for i in range(display_count):
		var weapon_id = sorted_weapons[i].id
		var weapon_dps = sorted_weapons[i].dps

		# 创建容器（包含名称+条形图+数值）
		var container = Control.new()
		container.position = Vector2(10, 80 + i * 28)
		container.size = Vector2(190, 24)

		# 武器名称标签
		var name_label = Label.new()
		var weapon_name = _get_weapon_display_name(weapon_id)
		name_label.text = weapon_name
		name_label.position = Vector2(5, 0)
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color("#dddddd"))
		container.add_child(name_label)

		# DPS条形图
		var progress_bar = ProgressBar.new()
		progress_bar.position = Vector2(70, 2)
		progress_bar.size = Vector2(80, 18)
		progress_bar.show_percentage = false
		progress_bar.min_value = 0
		progress_bar.max_value = 100

		# 计算百分比（相对于最大DPS）
		var percent = 0.0
		if max_dps > 0:
			percent = (weapon_dps / max_dps) * 100.0
		progress_bar.value = percent

		# 根据DPS值设置条形图颜色
		var bar_color = Color("#ffffff")
		if weapon_dps > 100:
			bar_color = Color("#ff6666")  # 高DPS红色
		elif weapon_dps > 50:
			bar_color = Color("#ffaa66")  # 中等DPS橙色
		else:
			bar_color = Color("#66ff66")  # 低DPS绿色

		# 设置条形图样式
		var style = StyleBoxFlat.new()
		style.bg_color = bar_color
		progress_bar.add_theme_stylebox_override("fill", style)

		container.add_child(progress_bar)

		# DPS数值标签
		var value_label = Label.new()
		value_label.text = str(int(weapon_dps))
		value_label.position = Vector2(155, 0)
		value_label.add_theme_font_size_override("font_size", 11)
		value_label.add_theme_color_override("font_color", bar_color)
		container.add_child(value_label)

		dps_panel.add_child(container)
		weapon_dps_labels[weapon_id] = container

func _get_weapon_display_name(weapon_id: String) -> String:
	"""获取武器显示名称（中文）"""
	var name_map = {
		"hakurei_orb": "阴阳玉",
		"homing_amulet": "追踪御札",
		"kunai": "苦无",
		"ofuda": "符咒",
		"star_dust": "星尘",
		"phoenix_wings": "凤翼光环",
		"phoenix_claws": "重踢",
		"mokou_kick_heavy": "重踢",
		"knives": "飞刀",
		"yin_yang_orb": "阴阳玉",
		"persuasion_needle": "说得针",
		"danmaku": "弹幕",
		"sword": "剑",
		"katana": "武士刀",
		"minigun": "机枪",
		"unknown": "其他",
		"": "其他"
	}

	# 如果找到映射，返回中文名
	if name_map.has(weapon_id):
		return name_map[weapon_id]

	# 如果没找到，尝试美化原始ID并显示
	# 例如 "my_weapon" -> "My Weapon"
	if weapon_id != "" and weapon_id != "unknown":
		var beautified = weapon_id.replace("_", " ").capitalize()
		# 显示原始名称，让用户知道是哪个武器
		return beautified + " (" + weapon_id + ")"

	# 默认返回"基础攻击"
	return "基础攻击"

# ==================== 房间/波次信息 UI ====================
func _create_room_ui():
	"""创建房间和波次信息显示面板"""
	room_panel = Control.new()
	room_panel.name = "RoomPanel"
	room_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	room_panel.position = Vector2(20, 165)  # 调整位置
	room_panel.size = Vector2(200, 80)
	add_child(room_panel)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.size = Vector2(200, 80)
	room_panel.add_child(bg)

	# 房间标签
	room_label = Label.new()
	room_label.text = "房间 1 - 普通"
	room_label.position = Vector2(10, 8)
	room_label.add_theme_font_size_override("font_size", 18)
	room_label.add_theme_color_override("font_color", Color("#ffcc00"))
	room_panel.add_child(room_label)

	# 波次标签
	wave_label = Label.new()
	wave_label.text = "波次 1/3"
	wave_label.position = Vector2(10, 35)
	wave_label.add_theme_font_size_override("font_size", 14)
	room_panel.add_child(wave_label)

	# 波次进度条
	wave_progress_bar = ProgressBar.new()
	wave_progress_bar.position = Vector2(10, 55)
	wave_progress_bar.size = Vector2(180, 16)
	wave_progress_bar.show_percentage = false
	wave_progress_bar.value = 33

	var style = StyleBoxFlat.new()
	style.bg_color = Color("#66ccff")
	wave_progress_bar.add_theme_stylebox_override("fill", style)
	room_panel.add_child(wave_progress_bar)
	
	# 创建区域名称显示（屏幕中央上方）
	zone_name_label = Label.new()
	zone_name_label.name = "ZoneNameLabel"
	zone_name_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	zone_name_label.position.y = 80
	zone_name_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	zone_name_label.add_theme_font_size_override("font_size", 48)
	zone_name_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.0)) # 初始透明
	zone_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	zone_name_label.add_theme_constant_override("outline_size", 4)
	add_child(zone_name_label)

func _on_wave_info_updated(current_wave: int, total_waves: int):
	"""击杀进度信息更新（重用波次信号）"""
	if wave_label:
		if total_waves > 0:
			wave_label.text = "击杀 " + str(current_wave) + "/" + str(total_waves)
		else:
			wave_label.text = "无战斗"

	if wave_progress_bar and total_waves > 0:
		wave_progress_bar.value = (float(current_wave) / float(total_waves)) * 100

func _on_room_info_updated(room_type: String, room_index: int):
	"""房间信息更新"""
	if room_label:
		room_label.text = "房间 " + str(room_index + 1) + " - " + room_type

		# 根据房间类型改变颜色
		var color = Color("#ffcc00")  # 默认金色
		match room_type:
			"商店":
				color = Color("#66ff66")  # 绿色
			"BOSS":
				color = Color("#ff4444")  # 红色
			"附魔":
				color = Color("#cc66ff")  # 紫色
			"宝箱":
				color = Color("#ffaa00")  # 橙色
			"休息":
				color = Color("#66ccff")  # 蓝色

		room_label.add_theme_color_override("font_color", color)
		
	# 更新区域名称并播放动画
	if zone_name_label:
		# 获取深度信息（需要从RoomManager获取，或者简单根据index推断）
		# 这里假设 RoomManager 已经通过其他方式传递了 depth，或者我们再次获取
		var room_manager = get_tree().get_first_node_in_group("room_manager")
		var depth = 0
		if room_manager and room_manager.room_map.size() > room_index:
			depth = room_manager.room_map[room_index].depth
			
		var zone_name = "竹林外围"
		if depth >= 3:
			zone_name = "竹林深处"
			
		zone_name_label.text = "- " + zone_name + " -"
		
		# 播放淡入淡出动画
		var tween = create_tween()
		tween.tween_property(zone_name_label, "modulate:a", 1.0, 1.0)
		tween.tween_interval(2.0)
		tween.tween_property(zone_name_label, "modulate:a", 0.0, 1.0)

	# 更新房间地图
	if room_map_canvas:
		room_map_canvas.queue_redraw()

# ==================== 房间地图 UI ====================

func _create_room_map_ui():
	"""创建房间地图小地图"""
	room_map_panel = Control.new()
	room_map_panel.name = "RoomMapPanel"
	room_map_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	room_map_panel.position = Vector2(-320, 10)  # 右上角
	room_map_panel.size = Vector2(300, 250)  # 调整大小适应方格布局
	add_child(room_map_panel)

	# 背景
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = Vector2(300, 250)
	room_map_panel.add_child(bg)

	# 标题
	var title = Label.new()
	title.text = "房间地图"
	title.position = Vector2(10, 5)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("#ffcc00"))
	room_map_panel.add_child(title)

	# 创建绘制画布 - 使用自定义RoomMapCanvas类
	var RoomMapCanvasScript = load("res://RoomMapCanvas.gd")
	if RoomMapCanvasScript:
		room_map_canvas = RoomMapCanvasScript.new()
		room_map_canvas.name = "RoomMapCanvas"
		room_map_canvas.position = Vector2(10, 30)
		room_map_canvas.size = Vector2(280, 210)  # 调整画布大小
		room_map_panel.add_child(room_map_canvas)
	else:
		print("[GameUI] Error: Could not load RoomMapCanvas.gd")

func _on_boss_dialogue(boss_name: String, dialogue: String):
	"""Boss对话显示 - 使用对话立绘系统"""
	# 检查是否已有对话系统
	var dialogue_system = get_node_or_null("DialoguePortrait")
	if not dialogue_system:
		# 创建对话系统
		var DialoguePortraitScript = load("res://DialoguePortrait.gd")
		if DialoguePortraitScript:
			dialogue_system = DialoguePortraitScript.new()
			dialogue_system.name = "DialoguePortrait"
			add_child(dialogue_system)

	if dialogue_system:
		# 根据Boss名字选择立绘
		var character_portrait = DialoguePortrait.CharacterPortrait.MOKOU  # 默认
		match boss_name:
			"蓬莱山辉夜", "辉夜":
				character_portrait = DialoguePortrait.CharacterPortrait.KAGUYA
			"魂魄妖梦", "妖梦":
				character_portrait = DialoguePortrait.CharacterPortrait.YOUMU
			"琪露诺":
				character_portrait = DialoguePortrait.CharacterPortrait.CIRNO
			_:
				# 默认使用琪露诺
				character_portrait = DialoguePortrait.CharacterPortrait.CIRNO

		dialogue_system.show_dialogue(character_portrait, dialogue)

# ==================== 転流货币 UI ====================

func _create_tenryu_ui():
	"""创建転流货币显示"""
	tenryu_label = Label.new()
	tenryu_label.name = "TenryuLabel"
	tenryu_label.text = "転流: 0"
	tenryu_label.position = Vector2(20, 255)  # 调整位置到房间面板下方
	tenryu_label.add_theme_font_size_override("font_size", 20)
	tenryu_label.add_theme_color_override("font_color", Color("#ff8800"))
	add_child(tenryu_label)

func _on_tenryu_changed(current_tenryu: int):
	"""転流货币更新"""
	if tenryu_label:
		tenryu_label.text = "転流: " + str(current_tenryu)

# ==================== 暂停菜单 ====================

func _create_pause_menu():
	"""创建暂停菜单"""
	var pause_menu = PauseMenu.new()
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)
	print("[GameUI] 暂停菜单已创建")

func _apply_settings():
	"""应用当前设置到UI"""
	if not GameSettings:
		return

	# 显示/隐藏DPS面板
	if dps_panel:
		dps_panel.visible = GameSettings.show_dps

	# 显示/隐藏房间地图
	if room_map_panel:
		room_map_panel.visible = GameSettings.show_room_map

func _on_settings_changed():
	"""设置改变时响应"""
	_apply_settings()
	print("[GameUI] 设置已更新")
