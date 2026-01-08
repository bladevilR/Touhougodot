extends RefCounted
class_name BulletFactory

## 弹幕工厂 - 简化弹幕创建和配置
## 提供统一的接口来生成各种类型的弹幕

# ==================== 弹幕预设 ====================
enum BulletPreset {
	BASIC,          # 基础弹
	FAST,           # 快速弹
	HEAVY,          # 重弹（高伤害）
	HOMING,         # 追踪弹
	EXPLOSIVE,      # 爆炸弹
	PIERCING,       # 穿透弹
	BOUNCING,       # 反弹弹
	SPREAD,         # 散射弹
	LASER,          # 激光
}

# 预设配置
const PRESETS = {
	BulletPreset.BASIC: {
		"speed": 400.0,
		"damage": 10.0,
		"lifetime": 5.0,
		"size": 1.0,
		"color": Color.WHITE,
	},
	BulletPreset.FAST: {
		"speed": 700.0,
		"damage": 8.0,
		"lifetime": 3.0,
		"size": 0.8,
		"color": Color.YELLOW,
	},
	BulletPreset.HEAVY: {
		"speed": 300.0,
		"damage": 25.0,
		"lifetime": 4.0,
		"size": 1.5,
		"color": Color.ORANGE_RED,
	},
	BulletPreset.HOMING: {
		"speed": 350.0,
		"damage": 12.0,
		"lifetime": 6.0,
		"size": 1.0,
		"color": Color.MAGENTA,
		"is_homing": true,
		"turn_speed": 3.0,
	},
	BulletPreset.EXPLOSIVE: {
		"speed": 350.0,
		"damage": 15.0,
		"lifetime": 4.0,
		"size": 1.2,
		"color": Color.RED,
		"is_explosive": true,
		"explosion_radius": 80.0,
	},
	BulletPreset.PIERCING: {
		"speed": 500.0,
		"damage": 12.0,
		"lifetime": 5.0,
		"size": 1.0,
		"color": Color.CYAN,
		"pierce_count": 3,
	},
	BulletPreset.BOUNCING: {
		"speed": 400.0,
		"damage": 10.0,
		"lifetime": 8.0,
		"size": 1.0,
		"color": Color.LIME_GREEN,
		"bounce_count": 3,
	},
	BulletPreset.SPREAD: {
		"speed": 380.0,
		"damage": 6.0,
		"lifetime": 3.0,
		"size": 0.7,
		"color": Color.LIGHT_BLUE,
	},
	BulletPreset.LASER: {
		"speed": 0.0,  # ��光不移动
		"damage": 30.0,
		"lifetime": 1.0,
		"size": 2.0,
		"color": Color.WHITE,
		"is_laser": true,
	},
}

# ==================== 弹幕创建 ====================
## 使用预设创建弹幕
static func create_bullet(bullet_scene: PackedScene, preset: int = BulletPreset.BASIC, overrides: Dictionary = {}) -> Node2D:
	var bullet = bullet_scene.instantiate()
	var config = PRESETS.get(preset, PRESETS[BulletPreset.BASIC]).duplicate()

	# 应用覆盖配置
	for key in overrides:
		config[key] = overrides[key]

	# 应用配置到弹幕
	_apply_config(bullet, config)

	return bullet

## 创建自定义配置弹幕
static func create_custom_bullet(bullet_scene: PackedScene, config: Dictionary) -> Node2D:
	var bullet = bullet_scene.instantiate()
	_apply_config(bullet, config)
	return bullet

