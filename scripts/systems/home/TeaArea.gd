extends Area2D

## TeaArea - 喝茶区域
## 放置在茶桌位置，按E键喝茶

var player_in_range: bool = false
@onready var prompt_label: Label = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_create_prompt_label()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("interact"):
		_interact()

func _interact() -> void:
	if HomeInteractionSystem:
		HomeInteractionSystem.interact_tea()

func _create_prompt_label() -> void:
	prompt_label = Label.new()
	prompt_label.text = "[E] 喝茶"
	prompt_label.position = Vector2(-30, -60)
	prompt_label.visible = false
	add_child(prompt_label)
