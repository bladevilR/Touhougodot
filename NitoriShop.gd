extends Node
class_name NitoriShop

# NitoriShop - 河童商店系统
# 在波次间隙提供商品购买：武器升级、被动道具、回复道具

signal shop_item_purchased(item: ShopItem)
signal coins_updated(amount: int)

# 金币（击杀敌人掉落，和经验分开）
var coins: int = 0

# 商店状态
var is_shop_open: bool = false
var current_stock: Array = []  # 当前商店库存

# 商品定义
class ShopItem:
	var id: String
	var item_name: String
	var description: String
	var price: int
	var item_type: String  # "weapon_upgrade", "passive", "consumable"
	var effect: Dictionary  # 效果数据
	var icon_color: Color

	func _init(p_id: String, p_name: String, p_desc: String, p_price: int, p_type: String, p_effect: Dictionary, p_color: Color = Color.WHITE):
		id = p_id
		item_name = p_name
		description = p_desc
		price = p_price
		item_type = p_type
		effect = p_effect
		icon_color = p_color

# 所有可用商品
var ALL_ITEMS: Dictionary = {}

func _ready():
	add_to_group("nitori_shop")
	# 初始化商品列表
	_init_shop_items()

	# 监听信号
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.shop_available.connect(_on_shop_available)

func _init_shop_items():
	"""初始化商店商品"""

	# ==================== 武器升级 ====================
	ALL_ITEMS["upgrade_damage"] = ShopItem.new(
		"upgrade_damage",
		"妖怪火药",
		"全武器伤害+10%",
		50,
		"passive",
		{"stat": "might", "bonus": 0.1},
		Color("#ff6b6b")
	)

	ALL_ITEMS["upgrade_speed"] = ShopItem.new(
		"upgrade_speed",
		"天狗羽毛",
		"移动速度+15%",
		40,
		"passive",
		{"stat": "speed", "bonus": 0.15},
		Color("#4ecdc4")
	)

	ALL_ITEMS["upgrade_cooldown"] = ShopItem.new(
		"upgrade_cooldown",
		"月兔钟表",
		"武器冷却-10%",
		60,
		"passive",
		{"stat": "cooldown", "bonus": -0.1},
		Color("#9b59b6")
	)

	ALL_ITEMS["upgrade_area"] = ShopItem.new(
		"upgrade_area",
		"八云隙间",
		"攻击范围+20%",
		55,
		"passive",
		{"stat": "area", "bonus": 0.2},
		Color("#f39c12")
	)

	ALL_ITEMS["upgrade_pickup"] = ShopItem.new(
		"upgrade_pickup",
		"妖精磁铁",
		"拾取范围+30%",
		30,
		"passive",
		{"stat": "pickup_range", "bonus": 0.3},
		Color("#2ecc71")
	)

	# ==================== 被动道具 ====================
	ALL_ITEMS["passive_regen"] = ShopItem.new(
		"passive_regen",
		"永琳的药",
		"每5秒回复5HP",
		80,
		"passive",
		{"type": "regen", "amount": 5, "interval": 5.0},
		Color("#e91e63")
	)

	ALL_ITEMS["passive_armor"] = ShopItem.new(
		"passive_armor",
		"河童甲壳",
		"受到伤害-15%",
		70,
		"passive",
		{"type": "armor", "reduction": 0.15},
		Color("#607d8b")
	)

	ALL_ITEMS["passive_luck"] = ShopItem.new(
		"passive_luck",
		"四叶草",
		"暴击率+10%",
		65,
		"passive",
		{"type": "crit_chance", "bonus": 0.1},
		Color("#8bc34a")
	)

	ALL_ITEMS["passive_greed"] = ShopItem.new(
		"passive_greed",
		"贪婪之壶",
		"金币获取+25%",
		45,
		"passive",
		{"type": "coin_bonus", "bonus": 0.25},
		Color("#ffc107")
	)

	ALL_ITEMS["passive_magnet"] = ShopItem.new(
		"passive_magnet",
		"玛丽莎的迷你八卦炉",
		"经验球自动吸附",
		100,
		"passive",
		{"type": "auto_pickup", "enabled": true},
		Color("#ff9800")
	)

	# ==================== 消耗品 ====================
	ALL_ITEMS["heal_small"] = ShopItem.new(
		"heal_small",
		"红茶",
		"回复30HP",
		25,
		"consumable",
		{"type": "heal", "amount": 30},
		Color("#e74c3c")
	)

	ALL_ITEMS["heal_large"] = ShopItem.new(
		"heal_large",
		"秘药",
		"回复全部HP",
		60,
		"consumable",
		{"type": "heal_full"},
		Color("#c0392b")
	)

	ALL_ITEMS["bomb"] = ShopItem.new(
		"bomb",
		"河童炸弹",
		"清屏所有敌人",
		80,
		"consumable",
		{"type": "clear_screen"},
		Color("#3498db")
	)

	ALL_ITEMS["exp_boost"] = ShopItem.new(
		"exp_boost",
		"经验水晶",
		"获得500经验",
		40,
		"consumable",
		{"type": "exp", "amount": 500},
		Color("#9b59b6")
	)

	# ==================== 测试道具 ====================
	ALL_ITEMS["test_pass"] = ShopItem.new(
		"test_pass",
		"测试通行证",
		"人物防御力增加999 (必然出现)",
		1,
		"passive",
		{"type": "defense", "value": 999.0},
		Color("#ffffff")
	)

