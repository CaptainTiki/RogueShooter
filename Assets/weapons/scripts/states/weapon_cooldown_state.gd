extends WeaponState
class_name WeaponCooldownState

var cooldowntimer : float = 0.0

func _on_cool_down_state_entered() -> void:
	cooldowntimer = weapon_controller.current_weapon.stats.shot_interval


func _on_cool_down_state_processing(delta: float) -> void:
	if not weapon_controller:
		return
	
	if cooldowntimer > 0:
		cooldowntimer -= delta
		return
	
	#Check if ammo is empty
	if not weapon_controller.can_fire():
		print("ammo empty")
		weapon_controller.weapon_state_chart.send_event("onEmpty")
		return

	#Check for fire input
	if weapon_controller.current_weapon.stats.trigger_mode == Enums.TriggerMode.AUTO:
		print("trigger mode")
		if Input.is_action_pressed("fire") and weapon_controller.can_fire():
			weapon_controller.weapon_state_chart.send_event("onFiring")
			return
			
	print("sending to idlestate")
	weapon_controller.weapon_state_chart.send_event("onIdle")
		
