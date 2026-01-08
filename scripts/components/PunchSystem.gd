extends Node
class_name PunchSystem

## PunchSystem - 拳击系统组件
## 管理轻拳、重拳、连击、伤害判定、自动锁定等功能

signal attack_started(attack_type: String)
signal attack_ended()
signal damage_dealt(target: Node, damage: float)
signal combo_changed(combo_state: int)

# ==================== 组件引用 ====================
var player: CharacterBody2D = null
var sprite: Sprite2D = null
var mokou_textures: Dictionary = {}

# ==================== 攻击状态 ====================
var is_attacking: bool = false
var is_recycling: bool = false
var current_attack_id: int = 0

# ==================== 连击系统 ====================
var combo_state: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.6

# ==================== 长按系统 ====================
var is_long_pressing: bool = false
var long_press_timer: float = 0.0
const LONG_PRESS_THRESHOLD: float = 0.3

# ==================== 输入缓冲系统 ====================
var buffered_input: String = ""
var input_buffer_timer: float = 0.0
const INPUT_BUFFER_WINDOW: float = 0.4

# ==================== 战斗状态 ====================
var is_in_combat: bool = false
var combat_exit_timer: float = 0.0
const COMBAT_EXIT_DELAY: float = 3.0

# ==================== 攻击配置 ====================
const PUNCH_CONFIGS = {
	"light": {
		"damage": 15.0,
		"knockback": 400.0,
		"range": 80.0,
		"duration": 0.2,
		"frames": "punch1"
	},
	"heavy": {
		"damage": 35.0,
		"knockback": 800.0,
		"range": 100.0,
		"duration": 0.35,
		"frames": "punch2"
	},
	"combo1": {
		"damage": 18.0,
		"knockback": 450.0,
		"range": 85.0,
		"duration": 0.18,
		"frames": "punch1"
	},
	"combo2": {
		"damage": 20.0,
		"knockback": 500.0,
		"range": 90.0,
		"duration": 0.18,
		"frames": "punch2"
	},
	"combo3": {
		"damage": 30.0,
		"knockback": 700.0,
		"range": 95.0,
		"duration": 0.25,
		"frames": "punch3"
	},
	"recycle": {
		"damage": 12.0,
		"knockback": 300.0,
		"range": 75.0,
		"duration": 0.15,
		"frames": "punch1"
	}
}

# ==================== 初始化 ====================
func initialize(p_player: CharacterBody2D, p_sprite: Sprite2D, p_textures: Dictionary) -> void:
	player = p_player
	sprite = p_sprite
	mokou_textures = p_textures

func _process(delta: float) -> void:
	_update_combo_timer(delta)
	_update_long_press(delta)
	_update_input_buffer(delta)
	_update_combat_state(delta)

# ==================== 输入处理 ====================
func on_light_attack_pressed() -> void:
	is_long_pressing = true
	long_press_timer = 0.0

	if is_attacking:
		buffered_input = "light"
		input_buffer_timer = INPUT_BUFFER_WINDOW
		return

	_trigger_light_punch()

func on_light_attack_released() -> void:
	is_long_pressing = false
	long_press_timer = 0.0
	is_recycling = false

func on_heavy_attack_pressed() -> void:
	if is_attacking:
		buffered_input = "heavy"
		input_buffer_timer = INPUT_BUFFER_WINDOW
		return

	_trigger_heavy_punch()

func on_heavy_attack_released() -> void:
	pass

# ==================== 攻击触发 ====================
func _trigger_light_punch() -> void:
	if is_attacking:
		return

	_enter_combat()

	var attack_type: String
	if combo_state == 0:
		attack_type = "light"
		combo_state = 1
	elif combo_state == 1:
		attack_type = "combo1"
		combo_state = 2
	elif combo_state == 2:
		attack_type = "combo2"
		combo_state = 3
	else:
		attack_type = "combo3"
		combo_state = 0

	combo_timer = COMBO_WINDOW
	_execute_attack(attack_type)

func _trigger_heavy_punch() -> void:
	if is_attacking:
		return

	_enter_combat()
	combo_state = 0
	_execute_attack("heavy")

func _trigger_recycle_punch() -> void:
	if is_attacking:
		return

	_enter_combat()
	_execute_attack("recycle")

