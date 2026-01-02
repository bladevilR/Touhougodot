extends GameComponent
## 阴影组件 - 为实体管理阴影
##
## 职责:
## - 为任何实体创建和管理阴影
## - 自动同步阴影位置、缩放、可见性
## - 独立的阴影配置（方向、角度、倾斜）
##
## 使用示例:
##   var shadow_component = ShadowComponent.new()
##   shadow_component.shadow_size = Vector2(40, 20)
##   shadow_component.use_entity_texture = true
##   player.add_child(shadow_component)

class_name ShadowComponent

# 阴影精灵
var shadow_sprite: Sprite2D = null

# 阴影配置
var shadow_size: Vector2 = Vector2(40, 20)
var shadow_offset: Vector2 = Vector2(0, 0)
var shadow_skew: float = 0.5
var height_factor: float = 1.0

# 是否使用实体纹理（true）还是椭圆阴影（false）
var use_entity_texture: bool = true

# 阴影颜色和透明度
var shadow_color: Color = Color(0, 0, 0, 0.35)

# 是否自动同步阴影（每帧更新）
var auto_sync: bool = true

## 组件初始化
func _on_entity_ready() -> void:
	if not entity:
		push_error("ShadowComponent: 实体为空")
		return

	# 等待RenderSystem准备好
	await get_tree().process_frame

	# 创建阴影
	create_shadow()

## 每帧更新
func _on_entity_process(delta: float) -> void:
	if auto_sync and shadow_sprite and is_instance_valid(shadow_sprite):
		sync_shadow()

## 创建阴影
func create_shadow() -> void:
	var render_system = ServiceLocator.get_service("render_system")
	if not render_system:
		push_warning("ShadowComponent: RenderSystem 未找到，稍后重试")
		# 延迟重试
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(self):
			create_shadow()
		return

	# 使用RenderSystem创建阴影
	shadow_sprite = render_system.create_shadow_for_entity(
		entity,
		shadow_size,
		shadow_offset,
		height_factor,
		not use_entity_texture  # force_ellipse
	)

	if shadow_sprite:
		shadow_sprite.modulate = shadow_color
		print("ShadowComponent: 为 %s 创建了阴影" % entity.name)
	else:
		push_error("ShadowComponent: 阴影创建失败")

## 同步阴影状态
func sync_shadow() -> void:
	if not shadow_sprite or not entity:
		return

	# 获取实体的Sprite2D（如果使用实体纹理）
	var source_sprite: Sprite2D = null
	if use_entity_texture:
		if entity is Sprite2D:
			source_sprite = entity
		else:
			for child in entity.get_children():
				if child is Sprite2D:
					source_sprite = child
					break

	# 同步纹理和帧（如果使用实体纹理）
	if use_entity_texture and source_sprite and source_sprite.texture:
		shadow_sprite.texture = source_sprite.texture
		shadow_sprite.frame = source_sprite.frame
		shadow_sprite.flip_h = source_sprite.flip_h

	# 同步可见性
	shadow_sprite.visible = entity.visible

## 设置阴影可见性
func set_shadow_visible(visible: bool) -> void:
	if shadow_sprite:
		shadow_sprite.visible = visible

## 设置阴影透明度
func set_shadow_alpha(alpha: float) -> void:
	shadow_color.a = clamp(alpha, 0.0, 1.0)
	if shadow_sprite:
		shadow_sprite.modulate = shadow_color

## 设置阴影颜色
func set_shadow_color(color: Color) -> void:
	shadow_color = color
	if shadow_sprite:
		shadow_sprite.modulate = shadow_color

## 重新创建阴影（当配置改变时）
func recreate_shadow() -> void:
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.queue_free()
		shadow_sprite = null

	create_shadow()

## 清理阴影资源
func cleanup() -> void:
	if shadow_sprite and is_instance_valid(shadow_sprite):
		shadow_sprite.queue_free()
		shadow_sprite = null
