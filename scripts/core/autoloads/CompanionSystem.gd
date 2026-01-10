extends Node

## CompanionSystem - 同伴系统
## 管理同伴招募、跟随和战斗支援

# 同伴状态枚举
enum CompanionState {
	IDLE,           # 空闲（在家或其他地方）
	FOLLOWING,      # 跟随中
	COMBAT,         # 战斗中
	UNAVAILABLE     # 不可用（日程冲突）
}

# 同伴数据类
class CompanionData:
	var npc_id: String
	var is_recruited: bool = false
	var is_in_party: bool = false
	var state: CompanionState = CompanionState.IDLE

	# 战斗属性
	var max_hp: float = 100.0
	var current_hp: float = 100.0
	var attack: float = 10.0
	var defense: float = 5.0
	var skills: Array[String] = []

	func _init(id: String):
		npc_id = id

# 所有同伴
var companions: Dictionary = {}  # npc_id -> CompanionData

# 当前激活的同伴（最多1个）
var active_companion: String = ""

# 最大同伴数量
const MAX_COMPANIONS_IN_PARTY = 1

func _ready():
	# 监听羁绊解锁
	if SignalBus.has_signal("companion_unlocked"):
		SignalBus.companion_unlocked.connect(_on_companion_unlocked)

	print("[CompanionSystem] 同伴系统已初始化")

## 羁绊解锁同伴
func _on_companion_unlocked(npc_id: String) -> void:
	recruit_companion(npc_id)

## 招募同伴
func recruit_companion(npc_id: String) -> bool:
	if companions.has(npc_id):
		if companions[npc_id].is_recruited:
			print("[CompanionSystem] %s 已经被招募过了" % npc_id)
			return false

	# 创建同伴数据
	var companion = CompanionData.new(npc_id)
	companion.is_recruited = true

	# 根据NPC设置初始属性
	_setup_companion_stats(companion)

	companions[npc_id] = companion

	SignalBus.companion_recruited.emit(npc_id)
	print("[CompanionSystem] ✨ 成功招募同伴: %s" % npc_id)

	return true

## 设置同伴属性
func _setup_companion_stats(companion: CompanionData) -> void:
	match companion.npc_id:
		"keine":
			companion.max_hp = 150.0
			companion.current_hp = 150.0
			companion.attack = 15.0
			companion.defense = 10.0
			companion.skills = ["history_beam", "protective_aura"]
		"reimu":
			companion.max_hp = 120.0
			companion.current_hp = 120.0
			companion.attack = 20.0
			companion.defense = 8.0
			companion.skills = ["spirit_seal", "fantasy_seal"]
		_:
			companion.max_hp = 100.0
			companion.current_hp = 100.0
			companion.attack = 10.0
			companion.defense = 5.0

## 邀请同伴加入队伍
func add_to_party(npc_id: String) -> bool:
	if not companions.has(npc_id):
		push_warning("[CompanionSystem] NPC %s 未被招募" % npc_id)
		return false

	var companion = companions[npc_id]

	if not companion.is_recruited:
		push_warning("[CompanionSystem] NPC %s 未被招募" % npc_id)
		return false

	# 检查是否已满员
	if active_companion != "" and active_companion != npc_id:
		push_warning("[CompanionSystem] 已有同伴跟随，请先解散当前同伴")
		return false

	# 检查NPC是否可用（日程冲突）
	if NPCScheduleManager and not NPCScheduleManager.is_npc_interruptible(npc_id):
		push_warning("[CompanionSystem] %s 当前不可用（有其他安排）" % npc_id)
		companion.state = CompanionState.UNAVAILABLE
		return false

	# 加入队伍
	companion.is_in_party = true
	companion.state = CompanionState.FOLLOWING
	active_companion = npc_id

	SignalBus.companion_joined_party.emit(npc_id)
	print("[CompanionSystem] %s 加入了队伍" % npc_id)

	return true

## 同伴离开队伍
func remove_from_party(npc_id: String) -> bool:
	if not companions.has(npc_id):
		return false

	var companion = companions[npc_id]

	if not companion.is_in_party:
		return false

	companion.is_in_party = false
	companion.state = CompanionState.IDLE

	if active_companion == npc_id:
		active_companion = ""

	SignalBus.companion_left_party.emit(npc_id)
	print("[CompanionSystem] %s 离开了队伍" % npc_id)

	return true

## 获取当前同伴
func get_active_companion() -> CompanionData:
	if active_companion != "" and companions.has(active_companion):
		return companions[active_companion]
	return null

## 同伴受伤
func damage_companion(npc_id: String, damage: float) -> void:
	if not companions.has(npc_id):
		return

	var companion = companions[npc_id]
	var old_hp = companion.current_hp
	companion.current_hp = maxf(companion.current_hp - damage, 0.0)

	SignalBus.companion_hp_changed.emit(npc_id, companion.current_hp, companion.max_hp)

	if companion.current_hp <= 0.0:
		_companion_downed(npc_id)

## 同伴倒下
func _companion_downed(npc_id: String) -> void:
	print("[CompanionSystem] %s 倒下了！" % npc_id)
	remove_from_party(npc_id)

	# TODO: 触发特殊剧情或对话

## 同伴治疗
func heal_companion(npc_id: String, amount: float) -> void:
	if not companions.has(npc_id):
		return

	var companion = companions[npc_id]
	companion.current_hp = minf(companion.current_hp + amount, companion.max_hp)

	SignalBus.companion_hp_changed.emit(npc_id, companion.current_hp, companion.max_hp)

## 检查同伴是否被招募
func is_recruited(npc_id: String) -> bool:
	if companions.has(npc_id):
		return companions[npc_id].is_recruited
	return false

## 检查同伴是否在队伍中
func is_in_party(npc_id: String) -> bool:
	if companions.has(npc_id):
		return companions[npc_id].is_in_party
	return false

## 保存数据
func get_save_data() -> Dictionary:
	var data = {
		"active_companion": active_companion,
		"companions": {}
	}

	for npc_id in companions:
		var companion = companions[npc_id]
		data.companions[npc_id] = {
			"is_recruited": companion.is_recruited,
			"is_in_party": companion.is_in_party,
			"current_hp": companion.current_hp
		}

	return data

## 读取数据
func load_save_data(data: Dictionary) -> void:
	active_companion = data.get("active_companion", "")

	var companions_data = data.get("companions", {})
	for npc_id in companions_data:
		if not companions.has(npc_id):
			var companion = CompanionData.new(npc_id)
			_setup_companion_stats(companion)
			companions[npc_id] = companion

		var companion = companions[npc_id]
		var comp_data = companions_data[npc_id]

		companion.is_recruited = comp_data.get("is_recruited", false)
		companion.is_in_party = comp_data.get("is_in_party", false)
		companion.current_hp = comp_data.get("current_hp", companion.max_hp)

		if companion.is_in_party:
			companion.state = CompanionState.FOLLOWING

	print("[CompanionSystem] 已读取同伴数据")
