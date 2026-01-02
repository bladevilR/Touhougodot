extends GameComponent
## 精灵组件 - 管理实体的精灵渲染
##
## 职责:
## - 管理Sprite2D节点
## - 处理动画帧切换
## - 处理翻转和方向
##
## 使用示例:
##   var sprite = SpriteComponent.new()
##   sprite.texture_path = "res://assets/player.png"
##   entity.add_child(sprite)

class_name SpriteComponent

# 精灵节点
var sprite: Sprite2D = null

# 纹理路径
var texture_path: String = ""

# 精灵配置
var centered: bool = true
var offset: Vector2 = Vector2.ZERO
var scale: Vector2 = Vector2.ONE
var flip_h: bool = false
var flip_v: bool = false

# 动画帧配置
var hframes: int = 1
var vframes: int = 1
var current_frame: int = 0

## 组件初始化
func _on_entity_ready() -> void:
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite"
		entity.add_child(sprite)

	# 应用配置
	sprite.centered = centered
	sprite.offset = offset
	sprite.scale = scale
	sprite.flip_h = flip_h
	sprite.flip_v = flip_v
	sprite.hframes = hframes
	sprite.vframes = vframes
	sprite.frame = current_frame

	# 加载纹理
	if texture_path.length() > 0:
		load_texture(texture_path)

## 加载纹理
func load_texture(path: String) -> void:
	texture_path = path
	var texture = ResourceManager.load_resource(path) if ResourceManager else load(path)

	if texture and sprite:
		sprite.texture = texture
	else:
		push_error("SpriteComponent: 无法加载纹理 '%s'" % path)

## 设置帧
func set_frame(frame: int) -> void:
	current_frame = frame
	if sprite:
		sprite.frame = frame

## 设置翻转
func set_flip_h(flip: bool) -> void:
	flip_h = flip
	if sprite:
		sprite.flip_h = flip

func set_flip_v(flip: bool) -> void:
	flip_v = flip
	if sprite:
		sprite.flip_v = flip

## 设置可见性
func set_visible(visible: bool) -> void:
	if sprite:
		sprite.visible = visible

## 设置调制颜色
func set_modulate(color: Color) -> void:
	if sprite:
		sprite.modulate = color

## 获取精灵节点
func get_sprite() -> Sprite2D:
	return sprite

## 清理资源
func cleanup() -> void:
	if sprite and is_instance_valid(sprite):
		sprite.queue_free()
		sprite = null
