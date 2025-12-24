#player_sprinting_state.gd
extends PlayerState
class_name PlayerSprintingState


func _on_sprinting_state_physics_processing(_delta: float) -> void:
	if not Input.is_action_pressed("sprint"):
		player_controller.state_chart.send_event("onWalking")

func _on_sprinting_state_entered() -> void:
	player_controller.sprint()