func _on_enemy_killed(_enemy: Node2D, xp_amount: int, pos: Vector2):
	"""敌人死亡时的回调"""
	# 增加転流（杀敌数）
	add_tenryu(1)
	var base_coins = max(1, xp_amount / 5)

	# 应用金币加成
	var coin_bonus = _get_passive_bonus("coin_bonus")
	var final_coins = int(base_coins * (1.0 + coin_bonus))

	add_coins(final_coins)

func add_tenryu(amount: int):
	"""转发给经验管理器处理"""
	var exp_manager = get_tree().get_first_node_in_group("experience_manager")
	if exp_manager and exp_manager.has_method("add_tenryu"):
		exp_manager.add_tenryu(amount)

func _on_shop_available():
	"""波次间隙，商店可用"""
	open_shop()

func add_coins(amount: int):
	"""添加金币"""
	coins += amount
	SignalBus.coins_changed.emit(coins)
	coins_updated.emit(coins)

func spend_coins(amount: int) -> bool:
	"""花费金币"""
	if coins >= amount:
		coins -= amount
		SignalBus.coins_changed.emit(coins)
		coins_updated.emit(coins)
		return true
	return false

func open_shop():
	"""打开商店"""
	if is_shop_open:
		return

	is_shop_open = true

	# 生成当前商品列表（随机选择5个）
	current_stock = _generate_stock()

	# 暂停游戏
	get_tree().paused = true

	SignalBus.shop_opened.emit()
	print("河童商店开门啦！当前金币: ", coins)

func close_shop():
	"""关闭商店"""
	is_shop_open = false
	current_stock.clear()

	# 恢复游戏
	get_tree().paused = false

	SignalBus.shop_closed.emit()
	print("河童商店关门了")

func _generate_stock() -> Array:
	"""生成商店库存（随机选择5个商品 + 必然出现的测试通行证）"""
	var stock = []
	var item_ids = ALL_ITEMS.keys()
	
	# 移除测试通行证，稍后单独添加
	if item_ids.has("test_pass"):
		item_ids.erase("test_pass")
		
	item_ids.shuffle()

	# 确保至少有一个回复道具
	var has_heal = false
	for i in range(min(5, item_ids.size())):
		var item = ALL_ITEMS[item_ids[i]]
		stock.append(item)
		if item.effect.get("type") == "heal" or item.effect.get("type") == "heal_full":
			has_heal = true

	# 如果没有回复道具，替换最后一个
	if not has_heal and stock.size() > 0:
		stock[stock.size() - 1] = ALL_ITEMS["heal_small"]

	# 必然添加测试通行证到末尾
	if ALL_ITEMS.has("test_pass"):
		stock.append(ALL_ITEMS["test_pass"])

	return stock

func get_stock() -> Array:
	"""获取当前商店库存"""
	return current_stock

func purchase_item(item: ShopItem) -> bool:
	"""购买商品"""
	if not spend_coins(item.price):
		print("金币不足！需要 ", item.price, " 当前 ", coins)
		return false

	# 应用效果
	_apply_item_effect(item)

	# 从库存移除（一次性商品）
	current_stock.erase(item)

	shop_item_purchased.emit(item)
	SignalBus.item_purchased.emit(item.id)

	print("购买成功: ", item.item_name)
	return true

