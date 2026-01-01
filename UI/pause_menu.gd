extends Control
class_name PauseMenu

func toggle_pause_menu() -> void:
	var pause_menu := $Screens/PauseMenu
	pause_menu.visible = not pause_menu.visible

	get_tree().paused = pause_menu.visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if pause_menu.visible else Input.MOUSE_MODE_CAPTURED)


func _on_resume_bn_pressed() -> void:
	MainScene.instance.ui.toggle_pause_menu()


func _on_exit_bn_pressed() -> void:
	MainScene.instance.quit_game()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		MainScene.instance.ui.toggle_pause_menu()
		get_viewport().set_input_as_handled()
