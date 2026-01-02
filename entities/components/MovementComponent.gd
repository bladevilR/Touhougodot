extends GameComponent
## 移动组件 - 处理实体的移动、冲刺和击退
##
## 职责:
## - 处理基础移动（速度、摩擦力）
## - 冲刺系统
## - 击退效果
## - 碰撞处理
##
## 使用示例:
##   var movement = MovementComponent.new()
##   movement.speed = 200.0
##   movement.friction = 0.85
##   entity.add_child(movement)

class_name MovementComponent

# 移动参数
var speed: float = 150.0
var friction: float = 0.85
var velocity: Vector2 = Vector2.ZERO

# 冲刺参数
var can_dash: bool = true
var dash_speed_multiplier: float = 3.0
var dash_duration: float = 0.2
var dash_cooldown: float = 0.5
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

# 击退参数
var knockback: Vector2 = Vector2.ZERO
var knockback_decay: float = 0.8

# 移动方向（由外部设置）
var move_direction: Vector2 = Vector2.ZERO

## 每帧更新
func _on_entity_process(delta: float) -> void:
	# 更新冲刺计时器
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	# 更新冲刺冷却
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

## 物理帧更新
func _on_entity_physics_process(delta: float) -> void:
	if not entity or not entity is CharacterBody2D:
		return

	var character = entity as CharacterBody2D

	# 计算移动
	if is_dashing:
		# 冲刺中，保持冲刺速度
		pass
	elif move_direction.length() > 0:
		# 正常移动
		velocity = move_direction.normalized() * speed
	else:
		# 应用摩擦力
		velocity *= friction

	# 应用击退
	if knockback.length() > 0:
		velocity += knockback
		knockback *= knockback_decay
		if knockback.length() < 1.0:
			knockback = Vector2.ZERO

	# 应用速度
	character.velocity = velocity
	character.move_and_slide()

## 移动
## @param direction: 移动方向（已归一化或未归一化）
func move(direction: Vector2) -> void:
	move_direction = direction

## 冲刺
## @param direction: 冲刺方向（如果为零则使用当前移动方向）
func dash(direction: Vector2 = Vector2.ZERO) -> void:
	if not can_dash or is_dashing or dash_cooldown_timer > 0:
		return

	var dash_dir = direction if direction.length() > 0 else move_direction
	if dash_dir.length() == 0:
		dash_dir = Vector2(1, 0)  # 默认向右

	dash_dir = dash_dir.normalized()

	# 设置冲刺速度
	velocity = dash_dir * speed * dash_speed_multiplier
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

	# 发送冲刺信号
	SignalBus.player_dashed.emit() if entity.is_in_group("player") else null

## 应用击退
## @param force: 击退力度和方向
func apply_knockback(force: Vector2) -> void:
	knockback = force

## 停止移动
func stop() -> void:
	move_direction = Vector2.ZERO
	velocity = Vector2.ZERO

## 获取当前速度
func get_velocity() -> Vector2:
	return velocity

## 检查是否在移动
func is_moving() -> bool:
	return velocity.length() > 1.0

## 检查冲刺是否冷却完成
func is_dash_ready() -> bool:
	return dash_cooldown_timer <= 0