func _apply_item_effect(item: ShopItem):
	"""应用商品效果"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	match item.item_type:
		"passive":
			_apply_passive_effect(item, player)
		"consumable":
			_apply_consumable_effect(item, player)

func _apply_passive_effect(item: ShopItem, player: Node):
	"""应用被动效果"""
	var effect = item.effect

	# 保存被动效果到玩家
	if not player.has_meta("shop_passives"):
		player.set_meta("shop_passives", {})

	var passives = player.get_meta("shop_passives")

	# 属性加成类
	if effect.has("stat"):
		var stat = effect.stat
		var bonus = effect.bonus

		if not passives.has(stat):
			passives[stat] = 0.0
		passives[stat] += bonus

		# 直接应用到角色属性
		match stat:
			"might":
				if player.character_data:
					player.character_data.stats.might += bonus
			"speed":
				player.speed *= (1.0 + bonus)
			"cooldown":
				if player.character_data:
					player.character_data.stats.cooldown += bonus
			"area":
				if player.character_data:
					player.character_data.stats.area += bonus
			"pickup_range":
				# 存储拾取范围加成
				passives["pickup_range"] = passives.get("pickup_range", 0.0) + bonus

		print("被动效果: ", stat, " +", bonus * 100, "%")

	# 特殊被动类
	if effect.has("type"):
		match effect.type:
			"regen":
				_start_regen_effect(player, effect.amount, effect.interval)
			"armor":
				passives["armor"] = passives.get("armor", 0.0) + effect.reduction
			"defense":
				passives["defense"] = passives.get("defense", 0.0) + effect.value
			"crit_chance":
				passives["crit_chance"] = passives.get("crit_chance", 0.0) + effect.bonus
			"coin_bonus":
				passives["coin_bonus"] = passives.get("coin_bonus", 0.0) + effect.bonus
			"auto_pickup":
				passives["auto_pickup"] = true

	player.set_meta("shop_passives", passives)

func _apply_consumable_effect(item: ShopItem, player: Node):
	"""应用消耗品效果"""
	var effect = item.effect

	match effect.get("type"):
		"heal":
			if player.health_comp:
				player.health_comp.heal(effect.amount)
				print("回复 ", effect.amount, " HP")

		"heal_full":
			if player.health_comp:
				player.health_comp.current_hp = player.health_comp.max_hp
				SignalBus.player_health_changed.emit(player.health_comp.current_hp, player.health_comp.max_hp)
				print("HP完全回复！")

		"clear_screen":
			var enemies = get_tree().get_nodes_in_group("enemy")
			for enemy in enemies:
				if enemy.has_method("take_damage"):
					enemy.take_damage(9999)
			SignalBus.screen_shake.emit(0.3, 15.0)
			print("河��炸弹！清除所有敌人！")

		"exp":
			SignalBus.xp_pickup.emit(effect.amount)
			print("获得 ", effect.amount, " 经验！")

func _start_regen_effect(player: Node, amount: int, interval: float):
	"""启动生命回复效果"""
	# 创建一个定时器节点
	var timer = Timer.new()
	timer.name = "RegenTimer"
	timer.wait_time = interval
	timer.autostart = true
	timer.timeout.connect(func():
		if is_instance_valid(self) and is_instance_valid(player) and player.health_comp:
			player.health_comp.heal(amount)
	)
	player.add_child(timer)
	print("生命回复效果启动: 每", interval, "秒回复", amount, "HP")

func _get_passive_bonus(bonus_type: String) -> float:
	"""获取被动加成值"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return 0.0

	if not player.has_meta("shop_passives"):
		return 0.0

	var passives = player.get_meta("shop_passives")
	return passives.get(bonus_type, 0.0)

# ==================== DEBUG ====================

func debug_add_coins(amount: int):
	"""调试用：添加金币"""
	add_coins(amount)
	print("[DEBUG] 添加金币: ", amount, " 当前: ", coins)

func debug_open_shop():
	"""调试用：强制开店"""
	open_shop()

func _input(event):
	# N键打开商店（调试用）
	if event is InputEventKey:
		if event.keycode == KEY_N and event.pressed and not event.echo:
			if is_shop_open:
				close_shop()
			else:
				debug_add_coins(100)  # 给点钱测试
				open_shop()
