extends Node3D
class_name Interactable

@export var debug : bool = false
@export var lock_input : bool = false

var actor : Node3D = null

func interact(node : Node3D) -> void:
	if not node:
		return
	
	actor = node
