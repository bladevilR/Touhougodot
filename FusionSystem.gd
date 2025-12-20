extends Node
class_name FusionSystem

# FusionSystem - 符卡融合系统
# 当两个武器都达到Lv.3 MAX时，可以融合成符卡武器

signal fusion_available(recipe: WeaponData.WeaponRecipe)
signal fusion_completed(result_weapon_id: String)
signal fusion_ui_requested(available_recipes: Array)

var weapon_system: Node = null
var available_fusions: Array = []  # 当前可用的融合配方

func _ready():
	# 获取WeaponSystem引用
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		weapon_system = players[0].get_node_or_null("WeaponSystem")

	# 监听武器升级信号
	SignalBus.weapon_upgraded.connect(_on_weapon_upgraded)

func _unhandled_input(event):
	# Tab键打开融合界面（如果有可用融合）
	if event is InputEventKey:
		if event.keycode == KEY_TAB and event.pressed and not event.echo:
			if available_fusions.size() > 0:
				fusion_ui_requested.emit(available_fusions)
				print("可用融合配方: ", available_fusions.size(), "个")
				get_viewport().set_input_as_handled()

func _on_weapon_upgraded(weapon_id: String):
	"""武器升级时检查是否有新的融合可用"""
	_check_available_fusions()

func _check_available_fusions():
	"""检查当前可用的融合配方"""
	available_fusions.clear()

	if not weapon_system:
		return

	# 获取所有已拥有的武器
	var owned_weapons = weapon_system.get_owned_weapon_ids()

	# 获取所有MAX等级的武器
	var max_level_weapons = []
	for weapon_id in owned_weapons:
		var weapon_data = weapon_system.get_weapon_data(weapon_id)
		if weapon_data.has("level") and weapon_data.level >= 3:
			max_level_weapons.append(weapon_id)

	# 检查每个配方
	var all_recipes = WeaponData.get_all_recipes()
	for recipe in all_recipes:
		var req = recipe.requires
		# 检查两个原料是否都是MAX等级
		if req[0] in max_level_weapons and req[1] in max_level_weapons:
			available_fusions.append(recipe)
			fusion_available.emit(recipe)
			print("融合可用: ", recipe.recipe_name)

func can_fuse(weapon_id1: String, weapon_id2: String) -> Dictionary:
	"""检查两个武器是否可以融合"""
	var result = {
		"can_fuse": false,
		"recipe": null,
		"reason": ""
	}

	if not weapon_system:
		result.reason = "武器系统未就绪"
		return result

	# 检查武器是否存在
	var weapon1_data = weapon_system.get_weapon_data(weapon_id1)
	var weapon2_data = weapon_system.get_weapon_data(weapon_id2)

	if weapon1_data.is_empty():
		result.reason = "武器1未装备"
		return result
	if weapon2_data.is_empty():
		result.reason = "武器2未装备"
		return result

	# 检查等级
	if weapon1_data.get("level", 1) < 3:
		result.reason = weapon_id1 + " 未达到MAX等级"
		return result
	if weapon2_data.get("level", 1) < 3:
		result.reason = weapon_id2 + " 未达到MAX等级"
		return result

	# 检查配方
	var recipe = WeaponData.can_fuse_weapons(weapon_id1, weapon_id2)
	if not recipe:
		result.reason = "没有匹配的融合配方"
		return result

	result.can_fuse = true
	result.recipe = recipe
	return result

func execute_fusion(weapon_id1: String, weapon_id2: String) -> bool:
	"""执行融合"""
	var check = can_fuse(weapon_id1, weapon_id2)
	if not check.can_fuse:
		print("融合失败: ", check.reason)
		return false

	var recipe = check.recipe

	# 移除原武器
	_remove_weapon(weapon_id1)
	_remove_weapon(weapon_id2)

	# 添加融合后的符卡武器
	SignalBus.weapon_added.emit(recipe.result_weapon_id)

	print("★ 符卡融合成功！")
	print("  ", weapon_id1, " + ", weapon_id2, " = ", recipe.result_weapon_id)

	fusion_completed.emit(recipe.result_weapon_id)

	# 重新检查可用融合
	_check_available_fusions()

	return true

func _remove_weapon(weapon_id: String):
	"""从武器系统移除武器"""
	if weapon_system and weapon_system.weapons.has(weapon_id):
		weapon_system.weapons.erase(weapon_id)
		print("移除武器: ", weapon_id)

func get_available_fusions() -> Array:
	"""获取当前可用的融合配方列表"""
	return available_fusions

func get_all_possible_fusions() -> Array:
	"""获取所有可能的融合配方（用于UI显示）"""
	return WeaponData.get_all_recipes()

func get_fusion_progress(recipe: WeaponData.WeaponRecipe) -> Dictionary:
	"""获取特定配方的进度"""
	var progress = {
		"weapon1_id": recipe.requires[0],
		"weapon2_id": recipe.requires[1],
		"weapon1_owned": false,
		"weapon2_owned": false,
		"weapon1_level": 0,
		"weapon2_level": 0,
		"weapon1_max": false,
		"weapon2_max": false,
		"can_fuse": false
	}

	if not weapon_system:
		return progress

	# 检查武器1
	var w1_data = weapon_system.get_weapon_data(recipe.requires[0])
	if not w1_data.is_empty():
		progress.weapon1_owned = true
		progress.weapon1_level = w1_data.get("level", 1)
		progress.weapon1_max = progress.weapon1_level >= 3

	# 检查武器2
	var w2_data = weapon_system.get_weapon_data(recipe.requires[1])
	if not w2_data.is_empty():
		progress.weapon2_owned = true
		progress.weapon2_level = w2_data.get("level", 1)
		progress.weapon2_max = progress.weapon2_level >= 3

	progress.can_fuse = progress.weapon1_max and progress.weapon2_max

	return progress

# ==================== DEBUG / TESTING ====================

func debug_print_status():
	"""打印融合系统状态（调试用）"""
	print("=== 融合系统状态 ===")

	if not weapon_system:
		print("武器系统未连接")
		return

	print("当前拥有武器:")
	for weapon_id in weapon_system.get_owned_weapon_ids():
		var data = weapon_system.get_weapon_data(weapon_id)
		var level = data.get("level", 1)
		var max_marker = " [MAX]" if level >= 3 else ""
		print("  - ", weapon_id, " Lv.", level, max_marker)

	print("\n可用融合配方:")
	if available_fusions.size() == 0:
		print("  (无)")
	else:
		for recipe in available_fusions:
			print("  ★ ", recipe.recipe_name)
			print("    ", recipe.requires[0], " + ", recipe.requires[1], " = ", recipe.result_weapon_id)

	print("\n所有配方进度:")
	for recipe in WeaponData.get_all_recipes():
		var prog = get_fusion_progress(recipe)
		var w1_status = "Lv.%d%s" % [prog.weapon1_level, "/MAX" if prog.weapon1_max else ""]
		var w2_status = "Lv.%d%s" % [prog.weapon2_level, "/MAX" if prog.weapon2_max else ""]
		if not prog.weapon1_owned:
			w1_status = "未获得"
		if not prog.weapon2_owned:
			w2_status = "未获得"
		print("  ", recipe.recipe_name, ": ", recipe.requires[0], "(", w1_status, ") + ", recipe.requires[1], "(", w2_status, ")")