## 应用配置到弹幕实例
static func _apply_config(bullet: Node2D, config: Dictionary) -> void:
	if "speed" in config and "speed" in bullet:
		bullet.speed = config.speed
	if "damage" in config and "damage" in bullet:
		bullet.damage = config.damage
	if "lifetime" in config and "lifetime" in bullet:
		bullet.lifetime = config.lifetime
	if "color" in config:
		bullet.modulate = config.color
	if "size" in config:
		bullet.scale = Vector2.ONE * config.size

	# 特殊属性
	if config.get("is_homing", false) and "is_homing" in bullet:
		bullet.is_homing = true
		if "turn_speed" in config and "turn_speed" in bullet:
			bullet.turn_speed = config.turn_speed

	if config.get("is_explosive", false) and "is_explosive" in bullet:
		bullet.is_explosive = true
		if "explosion_radius" in config and "explosion_radius" in bullet:
			bullet.explosion_radius = config.explosion_radius

	if "pierce_count" in config and "pierce_count" in bullet:
		bullet.pierce_count = config.pierce_count

	if "bounce_count" in config and "bounce_count" in bullet:
		bullet.bounce_count = config.bounce_count

# ==================== 批量生成 ====================
## 生成环形弹幕
static func spawn_ring(bullet_scene: PackedScene, position: Vector2, count: int, preset: int = BulletPreset.BASIC, overrides: Dictionary = {}) -> Array[Node2D]:
	var bullets: Array[Node2D] = []
	var angle_step = TAU / count

	for i in range(count):
		var bullet = create_bullet(bullet_scene, preset, overrides)
		bullet.global_position = position
		bullet.direction = Vector2.RIGHT.rotated(i * angle_step)
		bullets.append(bullet)

	return bullets

## 生成扇形弹幕
static func spawn_spread(bullet_scene: PackedScene, position: Vector2, direction: Vector2, count: int, spread_angle: float, preset: int = BulletPreset.BASIC, overrides: Dictionary = {}) -> Array[Node2D]:
	var bullets: Array[Node2D] = []
	var half_spread = deg_to_rad(spread_angle) / 2.0
	var angle_step = deg_to_rad(spread_angle) / max(count - 1, 1)

	for i in range(count):
		var bullet = create_bullet(bullet_scene, preset, overrides)
		bullet.global_position = position
		bullet.direction = direction.rotated(-half_spread + i * angle_step)
		bullets.append(bullet)

	return bullets

## 生成螺旋弹幕
static func spawn_spiral(bullet_scene: PackedScene, position: Vector2, count: int, start_angle: float, angle_increment: float, preset: int = BulletPreset.BASIC, overrides: Dictionary = {}) -> Array[Node2D]:
	var bullets: Array[Node2D] = []

	for i in range(count):
		var bullet = create_bullet(bullet_scene, preset, overrides)
		bullet.global_position = position
		bullet.direction = Vector2.RIGHT.rotated(start_angle + i * deg_to_rad(angle_increment))
		bullets.append(bullet)

	return bullets

## 生成随机弹幕
static func spawn_random(bullet_scene: PackedScene, position: Vector2, count: int, preset: int = BulletPreset.BASIC, overrides: Dictionary = {}) -> Array[Node2D]:
	var bullets: Array[Node2D] = []

	for i in range(count):
		var bullet = create_bullet(bullet_scene, preset, overrides)
		bullet.global_position = position
		bullet.direction = Vector2.RIGHT.rotated(randf() * TAU)
		bullets.append(bullet)

	return bullets

# ==================== 辅助方法 ====================
## 获取预设配置的副本
static func get_preset_config(preset: int) -> Dictionary:
	return PRESETS.get(preset, PRESETS[BulletPreset.BASIC]).duplicate()

## 混合两个预设
static func blend_presets(preset_a: int, preset_b: int, blend_factor: float = 0.5) -> Dictionary:
	var config_a = get_preset_config(preset_a)
	var config_b = get_preset_config(preset_b)
	var result = {}

	for key in config_a:
		if key in config_b:
			if config_a[key] is float:
				result[key] = lerp(config_a[key], config_b[key], blend_factor)
			elif config_a[key] is Color:
				result[key] = config_a[key].lerp(config_b[key], blend_factor)
			else:
				result[key] = config_a[key] if blend_factor < 0.5 else config_b[key]
		else:
			result[key] = config_a[key]

	return result
