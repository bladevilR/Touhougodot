extends Node

# ExperienceManager - 经验/升级管理器 + 掉落物管理 + 転流货币系统
# 这是一个纯逻辑节点，负责计算"捡经验球 -> 加经验 -> 升级"
# 也负责生成宝箱和元素附魔掉落物
# 管理転流货币（杀敌数）

var current_level = 1
var current_xp = 0
var xp_required = 100

# 転流货币系统（杀敌数）
var tenryu: int = 0  # 当前転流数量

func add_tenryu(amount: int):
	"""增加転流（杀敌数）"""
	tenryu += amount
	SignalBus.tenryu_changed.emit(tenryu)
	# print("获得転流: ", amount, " 当前总计: ", tenryu)

# 预加载场景
var gem_scene = preload("res://ExperienceGem.tscn")
var chest_scene = preload("res://TreasureChest.tscn")
var enchant_scene = preload("res://ElementEnchant.tscn")

# 元素附魔生成计时
var enchant_spawn_timer: float = 0.0
const ENCHANT_SPAWN_INTERVAL: float = 45.0  # 每45秒生成一个元素附魔道具

func _ready():
	add_to_group("experience_manager")

	# 监听怪物的死亡信号，生成经验球
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	# 监听经验球拾取信号
	SignalBus.xp_pickup.connect(_on_xp_pickup)
	# 监听宝箱生成信号
	SignalBus.treasure_chest_spawn.connect(_on_treasure_chest_spawn)
	# 监听元素附魔生成信号
	SignalBus.element_enchant_spawn.connect(_on_element_enchant_spawn)
	# 初始化元素数据
	ElementData.initialize()

func _on_enemy_killed(_enemy, xp_amount, pos):
	"""敌人被击杀时的处理"""
	# 在敌人位置生成经验球
	spawn_gem(xp_amount, pos)

func spawn_gem(xp_amount: int, pos: Vector2):
	"""在指定位置生成经验球"""
	var gem = gem_scene.instantiate()
	gem.xp_value = xp_amount
	gem.global_position = pos

	# 添加到当前场景
	get_tree().current_scene.call_deferred("add_child", gem)

func _on_xp_pickup(xp_amount: int):
	"""拾取经验球时调用"""
	gain_xp(xp_amount)

func gain_xp(amount):
	# 升级速度加快1.5倍：获得的经验乘以1.5
	var boosted_amount = int(amount * 1.5)
	current_xp += boosted_amount

	# 检查升级
	while current_xp >= xp_required:
		current_xp -= xp_required
		level_up()

	# 通知 UI 更新
	SignalBus.xp_gained.emit(current_xp, xp_required, current_level)

func level_up():
	current_level += 1
	xp_required = int(xp_required * 1.5) # 简单的升级曲线

	# 通知全世界：升级了！
	# 玩家脚本听到了可以回满血，UI听到了可以弹窗，武器系统听到了可以重置CD
	SignalBus.level_up.emit(current_level)
	# print("升级到 Lv.", current_level, "！需要经验: ", xp_required)

func _on_treasure_chest_spawn(pos: Vector2):
	"""在指定位置生成宝箱"""
	spawn_chest(pos)

func spawn_chest(pos: Vector2):
	"""生成宝箱掉落物"""
	var chest = chest_scene.instantiate()
	chest.global_position = pos

	# 添加到当前场景
	get_tree().current_scene.call_deferred("add_child", chest)
	# print("宝箱已生成在位置: ", pos)

func _on_element_enchant_spawn(pos: Vector2, element_type: int):
	"""在指定位置生成指定元素的附魔道具"""
	spawn_enchant(pos, element_type)

func spawn_enchant(pos: Vector2, element_type: int = -1):
	"""生成元素附魔道具"""
	var enchant = enchant_scene.instantiate()
	enchant.global_position = pos

	# 如果指定了元素类型则使用，否则随机
	if element_type >= 0:
		enchant.element_type = element_type
	else:
		var element_types = ElementData.get_all_element_types()
		enchant.element_type = element_types[randi() % element_types.size()]

	# 添加到当前场景
	get_tree().current_scene.call_deferred("add_child", enchant)

	var element_item = ElementData.get_element_item(enchant.element_type)
	var element_name = element_item.item_name if element_item else "未知元素"
	# print("元素附魔道具已生成: ", element_name, " 位置: ", pos)

func _spawn_random_enchant():
	"""在玩家附近随机位置生成元素附魔道具"""
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# 在玩家周围300-500像素范围内生成
	var angle = randf() * TAU
	var distance = randf_range(300.0, 500.0)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance

	# 检查地图边界
	var map_system = get_tree().get_first_node_in_group("map_system")
	if map_system and map_system.has_method("get_map_size"):
		var map_size = map_system.get_map_size()
		spawn_pos.x = clamp(spawn_pos.x, 100, map_size.x - 100)
		spawn_pos.y = clamp(spawn_pos.y, 100, map_size.y - 100)

	spawn_enchant(spawn_pos)
