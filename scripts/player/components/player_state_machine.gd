#player_state_machine.gd
extends Node
class_name PlayerStateMachine

@export var debug : bool = false
@export_category("References")
@export var player_controller : PlayerController

func _process(_delta : float ) -> void:
	player_controller.state_chart.set_expression_property("Player Velocity", player_controller.velocity)
	player_controller.state_chart.set_expression_property("Player Hitting Head", player_controller.crouch_check.is_colliding())
	player_controller.state_chart.set_expression_property("Looking At: ", player_controller.interaction_raycast.current_object)
