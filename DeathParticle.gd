extends Sprite2D

# DeathParticle - 单个死亡粒子
# 原项目实现：使用pixi-particles库，配置alpha、color、moveSpeed、rotation

var is_active: bool = false
var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 0.0
var max_lifetime: float = 0.5

func _ready():
	# 创建简单的圆形纹理
	if not texture:
		var image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
		for x in range(8):
			for y in range(8):
				var dist = Vector2(x - 4, y - 4).length()
				if dist < 4:
					var alpha = 1.0 - (dist / 4.0)
					image.set_pixel(x, y, Color(1, 1, 1, alpha))
		texture = ImageTexture.create_from_image(image)

	visible = false
	is_active = false

func start_particle(vel: Vector2, life: float):
	"""启动粒子
	vel: 初始速度
	life: 生命周期
	"""
	is_active = true
	visible = true
	velocity = vel
	max_lifetime = life
	lifetime = 0.0
	scale = Vector2(1.0, 1.0)
	rotation = randf() * TAU

func _process(delta):
	if not is_active:
		return

	lifetime += delta

	# 检查生命周期
	if lifetime >= max_lifetime:
		is_active = false
		visible = false
		return

	# 计算进度（0 -> 1）
	var progress = lifetime / max_lifetime

	# 更新透明度（淡出）
	# 原项目：alpha: { time: 0, value: 1 } -> { time: 1, value: 0 }
	modulate.a = 1.0 - progress

	# 更新颜色（从原色 -> 白色 -> 灰色）
	# 原项目：color: time:0=original, time:0.5=white, time:1=gray
	if progress < 0.5:
		var t = progress * 2.0
		modulate = modulate.lerp(Color.WHITE, t)
	else:
		var t = (progress - 0.5) * 2.0
		modulate = Color.WHITE.lerp(Color.GRAY, t)
		modulate.a = 1.0 - progress  # 保持透明度

	# 更新速度（减速）
	# 原项目：speed: { time: 0, value: 300 } -> { time: 1, value: 0 }
	var current_speed = velocity.length() * (1.0 - progress)
	var direction = velocity.normalized()
	velocity = direction * current_speed

	# 更新位置
	global_position += velocity * delta

	# 旋转
	rotation += delta * 5.0

	# 缩放（略微缩小）
	var scale_factor = 1.0 - progress * 0.5
	scale = Vector2(scale_factor, scale_factor)
