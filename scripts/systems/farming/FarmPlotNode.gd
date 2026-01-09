extends Area2D

class_name FarmPlotNode

# 对应的数据对象
var plot_data: FarmPlot

# 视觉组件引用
@onready var soil_sprite: Sprite2D = $SoilSprite
@onready var crop_sprite: Sprite2D = $CropSprite
@onready var selection_sprite: Sprite2D = $SelectionSprite

# 资源预加载 (复用之前的，或者使用纯色占位如果缺素材)
# 这里我们尽量使用现有的素材，或者用颜色块代替
# 为了风格统一，我们假设这里使用简单的颜色块或者现有的花朵图
const TEX_CROP_TOMATO = preload("res://flower_red_tulip.png")
const TEX_CROP_WHEAT = preload("res://flower_yellow_cluster_1.png")
const TEX_CROP_PUMPKIN = preload("res://flower_red_cluster_1.png")
const TEX_CROP_CARROT = preload("res://flower_white_daisy_single.png")
const TEX_SHOOT_SMALL = preload("res://shoot_small_1.png")
const TEX_SHOOT_MEDIUM = preload("res://shoot_medium_1.png")

# 颜色定义
const COLOR_GRASS = Color(0.3, 0.5, 0.3)
const COLOR_DRY = Color(0.55, 0.47, 0.35)
const COLOR_WET = Color(0.4, 0.35, 0.3) # 更深的褐色

func _ready() -> void:
	# 初始隐藏选中框
	if selection_sprite:
		selection_sprite.visible = false
	
	# 确保z_index正确，防止被遮挡，或者依靠y-sort
	# 父节点应该开启 y_sort_enabled
	pass

func setup(data: FarmPlot) -> void:
	plot_data = data
	refresh_visuals()

func refresh_visuals() -> void:
	if not plot_data:
		return
		
	# 1. 更新土地 (这里我们改变modulate或者texture)
	# 假设SoilSprite是一个白色的方块图，我们通过染色来改变状态
	if plot_data.is_tilled:
		if plot_data.water_level > 20.0:
			soil_sprite.modulate = COLOR_WET
		else:
			soil_sprite.modulate = COLOR_DRY
	else:
		soil_sprite.modulate = COLOR_GRASS
		
	# 2. 更新作物
	if plot_data.has_crop():
		crop_sprite.visible = true
		# 简单的生长阶段判断
		if plot_data.growth_stage < 30:
			crop_sprite.texture = TEX_SHOOT_SMALL
		elif plot_data.growth_stage < 100:
			crop_sprite.texture = TEX_SHOOT_MEDIUM
		else:
			# 成熟
			match plot_data.current_crop_id:
				1: crop_sprite.texture = TEX_CROP_TOMATO
				2: crop_sprite.texture = TEX_CROP_WHEAT
				3: crop_sprite.texture = TEX_CROP_PUMPKIN
				4: crop_sprite.texture = TEX_CROP_CARROT
				_: crop_sprite.texture = TEX_SHOOT_MEDIUM
				
		# 稍微调整位置以产生“种在地上”的感觉 (y-offset)
		crop_sprite.position.y = -16
	else:
		crop_sprite.visible = false

func set_highlight(active: bool) -> void:
	if selection_sprite:
		selection_sprite.visible = active

func interact(tool_type: String) -> void:
	# 这个方法将由 Player 调用
	pass
