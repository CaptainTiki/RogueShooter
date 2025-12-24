#player_controller.gd
extends CharacterBody3D
class_name PlayerController

@export var debug : bool = false
@export_category("References")
@export var camera : CameraController
@export var state_chart : StateChart
@export var standing_collision : CollisionShape3D
@export var crouch_collision : CollisionShape3D
@export var crouch_check : ShapeCast3D
@export var interaction_raycast : RayCast3D
@export var camera_effects : CameraEffects
@export_category("Easing")
@export var acceleration : float = 0.2
@export var deceleration : float = 0.5
@export_category("Speed")
@export var default_speed : float = 7.0
@export var sprint_speed_mod : float = 3
@export var crouch_speed_mod : float = -4
@export_category("Jump Settings")
@export var jump_velocity : float = 5
var _input_dir : Vector2 = Vector2.ZERO
var _movement_velocity : Vector3 = Vector3.ZERO
var sprint_modifier : float = 0.0
var crouch_modifier : float = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	_input_dir = Input.get_vector("move_left", "move_right", "move_fwd", "move_back")
	var speed = default_speed + sprint_modifier + crouch_modifier
	var current_velocity : Vector2 = Vector2(_movement_velocity.x, _movement_velocity.z)
	var direction : Vector3 = (transform.basis * Vector3(_input_dir.x, 0.0, _input_dir.y)).normalized()
	if _input_dir.length() > 0.0:
		current_velocity = lerp(current_velocity, Vector2(direction.x, direction.z) * speed, acceleration)
	else:
		current_velocity = current_velocity.move_toward(Vector2.ZERO, deceleration)
	
	_movement_velocity = Vector3(current_velocity.x, velocity.y, current_velocity.y)
	velocity = _movement_velocity
	
	move_and_slide()
	
	if debug:
		print("Player Velocity: ", velocity)

func update_rotation(rotation_input : Vector3) -> void:
	global_transform.basis = Basis.from_euler(rotation_input)

func sprint() -> void:
	sprint_modifier = sprint_speed_mod

func walk() -> void:
	sprint_modifier = 0.0

func crouch() -> void:
	crouch_modifier = crouch_speed_mod
	crouch_collision.disabled = false
	standing_collision.disabled = true

func stand() -> void:
	crouch_collision.disabled = true
	standing_collision.disabled = false

func jump() -> void:
	velocity.y += jump_velocity