# ==================== 攻击执行 ====================
func _execute_attack(attack_type: String) -> void:
	var config = PUNCH_CONFIGS.get(attack_type)
	if not config:
		return

	is_attacking = true
	current_attack_id += 1
	var attack_id = current_attack_id

	attack_started.emit(attack_type)

	# 自动锁定敌人
	_auto_lock_to_enemy(config.range)

	# 播放动画（需要Player调用）
	_play_attack_animation(config, attack_type)

	# 伤害判定
	await get_tree().create_timer(config.duration * 0.3).timeout
	if current_attack_id == attack_id and is_instance_valid(self):
		_check_punch_damage(config, attack_type)

	# 攻击结束
	await get_tree().create_timer(config.duration * 0.7).timeout
	if current_attack_id == attack_id and is_instance_valid(self):
		is_attacking = false
		attack_ended.emit()

		# 处理缓冲输入
		if buffered_input != "":
			var input = buffered_input
			buffered_input = ""
			if input == "light":
				_trigger_light_punch()
			elif input == "heavy":
				_trigger_heavy_punch()

# ==================== 伤害判定 ====================
func _check_punch_damage(config: Dictionary, attack_type: String) -> void:
	if not is_instance_valid(player):
		return

	var attack_direction = _get_attack_direction()
	var attack_center = player.global_position + attack_direction * (config.range * 0.5)

	var enemies = player.get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = attack_center.distance_to(enemy.global_position)
		if distance < config.range:
			# 造成伤害
			if enemy.has_method("take_damage"):
				enemy.take_damage(config.damage)
				damage_dealt.emit(enemy, config.damage)

			# 击退
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(attack_direction, config.knockback)

# ==================== 自动锁定 ====================
func _auto_lock_to_enemy(attack_range: float) -> bool:
	if not is_instance_valid(player):
		return false

	var best_target: Node2D = null
	var best_distance: float = attack_range * 1.5
	var attack_direction = _get_attack_direction()

	var enemies = player.get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var to_enemy = enemy.global_position - player.global_position
		var distance = to_enemy.length()

		if distance > attack_range * 1.5:
			continue

		# 检查方向
		var dot = attack_direction.dot(to_enemy.normalized())
		if dot < 0.3:
			continue

		if distance < best_distance:
			best_distance = distance
			best_target = enemy

	if best_target:
		# 稍微向目标移动
		var move_distance = min(best_distance - attack_range * 0.3, 50.0)
		if move_distance > 10:
			var move_direction = (best_target.global_position - player.global_position).normalized()
			player.global_position += move_direction * move_distance * 0.5
		return true

	return false

func _get_attack_direction() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.RIGHT

	# 优先使用鼠标方向
	var mouse_pos = player.get_global_mouse_position()
	var to_mouse = mouse_pos - player.global_position
	if to_mouse.length() > 10:
		return to_mouse.normalized()

	# 否则使用面朝方向
	if sprite and sprite.flip_h:
		return Vector2.LEFT
	return Vector2.RIGHT

# ==================== 动画播放 ====================
func _play_attack_animation(config: Dictionary, attack_type: String) -> void:
	# 这个方法可以被 Player 覆盖或通过信号触发
	pass

# ==================== 状态更新 ====================
func _update_combo_timer(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_state = 0
			combo_changed.emit(0)

func _update_long_press(delta: float) -> void:
	if is_long_pressing and not is_attacking:
		long_press_timer += delta
		if long_press_timer >= LONG_PRESS_THRESHOLD and not is_recycling:
			is_recycling = true
			_trigger_recycle_punch()
		elif is_recycling:
			_trigger_recycle_punch()

func _update_input_buffer(delta: float) -> void:
	if input_buffer_timer > 0:
		input_buffer_timer -= delta
		if input_buffer_timer <= 0:
			buffered_input = ""

func _update_combat_state(delta: float) -> void:
	if is_in_combat:
		if is_attacking:
			combat_exit_timer = COMBAT_EXIT_DELAY
		else:
			combat_exit_timer -= delta
			if combat_exit_timer <= 0:
				is_in_combat = false

func _enter_combat() -> void:
	is_in_combat = true
	combat_exit_timer = COMBAT_EXIT_DELAY

# ==================== 公开接口 ====================
func is_busy() -> bool:
	return is_attacking

func get_combo_state() -> int:
	return combo_state

func reset() -> void:
	is_attacking = false
	is_recycling = false
	combo_state = 0
	combo_timer = 0.0
	buffered_input = ""
