extends Area2D

## SleepArea - 睡眠区域
## 放置在床铺位置，按E键睡觉

var player_in_range: bool = false
@onready var prompt_label: Label = null

func _ready():
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 创建提示标签
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
	if player_in_range and Input.is_action_just_pressed("interact"):  # E键
		_interact()

func _interact() -> void:
	if FatigueSystem and FatigueSystem.current_fatigue < 30:
		# 疲劳太低，不想睡觉
		SignalBus.show_notification.emit("还不困，不想睡觉", Color.ORANGE)
		return

	# 调用小屋交互系统的睡眠功能
	if HomeInteractionSystem:
		HomeInteractionSystem.interact_sleep()

func _create_prompt_label() -> void:
	prompt_label = Label.new()
	prompt_label.text = "[E] 睡觉"
	prompt_label.position = Vector2(-30, -60)
	prompt_label.visible = false
	add_child(prompt_label)
