extends Area2D
class_name NitoriNPC

# NitoriNPC - 河童商人NPC
# 玩家靠近后按E键对话进入商店

@export var interaction_radius: float = 80.0  # 交互范围

var player_in_range: bool = false
var player: Node2D = null
var prompt_label: Label = null  # 提示文字

@onready var sprite = $Sprite2D

func _ready():
	add_to_group("npc")

	# 加载河童立绘
	if sprite:
		var texture_path = "res://assets/characters/hetong.png"
		if ResourceLoader.exists(texture_path):
			sprite.texture = load(texture_path)
			print("Nitori sprite loaded successfully")
		else:
			print("Warning: Nitori sprite not found at: ", texture_path)

	# 设置碰撞检测
	collision_layer = 0
	collision_mask = 1  # 检测玩家

	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 创建交互提示
	_create_prompt_label()

	# 添加阴影
	_create_shadow()

func _create_prompt_label():
	"""创建交互提示标签"""
	prompt_label = Label.new()
	prompt_label.text = "按 E 对话"
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-40, -80)
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	prompt_label.visible = false
	add_child(prompt_label)

func _create_shadow():
	"""创建阴影"""
	var map_system = get_tree().get_first_node_in_group("map_system")
	if map_system and map_system.has_method("create_shadow_for_entity"):
		var shadow_size = Vector2(50, 15)
		map_system.create_shadow_for_entity(self, shadow_size, Vector2(0, 0))

func _process(_delta):
	# 检测E键交互
	if player_in_range and Input.is_action_just_pressed("interact"):
		_interact()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player = body
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		player = null
		if prompt_label:
			prompt_label.visible = false

func _interact():
	"""与河童对话，打开商店"""
	# 显示河童对话
	_show_nitori_dialogue()

func _show_nitori_dialogue():
	"""显示河童对话立绘"""
	# 使用对话序列系统
	var dialogue_data = [
		{
			"speaker": "妹红",
			"text": "河童，好久不见啊！",
			"portrait": "res://assets/characters/1C.png"
		},
		{
			"speaker": "河童",
			"text": "哎呀！是妹红啊！来得正好，我这有很多新发明的道具，要不要试试？",
			"portrait": "res://assets/characters/2C.png"
		}
	]

	await _play_dialogue(dialogue_data)
	_open_shop()

func _play_dialogue(data: Array):
	"""播放对话序列"""
	var dm = _get_dialogue_manager()
	if dm:
		dm.show_sequence(data)
		await dm.dialogue_finished
	else:
		await get_tree().create_timer(1.0).timeout

func _get_dialogue_manager() -> Node:
	# 检查是否存在 DialogueLayer/DialogueManager
	var existing_layer = get_tree().root.get_node_or_null("DialogueLayer")
	if existing_layer:
		return existing_layer.get_node_or_null("DialogueManager")
	
	# 创建新的 Layer 和 Manager
	var layer = CanvasLayer.new()
	layer.layer = 128 # 确保在最上层
	layer.name = "DialogueLayer"
	get_tree().root.add_child(layer)
	
	var DialoguePortraitScript = load("res://DialoguePortrait.gd")
	var dm = null
	if DialoguePortraitScript:
		dm = DialoguePortraitScript.new()
		dm.name = "DialogueManager"
		layer.add_child(dm)
	
	return dm

func _open_shop():
	"""打开商店"""
	var shop = get_tree().get_first_node_in_group("nitori_shop")
	if shop and shop.has_method("open_shop"):
		shop.open_shop()
	else:
		# 尝试通过信号打开
		SignalBus.shop_opened.emit()
