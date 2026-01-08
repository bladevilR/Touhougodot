extends Node
class_name StatusEffectComponent

## StatusEffectComponent - 状态效果组件
## 管理燃烧、中毒、冻结、眩晕、减速等状态效果

signal status_applied(effect_type: String)
signal status_removed(effect_type: String)
signal dot_damage_dealt(damage: float, effect_type: String)

# ==================== 组件引用 ====================
var entity: Node2D = null
var health_comp: Node = null
var sprite: Sprite2D = null

# ==================== 状态效果数据 ====================
var active_status_effects = {
	"burns": [],        # Array of {damage: float, duration: float, timer: float}
	"poisons": [],      # Array of {damage: float, duration: float, timer: float}
	"freeze": null,     # {duration: float, timer: float} or null
	"stun": null,       # {duration: float, timer: float} or null
	"slow": null,       # {amount: float, duration: float, timer: float} or null
}

# ==================== DOT计时器 ====================
var burn_tick_timer: float = 0.0
var poison_tick_timer: float = 0.0
const STATUS_TICK_INTERVAL: float = 1.0

# ==================== 视觉反馈 ====================
var status_color_timer: float = 0.0
var original_color: Color = Color.WHITE

# ==================== 初始化 ====================
func initialize(p_entity: Node2D, p_sprite: Sprite2D = null, p_health_comp: Node = null) -> void:
	entity = p_entity
	sprite = p_sprite
	health_comp = p_health_comp

	if sprite:
		original_color = sprite.modulate

func _process(delta: float) -> void:
	_update_status_effects(delta)
	_update_status_visuals(delta)

# ==================== 应用状态效果 ====================
func apply_burn(damage: float, duration: float) -> void:
	var burn_effect = {
		"damage": damage,
		"duration": duration,
		"timer": 0.0
	}
	active_status_effects.burns.append(burn_effect)
	status_applied.emit("burn")

func apply_poison(damage: float, duration: float) -> void:
	var poison_effect = {
		"damage": damage,
		"duration": duration,
		"timer": 0.0
	}
	active_status_effects.poisons.append(poison_effect)
	status_applied.emit("poison")

func apply_freeze(duration: float) -> void:
	if active_status_effects.freeze == null:
		active_status_effects.freeze = {
			"duration": duration,
			"timer": 0.0
		}
		status_applied.emit("freeze")

func apply_stun(duration: float) -> void:
	if active_status_effects.stun == null:
		active_status_effects.stun = {
			"duration": duration,
			"timer": 0.0
		}
		status_applied.emit("stun")
	else:
		active_status_effects.stun.duration = max(active_status_effects.stun.duration, duration)

func apply_slow(amount: float, duration: float) -> void:
	if active_status_effects.slow == null:
		active_status_effects.slow = {
			"amount": amount,
			"duration": duration,
			"timer": 0.0
		}
		status_applied.emit("slow")
	else:
		if amount < active_status_effects.slow.amount:
			active_status_effects.slow.amount = amount
		active_status_effects.slow.duration = max(active_status_effects.slow.duration, duration)

# ==================== 状态更新逻辑 ====================
func _update_status_effects(delta: float) -> void:
	_update_burn_effects(delta)
	_update_poison_effects(delta)

	# 更新冻结
	if active_status_effects.freeze != null:
		active_status_effects.freeze.timer += delta
		if active_status_effects.freeze.timer >= active_status_effects.freeze.duration:
			active_status_effects.freeze = null
			status_removed.emit("freeze")

	# 更新眩晕
	if active_status_effects.stun != null:
		active_status_effects.stun.timer += delta
		if active_status_effects.stun.timer >= active_status_effects.stun.duration:
			active_status_effects.stun = null
			status_removed.emit("stun")

	# 更新减速
	if active_status_effects.slow != null:
		active_status_effects.slow.timer += delta
		if active_status_effects.slow.timer >= active_status_effects.slow.duration:
			active_status_effects.slow = null
			status_removed.emit("slow")

func _update_burn_effects(delta: float) -> void:
	if active_status_effects.burns.size() == 0:
		return

	burn_tick_timer += delta

	if burn_tick_timer >= STATUS_TICK_INTERVAL:
		burn_tick_timer = 0.0

		var total_burn_damage = 0.0
		for burn in active_status_effects.burns:
			total_burn_damage += burn.damage

		if total_burn_damage > 0:
			_deal_dot_damage(total_burn_damage, "burn")

	# 更新计时器并移除过期效果
	var i = 0
	while i < active_status_effects.burns.size():
		active_status_effects.burns[i].timer += delta
		if active_status_effects.burns[i].timer >= active_status_effects.burns[i].duration:
			active_status_effects.burns.remove_at(i)
			if active_status_effects.burns.size() == 0:
				status_removed.emit("burn")
		else:
			i += 1

