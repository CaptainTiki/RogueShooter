extends Node3D
class_name InteractionComponent

@export var debug : bool = false
@export var ray : InteractionRaycast
@export var player : PlayerController

@export var max_parent_hops : int = 5

const max_loop_runs : int = 10

func try_interact() -> void:
	if ray == null:
		return
	var hit : Node3D = ray.current_object
	if hit == null:
		if debug:
			print("Try Interact: no node collision")
		return

	var interactable : Interactable = _find_interactable(hit)
	if interactable != null:
		interactable.interact(player)

func _find_interactable(node: Node) -> Interactable:
	if not node:
		return null
	var cur: Node = node
	var runs : int = 0
	while cur != null and runs < max_loop_runs:
		if cur is Interactable:
			return cur as Interactable
		if cur.is_in_group("level_root"):
			if debug:
				print("Try Interact: Reached Level Root, while searching for Interactable!!")
			break
		runs += 1
		cur = cur.get_parent()

	if debug:
			print("Try Interact: Node was not Interactable!")
	return null


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact"):
		try_interact()
