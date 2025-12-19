extends Node
class_name Interactable

signal interacted

@onready var interact_area: Area3D = $InteractArea

var interactor : Node3D = null
var in_range : bool = false

func _ready() -> void:
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)
	pass

func _on_interact_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		in_range = true
		interactor = body


func _on_interact_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		in_range = false
		interactor = null

func _do_interaction() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if not in_range:
		return
	
	if event.is_action_pressed("interact"):
		interacted.emit()
		_do_interaction()