func _update_poison_effects(delta: float) -> void:
	if active_status_effects.poisons.size() == 0:
		return

	poison_tick_timer += delta

	if poison_tick_timer >= STATUS_TICK_INTERVAL:
		poison_tick_timer = 0.0

		var total_poison_damage = 0.0
		for poison in active_status_effects.poisons:
			total_poison_damage += poison.damage

		if total_poison_damage > 0:
			_deal_dot_damage(total_poison_damage, "poison")

	# 更新计时器并移除过期效果
	var i = 0
	while i < active_status_effects.poisons.size():
		active_status_effects.poisons[i].timer += delta
		if active_status_effects.poisons[i].timer >= active_status_effects.poisons[i].duration:
			active_status_effects.poisons.remove_at(i)
			if active_status_effects.poisons.size() == 0:
				status_removed.emit("poison")
		else:
			i += 1

func _deal_dot_damage(damage: float, effect_type: String) -> void:
	if health_comp and health_comp.has_method("damage"):
		health_comp.damage(damage)
		dot_damage_dealt.emit(damage, effect_type)

# ==================== 状态查询 ====================
func is_movement_disabled() -> bool:
	if active_status_effects.freeze != null:
		return true
	if active_status_effects.stun != null:
		return true
	return false

func get_speed_multiplier() -> float:
	if active_status_effects.slow != null:
		return active_status_effects.slow.amount
	return 1.0

func has_status(status_type: String) -> bool:
	match status_type:
		"burn": return active_status_effects.burns.size() > 0
		"poison": return active_status_effects.poisons.size() > 0
		"freeze": return active_status_effects.freeze != null
		"stun": return active_status_effects.stun != null
		"slow": return active_status_effects.slow != null
		_: return false

func get_active_statuses() -> Array[String]:
	var statuses: Array[String] = []
	if active_status_effects.burns.size() > 0:
		statuses.append("burn")
	if active_status_effects.poisons.size() > 0:
		statuses.append("poison")
	if active_status_effects.freeze != null:
		statuses.append("freeze")
	if active_status_effects.stun != null:
		statuses.append("stun")
	if active_status_effects.slow != null:
		statuses.append("slow")
	return statuses

# ==================== 视觉反馈 ====================
func _update_status_visuals(delta: float) -> void:
	if not sprite:
		return

	status_color_timer += delta

	var status_colors: Array[Color] = []

	if active_status_effects.burns.size() > 0:
		status_colors.append(Color.RED)
	if active_status_effects.freeze != null:
		status_colors.append(Color.CYAN)
	if active_status_effects.poisons.size() > 0:
		status_colors.append(Color.GREEN)
	if active_status_effects.stun != null:
		status_colors.append(Color.YELLOW)
	if active_status_effects.slow != null:
		status_colors.append(Color.GRAY)

	if status_colors.size() > 0:
		var pulse = abs(sin(status_color_timer * 5.0))
		var blend_factor = 0.3 + pulse * 0.4
		var blended_color = _blend_status_colors(status_colors)
		sprite.modulate = original_color.lerp(blended_color, blend_factor)
	else:
		sprite.modulate = original_color

func _blend_status_colors(colors: Array[Color]) -> Color:
	if colors.size() == 0:
		return Color.WHITE
	if colors.size() == 1:
		return colors[0]

	var result = Color.BLACK
	for color in colors:
		result += color
	result /= float(colors.size())
	return result

# ==================== 清除效果 ====================
func clear_all() -> void:
	active_status_effects.burns.clear()
	active_status_effects.poisons.clear()
	active_status_effects.freeze = null
	active_status_effects.stun = null
	active_status_effects.slow = null
	burn_tick_timer = 0.0
	poison_tick_timer = 0.0

	if sprite:
		sprite.modulate = original_color

func clear_status(status_type: String) -> void:
	match status_type:
		"burn":
			active_status_effects.burns.clear()
			status_removed.emit("burn")
		"poison":
			active_status_effects.poisons.clear()
			status_removed.emit("poison")
		"freeze":
			active_status_effects.freeze = null
			status_removed.emit("freeze")
		"stun":
			active_status_effects.stun = null
			status_removed.emit("stun")
		"slow":
			active_status_effects.slow = null
			status_removed.emit("slow")
