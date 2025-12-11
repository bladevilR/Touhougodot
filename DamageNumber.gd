extends Label

# DamageNumber - 浮动伤害数字显示

var velocity: Vector2 = Vector2(0, -50)  # 向上飘
var lifetime: float = 0.0
var max_lifetime: float = 1.0
var is_active: bool = false

func _ready():
	visible = false
	is_active = false

	# 设置标签样式
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# 添加描边效果
	add_theme_constant_override("outline_size", 2)
	add_theme_color_override("font_outline_color", Color.BLACK)

func start_damage_number(damage: float, pos: Vector2, is_critical: bool = false):
	"""显示伤害数字
	damage: 伤害值
	pos: 显示位置
	is_critical: 是否暴击
	"""
	is_active = true
	visible = true
	global_position = pos
	lifetime = 0.0

	# 设置文本
	text = str(int(damage))

	# 暴击使用更大字体和特殊颜色
	if is_critical:
		add_theme_font_size_override("font_size", 32)
		add_theme_color_override("font_color", Color.ORANGE)
		max_lifetime = 1.2
		velocity = Vector2(randf_range(-20, 20), -80)
	else:
		add_theme_font_size_override("font_size", 20)
		add_theme_color_override("font_color", Color.WHITE)
		max_lifetime = 1.0
		velocity = Vector2(randf_range(-10, 10), -50)

func _process(delta):
	if not is_active:
		return

	lifetime += delta

	# 检查生命周期
	if lifetime >= max_lifetime:
		is_active = false
		visible = false
		return

	# 计算进度
	var progress = lifetime / max_lifetime

	# 更新透明度（淡出）
	modulate.a = 1.0 - progress

	# 更新位置
	global_position += velocity * delta

	# 速度衰减
	velocity.y += 50.0 * delta  # 轻微减速
