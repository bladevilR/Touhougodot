extends Node

# GameSettings - 游戏设置单例
# 自动加载到场景树，管理所有游戏设置

# 显示设置
var show_dps: bool = true
var show_room_map: bool = true

# 音频设置
var master_volume: float = 1.0  # 0.0 - 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var ui_sound_enabled: bool = true  # 按键音效

# 图像设置
var screen_shake_enabled: bool = true
var particle_quality: int = 2  # 0=低, 1=中, 2=高
var show_damage_numbers: bool = true  # 是否显示伤害数字（暴击感叹号）

# 设置文件路径
const SETTINGS_FILE = "user://game_settings.json"

func _ready():
	load_settings()

func load_settings():
	"""从文件加载设置"""
	if not FileAccess.file_exists(SETTINGS_FILE):
		print("[GameSettings] 使用默认设置")
		return

	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		if parse_result == OK:
			var data = json.data
			if data is Dictionary:
				# 加载显示设置
				show_dps = data.get("show_dps", true)
				show_room_map = data.get("show_room_map", true)

				# 加载音频设置
				master_volume = data.get("master_volume", 1.0)
				music_volume = data.get("music_volume", 0.8)
				sfx_volume = data.get("sfx_volume", 0.8)
				ui_sound_enabled = data.get("ui_sound_enabled", true)

				# 加载图像设置
				screen_shake_enabled = data.get("screen_shake_enabled", true)
				particle_quality = data.get("particle_quality", 2)
				show_damage_numbers = data.get("show_damage_numbers", true)

				print("[GameSettings] 设置加载成功")
		file.close()

	apply_settings()

func save_settings():
	"""保存设置到文件"""
	var data = {
		"show_dps": show_dps,
		"show_room_map": show_room_map,
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ui_sound_enabled": ui_sound_enabled,
		"screen_shake_enabled": screen_shake_enabled,
		"particle_quality": particle_quality,
		"show_damage_numbers": show_damage_numbers
	}

	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[GameSettings] 设置已保存")
	else:
		print("[GameSettings] 警告: 无法保存设置")

func apply_settings():
	"""应用设置到游戏（通过信号通知各个系统）"""
	# 发送设置更新信号
	SignalBus.settings_changed.emit()

	# 音量设置（如果有音频总线）
	var master_bus_idx = AudioServer.get_bus_index("Master")
	if master_bus_idx >= 0:
		AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(master_volume))

	print("[GameSettings] 设置已应用")

func toggle_dps_display():
	"""切换DPS显示"""
	show_dps = !show_dps
	SignalBus.settings_changed.emit()
	save_settings()

func toggle_map_display():
	"""切换地图显示"""
	show_room_map = !show_room_map
	SignalBus.settings_changed.emit()
	save_settings()

func set_master_volume(value: float):
	"""设置主音量"""
	master_volume = clamp(value, 0.0, 1.0)
	apply_settings()
	save_settings()

func set_ui_sound(enabled: bool):
	"""设置UI音效"""
	ui_sound_enabled = enabled
	save_settings()
