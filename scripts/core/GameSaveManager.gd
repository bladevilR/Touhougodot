extends Node

# GameSaveManager.gd - 游戏存档管理器
# 负责保存和加载所有持久化数据：局外升级、设置、统计等

const SAVE_PATH = "user://touhou_phantom_save.dat"
const SAVE_VERSION = 1

# 存档数据结构
var save_data: Dictionary = {
	"version": SAVE_VERSION,
	"meta_currency": 0,                    # 局外货币（灵魂碎片）
	"total_meta_currency_earned": 0,       # 总共获得过的货币
	"upgrade_levels": {},                   # 各升级项的当前等级
	"settings": {},                         # 游戏设置
	"statistics": {},                       # 游戏统计
	"unlocks": {},                          # 解锁内容
	"first_play_date": "",                  # 首次游戏日期
	"last_play_date": "",                   # 最后游戏日期
	"total_playtime": 0,                    # 总游戏时间（秒）
}

# 统计数据模板
var default_statistics: Dictionary = {
	"total_runs": 0,                        # 总游戏局数
	"successful_runs": 0,                   # 胜利局数
	"total_kills": 0,                       # 总击杀数
	"total_damage_dealt": 0,                # 总造成伤害
	"total_damage_taken": 0,                # 总受到伤害
	"total_xp_gained": 0,                   # 总获得经验
	"total_gold_earned": 0,                 # 总获得金币
	"highest_level_reached": 0,             # 最高达到等级
	"longest_survival_time": 0,             # 最长存活时间
	"bosses_defeated": 0,                   # 击败Boss数
	"character_runs": {},                   # 各角色游玩次数
	"character_wins": {},                   # 各角色胜利次数
}

func _ready():
	load_game()
	_ensure_data_integrity()

func _ensure_data_integrity():
	# 确保所有必要字段存在
	if not save_data.has("version"):
		save_data.version = SAVE_VERSION
	if not save_data.has("meta_currency"):
		save_data.meta_currency = 0
	if not save_data.has("total_meta_currency_earned"):
		save_data.total_meta_currency_earned = 0
	if not save_data.has("upgrade_levels"):
		save_data.upgrade_levels = {}
	if not save_data.has("settings"):
		save_data.settings = {}
	if not save_data.has("statistics"):
		save_data.statistics = default_statistics.duplicate(true)
	if not save_data.has("unlocks"):
		save_data.unlocks = {}
	if not save_data.has("first_play_date"):
		save_data.first_play_date = Time.get_datetime_string_from_system()
	if not save_data.has("last_play_date"):
		save_data.last_play_date = ""
	if not save_data.has("total_playtime"):
		save_data.total_playtime = 0

	# 确保统计数据完整
	for key in default_statistics:
		if not save_data.statistics.has(key):
			save_data.statistics[key] = default_statistics[key]

# === 保存/加载 ===

func save_game():
	save_data.last_play_date = Time.get_datetime_string_from_system()

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("[GameSaveManager] 游戏已保存")
	else:
		push_error("[GameSaveManager] 保存失败: " + str(FileAccess.get_open_error()))

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("[GameSaveManager] 没有找到存档，使用默认数据")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			save_data = json.get_data()
			_migrate_save_data()
			print("[GameSaveManager] 存档加载成功")
		else:
			push_error("[GameSaveManager] 存档解析失败: " + json.get_error_message())
	else:
		push_error("[GameSaveManager] 存档读取失败")

func _migrate_save_data():
	# 版本迁移逻辑
	var saved_version = save_data.get("version", 0)
	if saved_version < SAVE_VERSION:
		print("[GameSaveManager] 迁移存档从版本 %d 到 %d" % [saved_version, SAVE_VERSION])
		# 在这里添加版本迁移逻辑
		save_data.version = SAVE_VERSION

