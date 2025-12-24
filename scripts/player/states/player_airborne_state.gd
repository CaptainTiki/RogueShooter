#player_Airborn_state.gd
extends PlayerState
class_name PlayerAirbornState


func _on_airborne_state_physics_processing(_delta: float) -> void:
	if player_controller.is_on_floor():
		if player_controller.check_fall_speed():
			player_controller.camera_effects.add_fall_kick(player_controller.camera_effects.fall_kick_strength)
		player_controller.state_chart.send_event("onGrounded")
