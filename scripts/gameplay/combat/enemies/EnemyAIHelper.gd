extends RefCounted
class_name EnemyAIHelper

## EnemyAI辅助类 - 提供敌人AI的通用计算方法
## 用于减轻Enemy.gd的复杂性

# ==================== 路径寻找 ====================
## 计算追踪玩家的方向
static func get_chase_direction(enemy_pos: Vector2, target_pos: Vector2, y_threshold: float = 40.0) -> Vector2:
	var to_target = target_pos - enemy_pos
	var y_diff = abs(to_target.y)

	# Y轴近战限制：优先垂直移动到同一水平线
	if y_diff > y_threshold:
		return Vector2(0, sign(to_target.y))
	else:
		return enemy_pos.direction_to(target_pos)

## 计算环绕移动方向（用于远程敌人）
static func get_orbit_direction(enemy_pos: Vector2, target_pos: Vector2, orbit_distance: float, clockwise: bool = true) -> Vector2:
	var to_target = target_pos - enemy_pos
	var distance = to_target.length()

	if distance < orbit_distance * 0.8:
		# 太近了，后退
		return -to_target.normalized()
	elif distance > orbit_distance * 1.2:
		# 太远了，靠近
		return to_target.normalized()
	else:
		# 保持距离，环绕移动
		var tangent = to_target.normalized().rotated(PI/2 if clockwise else -PI/2)
		return tangent

# ==================== 分离力计算 ====================
## 计算敌人之间的分离力
static func calculate_separation_force(enemy: Node2D, enemies: Array, separation_radius: float = 80.0, separation_strength: float = 150.0, max_force: float = 400.0) -> Vector2:
	var separation_force = Vector2.ZERO
	var neighbor_count = 0

	for other in enemies:
		if other == enemy or not is_instance_valid(other):
			continue

		var to_other = other.global_position - enemy.global_position
		var dist = to_other.length()

		if dist < separation_radius and dist > 0:
			# 反向推力，越近越强
			var repel_direction = -to_other.normalized()
			var force_magnitude = (1.0 - dist / separation_radius) * separation_strength
			separation_force += repel_direction * force_magnitude
			neighbor_count += 1

	# 限制最大分离力
	if separation_force.length() > max_force:
		separation_force = separation_force.normalized() * max_force

	return separation_force

# ==================== 击退计算 ====================
## 计算击退速度
static func calculate_knockback(damage: float, direction: Vector2, mass: float, base_force: float = 600.0) -> Vector2:
	var force = base_force * (1.0 + damage * 0.05)  # 伤害越高，击退越强
	var knockback = direction * force / mass
	return knockback

## 应用击退衰减
static func apply_knockback_decay(knockback: Vector2, decay_rate: float, delta: float) -> Vector2:
	return knockback.lerp(Vector2.ZERO, decay_rate * delta)

# ==================== 视野���测 ====================
## 检查目标是否在视野内
static func is_target_in_sight(enemy_pos: Vector2, target_pos: Vector2, facing_direction: Vector2, fov_angle: float = 120.0, max_distance: float = 500.0) -> bool:
	var to_target = target_pos - enemy_pos
	var distance = to_target.length()

	if distance > max_distance:
		return false

	var angle = rad_to_deg(facing_direction.angle_to(to_target.normalized()))
	return abs(angle) <= fov_angle / 2.0

## 检查是否有障碍物阻挡
static func has_line_of_sight(space_state: PhysicsDirectSpaceState2D, from: Vector2, to: Vector2, collision_mask: int) -> bool:
	var query = PhysicsRayQueryParameters2D.create(from, to, collision_mask)
	var result = space_state.intersect_ray(query)
	return result.is_empty()

# ==================== 攻击模式 ====================
## 获取散射方向数组
static func get_spread_directions(base_direction: Vector2, count: int, spread_angle: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	var half_spread = spread_angle / 2.0
	var angle_step = spread_angle / max(count - 1, 1)

	for i in range(count):
		var angle_offset = -half_spread + i * angle_step
		directions.append(base_direction.rotated(deg_to_rad(angle_offset)))

	return directions

## 获取环形方向数组
static func get_circle_directions(count: int, start_angle: float = 0.0) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	var angle_step = TAU / count

	for i in range(count):
		var angle = start_angle + i * angle_step
		directions.append(Vector2.RIGHT.rotated(angle))

	return directions

## 获取螺旋方向数组
static func get_spiral_directions(count: int, start_angle: float, angle_offset: float = 15.0) -> Array[Vector2]:
	var directions: Array[Vector2] = []

	for i in range(count):
		var angle = start_angle + i * deg_to_rad(angle_offset)
		directions.append(Vector2.RIGHT.rotated(angle))

	return directions

# ==================== Boss专用 ====================
## 获取安全的瞬移位置
static func get_safe_teleport_position(current_pos: Vector2, target_pos: Vector2, min_distance: float = 200.0, max_distance: float = 400.0, arena_bounds: Rect2 = Rect2()) -> Vector2:
	var attempts = 10

	for i in range(attempts):
		var random_angle = randf() * TAU
		var random_distance = randf_range(min_distance, max_distance)
		var new_pos = target_pos + Vector2.RIGHT.rotated(random_angle) * random_distance

		# 检查是否在竞技场范围内
		if arena_bounds.size != Vector2.ZERO:
			new_pos.x = clamp(new_pos.x, arena_bounds.position.x, arena_bounds.position.x + arena_bounds.size.x)
			new_pos.y = clamp(new_pos.y, arena_bounds.position.y, arena_bounds.position.y + arena_bounds.size.y)

		# 确保不会太靠近当前位置
		if new_pos.distance_to(current_pos) > min_distance * 0.5:
			return new_pos

	# 失败时返回随机偏移
	return current_pos + Vector2(randf_range(-100, 100), randf_range(-100, 100))
