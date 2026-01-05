extends Area2D

## Harvestable - 可采集物体基类
## 用于场景中可以采集的环境物体（花、竹笋、矿石等）

class_name Harvestable

# 物体配置
@export var item_id: String = ""  # 物品 ID（对应 ItemData）
@export var harvest_amount_min: int = 1  # 采集数量最小值
@export var harvest_amount_max: int = 1  # 采集数量最大值
@export var respawn_time: float = 0.0  # 重生时间（秒），0 表示不重生（采完就消失）
@export var require_tool: String = ""  # 需要的工具（例如："pickaxe"），空字符串表示不需要

# 视觉配置
@export var sprite_normal: Texture2D  # 正常状态纹理
@export var sprite_harvested: Texture2D  # 采集后纹理（可选）

# 音效
@export var harvest_sound: AudioStream  # 采集音效

# 内部状态
var is_harvestable: bool = true
var respawn_timer: float = 0.0
var player_nearby: bool = false
var nearby_player: Node = null

# 节点引用
@onready var sprite: Sprite2D = null
@onready var collision_shape: CollisionShape2D = null
@onready var interaction_label: Label = null

# 信号
signal harvested(item_id: String, amount: int)

func _ready():
	# 自动查找子节点
	sprite = get_node_or_null("Sprite2D")
	collision_shape = get_node_or_null("CollisionShape2D")
	interaction_label = get_node_or_null("InteractionLabel")

	# 设置碰撞层
	collision_layer = 8  # Layer 8: Harvestable
	collision_mask = 1   # 只检测玩家 (Layer 1)

	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 设置初始纹理
	if sprite and sprite_normal:
		sprite.texture = sprite_normal

	# 隐藏交互提示
	if interaction_label:
		interaction_label.visible = false

	# 添加到组
	add_to_group("harvestable")

	print("[Harvestable] %s 初始化完成" % name)

func _process(_delta):
	# 更新交互提示
	if interaction_label:
		if player_nearby and is_harvestable:
			interaction_label.visible = true
			# 根据是否需要工具显示不同提示
			if require_tool != "":
				var tool_name = _get_tool_display_name(require_tool)
				interaction_label.text = "[E] 采集 (需要%s)" % tool_name
			else:
				interaction_label.text = "[E] 采集"
		else:
			interaction_label.visible = false

func _input(event):
	# 处理采集输入
	if event.is_action_pressed("interact") and player_nearby and is_harvestable:
		_try_harvest()

## 尝试采集
func _try_harvest():
	if not is_harvestable:
		return

	# 检查是否需要工具
	if require_tool != "" and nearby_player:
		# TODO: 检查玩家是否装备了所需工具
		# if not nearby_player.has_tool(require_tool):
		#     _show_message("需要 %s" % _get_tool_display_name(require_tool))
		#     return
		pass

	# 执行采集
	_harvest()

## 执行采集
func _harvest():
	if not is_harvestable:
		return

	# 计算采集数量
	var amount = randi_range(harvest_amount_min, harvest_amount_max)

	# 添加物品到背包
	if item_id != "":
		InventoryManager.add_item(item_id, amount)

		# 获取物品名称用于显示
		var item_data = ItemData.get_item(item_id)
		var item_name = item_data.get("name", item_id)
		_show_harvest_message("获得 %s x%d" % [item_name, amount])

	# 发射信号
	harvested.emit(item_id, amount)

	# 播放采集音效
	if harvest_sound:
		_play_harvest_sound()

	# 视觉反馈
	_play_harvest_animation()

	# 标记为已采集
	is_harvestable = false

	print("[Harvestable] 采集 %s x%d，物品将从世界中移除" % [item_id, amount])

## 重生
func _respawn():
	is_harvestable = true
	respawn_timer = 0.0

	# 恢复外观
	_update_appearance()

	# 重生动画
	_play_respawn_animation()

	print("[Harvestable] %s 已重生" % name)

## 更新外观
func _update_appearance():
	if not sprite:
		return

	if is_harvestable:
		# 恢复正常纹理
		if sprite_normal:
			sprite.texture = sprite_normal
		sprite.modulate = Color.WHITE
	else:
		# 采集后纹理
		if sprite_harvested:
			sprite.texture = sprite_harvested
		else:
			# 如果没有采集后纹理，变暗
			sprite.modulate = Color(0.5, 0.5, 0.5, 0.5)

## 播放采集动画
func _play_harvest_animation():
	if not sprite:
		return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# 缩小消失
	tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.2)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)

	# 长期RPG：采完直接删除节点
	tween.tween_callback(func():
		if is_instance_valid(self):
			queue_free()  # 完全移除这个可采集物
	)

## 播放重生动画
func _play_respawn_animation():
	if not sprite:
		return

	# 重置透明度和缩放
	sprite.modulate.a = 0.0
	sprite.scale = Vector2(0.5, 0.5)
	visible = true

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)

	# 放大出现
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.5)
	tween.parallel().tween_property(sprite, "modulate:a", 1.0, 0.5)

## 播放采集音效
func _play_harvest_sound():
	if not harvest_sound:
		return

	# 创建临时音频播放器
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = harvest_sound
	audio_player.volume_db = -5.0
	add_child(audio_player)
	audio_player.play()

	# 播放完后自动删除
	audio_player.finished.connect(func():
		if is_instance_valid(audio_player):
			audio_player.queue_free()
	)

## 显示采集消息
func _show_harvest_message(message: String):
	# 通过信号总线显示消息
	SignalBus.show_notification.emit(message, Color.GREEN)

	# 创建漂浮文字
	_create_floating_text(message)

## 创建漂浮文字
func _create_floating_text(text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color.GREEN)
	label.add_theme_font_size_override("font_size", 20)
	label.position = global_position + Vector2(0, -50)
	label.z_index = 100

	get_tree().current_scene.add_child(label)

	# 漂浮动画
	var tween = label.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func():
		if is_instance_valid(label):
			label.queue_free()
	)

## 获取工具显示名称
func _get_tool_display_name(tool_id: String) -> String:
	match tool_id:
		"pickaxe":
			return "镐子"
		"axe":
			return "斧头"
		"sickle":
			return "���刀"
		"fishing_rod":
			return "钓鱼竿"
		_:
			return tool_id

## 玩家进入范围
func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_nearby = true
		nearby_player = body
		print("[Harvestable] 玩家进入 %s 范围" % name)

## 玩家离开范围
func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_nearby = false
		nearby_player = null
		print("[Harvestable] 玩家离开 %s 范围" % name)
