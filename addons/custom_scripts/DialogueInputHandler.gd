extends Control

signal interact_pressed

func _input(event):
	if event.is_action_pressed("interact"):
		interact_pressed.emit()
		get_viewport().set_input_as_handled() # Consume the event
