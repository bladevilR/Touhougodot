extends Node2D
## 渲染系统 - 统一管理光照、阴影、雾效等视觉效果
##
## 职责:
## - 管理光照层（lighting_layer）
## - 管理阴影层（shadow_layer）
## - 提供光照风格切换接口
## - 管理雾层动画
##
## 使用示例:
##   # 切换光照风格
##   render_system.set_lighting_style(RenderSystem.LightingStyle.OUTSKIRTS)
##
##   # 添加实体阴影
##   var shadow = render_system.create_shadow_for_entity(player_sprite)

class_name RenderSystem

# 光照风格枚举
enum LightingStyle {
	OUTSKIRTS,          # 竹林外围 - 明亮通透
	DEEP_FOREST_MIST,   # 竹林深处 - 浓雾
	DEEP_FOREST_BEAM    # 竹林深处 - 光柱
}

# 阴影常数
const SHADOW_DIRECTION = Vector2(5, 0)
const SHADOW_ANGLE = -0.5
const SHADOW_SKEW = 0.5

# 层级
var lighting_layer: Node2D
var shadow_layer: Node2D
var fog_layer: CanvasLayer = null

# 地图尺寸（从MapSystem传入）
var map_width: float = 2400.0
var map_height: float = 1800.0

func _ready():
	print("RenderSystem: 初始化中...")
	setup_layers()

	# 注册到ServiceLocator
	ServiceLocator.register_service("render_system", self)
	print("RenderSystem: 初始化完成")

## 设置渲染层级
func setup_layers() -> void:
	# 光照层（用于世界空间的光柱等效果）
	if not lighting_layer:
		lighting_layer = Node2D.new()
		lighting_layer.name = "LightingLayer"
		lighting_layer.z_index = 10
		add_child(lighting_layer)

	# 阴影层
	if not shadow_layer:
		shadow_layer = Node2D.new()
		shadow_layer.name = "ShadowLayer"
		shadow_layer.z_index = -10
		add_child(shadow_layer)

	print("RenderSystem: 渲染层级已设置")

## 设置地图尺寸
func set_map_size(width: float, height: float) -> void:
	map_width = width
	map_height = height

## 切换光照风格
func set_lighting_style(style: LightingStyle) -> void:
	if not is_inside_tree():
		return

	_clear_lighting()

	match style:
		LightingStyle.OUTSKIRTS:
			_create_lighting_outskirts()
		LightingStyle.DEEP_FOREST_MIST:
			_create_lighting_deep_forest_mist()
		LightingStyle.DEEP_FOREST_BEAM:
			_create_lighting_deep_forest_beam()
		_:
			_create_lighting_outskirts()

## 清除所有光照效果
func _clear_lighting() -> void:
	# 清除雾层
	if fog_layer and is_instance_valid(fog_layer):
		fog_layer.queue_free()
		fog_layer = null

	# 清除CanvasModulate
	for child in get_children():
		if child is CanvasModulate:
			child.queue_free()

	# 清除WorldEnvironment
	for child in get_parent().get_children():
		if child is WorldEnvironment and is_instance_valid(child):
			child.queue_free()

	# 清除光照层中的光柱
	if lighting_layer:
		for child in lighting_layer.get_children():
			child.queue_free()

## 竹林外围光照 - 明亮通透，高对比度
func _create_lighting_outskirts() -> void:
	print("RenderSystem: 创建 OUTSKIRTS 光照")

	# 1. CanvasModulate（压暗一点，增加氛围）
	var modulate = CanvasModulate.new()
	modulate.color = Color(0.75, 0.75, 0.8)  # 稍微偏冷的暗色
	add_child(modulate)

	# 2. WorldEnvironment
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_CANVAS

	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_strength = 0.8
	env.glow_bloom = 0.1

	env.adjustment_enabled = true
	env.adjustment_contrast = 1.2
	env.adjustment_saturation = 1.1
	env.adjustment_brightness = 1.0

	world_env.environment = env
	get_parent().call_deferred("add_child", world_env)

	# 3. 添加薄雾
	create_fog_layer(0.25)

## 竹林深处光照 - 浓雾
func _create_lighting_deep_forest_mist() -> void:
	print("RenderSystem: 创建 DEEP FOREST MIST 光照")

	# CanvasModulate（更暗）
	var modulate = CanvasModulate.new()
	modulate.color = Color(0.3, 0.35, 0.4)
	add_child(modulate)

	# 浓雾
	create_fog_layer(0.6)

