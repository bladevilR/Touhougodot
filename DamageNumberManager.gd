extends CanvasLayer

# DamageNumberManager - 管理浮动伤害数字
# 限制最多显示20个伤害数字，使用对象池

var damage_number_scene = preload("res://DamageNumber.tscn")
var damage_number_pool: Array = []
const MAX_DAMAGE_NUMBERS: int = 20

func _ready():
	# 监听伤害信号
	SignalBus.damage_dealt.connect(_on_damage_dealt)

func _on_damage_dealt(damage: float, pos: Vector2, is_critical: bool, weapon_id: String = ""):
	"""显示伤害数字"""
	var damage_number = _get_damage_number_from_pool()
	if not damage_number:
		return

	damage_number.start_damage_number(damage, pos, is_critical)

func _get_damage_number_from_pool() -> Label:
	"""从对象池获取伤害数字"""
	# 查找未激活的伤害数字
	for num in damage_number_pool:
		if is_instance_valid(num) and not num.is_active:
			return num

	# 对象池已满，跳过
	if damage_number_pool.size() >= MAX_DAMAGE_NUMBERS:
		return null

	# 创建新伤害数字
	var num = damage_number_scene.instantiate()
	add_child(num)
	damage_number_pool.append(num)
	return num
