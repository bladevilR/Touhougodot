extends Node
## 玩法协调器 - 统一协调游戏系统的交互
##
## 职责:
## - 监听SignalBus的核心游戏事件
## - 协调RoomManager、WaveManager、EnemySpawner的交互
## - 处理游戏开始、胜利、失败逻辑
## - 触发场景切换
## - 管理游戏流程状态机
##
## 使用说明:
##   GameplaySystem会自动在游戏启动时初始化
##   无需手动调用，通过SignalBus触发即可

# 游戏状态枚举
enum GameState {
	IDLE,           # 空闲（主菜单）
	LOADING,        # 加载中
	PLAYING,        # 游戏进行中
	PAUSED,         # 暂停
	GAME_OVER,      # 游戏结束
	VICTORY         # 胜利
}

# 当前游戏状态
var current_state: GameState = GameState.IDLE

# 游戏统计
var game_start_time: float = 0.0
var total_enemies_killed: int = 0
var total_damage_dealt: float = 0.0
var rooms_cleared: int = 0

func _ready():
	print("GameplaySystem: 初始化中...")
	_connect_signals()
	print("GameplaySystem: 初始化完成")

## 连接所有游戏事件信号
func _connect_signals() -> void:
	# 游戏生命周期
	SignalBus.game_started.connect(_on_game_started)
	SignalBus.game_paused.connect(_on_game_paused)
	SignalBus.game_resumed.connect(_on_game_resumed)

	# 玩家事件
	SignalBus.player_died.connect(_on_player_died)
	SignalBus.player_leveled_up.connect(_on_player_leveled_up)

	# 房间和波次
	SignalBus.room_entered.connect(_on_room_entered)
	SignalBus.room_cleared.connect(_on_room_cleared)
	SignalBus.wave_started.connect(_on_wave_started)
	SignalBus.all_waves_completed.connect(_on_all_waves_completed)

	# 敌人事件
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	SignalBus.boss_spawned.connect(_on_boss_spawned)
	SignalBus.boss_defeated.connect(_on_boss_defeated)

	# 战斗事件
	SignalBus.damage_dealt.connect(_on_damage_dealt)

	print("GameplaySystem: 已连接 %d 个信号" % 13)

## 游戏开始
func _on_game_started() -> void:
	print("GameplaySystem: 游戏开始")
	current_state = GameState.PLAYING

	# 重置统计
	game_start_time = Time.get_ticks_msec() / 1000.0
	total_enemies_killed = 0
	total_damage_dealt = 0.0
	rooms_cleared = 0

	# 可以在这里添加游戏开始时的初始化逻辑
	# 例如：生成第一个房间、播放开场音乐等

## 游戏暂停
func _on_game_paused() -> void:
	print("GameplaySystem: 游戏暂停")
	current_state = GameState.PAUSED
	get_tree().paused = true

	# 暂停所有音频
	if AudioManager:
		AudioManager.pause_all()

## 游戏恢复
func _on_game_resumed() -> void:
	print("GameplaySystem: 游戏恢复")
	current_state = GameState.PLAYING
	get_tree().paused = false

	# 恢复所有音频
	if AudioManager:
		AudioManager.resume_all()

## 玩家死亡
func _on_player_died() -> void:
	print("GameplaySystem: 玩家死亡")
	current_state = GameState.GAME_OVER

	# 延迟显示游戏结束界面
	await get_tree().create_timer(1.5).timeout

	# 保存游戏统计
	_save_game_statistics()

	# 切换到游戏结束场景
	if SceneManager:
		SceneManager.change_scene(SceneManager.Scene.GAME_OVER, "", "fade", 1.0)

## 玩家升级
func _on_player_leveled_up(new_level: int) -> void:
	print("GameplaySystem: 玩家升级到 Lv.%d" % new_level)

	# 可以在这里添加升级奖励逻辑
	# 例如：播放升级特效、显示升级选择界面等

