extends GameComponent
## 状态效果组件 - 管理实体的各种状态效果
##
## 职责:
## - 管理燃烧、冰冻、中毒、减速、眩晕等状态
## - 状态效果的叠加和衰减
## - 状态视觉反馈
##
## 使用示例:
##   var status = StatusEffectComponent.new()
##   status.apply_effect("burn", 3.0, 10.0)
##   entity.add_child(status)

class_name StatusEffectComponent

# 状态效果类型
enum EffectType {
	BURN,       # 燃烧
	FREEZE,     # 冰冻
	POISON,     # 中毒
	SLOW,       # 减速
	STUN,       # 眩晕
	VULNERABILITY  # 易伤
}

# 活跃的状态效果 {effect_type: {duration, power, stacks}}
var active_effects: Dictionary = {}

# 状态叠层（用于某些效果）
var frost_stacks: int = 0
var vulnerability_stacks: int = 0

# 冻结阈值
const FREEZE_THRESHOLD: int = 3

# 视觉效果节点
var burn_particles: GPUParticles2D = null
var freeze_overlay: Sprite2D = null
var poison_particles: GPUParticles2D = null

## 每帧更新
func _on_entity_process(delta: float) -> void:
	_update_status_effects(delta)
	_update_status_visuals()

## 应用状态效果
## @param effect_name: 效果名称 ("burn", "freeze", "poison", "slow", "stun")
## @param duration: 持续时间（秒）
## @param power: 效果强度
func apply_effect(effect_name: String, duration: float, power: float = 1.0) -> void:
	var effect_type = _get_effect_type(effect_name)
	if effect_type == -1:
		push_warning("StatusEffectComponent: 未知的效果类型 '%s'" % effect_name)
		return

	# 特殊处理：冰霜叠层
	if effect_name == "frost":
		frost_stacks += 1
		if frost_stacks >= FREEZE_THRESHOLD:
			# 触发冰冻
			apply_effect("freeze", duration, power)
			frost_stacks = 0
		return

	# 添加或更新效果
	if effect_name in active_effects:
		# 刷新持续时间，叠加强度
		active_effects[effect_name]["duration"] = max(active_effects[effect_name]["duration"], duration)
		active_effects[effect_name]["power"] += power * 0.5  # 叠加时减半
	else:
		active_effects[effect_name] = {
			"duration": duration,
			"power": power,
			"tick_timer": 0.0
		}

	# 创建视觉效果
	_create_visual_effect(effect_name)

	print("StatusEffectComponent: 应用 %s 效果 (持续%.1fs, 强度%.1f)" % [effect_name, duration, power])

## 移除状态效果
func remove_effect(effect_name: String) -> void:
	if effect_name in active_effects:
		active_effects.erase(effect_name)
		_remove_visual_effect(effect_name)

## 清除所有状态效果
func clear_all_effects() -> void:
	active_effects.clear()
	frost_stacks = 0
	vulnerability_stacks = 0
	_clear_all_visuals()

## 检查是否有某个效果
func has_effect(effect_name: String) -> bool:
	return effect_name in active_effects

## 获取效果强度
func get_effect_power(effect_name: String) -> float:
	if effect_name in active_effects:
		return active_effects[effect_name]["power"]
	return 0.0

## 更新状态效果
func _update_status_effects(delta: float) -> void:
	var effects_to_remove = []

	for effect_name in active_effects:
		var effect = active_effects[effect_name]

		# 更新持续时间
		effect["duration"] -= delta
		if effect["duration"] <= 0:
			effects_to_remove.append(effect_name)
			continue

		# 更新tick计时器
		effect["tick_timer"] -= delta

		# 处理效果逻辑
		match effect_name:
			"burn":
				if effect["tick_timer"] <= 0:
					_apply_burn_damage(effect["power"])
					effect["tick_timer"] = 1.0  # 每秒触发一次

			"poison":
				if effect["tick_timer"] <= 0:
					_apply_poison_damage(effect["power"])
					effect["tick_timer"] = 0.5  # 每0.5秒触发一次

			"freeze":
				# 冰冻时减速（在移动组件中处理）
				pass

			"slow":
				# 减速效果（在移动组件中处理）
				pass

			"stun":
				# 眩晕效果（在实体中处理）
				pass

	# 移除过期效果
	for effect_name in effects_to_remove:
		remove_effect(effect_name)

	# 衰减冰霜叠层
	if frost_stacks > 0:
		frost_stacks = max(0, frost_stacks - int(delta * 2))  # 每0.5秒减1层