## 竹林深处光照 - 光柱
func _create_lighting_deep_forest_beam() -> void:
	print("RenderSystem: 创建 DEEP FOREST BEAM 光照")

	# 1. CanvasModulate（压暗）
	var modulate = CanvasModulate.new()
	modulate.color = Color(0.4, 0.45, 0.55)  # 蓝调黑暗
	add_child(modulate)

	# 2. 世界空间光柱
	var beam_count = 12
	var mat_add = CanvasItemMaterial.new()
	mat_add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	for i in range(beam_count):
		# 随机位置
		var pos = Vector2(
			randf_range(100, map_width - 100),
			randf_range(100, map_height - 100)
		)

		# 光柱 Sprite
		var beam = Sprite2D.new()
		beam.texture = _create_light_beam_texture(80, 400)
		beam.position = pos
		beam.rotation = randf_range(-0.2, 0.2)
		beam.scale = Vector2(randf_range(0.5, 1.0), randf_range(0.8, 1.2))
		beam.modulate = Color(1.0, 0.95, 0.8, randf_range(0.3, 0.6))
		beam.material = mat_add
		beam.z_index = 5

		lighting_layer.add_child(beam)

		# 简单旋转动画
		var tween = beam.create_tween().set_loops()
		tween.tween_property(beam, "rotation", beam.rotation + 0.1, 3.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(beam, "rotation", beam.rotation - 0.1, 3.0).set_trans(Tween.TRANS_SINE)

	# 3. 薄雾
	create_fog_layer(0.4)

## 创建雾层
func create_fog_layer(density: float) -> void:
	if fog_layer and is_instance_valid(fog_layer):
		fog_layer.queue_free()

	fog_layer = CanvasLayer.new()
	fog_layer.name = "FogLayer"
	fog_layer.layer = 5  # 在World之上，UI之下
	get_tree().root.add_child(fog_layer)

	var fog_rect = TextureRect.new()
	fog_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fog_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	# 噪声纹理
	var noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.005
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM

	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = 512
	noise_tex.height = 512
	noise_tex.seamless = true

	fog_rect.texture = noise_tex
	fog_rect.modulate = Color(0.9, 0.95, 1.0, density)  # 蓝白色雾

	# 材质：加法混合
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fog_rect.material = mat

	fog_layer.add_child(fog_rect)

	# 流动动画
	_start_fog_flow_animation(fog_rect, density)

## 雾层流动动画
func _start_fog_flow_animation(fog_rect: TextureRect, density: float) -> void:
	if not is_instance_valid(fog_rect) or not is_instance_valid(self) or not is_inside_tree():
		return

	var tween = fog_rect.create_tween()
	tween.tween_property(fog_rect, "modulate:a", density * 0.8, 3.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(fog_rect, "modulate:a", density * 1.2, 3.0).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(func():
		if not is_instance_valid(self) or is_queued_for_deletion():
			return
		if is_instance_valid(fog_rect) and is_inside_tree():
			_start_fog_flow_animation(fog_rect, density)
	)

## 设置雾层密度
func set_fog_density(density: float) -> void:
	if fog_layer and is_instance_valid(fog_layer):
		var rect = fog_layer.get_child(0)
		if rect:
			rect.modulate.a = density

## 创建光柱纹理
func _create_light_beam_texture(width: int, height: int) -> ImageTexture:
	width = max(width, 2)
	height = max(height, 2)
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var cx = width / 2.0

	for x in range(width):
		for y in range(height):
			var dx = abs(x - cx) / (width / 2.0)
			var fade = 1.0 - dx
			fade = pow(fade, 2.0)
			var brightness = fade * 0.8
			image.set_pixel(x, y, Color(brightness, brightness, brightness, fade))

	return ImageTexture.create_from_image(image)

## 创建阴影纹理（椭圆形）
func _create_shadow_texture(width: int, height: int) -> ImageTexture:
	width = max(width, 2)
	height = max(height, 2)
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var cx = width / 2.0
	var cy = height / 2.0

	for x in range(width):
		for y in range(height):
			var dx = (x - cx) / (width / 2.0)
			var dy = (y - cy) / (height / 2.0)
			var d = dx * dx + dy * dy
			if d <= 1.0:
				var alpha = pow(1.0 - sqrt(d), 2.0) * 0.8
				image.set_pixel(x, y, Color(0, 0, 0, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(image)

## 为实体创建阴影
##
## @param parent: 父节点（实体本身）
## @param size: 阴影大小（用于fallback椭圆）
## @param offset: 阴影偏移
## @param height_factor: 高度因子（影响阴影贴合度）
## @param force_ellipse: 强制使用椭圆阴影而非实体纹理阴影
## @return: 创建的阴影 Sprite2D
func create_shadow_for_entity(parent: Node2D, size: Vector2 = Vector2(40, 20), offset: Vector2 = Vector2(0, 0), height_factor: float = 1.0, force_ellipse: bool = false) -> Sprite2D:
	var source_sprite: Sprite2D = null
	if not force_ellipse:
		if parent is Sprite2D:
			source_sprite = parent
		else:
			for child in parent.get_children():
				if child is Sprite2D:
					source_sprite = child
					break

	var shadow: Sprite2D = null

	if not force_ellipse and source_sprite and source_sprite.texture:
		# 使用实体纹理创建阴影
		shadow = Sprite2D.new()
		shadow.texture = source_sprite.texture
		shadow.hframes = source_sprite.hframes
		shadow.vframes = source_sprite.vframes
		shadow.frame = source_sprite.frame
		shadow.flip_h = source_sprite.flip_h

		# 计算阴影底部对齐
		var img = source_sprite.texture.get_image()
		var visible_bottom_y = float(source_sprite.texture.get_height())
		var visible_center_x = float(source_sprite.texture.get_width()) / 2.0

		if img:
			var used = img.get_used_rect()
			visible_bottom_y = float(used.end.y)
			visible_center_x = float(used.get_center().x)

		# 计算源精灵的视觉底部
		var source_local_bottom_y = visible_bottom_y

		# 根据高度因子动态缩放接触距离
		var contact_eat_in = 40.0 * (height_factor / 2.5)
		source_local_bottom_y -= contact_eat_in

		# 调整居中/偏移
		if source_sprite.centered:
			source_local_bottom_y -= source_sprite.texture.get_height() / 2.0
		source_local_bottom_y += source_sprite.offset.y

		# 应用源缩放
		var source_feet_offset = Vector2(0, source_local_bottom_y * source_sprite.scale.y)

		# 配置阴影锚点到其视觉底部
		shadow.centered = false
		shadow.offset = Vector2(-visible_center_x, -visible_bottom_y)

		# 定位阴影到计算的脚部位置
		shadow.position = source_sprite.position + source_feet_offset + offset

		# 变换：翻转Y（反射）+ 倾斜
		shadow.scale = Vector2(source_sprite.scale.x, source_sprite.scale.y * -0.5)
		shadow.skew = SHADOW_SKEW

	else:
		# Fallback: 通用椭圆阴影
		shadow = Sprite2D.new()
		shadow.texture = _create_shadow_texture(int(size.x), int(size.y))
		shadow.position = SHADOW_DIRECTION + offset
		shadow.rotation = 0.0
		shadow.skew = SHADOW_SKEW
		shadow.scale = Vector2(1.0, 1.0)

	shadow.name = "Shadow"
	shadow.z_index = -10
	shadow.modulate = Color(0, 0, 0, 0.35)

	# 添加到阴影层而非父节点
	shadow_layer.call_deferred("add_child", shadow)

	return shadow

## 添加动态阴影到阴影层
func add_shadow(shadow: Sprite2D) -> void:
	if shadow_layer:
		shadow_layer.add_child(shadow)

## 创建动态光源
func create_dynamic_light(position: Vector2, color: Color = Color.WHITE, energy: float = 1.0) -> Light2D:
	var light = PointLight2D.new()
	light.position = position
	light.color = color
	light.energy = energy
	light.texture_scale = 2.0

	lighting_layer.add_child(light)
	return light

## 清理所有动态效果
func cleanup() -> void:
	_clear_lighting()

	# 清理阴影层
	if shadow_layer:
		for child in shadow_layer.get_children():
			child.queue_free()

	# 清理光照层
	if lighting_layer:
		for child in lighting_layer.get_children():
			child.queue_free()

	print("RenderSystem: 已清理所有渲染效果")
