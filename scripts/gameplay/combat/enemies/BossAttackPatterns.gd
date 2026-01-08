extends RefCounted
class_name BossAttackPatterns

## Boss攻击模式库
## 提供各种Boss攻击弹幕的生成方法

# ==================== 弹幕发射接口 ====================
## 环形弹幕
static func spawn_circle_bullets(spawner: Node2D, bullet_scene: PackedScene, count: int, speed: float, damage: float, start_angle: float = 0.0, bullet_color: Color = Color.RED) -> void:
	var directions = EnemyAIHelper.get_circle_directions(count, start_angle)

	for direction in directions:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = spawner.global_position
		bullet.direction = direction
		bullet.speed = speed
		bullet.damage = damage
		if bullet.has("modulate"):
			bullet.modulate = bullet_color
		spawner.get_tree().current_scene.add_child(bullet)

## 扇形弹幕
static func spawn_spread_bullets(spawner: Node2D, bullet_scene: PackedScene, target_pos: Vector2, count: int, spread_angle: float, speed: float, damage: float, bullet_color: Color = Color.ORANGE_RED) -> void:
	var base_direction = spawner.global_position.direction_to(target_pos)
	var directions = EnemyAIHelper.get_spread_directions(base_direction, count, spread_angle)

	for direction in directions:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = spawner.global_position
		bullet.direction = direction
		bullet.speed = speed
		bullet.damage = damage
		if bullet.has("modulate"):
			bullet.modulate = bullet_color
		spawner.get_tree().current_scene.add_child(bullet)

## 螺旋弹幕
static func spawn_spiral_bullets(spawner: Node2D, bullet_scene: PackedScene, count: int, speed: float, damage: float, spiral_offset: float, bullet_color: Color = Color.CYAN) -> void:
	var directions = EnemyAIHelper.get_spiral_directions(count, spiral_offset, 15.0)

	for direction in directions:
		var bullet = bullet_scene.instantiate()
		bullet.global_position = spawner.global_position
		bullet.direction = direction
		bullet.speed = speed
		bullet.damage = damage
		if bullet.has("modulate"):
			bullet.modulate = bullet_color
		spawner.get_tree().current_scene.add_child(bullet)

## 追踪弹幕
static func spawn_homing_bullet(spawner: Node2D, bullet_scene: PackedScene, target: Node2D, speed: float, damage: float, turn_speed: float = 2.0, bullet_color: Color = Color.MAGENTA) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = spawner.global_position
	bullet.direction = spawner.global_position.direction_to(target.global_position)
	bullet.speed = speed
	bullet.damage = damage

	# 设置追踪属性（需要Bullet支持）
	if bullet.has("is_homing"):
		bullet.is_homing = true
		bullet.target = target
		bullet.turn_speed = turn_speed

	if bullet.has("modulate"):
		bullet.modulate = bullet_color

	spawner.get_tree().current_scene.add_child(bullet)

## 激光扫射
static func spawn_laser_sweep(spawner: Node2D, laser_scene: PackedScene, start_angle: float, end_angle: float, sweep_duration: float, damage: float, laser_color: Color = Color.YELLOW) -> void:
	var laser = laser_scene.instantiate()
	laser.global_position = spawner.global_position
	laser.damage = damage

	# 设置激光扫射属性（需要Laser支持）
	if laser.has("start_angle"):
		laser.start_angle = start_angle
		laser.end_angle = end_angle
		laser.sweep_duration = sweep_duration

	if laser.has("modulate"):
		laser.modulate = laser_color

	spawner.get_tree().current_scene.add_child(laser)

## 波纹弹幕
static func spawn_wave_bullets(spawner: Node2D, bullet_scene: PackedScene, target_pos: Vector2, wave_count: int, bullets_per_wave: int, wave_delay: float, speed: float, damage: float) -> void:
	# 需要协程支持，这里提供计算方法
	for wave in range(wave_count):
		await spawner.get_tree().create_timer(wave * wave_delay).timeout
		spawn_circle_bullets(spawner, bullet_scene, bullets_per_wave, speed, damage, wave * 30.0)

