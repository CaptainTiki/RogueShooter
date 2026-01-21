extends WeaponState
class_name WeaponCycleUpState

func _on_cycle_up_state_entered() -> void:
	weapon_controller.cycle_weapon(+1)# wheel up = next
	#TODO: await animation to finish playing before allowing onIdle
	weapon_controller.weapon_state_chart.send_event("onIdle")


func _on_cycle_up_state_processing(_delta: float) -> void:
	if not weapon_controller:
		return
			
	#TODO: process animation of swapping weapon - when finished send_event("onIdle")
