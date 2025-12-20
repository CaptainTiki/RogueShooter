extends Control
class_name PauseMenu


func _show_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show()

func _hide_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hide()

func _unhandled_input(event: InputEvent) -> void:	
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_hide_menu()
		else:
			_show_menu()