## 应用燃烧伤害
func _apply_burn_damage(power: float) -> void:
	if not entity:
		return

	var damage = power * 5.0  # 每秒5倍强度的伤害

	# 查找HealthComponent
	var health_component = entity.get_node_or_null("HealthComponent")
	if health_component and health_component.has_method("take_damage"):
		health_component.take_damage(damage)

## 应用中毒伤害
func _apply_poison_damage(power: float) -> void:
	if not entity:
		return

	var damage = power * 3.0

	var health_component = entity.get_node_or_null("HealthComponent")
	if health_component and health_component.has_method("take_damage"):
		health_component.take_damage(damage)

## 获取移动速度修正系数
func get_speed_modifier() -> float:
	var modifier = 1.0

	if has_effect("freeze"):
		modifier *= 0.0  # 完全冻结

	if has_effect("slow"):
		var slow_power = get_effect_power("slow")
		modifier *= (1.0 - slow_power * 0.5)  # 最多减速50%

	return clamp(modifier, 0.0, 1.0)

## 检查是否被眩晕
func is_stunned() -> bool:
	return has_effect("stun")

## 检查是否被冰冻
func is_frozen() -> bool:
	return has_effect("freeze")

## 获取易伤倍率
func get_vulnerability_multiplier() -> float:
	if has_effect("vulnerability"):
		return 1.0 + get_effect_power("vulnerability") * 0.2  # 每层增加20%伤害
	return 1.0

## 创建视觉效果
func _create_visual_effect(effect_name: String) -> void:
	match effect_name:
		"burn":
			if not burn_particles:
				burn_particles = GPUParticles2D.new()
				burn_particles.amount = 20
				burn_particles.lifetime = 0.5
				burn_particles.emitting = true
				# 这里可以配置粒子属性
				entity.add_child(burn_particles)

		"freeze":
			if not freeze_overlay:
				freeze_overlay = Sprite2D.new()
				freeze_overlay.modulate = Color(0.5, 0.8, 1.0, 0.5)
				# 可以设置冰冻纹理
				entity.add_child(freeze_overlay)

		"poison":
			if not poison_particles:
				poison_particles = GPUParticles2D.new()
				poison_particles.amount = 15
				poison_particles.lifetime = 0.8
				poison_particles.modulate = Color(0.5, 1.0, 0.5)
				poison_particles.emitting = true
				entity.add_child(poison_particles)

## 移除视觉效果
func _remove_visual_effect(effect_name: String) -> void:
	match effect_name:
		"burn":
			if burn_particles:
				burn_particles.queue_free()
				burn_particles = null

		"freeze":
			if freeze_overlay:
				freeze_overlay.queue_free()
				freeze_overlay = null

		"poison":
			if poison_particles:
				poison_particles.queue_free()
				poison_particles = null

## 更新状态视觉
func _update_status_visuals() -> void:
	# 更新冰冻叠层视觉（可以显示霜冻效果）
	if frost_stacks > 0 and entity:
		# 可以添加霜冻叠层的视觉反馈
		pass

## 清除所有视觉效果
func _clear_all_visuals() -> void:
	if burn_particles:
		burn_particles.queue_free()
		burn_particles = null
	if freeze_overlay:
		freeze_overlay.queue_free()
		freeze_overlay = null
	if poison_particles:
		poison_particles.queue_free()
		poison_particles = null

## 获取效果类型枚举
func _get_effect_type(effect_name: String) -> int:
	match effect_name:
		"burn": return EffectType.BURN
		"freeze": return EffectType.FREEZE
		"poison": return EffectType.POISON
		"slow": return EffectType.SLOW
		"stun": return EffectType.STUN
		"vulnerability": return EffectType.VULNERABILITY
		"frost": return -2  # 特殊处理
		_: return -1

## 清理资源
func cleanup() -> void:
	_clear_all_visuals()
	active_effects.clear()
