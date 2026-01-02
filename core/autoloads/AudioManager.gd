extends Node
## 音频管理器 - 统一管理音乐和音效
##
## 功能:
## - 音乐播放和淡入淡出
## - 音效播放和音量控制
## - 音频池管理（避免创建过多AudioStreamPlayer）
## - BGM和SFX分离管理
##
## 使用示例:
##   # 播放音乐（带淡入）
##   AudioManager.play_music("res://assets/music/battle.ogg", 1.0)
##
##   # 播放音效
##   AudioManager.play_sfx("res://assets/sfx/shoot.wav")
##
##   # 设置音量
##   AudioManager.set_music_volume(0.7)

# 音乐播放器
var music_player: AudioStreamPlayer = null
var current_music_path: String = ""

# 音效播放器池
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_size: int = 10
var active_sfx_count: int = 0

# 音量设置
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8

# 音乐淡入淡出
var music_tween: Tween = null

func _ready():
	print("AudioManager: 初始化中...")
	_setup_music_player()
	_setup_sfx_pool()
	_load_volume_settings()
	print("AudioManager: 初始化完成")

## 设置音乐播放器
func _setup_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	add_child(music_player)

## 设置音效播放器池
func _setup_sfx_pool() -> void:
	for i in range(sfx_pool_size):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_%d" % i
		player.bus = "SFX"
		player.finished.connect(_on_sfx_finished.bind(player))
		add_child(player)
		sfx_players.append(player)

## 加载音量设置
func _load_volume_settings() -> void:
	if GameSettings:
		master_volume = GameSettings.master_volume
		music_volume = GameSettings.music_volume
		sfx_volume = GameSettings.sfx_volume

	_apply_volume_settings()

## 应用音量设置
func _apply_volume_settings() -> void:
	# 设置音频总线音量
	var master_bus_index = AudioServer.get_bus_index("Master")
	var music_bus_index = AudioServer.get_bus_index("Music")
	var sfx_bus_index = AudioServer.get_bus_index("SFX")

	if master_bus_index >= 0:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(master_volume))
	if music_bus_index >= 0:
		AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(music_volume))
	if sfx_bus_index >= 0:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sfx_volume))

## 播放音乐
## @param music_path: 音乐文件路径
## @param fade_in_duration: 淡入时长（秒）
## @param force_restart: 如果是同一首音乐，是否强制重新播放
func play_music(music_path: String, fade_in_duration: float = 0.0, force_restart: bool = false) -> void:
	# 如果是同一首音乐且不强制重启，不做任何操作
	if current_music_path == music_path and music_player.playing and not force_restart:
		return

	# 停止当前音乐淡入淡出
	if music_tween and music_tween.is_running():
		music_tween.kill()

	# 如果有音乐正在播放，先淡出
	if music_player.playing:
		await fade_out_music(0.3)

	# 加载新音乐
	var music_stream = ResourceManager.load_resource(music_path)
	if not music_stream:
		push_error("AudioManager: 无法加载音乐 '%s'" % music_path)
		return

	music_player.stream = music_stream
	current_music_path = music_path

	# 开始播放
	if fade_in_duration > 0:
		music_player.volume_db = linear_to_db(0.0)
		music_player.play()
		await fade_in_music(fade_in_duration)
	else:
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()

	print("AudioManager: 播放音乐 '%s'" % music_path)

## 停止音乐
## @param fade_out_duration: 淡出时长（秒）
func stop_music(fade_out_duration: float = 0.0) -> void:
	if fade_out_duration > 0:
		await fade_out_music(fade_out_duration)
	else:
		music_player.stop()

	current_music_path = ""

## 淡入音乐
func fade_in_music(duration: float) -> void:
	if music_tween and music_tween.is_running():
		music_tween.kill()

	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), duration)
	await music_tween.finished

## 淡出音乐
func fade_out_music(duration: float) -> void:
	if music_tween and music_tween.is_running():
		music_tween.kill()

	music_tween = create_tween()
	music_tween.tween_property(music_player, "volume_db", linear_to_db(0.0), duration)
	await music_tween.finished
	music_player.stop()

## 播放音效
## @param sfx_path: 音效文件路径
## @param volume_multiplier: 音量倍数（0.0 - 1.0）
## @param pitch_scale: 音调缩放（0.5 - 2.0）
func play_sfx(sfx_path: String, volume_multiplier: float = 1.0, pitch_scale: float = 1.0) -> void:
	# 从池中获取空闲的播放器
	var player = _get_available_sfx_player()
	if not player:
		push_warning("AudioManager: 音效播放器池已满，跳过播放 '%s'" % sfx_path)
		return

	# 加载音效
	var sfx_stream = ResourceManager.load_resource(sfx_path)
	if not sfx_stream:
		push_error("AudioManager: 无法加载音效 '%s'" % sfx_path)
		return

	# 设置并播放
	player.stream = sfx_stream
	player.volume_db = linear_to_db(sfx_volume * volume_multiplier)
	player.pitch_scale = pitch_scale
	player.play()

	active_sfx_count += 1

## 获取可用的音效播放器
func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

## 音效播放完成回调
func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	active_sfx_count = max(0, active_sfx_count - 1)
	player.stream = null

## 设置主音量
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()

	if GameSettings:
		GameSettings.master_volume = master_volume
		GameSettings.save_settings()

## 设置音乐音量
func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()

	if GameSettings:
		GameSettings.music_volume = music_volume
		GameSettings.save_settings()

## 设置音效音量
func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	_apply_volume_settings()

	if GameSettings:
		GameSettings.sfx_volume = sfx_volume
		GameSettings.save_settings()

## 暂停所有音频
func pause_all() -> void:
	music_player.stream_paused = true
	for player in sfx_players:
		if player.playing:
			player.stream_paused = true

## 恢复所有音频
func resume_all() -> void:
	music_player.stream_paused = false
	for player in sfx_players:
		player.stream_paused = false

## 停止所有音频
func stop_all() -> void:
	music_player.stop()
	for player in sfx_players:
		player.stop()

## 获取音频状态
func get_audio_status() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"music_playing": music_player.playing,
		"current_music": current_music_path,
		"active_sfx": active_sfx_count,
		"sfx_pool_available": sfx_players.size() - active_sfx_count
	}
