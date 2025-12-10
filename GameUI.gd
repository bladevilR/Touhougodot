extends CanvasLayer

# GameUI - 解耦后的 UI 系统
# 彻底不依赖 Player。哪怕场景里没有 Player，UI 也不会报错

@onready var hp_bar = $HealthBar # 血条节点
@onready var xp_bar = $ExpBar    # 经验条节点
@onready var level_label = $LevelLabel

func _ready():
	# UI 只监听总线，完全不知道 Player 的存在
	SignalBus.player_health_changed.connect(update_hp)
	SignalBus.xp_gained.connect(update_xp)
	SignalBus.level_up.connect(on_level_up)

func update_hp(current, max_val):
	if hp_bar:
		hp_bar.value = (current / max_val) * 100

func update_xp(current, max_val, level):
	if xp_bar:
		xp_bar.value = (float(current) / float(max_val)) * 100
	if level_label:
		level_label.text = "Lv." + str(level)

func on_level_up(new_level):
	# 这里可以弹出一个升级选择窗口
	print("UI: 升级到 Lv.", new_level, "！")
	# TODO: 显示升级选择窗口
