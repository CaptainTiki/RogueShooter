extends CanvasLayer
class_name UserInterface

@onready var reticle: ReticleDraw = $CenterContainer/ReticleDraw
@onready var screens: Control = $Screens

func _ready() -> void:
	for child in screens.get_children():
		child.visible = false

func push_ui(screen: Control) -> void:
	print("adding: ", screen.name)
	screens.add_child(screen)

func toggle_pause_menu() -> void:
	var pause_menu : PauseMenu = $Screens/PauseMenu
	pause_menu.visible = not pause_menu.visible

	get_tree().paused = pause_menu.visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if pause_menu.visible else Input.MOUSE_MODE_CAPTURED)
