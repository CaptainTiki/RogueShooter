#player_crouching_state.gd
extends PlayerState
class_name PlayerCrouchingState


func _on_crouching_state_physics_processing(delta: float) -> void:
	player_controller.camera.update_camera_height(delta, -1)

	if not Input.is_action_pressed("crouch") and not player_controller.crouch_check.is_colliding():
		player_controller.state_chart.send_event("onStanding")

func _on_crouching_state_entered() -> void:
	player_controller.crouch()
