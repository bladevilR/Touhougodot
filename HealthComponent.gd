extends Node
class_name HealthComponent

# HealthComponent - 生命值组件
# 这是解耦的神器。无论是玩家、敌人、还是可破坏的箱子，只要挂上这个，就有血条逻辑

@export var max_hp: float = 100.0
var current_hp: float

# 组件内部信号
signal died
signal health_changed(new_hp)

func _ready():
	current_hp = max_hp

func damage(amount: float):
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)

	emit_signal("health_changed", current_hp)

	# 如果是玩家，顺便通知全局总线（解耦的关键！）
	# 这样 UI 系统只需要听 SignalBus，不需要知道 Player 是谁
	if get_parent().is_in_group("player"):
		SignalBus.player_health_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		emit_signal("died")

func heal(amount: float):
	current_hp += amount
	current_hp = clamp(current_hp, 0, max_hp)

	emit_signal("health_changed", current_hp)

	if get_parent().is_in_group("player"):
		SignalBus.player_health_changed.emit(current_hp, max_hp)
