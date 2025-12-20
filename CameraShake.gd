extends Node

# CameraShake - 高级屏幕震动与反馈系统
# 支持随机震动、定向冲击、屏幕闪光

var camera: Camera2D = null

# Random Shake state
var shake_duration: float = 0.0
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

# Directional Shake state
var directional_offset: Vector2 = Vector2.ZERO
var directional_decay: float = 5.0

# Screen Flash state
var flash_rect: ColorRect = null
var flash_timer: float = 0.0
var flash_duration: float = 0.0
var flash_color: Color = Color.TRANSPARENT

func _ready():
	# Get parent Camera2D
	if get_parent() is Camera2D:
		camera = get_parent()

	# Connect to shake signals
	SignalBus.screen_shake.connect(_on_screen_shake)
	SignalBus.directional_shake.connect(_on_directional_shake)
	SignalBus.screen_flash.connect(_on_screen_flash)
	
	_create_flash_layer()

func _create_flash_layer():
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # Top layer
	add_child(canvas)
	
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(0, 0, 0, 0)
	canvas.add_child(flash_rect)

func _process(delta):
	var final_offset = Vector2.ZERO

	# 1. Random Shake (Noise)
	if shake_timer > 0:
		shake_timer -= delta
		var progress = shake_timer / shake_duration
		var current_intensity = shake_intensity * progress

		# High frequency jitter
		final_offset += Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)

	# 2. Directional Shake (Impact recoil)
	if directional_offset.length_squared() > 0.1:
		# Decay back to zero
		directional_offset = directional_offset.lerp(Vector2.ZERO, directional_decay * delta)
		final_offset += directional_offset

	# Apply to camera
	if camera:
		camera.offset = final_offset

	# 3. Screen Flash
	if flash_timer > 0:
		flash_timer -= delta
		var alpha = flash_timer / flash_duration
		# Keep color, fade alpha
		if flash_rect:
			flash_rect.color = Color(flash_color.r, flash_color.g, flash_color.b, flash_color.a * alpha)
	else:
		if flash_rect and flash_rect.color.a > 0:
			flash_rect.color = Color(0,0,0,0)

func _on_screen_shake(duration: float, intensity: float):
	"""触发随机震动 (受击/爆炸) - 行业成熟的打击感方案"""
	# 如果正在震动，叠加新的震动（不覆盖）
	if shake_timer > 0.0:
		# 计算叠加权重：新震动占70%，旧震动占30%
		var weight_new = 0.7
		var weight_old = 0.3
		shake_duration = max(shake_duration * weight_old + duration * weight_new, 0.1)
		shake_intensity = max(shake_intensity * weight_old + intensity * weight_new, 0.1)
	else:
		shake_duration = max(duration, 0.05)  # 最小震动时间
		shake_intensity = max(intensity, 0.5)  # 最小震动强度

	shake_timer = shake_duration

func _on_directional_shake(direction: Vector2, force: float, duration: float):
	"""触发定向震动 (飞踢/冲撞)"""
	# 立即偏移，然后回弹
	directional_offset = direction.normalized() * force
	# Decay speed depends on duration (approx)
	directional_decay = 4.0 / max(duration, 0.1)

func _on_screen_flash(color: Color, duration: float):
	"""触发屏幕闪光 (受击泛红)"""
	flash_color = color
	flash_duration = duration
	flash_timer = duration

func trigger_shake(duration: float, intensity: float):
	"""手动触发震动"""
	_on_screen_shake(duration, intensity)
