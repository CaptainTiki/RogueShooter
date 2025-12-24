#interaction_raycast.gd
extends RayCast3D
class_name InteractionRaycast

var current_object

func _process(_delta: float) -> void:
	if is_colliding():
		var object = get_collider()
		if object == current_object:
			return
		else:
			current_object = object
	else:
		current_object = null
