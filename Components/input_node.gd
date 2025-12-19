extends Node
class_name InputNode

var look_delta : Vector2 #look up / down / left / right
var move_input : Vector3 #fwd / bkwd / strafe left and right
var sprint_held : bool = false
var jump_held : bool = false
var jump_pressed : bool = false
var jump_released : bool = false

func get_look_delta() -> Vector2:
	return Vector2.ZERO

func get_move_delta() -> Vector3:
	return Vector3.ZERO
