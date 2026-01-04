extends Node2D

## DungeonEntrance - 地下城入口场景
## 玩家选择地下城难度并进入战斗的场景

# 场景节点引用
@onready var player: CharacterBody2D = null
@onready var difficulty_panel: Control = null

# 地下城配置
var available_difficulties: Array = [
	{"name": "简单", "level": 1, "description": "适合新手"},
	{"name": "普通", "level": 2, "description": "挑战性适中"},
	{"name": "困难", "level": 3, "description": "需要一定实力"},
	{"name": "地狱", "level": 5, "description": "极限挑战"}
]

var selected_difficulty: int = 1

func _ready():
	print("[DungeonEntrance] 地下城入口场景初始化")

	# 设置场景名称
	name = "DungeonEntrance"

	# 查找玩家
	player = get_node_or_null("Player")
	if not player:
		push_warning("[DungeonEntrance] 玩家节点未找到")

	# 查找难度选择面板
	difficulty_panel = get_node_or_null("DifficultyPanel")

	# 进入主世界模式
	GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

	# 显示难度选择界面
	if difficulty_panel:
		_show_difficulty_selection()

	print("[DungeonEntrance] 地下城入口场景加载完成")

func _show_difficulty_selection():
	"""显示难度选择界面"""
	print("[DungeonEntrance] 显示难度选择")

	# TODO: 创建难度选择按钮
	# 在实际场景中，这些应该在 DifficultyPanel 中创建

## 选择难度
func select_difficulty(level: int):
	selected_difficulty = level
	print("[DungeonEntrance] 选择难度等级: %d" % level)

## 进入地下城
func enter_dungeon():
	print("[DungeonEntrance] 进入地下城，难度: %d" % selected_difficulty)

	# 使用 SceneManager 进入战斗
	SceneManager.enter_combat(selected_difficulty)

## 返回城镇
func return_to_town():
	print("[DungeonEntrance] 返回城镇")
	SceneManager.change_scene("town", "from_dungeon")

## 显示地下城信息
func show_dungeon_info(level: int):
	"""显示选中难度的地下城信息"""
	for diff in available_difficulties:
		if diff.level == level:
			print("[DungeonEntrance] 难度: %s - %s" % [diff.name, diff.description])
			# TODO: 更新 UI ��示
			break

func _input(event):
	# ESC 返回城镇
	if event.is_action_pressed("ui_cancel"):
		return_to_town()
