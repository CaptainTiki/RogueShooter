extends Control
class_name WeaponBenchUI

@export var debug : bool = true

var bench: WeaponBench = null
var actor: PlayerController = null

func open_for(player: Node3D, _bench: WeaponBench) -> void:
	if player is PlayerController:
		actor = player as PlayerController
	bench = _bench
	visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if bench != null:
			bench.close_ui()
		get_viewport().set_input_as_handled()


func _on_exit_bn_pressed() -> void:
	if debug:
		print("BenchUI: exit button pressed!")
	if bench != null:
			bench.close_ui()
	else:
		if debug:
			print("BenchUI: exit button pressed, but bench was null!")