# ==================== Boss专属复杂攻击模式 ====================
## 辉夜 - 五难之一：燕子安贝
static func kaguya_swallow_cowrie(spawner: Node2D, bullet_scene: PackedScene) -> void:
	# 5个方向的弹幕波
	for i in range(5):
		await spawner.get_tree().create_timer(0.3).timeout
		spawn_spread_bullets(spawner, bullet_scene, spawner.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100)), 7, 60.0, 200.0, 15.0, Color.GOLD)

## 辉夜 - 五难之一：蓬莱之玉枝
static func kaguya_hourai_jeweled_branch(spawner: Node2D, bullet_scene: PackedScene) -> void:
	# 环形扩散弹幕，多层
	for layer in range(4):
		await spawner.get_tree().create_timer(0.5).timeout
		var count = 12 + layer * 4
		var speed = 150.0 + layer * 25.0
		spawn_circle_bullets(spawner, bullet_scene, count, speed, 15.0, layer * 15.0, Color.CYAN)

## 辉夜 - 五难之一：火鼠之皮衣
static func kaguya_fire_rat_robe(spawner: Node2D, bullet_scene: PackedScene, target: Node2D) -> void:
	# 追踪火球弹幕
	for i in range(8):
		await spawner.get_tree().create_timer(0.4).timeout
		spawn_homing_bullet(spawner, bullet_scene, target, 180.0, 20.0, 3.0, Color.ORANGE_RED)

## 辉夜 - 五难之一：龙颈之玉
static func kaguya_dragon_jewel(spawner: Node2D, bullet_scene: PackedScene) -> void:
	# 螺旋弹幕
	for i in range(10):
		await spawner.get_tree().create_timer(0.2).timeout
		spawn_spiral_bullets(spawner, bullet_scene, 8, 220.0, 15.0, i * 36.0, Color.MEDIUM_PURPLE)

## 辉夜 - 五难之一：佛之石钵
static func kaguya_buddhas_stone_bowl(spawner: Node2D, bullet_scene: PackedScene, target_pos: Vector2) -> void:
	# 密集扇形弹幕
	for i in range(5):
		await spawner.get_tree().create_timer(0.3).timeout
		spawn_spread_bullets(spawner, bullet_scene, target_pos, 15, 90.0, 200.0, 15.0, Color.SLATE_BLUE)

# ==================== 妖梦专属攻击模式 ====================
## 妖梦 - 剑技：六道斩
static func youmu_six_realms_slash(spawner: Node2D, bullet_scene: PackedScene) -> void:
	# 六个方向的快速斩击
	for i in range(6):
		var angle = i * (TAU / 6.0)
		var direction = Vector2.RIGHT.rotated(angle)
		spawn_spread_bullets(spawner, bullet_scene, spawner.global_position + direction * 100.0, 3, 30.0, 300.0, 20.0, Color.SKY_BLUE)
		await spawner.get_tree().create_timer(0.15).timeout

## 妖梦 - 剑技：迷津慈航斩
static func youmu_delusion_enlightenment_slash(spawner: Node2D, bullet_scene: PackedScene, target: Node2D) -> void:
	# 追踪光剑
	for i in range(4):
		spawn_homing_bullet(spawner, bullet_scene, target, 250.0, 25.0, 4.0, Color.WHITE)
		await spawner.get_tree().create_timer(0.5).timeout

# ==================== 通用Boss攻击模式 ====================
## 通用 - 环绕弹幕
static func generic_ring_attack(spawner: Node2D, bullet_scene: PackedScene, ring_count: int = 3) -> void:
	for i in range(ring_count):
		spawn_circle_bullets(spawner, bullet_scene, 16 + i * 4, 180.0 + i * 30.0, 15.0, i * 22.5)
		await spawner.get_tree().create_timer(0.4).timeout

## 通用 - 随机散射
static func generic_random_spray(spawner: Node2D, bullet_scene: PackedScene, duration: float = 3.0, bullets_per_second: int = 10) -> void:
	var timer = 0.0
	var interval = 1.0 / bullets_per_second

	while timer < duration:
		var random_direction = Vector2.RIGHT.rotated(randf() * TAU)
		var bullet = bullet_scene.instantiate()
		bullet.global_position = spawner.global_position
		bullet.direction = random_direction
		bullet.speed = randf_range(150.0, 250.0)
		bullet.damage = 12.0
		spawner.get_tree().current_scene.add_child(bullet)

		await spawner.get_tree().create_timer(interval).timeout
		timer += interval
