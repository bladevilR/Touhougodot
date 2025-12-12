extends Node

# ExperienceManager - 经验/升级管理器
# 这是一个纯逻辑节点，负责计算"捡经验球 -> 加经验 -> 升级"

var current_level = 1
var current_xp = 0
var xp_required = 100

# 预加载经验球场景
var gem_scene = preload("res://ExperienceGem.tscn")

func _ready():
	# 监听怪物的死亡信号，生成经验球
	SignalBus.enemy_killed.connect(_on_enemy_killed)
	# 监听经验球拾取信号
	SignalBus.xp_pickup.connect(_on_xp_pickup)

func _on_enemy_killed(xp_amount, pos):
	# 在怪物死亡位置生成经验球
	spawn_gem(xp_amount, pos)

func spawn_gem(xp_amount: int, pos: Vector2):
	"""在指定位置生成经验球"""
	var gem = gem_scene.instantiate()
	gem.xp_value = xp_amount
	gem.global_position = pos

	# 添加到当前场景
	get_tree().current_scene.call_deferred("add_child", gem)

func _on_xp_pickup(xp_amount: int):
	"""拾取经验球时调用"""
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
