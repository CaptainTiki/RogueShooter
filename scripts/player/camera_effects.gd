extends Camera3D
class_name CameraEffects

@export_category("References")
@export var player : PlayerController

@export_category("Effects")
@export var enable_tilt : bool = true

@export_category("Kick & Recoil Settings")
@export_group("Run Tilt")
@export var run_pitch : float = 0.15 #Degrees
@export var run_roll : float = 0.25 #Degrees
@export var max_pitch : float = 1.0 #Degrees
@export var max_roll : float = 2.5 #Degrees

func _process(delta: float) -> void:
	calculate_view_offset(delta)

func calculate_view_offset(delta):
	if not player:
		return
	
	var velocity = player.velocity
	
	var angles = Vector3.ZERO
	
	if enable_tilt:
		var forward = global_transform.basis.z
		var right = global_transform.basis.x
		
		var forward_dot = velocity.dot(forward)
		var forward_tilt = clampf(forward_dot * deg_to_rad(run_pitch), deg_to_rad(-max_pitch), deg_to_rad(max_pitch))
		angles.x += forward_tilt
		
		var right_dot = velocity.dot(right)
		var side_tilt = clampf(right_dot * deg_to_rad(run_roll), deg_to_rad(-max_roll), deg_to_rad(max_roll))
		angles.z -= side_tilt
	rotation = angles
