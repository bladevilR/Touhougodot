extends Node

## SaveSystem - 存档系统
## 处理游戏存档、读档、自动保存

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(error: String)
signal load_failed(error: String)

# 存档路径
const SAVE_DIR = "user://saves/"
const SAVE_FILE_PREFIX = "save_slot_"
const SAVE_FILE_EXTENSION = ".json"
const AUTO_SAVE_SLOT = 0  # 0号槽位为自动存档

# 自动保存设置
var auto_save_enabled: bool = true
var auto_save_interval: float = 300.0  # 5分钟自动保存一次
var auto_save_timer: float = 0.0

func _ready():
	# 确保存档目录存在
	_ensure_save_directory()
	# print("[SaveSystem] 存档系统初始化完成")

func _process(delta):
	if not auto_save_enabled:
		return

	# 只在主世界自动保存
	if GameStateManager.current_mode != GameStateManager.GameMode.OVERWORLD:
		return

	auto_save_timer += delta
	if auto_save_timer >= auto_save_interval:
		auto_save_timer = 0.0
		auto_save()

## 确保存档目录存在
func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

## 保存游戏
func save_game(slot: int = 1) -> bool:
	var save_data = _collect_save_data()
	var file_path = _get_save_file_path(slot)

	var json = JSON.new()
	var json_string = json.stringify(save_data, "\t")

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var error = "无法创建存档文件: %s" % file_path
		push_error("[SaveSystem] %s" % error)
		save_failed.emit(error)
		return false

	file.store_string(json_string)
	file.close()

	# print("[SaveSystem] 游戏已保存到槽位 %d" % slot)
	save_completed.emit(slot)
	return true

## 读取游戏
func load_game(slot: int = 1) -> bool:
	var file_path = _get_save_file_path(slot)

	if not FileAccess.file_exists(file_path):
		var error = "存档文件不存在: %s" % file_path
		push_warning("[SaveSystem] %s" % error)
		load_failed.emit(error)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error = "无法读取存档文件: %s" % file_path
		push_error("[SaveSystem] %s" % error)
		load_failed.emit(error)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		var error = "存档文件格式错误"
		push_error("[SaveSystem] %s" % error)
		load_failed.emit(error)
		return false

	var save_data = json.data
	_apply_save_data(save_data)

	# print("[SaveSystem] 存档已加载，槽位 %d" % slot)
	load_completed.emit(slot)
	return true

## 自动保存
func auto_save() -> void:
	save_game(AUTO_SAVE_SLOT)
	# print("[SaveSystem] 自动保存完成")

## 检查���档是否存在
func has_save(slot: int) -> bool:
	var file_path = _get_save_file_path(slot)
	return FileAccess.file_exists(file_path)

## 删除存档
func delete_save(slot: int) -> bool:
	var file_path = _get_save_file_path(slot)

	if not FileAccess.file_exists(file_path):
		push_warning("[SaveSystem] 存档不存在: %s" % file_path)
		return false

	var dir = DirAccess.open(SAVE_DIR)
	var result = dir.remove(file_path)
	if result != OK:
		push_error("[SaveSystem] 删除存档失败: %s" % file_path)
		return false

	# print("[SaveSystem] 存档已删除，槽位 %d" % slot)
	return true

## 获取存档信息（用于显示存档列表）
func get_save_info(slot: int) -> Dictionary:
	var file_path = _get_save_file_path(slot)

	if not FileAccess.file_exists(file_path):
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return {}

	var save_data = json.data
	return {
		"slot": slot,
		"player_name": save_data.get("player_name", "未知"),
		"level": save_data.get("level", 1),
		"play_time": save_data.get("play_time", 0.0),
		"scene": save_data.get("current_scene", ""),
		"timestamp": save_data.get("timestamp", "")
	}

## 收集存档数据
func _collect_save_data() -> Dictionary:
	var player = _get_player_node()

	var save_data = {
		"version": "1.0.0",
		"timestamp": Time.get_datetime_string_from_system(),

		# 玩家基础数据
		"player_name": GameStateManager.player_data.name,
		"level": GameStateManager.player_data.level,
		"max_hp": GameStateManager.player_data.max_hp,
		"current_hp": GameStateManager.player_data.current_hp,
		"coins": GameStateManager.player_data.coins,

		# 位置和场景
		"current_scene": SceneManager.current_scene_name,
		"position": {
			"x": GameStateManager.player_data.position.x,
			"y": GameStateManager.player_data.position.y
		},

		# 背包数据
		"inventory": InventoryManager.get_save_data() if has_node("/root/InventoryManager") else {},

		# 任务数据
		"quests": QuestManager.get_save_data() if has_node("/root/QuestManager") else {},

		# 游戏统计
		"play_time": _get_play_time(),
		"total_kills": 0,  # TODO: 从统计系统获取
	}

	return save_data

## 应用存档数据
func _apply_save_data(save_data: Dictionary) -> void:
	# 恢复玩家数据
	GameStateManager.player_data.name = save_data.get("player_name", "藤原妹红")
	GameStateManager.player_data.level = save_data.get("level", 1)
	GameStateManager.player_data.max_hp = save_data.get("max_hp", 100)
	GameStateManager.player_data.current_hp = save_data.get("current_hp", 100)
	GameStateManager.player_data.coins = save_data.get("coins", 0)

	# 恢复位置
	var pos_data = save_data.get("position", {"x": 0, "y": 0})
	GameStateManager.player_data.position = Vector2(pos_data.x, pos_data.y)

	# 恢复场景
	var scene_name = save_data.get("current_scene", "town")
	GameStateManager.player_data.current_scene = scene_name

	# 恢复背包
	if has_node("/root/InventoryManager"):
		InventoryManager.load_save_data(save_data.get("inventory", {}))

	# 恢复任务
	if has_node("/root/QuestManager"):
		QuestManager.load_save_data(save_data.get("quests", {}))

	# 加载场景
	SceneManager.change_scene(scene_name)

## 辅助方法
func _get_save_file_path(slot: int) -> String:
	return SAVE_DIR + SAVE_FILE_PREFIX + str(slot) + SAVE_FILE_EXTENSION

func _get_player_node() -> Node:
	var scene_root = get_tree().current_scene
	if scene_root:
		return scene_root.find_child("Player", true, false)
	return null

func _get_play_time() -> float:
	# TODO: 从游戏统计系统获取
	return 0.0
