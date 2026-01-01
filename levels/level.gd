extends Node3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		# If weapon bench (or other screen) is open, let it handle ESC.
		# If nothing else handled it, open pause.
		MainScene.instance.ui.toggle_pause_menu()
		get_viewport().set_input_as_handled()
