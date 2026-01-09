extends SubViewportContainer

@onready var visuals = $SubViewport/World3D/Player3DVisuals

func play_animation(anim_name):
	if visuals:
		visuals.play_animation(anim_name)

func set_orientation(dir):
	if visuals:
		visuals.set_orientation(dir)
