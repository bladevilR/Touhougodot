extends Node2D

## Farm - 农场场景
## 玩家的农场，可以种植、饲养、建造等

# 场景节点引用
@onready var player: CharacterBody2D = null
@onready var camera: Camera2D = null

# 农场系统
var farm_plots: Array = []  # 农田
var animals: Array = []      # 动物
var buildings: Array = []    # 建筑

func _ready():
	print("[Farm] 农场场景初始化")

	# 设置场景名称
	name = "Farm"

	# 查找玩家
	player = get_node_or_null("Player")
	if not player:
		push_warning("[Farm] 玩家节点未找到")

	camera = get_node_or_null("Player/Camera2D") if player else null

	# 初始化农场
	_initialize_farm()

	# 进入主世界模式
	GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

	print("[Farm] 农场场景加载完成")

func _initialize_farm():
	"""初始化农场元素"""
	# 查找农田
	farm_plots = get_tree().get_nodes_in_group("farm_plot")
	print("[Farm] 找到 %d 块农田" % farm_plots.size())

	# 查找动物
	animals = get_tree().get_nodes_in_group("animal")
	print("[Farm] 找到 %d 只动物" % animals.size())

	# 查找建筑
	buildings = get_tree().get_nodes_in_group("building")
	print("[Farm] 找到 %d 个建筑" % buildings.size())

## 返回城镇
func return_to_town():
	print("[Farm] 返回城镇")
	SceneManager.change_scene("town", "from_farm")

## 种植作物
func plant_crop(plot_index: int, crop_id: String):
	if plot_index < 0 or plot_index >= farm_plots.size():
		push_error("[Farm] 无效的农田索引: %d" % plot_index)
		return

	print("[Farm] 在农田 %d 种植作物: %s" % [plot_index, crop_id])
	# TODO: 实现种植逻辑

## 收获作物
func harvest_crop(plot_index: int):
	if plot_index < 0 or plot_index >= farm_plots.size():
		push_error("[Farm] 无效的农田索引: %d" % plot_index)
		return

	print("[Farm] 收获农田 %d 的作物" % plot_index)
	# TODO: 实现收获逻辑
	# 添加物品到背包
	# InventoryManager.add_item(crop_id, amount)

## 喂养动物
func feed_animal(animal_index: int):
	if animal_index < 0 or animal_index >= animals.size():
		push_error("[Farm] 无效的动物索引: %d" % animal_index)
		return

	print("[Farm] 喂养动物 %d" % animal_index)
	# TODO: 实现喂养逻辑

func _input(event):
	# E 键交互
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_interact():
	"""尝试与附近的农田/动物/建筑交互"""
	if not player:
		return

	# TODO: 检测玩家附近的可交互对象
	pass
