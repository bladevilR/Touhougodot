extends Node

# CameraShake - 屏幕震动效果
# 原项目实现：GameCanvas.tsx line 648-660

var camera: Camera2D = null

# Shake state
var shake_duration: float = 0.0
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _ready():
	# Get parent Camera2D
	if get_parent() is Camera2D:
		camera = get_parent()

	# Connect to shake signals
	SignalBus.screen_shake.connect(_on_screen_shake)

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta

		# Calculate shake offset with decay
		var progress = shake_timer / shake_duration
		var current_intensity = shake_intensity * progress

		# Random shake offset
		var shake_x = randf_range(-current_intensity, current_intensity)
		var shake_y = randf_range(-current_intensity, current_intensity)

		# Apply to camera
		if camera:
			camera.offset = Vector2(shake_x, shake_y)
	else:
		# Reset camera offset when shake ends
		if camera and camera.offset != Vector2.ZERO:
			camera.offset = Vector2.ZERO

func _on_screen_shake(duration: float, intensity: float):
	"""触发屏幕震动
	duration: 震动持续时间（秒）
	intensity: 震动强度（像素）
	"""
	# 原项目：screenShakeRef.current.duration = Math.max(screenShakeRef.current.duration, duration)
	# 如果新的震动更长，延长持续时间；如果强度更大，使用更大的强度
	shake_duration = max(shake_duration, duration)
	shake_intensity = max(shake_intensity, intensity)
	shake_timer = shake_duration

func trigger_shake(duration: float, intensity: float):
	"""手动触发震动（兼容直接调用）"""
	_on_screen_shake(duration, intensity)
