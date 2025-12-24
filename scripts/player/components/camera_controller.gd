#camera_controller.gd
extends Node3D
class_name CameraController

@export var debug : bool = false
@export_category("References")
@export var player_controller : PlayerController
@export var component_mouse_capture : MouseCaptureComponent
@export_category("Camera Settings")
@export_group("Camera Tilt")
@export_range(-90,-60) var tilt_lower_limit : int = -90 #in degrees
@export_range(60,90) var tilt_upper_limit : int = 90 #in degrees
@export_group("Crouch Vertical Movement")
@export var crouch_offset : float = 1.0
@export var crouch_speed : float = 3.0

var _rotation : Vector3
var DEFAULT_HEIGHT : float = 1.5

func _physics_process(_delta: float) -> void:
	update_camera_rotation(component_mouse_capture._mouse_input)
	pass

func update_camera_rotation(input : Vector2) -> void:
	_rotation.x += input.y
	_rotation.y += input.x
	_rotation.x = clamp(_rotation.x, deg_to_rad(tilt_lower_limit), deg_to_rad(tilt_upper_limit))
	
	#only rotate the player on y
	var _player_rotation : Vector3 = Vector3(0.0,_rotation.y,0.0)
	var _camera_rotation : Vector3 = Vector3(_rotation.x, 0.0, 0.0)
	
	transform.basis = Basis.from_euler(_camera_rotation)
	player_controller.update_rotation(_player_rotation)
	#we don't spin the camera :D
	rotation.z = 0.0

func update_camera_height(delta : float, direction: int) -> void:
	if position.y >= crouch_offset and position.y <= DEFAULT_HEIGHT:
		position.y = clampf(position.y + (crouch_speed * direction) * delta, crouch_offset, DEFAULT_HEIGHT)
