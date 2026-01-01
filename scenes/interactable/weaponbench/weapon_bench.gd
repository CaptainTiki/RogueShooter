extends Interactable
class_name WeaponBench

var bench_ui_scene: PackedScene = preload("res://scenes/interactable/weaponbench/weapon_bench_ui.tscn")
var ui_instance: WeaponBenchUI = null

func _ready() -> void:
	debug = true

func interact(actor: Node3D) -> void:
	super.interact(actor)

	if ui_instance != null and ui_instance.visible:
		close_ui()
	else:
		open_ui()


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

func open_ui() -> void:
	if ui_instance == null:
		create_ui()
		if ui_instance == null:
			if debug:
				print(" ui_instance is null, after create attempt")
			return

	ui_instance.open_for(actor, self)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_ui() -> void:
	if ui_instance == null:
		return
	ui_instance.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
