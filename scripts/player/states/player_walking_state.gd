#player_walking_state.gd
extends PlayerState
class_name PlayerWalkingState




func _on_walking_state_physics_processing(_delta: float) -> void:
	if Input.is_action_pressed("sprint"):
		player_controller.state_chart.send_event("onSprinting")


func _on_walking_state_entered() -> void:
	player_controller.walk()
