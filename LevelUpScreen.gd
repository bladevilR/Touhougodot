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

	var player_character_id = player.character_id

	# 获取玩家当前拥有的武器
	var owned_weapons = []
	if player.weapon_system:
		owned_weapons = player.weapon_system.get_owned_weapon_ids()

	# 过滤可用武器
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

		available_weapons.append(weapon_id)

	# 如果可用武器不足3个，也添加武器升级选项
	# TODO: 实现武器升级选项

	# 随机选择3个
	available_weapons.shuffle()
	for i in range(min(3, available_weapons.size())):
		var weapon_id = available_weapons[i]
		var weapon_config = WeaponData.WEAPONS[weapon_id]
		choices.append({
			"weapon_id": weapon_id,
			"name": weapon_config.weapon_name,
			"description": weapon_config.description,
			"icon": weapon_config.id
		})

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
		button.text = choice.name + "\n" + choice.description

		# 增大字体
		button.add_theme_font_size_override("font_size", 24)

		button.pressed.connect(_on_choice_selected.bind(choice))
		choice_container.add_child(button)

func _on_choice_selected(choice: Dictionary):
	# 添加武器
	SignalBus.weapon_added.emit(choice.weapon_id)

	# 隐藏界面
	visible = false

	# 恢复游戏
	get_tree().paused = false

	print("选择了升级: ", choice.name)
