extends WeaponState
class_name WeaponEmptyState


func _on_empty_state_entered() -> void:
	print("Weapon empty!")

func _on_empty_state_processing(_delta: float) -> void:
	if not weapon_controller:
		return
	
	#Check for reload input
	if Input.is_action_just_pressed("reload"):
		#weapon_controller.weapon_state_chart.send_event("onReloading")
		weapon_controller.reload_weapon()
		weapon_controller.weapon_state_chart.send_event("onIdle")
	
	#Check for cycle_weapon
	if Input.is_action_just_pressed("cycle_up") and weapon_controller.can_fire():
		weapon_controller.weapon_state_chart.send_event("onCycleUp")
	elif Input.is_action_just_pressed("cycle_down") and weapon_controller.can_fire():
			weapon_controller.weapon_state_chart.send_event("onCycleDown")
