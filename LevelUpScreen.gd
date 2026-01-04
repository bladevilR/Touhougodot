extends Control

# LevelUpScreen - 升级选择界面

var upgrade_choices: Array = []

@onready var background = $Background
@onready var title_label = $TitleLabel
@onready var choice_container = $ChoiceContainer

func _ready():
	visible = false
	SignalBus.level_up.connect(_on_level_up)

func _on_level_up(new_level: int):
	# 暂停游戏
	get_tree().paused = true

	# 获取可选的升级选项
	upgrade_choices = _get_upgrade_choices()

	# 显示界面
	_show_upgrades()

func _get_upgrade_choices() -> Array:
	"""获取3个随机升级选项"""
	var choices = []

	# 获取玩家节点和当前角色ID
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return choices

	# 固定使用妹红（已移除多角色系统）
	var player_character_id = GameConstants.CharacterId.MOKOU
	if SignalBus.selected_character_id >= 0:
		player_character_id = SignalBus.selected_character_id

	# 获取玩家当前拥有的武器
	var owned_weapons = []
	if player.weapon_system:
		owned_weapons = player.weapon_system.get_owned_weapon_ids()

	# 1. 收集所有可用的新武器
	var available_weapons = []
	for weapon_id in WeaponData.WEAPONS.keys():
		var weapon_config = WeaponData.WEAPONS[weapon_id]

		# 跳过符卡武器（需要通过融合获得）
		if weapon_config.is_spell_card:
			continue

		# 跳过已拥有的武器
		if weapon_id in owned_weapons:
			continue

		# 检查角色专属武器
		if weapon_config.exclusive_to >= 0 and weapon_config.exclusive_to != player_character_id:
			continue

		available_weapons.append({
			"type": "new_weapon",
			"weapon_id": weapon_id,
			"name": weapon_config.weapon_name,
			"description": weapon_config.description,
			"icon": weapon_config.id
		})

	# 2. 收集所有可用的武器升级
	var available_upgrades = []
	for weapon_id in owned_weapons:
		var weapon_data = player.weapon_system.weapons.get(weapon_id)
		if not weapon_data:
			continue

		var current_level = weapon_data.level
		var applied_upgrades = weapon_data.get("applied_upgrades", [])

		# 获取该武器的升级树
		var upgrade_tree = WeaponData.get_upgrade_tree(weapon_id)
		for upgrade in upgrade_tree:
			# 跳过已应用的升级
			if upgrade.id in applied_upgrades:
				continue

			# 添加到可用升级列表
			available_upgrades.append({
				"type": "weapon_upgrade",
				"weapon_id": weapon_id,
				"upgrade_id": upgrade.id,
				"name": upgrade.upgrade_name,
				"description": upgrade.description,
				"icon": upgrade.icon
			})

	# 3. 合并并随机选择
	var all_choices = available_weapons + available_upgrades
	all_choices.shuffle()

	print("=== 升级选项调试信息 ===")
	print("可用新武器数量: ", available_weapons.size())
	print("可用武器升级数量: ", available_upgrades.size())
	print("总可选项数量: ", all_choices.size())

	# 选择最多3个
	for i in range(min(3, all_choices.size())):
		choices.append(all_choices[i])
		print("选项 ", i+1, ": ", all_choices[i].name, " (", all_choices[i].type, ")")

	if choices.size() == 0:
		print("警告：没有可用的升级选项！")

	return choices

func _show_upgrades():
	visible = true

	# 清空之前的选项
	for child in choice_container.get_children():
		child.queue_free()

	# 创建选项按钮
	for i in range(upgrade_choices.size()):
		var choice = upgrade_choices[i]
		var button = Button.new()
		button.custom_minimum_size = Vector2(400, 150)  # 增大按钮尺寸

		# 构建按钮文本，包含图标
		var icon = choice.get("icon", "")
		var display_text = ""
		if icon != "":
			display_text = icon + " " + choice.name
		else:
			display_text = choice.name

		display_text += "\n" + choice.description

		# 如果是武器升级，显示对应的武器名称
		if choice.type == "weapon_upgrade":
			var weapon_config = WeaponData.get_weapon(choice.weapon_id)
			if weapon_config:
				display_text += "\n[" + weapon_config.weapon_name + "]"

		button.text = display_text

		# 增大字体
		button.add_theme_font_size_override("font_size", 20)

		button.pressed.connect(_on_choice_selected.bind(choice))
		choice_container.add_child(button)

func _on_choice_selected(choice: Dictionary):
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.weapon_system:
		return

	# 根据类型处理选择
	if choice.type == "new_weapon":
		# 添加新武器
		SignalBus.weapon_added.emit(choice.weapon_id)
		print("选择了新武器: ", choice.name)
	elif choice.type == "weapon_upgrade":
		# 应用武器升级
		player.weapon_system.apply_weapon_upgrade(choice.weapon_id, choice.upgrade_id)
		print("选择了武器升级: ", choice.name)

	# 隐藏界面
	visible = false

	# 恢复游戏
	get_tree().paused = false
