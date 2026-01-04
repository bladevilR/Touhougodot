extends Node2D

## Town - 城镇场景
## 游戏主要的主世界场景，包含 NPC、商店、任务等

# 场景节点引用
@onready var player: CharacterBody2D = null
@onready var camera: Camera2D = null
@onready var tilemap: TileMap = null

# NPC 和交互点
var npcs: Array = []
var shops: Array = []
var quest_givers: Array = []

func _ready():
	print("[Town] 城镇场景初始化")

	# 设置场景名称（用于 SceneManager）
	name = "Town"

	# 查找玩家节点
	player = get_node_or_null("Player")
	if not player:
		push_warning("[Town] 玩家节点未找到")

	# 查找相机
	camera = get_node_or_null("Player/Camera2D") if player else null

	# 查找地图
	tilemap = get_node_or_null("TileMap")

	# 初始化场景
	_initialize_scene()

	# 通知 GameStateManager 进入主世界模式
	GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

	print("[Town] 城镇场景加载完成")

func _initialize_scene():
	"""初始化场景元素"""
	# 查找所有 NPC
	npcs = get_tree().get_nodes_in_group("npc")
	print("[Town] 找到 %d 个 NPC" % npcs.size())

	# 查找所有商店
	shops = get_tree().get_nodes_in_group("shop")
	print("[Town] 找到 %d 个商店" % shops.size())

	# 查找所有任务发布者
	quest_givers = get_tree().get_nodes_in_group("quest_giver")
	print("[Town] 找到 %d 个任务发布者" % quest_givers.size())

	# 连接场景信号
	_connect_signals()

func _connect_signals():
	"""连接场景信号"""
	# 连接 NPC 交互信号
	for npc in npcs:
		if npc.has_signal("interacted"):
			npc.interacted.connect(_on_npc_interacted.bind(npc))

	# 连接商店信号
	for shop in shops:
		if shop.has_signal("shop_opened"):
			shop.shop_opened.connect(_on_shop_opened.bind(shop))

## NPC 交互回调
func _on_npc_interacted(npc):
	print("[Town] 与 NPC 交互: ", npc.name)
	# TODO: 显示对话界面

## 商店打开回调
func _on_shop_opened(shop):
	print("[Town] 打开商店: ", shop.name)
	# TODO: 显示商店界面

## 进入地下城
func enter_dungeon(dungeon_level: int = 1):
	print("[Town] 进入地下城，难度等级: ", dungeon_level)
	SceneManager.enter_combat(dungeon_level)

## 前往农场
func go_to_farm():
	print("[Town] 前往农场")
	SceneManager.change_scene("farm", "from_town")

## 保存游戏
func save_game():
	print("[Town] 保存游戏")
	SaveSystem.save_game(1)  # 保存到槽位 1

func _input(event):
	# F5 快速保存
	if event.is_action_pressed("ui_text_submit"):  # 可以改为自定义快捷键
		save_game()
