extends Node

## GameStateManager - 游戏状态管理器
## 管理游戏的不同模式：RPG探索、Roguelike战斗、菜单等

# 游戏模式枚举
enum GameMode {
	MENU,           # 主菜单
	HOME,           # 在家（竹林小屋）
	OVERWORLD,      # 主世界（RPG模式：城镇、农场等）
	COMBAT,         # 战斗模式（Roguelike地下城）
	DIALOGUE,       # 对话中
	CUTSCENE,       # 过场动画
	SLEEPING        # 睡眠中
}

# 当前游戏模式
var current_mode: GameMode = GameMode.MENU

# 模式切换信号
signal game_mode_changed(old_mode: GameMode, new_mode: GameMode)
signal combat_started()
signal combat_ended(victory: bool)
signal dialogue_started()
signal dialogue_ended()

# 玩家数据（持久化）
var player_data = {
	"name": "藤原妹红",
	"level": 1,
	"max_hp": 100,
	"current_hp": 100,
	"coins": 0,
	"position": Vector2.ZERO,
	"current_scene": "res://scenes/overworld/town/Town.tscn"
}

# 战斗数据（临时，战斗结束后清空）
var combat_data = {
	"floor": 1,
	"room": 0,
	"kills": 0,
	"time": 0.0,
	"weapons": [],
	"relics": []
}

func _ready():
	pass

## 切换游戏模式
func change_mode(new_mode: GameMode) -> void:
	var old_mode = current_mode
	current_mode = new_mode
	game_mode_changed.emit(old_mode, new_mode)

	# 根据模式执行特定逻辑
	match new_mode:
		GameMode.COMBAT:
			_on_combat_start()
		GameMode.OVERWORLD:
			_on_return_to_overworld()

## 进入战斗模式
func start_combat(dungeon_level: int = 1) -> void:
	combat_data.floor = dungeon_level
	combat_data.room = 0
	combat_data.kills = 0
	combat_data.time = 0.0
	combat_data.weapons = []
	combat_data.relics = []

	change_mode(GameMode.COMBAT)
	combat_started.emit()

## 结束战斗
func end_combat(victory: bool) -> void:
	combat_ended.emit(victory)

	# 战斗胜利，获得奖励
	if victory:
		_apply_combat_rewards()

	# 清空战斗数据
	combat_data.floor = 1
	combat_data.room = 0
	combat_data.kills = 0
	combat_data.time = 0.0

	change_mode(GameMode.OVERWORLD)

## 应用战斗奖励
func _apply_combat_rewards() -> void:
	# TODO: 根据击杀数、通关时间等计算奖励
	var reward_coins = combat_data.kills * 10
	player_data.coins += reward_coins

## 进入对话
func start_dialogue() -> void:
	change_mode(GameMode.DIALOGUE)
	dialogue_started.emit()

## 结束对话
func end_dialogue() -> void:
	dialogue_ended.emit()
	change_mode(GameMode.OVERWORLD)

## 检查是否可以移动（非对话、非菜单、非过场、非睡眠）
func can_player_move() -> bool:
	return current_mode in [GameMode.HOME, GameMode.OVERWORLD, GameMode.COMBAT]

## 检查是否可以打开菜单
func can_open_menu() -> bool:
	return current_mode in [GameMode.HOME, GameMode.OVERWORLD, GameMode.COMBAT]

## 私有方法
func _on_combat_start() -> void:
	pass

func _on_return_to_overworld() -> void:
	pass

func _mode_to_string(mode: GameMode) -> String:
	match mode:
		GameMode.MENU: return "菜单"
		GameMode.HOME: return "在家"
		GameMode.OVERWORLD: return "主世界"
		GameMode.COMBAT: return "战斗"
		GameMode.DIALOGUE: return "对话"
		GameMode.CUTSCENE: return "过场"
		GameMode.SLEEPING: return "睡眠中"
		_: return "未知"
