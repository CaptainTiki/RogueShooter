extends WeaponState
class_name WeaponIdleState


func _on_idle_state_processing(_delta: float) -> void:
	if not weapon_controller:
		return
	
	#Check for fire input
	if Input.is_action_just_pressed("fire") and weapon_controller.can_fire():
		weapon_controller.weapon_state_chart.send_event("onFiring")
	
	#Check if ammo is empty
	if weapon_controller.current_ammo <= 0:
		weapon_controller.weapon_state_chart.send_event("onEmpty")


func _on_idle_state_entered() -> void:
	print("idle")
	weapon_controller.camera.set_weapon_decay(false)
