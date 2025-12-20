extends Control

func _ready() -> void:
	World.setup_world()
	World.setup_menus()
	#TODO: display a title screen - wait for click / timer
	queue_free()