func reset_save():
	# 重置存档（用于调试或玩家选择）
	save_data = {
		"version": SAVE_VERSION,
		"meta_currency": 0,
		"total_meta_currency_earned": 0,
		"upgrade_levels": {},
		"settings": {},
		"statistics": default_statistics.duplicate(true),
		"unlocks": {},
		"first_play_date": Time.get_datetime_string_from_system(),
		"last_play_date": "",
		"total_playtime": 0,
	}
	save_game()
	print("[GameSaveManager] 存档已重置")

# === 货币操作 ===

func add_meta_currency(amount: int):
	if amount <= 0:
		return
	save_data.meta_currency += amount
	save_data.total_meta_currency_earned += amount
	save_game()
	print("[GameSaveManager] 获得灵魂碎片: +%d (当前: %d)" % [amount, save_data.meta_currency])

func spend_meta_currency(amount: int) -> bool:
	if amount <= 0 or save_data.meta_currency < amount:
		return false
	save_data.meta_currency -= amount
	save_game()
	print("[GameSaveManager] 消耗灵魂碎片: -%d (剩余: %d)" % [amount, save_data.meta_currency])
	return true

func get_meta_currency() -> int:
	return save_data.meta_currency

# === 升级等级操作 ===

func get_upgrade_level(upgrade_id: String) -> int:
	return save_data.upgrade_levels.get(upgrade_id, 0)

func set_upgrade_level(upgrade_id: String, level: int):
	save_data.upgrade_levels[upgrade_id] = level
	save_game()

func increment_upgrade_level(upgrade_id: String) -> int:
	var current = get_upgrade_level(upgrade_id)
	set_upgrade_level(upgrade_id, current + 1)
	return current + 1

# === 统计数据操作 ===

func update_statistic(stat_name: String, value, mode: String = "add"):
	if not save_data.statistics.has(stat_name):
		save_data.statistics[stat_name] = 0

	match mode:
		"add":
			save_data.statistics[stat_name] += value
		"set":
			save_data.statistics[stat_name] = value
		"max":
			save_data.statistics[stat_name] = max(save_data.statistics[stat_name], value)
		"min":
			if save_data.statistics[stat_name] == 0:
				save_data.statistics[stat_name] = value
			else:
				save_data.statistics[stat_name] = min(save_data.statistics[stat_name], value)

func get_statistic(stat_name: String):
	return save_data.statistics.get(stat_name, 0)

func record_run_end(won: bool, character_id: int, stats: Dictionary):
	# 记录一局游戏结束的统计
	update_statistic("total_runs", 1, "add")
	if won:
		update_statistic("successful_runs", 1, "add")

	# 角色统计
	var char_id_str = str(character_id)
	if not save_data.statistics.character_runs.has(char_id_str):
		save_data.statistics.character_runs[char_id_str] = 0
	save_data.statistics.character_runs[char_id_str] += 1

	if won:
		if not save_data.statistics.character_wins.has(char_id_str):
			save_data.statistics.character_wins[char_id_str] = 0
		save_data.statistics.character_wins[char_id_str] += 1

	# 其他统计
	update_statistic("total_kills", stats.get("kills", 0), "add")
	update_statistic("total_damage_dealt", stats.get("damage_dealt", 0), "add")
	update_statistic("total_damage_taken", stats.get("damage_taken", 0), "add")
	update_statistic("total_xp_gained", stats.get("xp_gained", 0), "add")
	update_statistic("total_gold_earned", stats.get("gold_earned", 0), "add")
	update_statistic("highest_level_reached", stats.get("level_reached", 0), "max")
	update_statistic("longest_survival_time", stats.get("survival_time", 0), "max")
	update_statistic("bosses_defeated", stats.get("bosses_defeated", 0), "add")

	save_game()

# === 解锁操作 ===

func is_unlocked(unlock_id: String) -> bool:
	return save_data.unlocks.get(unlock_id, false)

func unlock(unlock_id: String):
	save_data.unlocks[unlock_id] = true
	save_game()
	print("[GameSaveManager] 解锁: " + unlock_id)

# === 设置操作 ===

func get_setting(key: String, default_value = null):
	return save_data.settings.get(key, default_value)

func set_setting(key: String, value):
	save_data.settings[key] = value
	# 不立即保存，等待apply时统一保存
