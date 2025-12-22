extends Node2D

var color = Color(1.0, 0.0, 0.0, 0.3)
var radius = 30.0
var tween: Tween

func _ready():
	# Simple animation: fade in/out or scale
	scale = Vector2.ZERO
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", PI, 0.5)
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.lightened(0.2), 2.0)

func disappear():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
