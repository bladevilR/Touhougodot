extends Node2D

## VillageCenter - 人之里中心
## 社交枢纽，任务中心，NPC动态出现的地方

# NPC节点容器
@onready var npc_container: Node2D = $NPCContainer if has_node("NPCContainer") else null

# 当前场景中的NPC
var active_npcs: Dictionary = {}

func _ready():
	name = "VillageCenter"

	# 切换到主世界模式
	GameStateManager.change_mode(GameStateManager.GameMode.OVERWORLD)

	print("[VillageCenter] 进入人之里中心")

	# 监听时间变化，动态生成/移除NPC
	if SignalBus.has_signal("hour_changed"):
		SignalBus.hour_changed.connect(_on_hour_changed)

	# 初始化时刷新一次NPC
	_refresh_npcs()

	# 设置场景传送
	_setup_scene_transitions()

## 每小时刷新NPC
func _on_hour_changed(_hour: int) -> void:
	_refresh_npcs()

## 刷新场景中的NPC
func _refresh_npcs() -> void:
	if not npc_container:
		return

	var current_hour = TimeManager.current_hour if TimeManager else 12

	# 定义哪些NPC在什么时段出现在人之里中心
	var npc_schedule = {
		"marisa": {
			"time_ranges": [[10, 12], [15, 17]],  # 10-12点和15-17点
			"position": Vector2(200, 300),
			"scene_path": "res://scenes/npcs/MarisaNPC.tscn"
		},
		"sakuya": {
			"time_ranges": [[9, 11]],  # 9-11点买菜
			"position": Vector2(400, 300),
			"scene_path": "res://scenes/npcs/SakuyaNPC.tscn"
		},
		"keine": {
			"time_ranges": [[17, 19]],  # 17-19点散步
			"position": Vector2(300, 250),
			"scene_path": "res://scenes/npcs/KeineNPC.tscn"
		},
		"koishi": {  # 恋恋（雨天全天）
			"time_ranges": [[0, 24]],  # 全天，但需要雨天
			"position": Vector2(100, 400),
			"scene_path": "res://scenes/npcs/KoishiNPC.tscn",
			"weather_condition": "rain"
		}
	}

	# 移除不应该出现的NPC
	for npc_id in active_npcs.keys():
		var should_appear = _should_npc_appear(npc_id, npc_schedule, current_hour)
		if not should_appear:
			_remove_npc(npc_id)

	# 添加应该出现的NPC
	for npc_id in npc_schedule:
		var should_appear = _should_npc_appear(npc_id, npc_schedule, current_hour)
		if should_appear and not active_npcs.has(npc_id):
			_spawn_npc(npc_id, npc_schedule[npc_id])

## 检查NPC是否应该出现
func _should_npc_appear(npc_id: String, schedule: Dictionary, hour: int) -> bool:
	if not schedule.has(npc_id):
		return false

	var npc_data = schedule[npc_id]

	# 检查天气条件
	if npc_data.has("weather_condition"):
		# TODO: 检查天气系统
		# 这里暂时假设不是雨天，所以恋恋不会出现
		return false

	# 检查时间范围
	for time_range in npc_data.time_ranges:
		var start = time_range[0]
		var end = time_range[1]

		if end < start:  # 跨夜
			if hour >= start or hour < end:
				return true
		else:
			if hour >= start and hour < end:
				return true

	return false

## 生成NPC
func _spawn_npc(npc_id: String, npc_data: Dictionary) -> void:
	if not npc_container:
		return

	# TODO: 实际加载NPC场景
	# 这里简化处理，只记录
	active_npcs[npc_id] = npc_data
	print("[VillageCenter] %s 出现在人之里中心" % npc_id)

	# 实际实现时需要：
	# var npc_scene = load(npc_data.scene_path)
	# var npc_instance = npc_scene.instantiate()
	# npc_instance.position = npc_data.position
	# npc_container.add_child(npc_instance)
	# active_npcs[npc_id] = npc_instance

## 移除NPC
func _remove_npc(npc_id: String) -> void:
	if active_npcs.has(npc_id):
		# TODO: 实际移除NPC节点
		# active_npcs[npc_id].queue_free()
		active_npcs.erase(npc_id)
		print("[VillageCenter] %s 离开了人之里中心" % npc_id)

## 设置场景传送
func _setup_scene_transitions() -> void:
	# 回竹林小屋
	var to_bamboo = get_node_or_null("ToBambooHouse")
	if to_bamboo and to_bamboo is Area2D:
		to_bamboo.body_entered.connect(_on_to_bamboo_entered)

	# 去寺子屋
	var to_school = get_node_or_null("ToTempleSchool")
	if to_school and to_school is Area2D:
		to_school.body_entered.connect(_on_to_school_entered)

	# 去博丽神社
	var to_shrine = get_node_or_null("ToHakureiShrine")
	if to_shrine and to_shrine is Area2D:
		to_shrine.body_entered.connect(_on_to_shrine_entered)

func _on_to_bamboo_entered(body: Node2D) -> void:
	if body.name == "Player":
		SceneManager.change_scene("res://scenes/home/BambooHouse.tscn")

func _on_to_school_entered(body: Node2D) -> void:
	if body.name == "Player":
		SceneManager.change_scene("res://scenes/overworld/village/TempleSchool.tscn")

func _on_to_shrine_entered(body: Node2D) -> void:
	if body.name == "Player":
		SceneManager.change_scene("res://scenes/overworld/shrine/HakureiShrine.tscn")
