extends WeaponState
class_name WeaponEmptyState


func _on_empty_state_entered() -> void:
	print("Weapon empty!")

func _on_empty_state_processing(_delta: float) -> void:
	if not weapon_controller:
		return
