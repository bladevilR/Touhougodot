extends Node

# ExperienceManager - 经验/升级管理器
# 这是一个纯逻辑节点，负责计算"杀怪 -> 加经验 -> 升级"

var current_level = 1
var current_xp = 0
var xp_required = 100

func _ready():
	# 监听怪物的死亡信号
	SignalBus.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(xp_amount, _pos):
	gain_xp(xp_amount)

func gain_xp(amount):
	current_xp += amount

	# 检查升级
	while current_xp >= xp_required:
		current_xp -= xp_required
		level_up()

	# 通知 UI 更新
	SignalBus.xp_gained.emit(current_xp, xp_required, current_level)

func level_up():
	current_level += 1
	xp_required = int(xp_required * 1.5) # 简单的升级曲线

	# 通知全世界：升级了！
	# 玩家脚本听到了可以回满血，UI听到了可以弹窗，武器系统听到了可以重置CD
	SignalBus.level_up.emit(current_level)
	print("升级到 Lv.", current_level, "！需要经验: ", xp_required)
