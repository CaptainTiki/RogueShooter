extends Control

func _ready() -> void:
	World.setup_world()
	#TODO: display a title screen - wait for click / timer
	queue_free()
