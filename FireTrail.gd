extends Area2D

# FireTrail - 独立的火墙逻辑脚本
# 负责处理火墙内的持续伤害

var damage_amount: float = 10.0
var damage_interval: float = 0.2
var enemies_in_fire = {} # {enemy: timer}

func _ready():
	# 设置Timer
	var timer = Timer.new()
	timer.wait_time = damage_interval
	timer.autostart = true
	timer.timeout.connect(_on_damage_tick)
	add_child(timer)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup(dmg: float, duration: float):
	damage_amount = dmg

	# 自毁计时器 - [修复] 使用 Timer 节点而非 SceneTreeTimer 避免 Lambda 捕获错误
	var destroy_timer = Timer.new()
	destroy_timer.wait_time = duration
	destroy_timer.one_shot = true
	destroy_timer.autostart = true
	add_child(destroy_timer)
	destroy_timer.timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)

func _on_body_entered(body):
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		enemies_in_fire[body] = 0.0

func _on_body_exited(body):
	if body in enemies_in_fire:
		enemies_in_fire.erase(body)

func _on_damage_tick():
	# 遍历字典时如果修改它可能会出问题，所以复制键列表
	var targets = enemies_in_fire.keys()
	
	for enemy in targets:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			# 造成伤害
			enemy.take_damage(damage_amount)
			
			# 燃烧效果累积
			enemies_in_fire[enemy] += damage_interval
			if enemies_in_fire[enemy] >= 1.0:
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(5.0, 2.0)
				enemies_in_fire[enemy] = 0.0
		else:
			# 敌人已失效
			enemies_in_fire.erase(enemy)
