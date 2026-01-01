extends Interactable
class_name WeaponBench

var bench_ui_scene: PackedScene = preload("res://scenes/interactable/weaponbench/weapon_bench_ui.tscn")
var ui_instance: WeaponBenchUI = null

func interact(actor: Node3D) -> void:
	super.interact(actor)

	if ui_instance != null and ui_instance.visible:
		close_ui()
	else:
		open_ui(actor)


func create_ui() -> void:
	print("created a ui for weaponbench")
	var main : MainScene = MainScene.instance
	if main == null or main.ui == null:
		push_warning("WeaponBench: Main UI not ready")
		return
		
	if ui_instance == null:
		ui_instance = bench_ui_scene.instantiate() as WeaponBenchUI
		main.ui.push_ui(ui_instance)
		ui_instance.visible = false

func open_ui(actor: Node3D) -> void:
	if ui_instance == null:
		create_ui()
		if ui_instance == null:
			return

	ui_instance.visible = true
	ui_instance.set_process_unhandled_input(true)
	ui_instance.set_process_input(true)

	# (optional) focus something on the UI so ESC works consistently
	ui_instance.grab_focus()

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_ui() -> void:
	if ui_instance == null:
		return

	ui_instance.visible = false
	ui_instance.release_focus()

	# stop UI from eating input while hidden
	ui_instance.set_process_unhandled_input(false)
	ui_instance.set_process_input(false)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