## 进入房间
func _on_room_entered(room_type: int, room_index: int) -> void:
	print("GameplaySystem: 进入房间 #%d (类型: %d)" % [room_index, room_type])

	# 根据房间类型播放不同的音乐
	# if AudioManager:
	#     match room_type:
	#         0: AudioManager.play_music("res://assets/music/battle.ogg")
	#         1: AudioManager.play_music("res://assets/music/boss.ogg")

## 房间清理完成
func _on_room_cleared() -> void:
	print("GameplaySystem: 房间清理完成")
	rooms_cleared += 1

	# 可以在这里添加房间清理奖励
	# 例如：掉落道具、恢复生命值等

## 波次开始
func _on_wave_started(wave_number: int, enemy_count: int) -> void:
	print("GameplaySystem: 波次 %d 开始 (敌人数: %d)" % [wave_number, enemy_count])

## 所有波次完成
func _on_all_waves_completed() -> void:
	print("GameplaySystem: 所有波次完成")

	# 这里可以触发房间清理逻辑
	SignalBus.room_cleared.emit()

## 敌人被杀死
func _on_enemy_killed(enemy: Node2D, xp_value: int, position: Vector2) -> void:
	total_enemies_killed += 1

	# 可以在这里添加击杀特效、掉落经验值等逻辑

## Boss生成
func _on_boss_spawned(boss_name: String, boss_hp: float, boss_max_hp: float) -> void:
	print("GameplaySystem: Boss '%s' 出现了！(血量: %.0f/%.0f)" % [boss_name, boss_hp, boss_max_hp])

	# 播放Boss音乐
	# if AudioManager:
	#     AudioManager.play_music("res://assets/music/boss_battle.ogg", 1.0)

	# 显示Boss警告界面
	# SignalBus.show_boss_warning.emit(boss_name)

## Boss被击败
func _on_boss_defeated(boss_name: String) -> void:
	print("GameplaySystem: Boss '%s' 被击败了！" % boss_name)
	current_state = GameState.VICTORY

	# 延迟显示胜利界面
	await get_tree().create_timer(2.0).timeout

	# 保存游戏统计
	_save_game_statistics()

	# 切换到胜利场景
	if SceneManager:
		SceneManager.change_scene(SceneManager.Scene.VICTORY, "", "fade", 1.0)

## 伤害造成
func _on_damage_dealt(damage: float, position: Vector2, is_critical: bool, weapon_id: String = "") -> void:
	total_damage_dealt += damage

## 保存游戏统计
func _save_game_statistics() -> void:
	var game_duration = (Time.get_ticks_msec() / 1000.0) - game_start_time

	var statistics = {
		"duration": game_duration,
		"enemies_killed": total_enemies_killed,
		"damage_dealt": total_damage_dealt,
		"rooms_cleared": rooms_cleared,
		"timestamp": Time.get_datetime_dict_from_system()
	}

	print("GameplaySystem: 游戏统计:")
	print("  - 游戏时长: %.2f 秒" % game_duration)
	print("  - 击杀敌人: %d" % total_enemies_killed)
	print("  - 总伤害: %.0f" % total_damage_dealt)
	print("  - 清理房间: %d" % rooms_cleared)

	# 可以在这里将统计数据保存到GameSaveManager
	# if GameSaveManager:
	#     GameSaveManager.save_run_statistics(statistics)

## 获取当前游戏状态
func get_game_state() -> GameState:
	return current_state

## 获取游戏时长
func get_game_duration() -> float:
	if current_state == GameState.PLAYING:
		return (Time.get_ticks_msec() / 1000.0) - game_start_time
	else:
		return 0.0

## 获取游戏统计
func get_game_statistics() -> Dictionary:
	return {
		"state": current_state,
		"duration": get_game_duration(),
		"enemies_killed": total_enemies_killed,
		"damage_dealt": total_damage_dealt,
		"rooms_cleared": rooms_cleared
	}

## 强制结束游戏（用于调试或退出）
func force_end_game() -> void:
	print("GameplaySystem: 强制结束游戏")
	current_state = GameState.IDLE

	# 停止所有音频
	if AudioManager:
		AudioManager.stop_all()

	# 切换到主菜单
	if SceneManager:
		SceneManager.change_scene(SceneManager.Scene.MAIN_MENU, "", "fade", 0.5)
