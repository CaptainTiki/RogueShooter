extends Node3D
class_name PlayerMoveController

@export_category("Nodes")
@export var player : Player
@export var input : InputNode
@export_category("InputSettings")
@export var sensitivity : float = 0.005
@export var pitch_min_deg : float = -80.0
@export var pitch_max_deg : float = 80.0

var pitch : float = 0.0
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

var coyote_timer : float = 0
var jump_buffer_timer : float = 0

#func _ready() -> void:
	#gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	handle_rotation(delta)
	handle_movement(delta)
	apply_gravity(delta)
	handle_jump(delta)
	player.move_and_slide()

func handle_rotation(_delta: float) -> void:
	var look_delta = input.get_look_delta()
	player.yaw_pivot.rotation.y += -look_delta.x * sensitivity
	pitch += -look_delta.y * sensitivity
	pitch = clamp(pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	player.pitch_pivot.rotation.x = pitch

func apply_gravity(delta: float) -> void:
	if not player.is_on_floor():
		if player.velocity.y > 0:
			player.velocity.y -= gravity * player.gravity_rise_mult * delta
		else:
			player.velocity.y -= gravity * player.gravity_fall_mult * delta
	elif player.velocity.y < 0:
		player.velocity.y = 0

func handle_jump(delta: float) -> void:
	if player.is_on_floor():
		coyote_timer = player.jump_coyote_time
	
	coyote_timer -= delta
	
	if input.jump_pressed:
		jump_buffer_timer = player.jump_buffer_time
		if player.is_on_floor() or coyote_timer > 0:
			player.velocity.y = player.jump_velocity

			
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
		if player.is_on_floor():
			player.velocity.y = player.jump_velocity
			jump_buffer_timer = -1
	
	if input.jump_released and player.velocity.y > 0:
		player.velocity.y *= player.jump_cut_multiplier

func handle_movement(delta: float) -> void:
	var accel = 0
	var friction = 0
	var run_speed = 0
	
	if player.is_on_floor():
		accel = player.accel_grounded
		friction = player.friction_ground
	else:
		accel = player.accel_in_air
		friction = player.friction_air
	
	if input.sprint_held and player.is_on_floor():
		run_speed = player.speed_sprint
	elif player.is_on_floor():
		run_speed = player.speed_run
	else:
		run_speed = player.speed_in_air
	
	var move_input = input.get_move_input()
	
	if move_input.length() > 1:
		move_input = move_input.normalized()
	
	var player_basis = player.yaw_pivot.global_transform.basis
	var wish_dir = (-player_basis.z * move_input.z) + (player_basis.x * move_input.x)
	wish_dir.y = 0
	var target_hvel = Vector2(wish_dir.x, wish_dir.z) * run_speed
	var hvel = Vector2(player.velocity.x, player.velocity.z)
	var rate = accel if target_hvel.length() > 0.0 else friction
	hvel = hvel.move_toward(target_hvel, rate * delta)

	player.velocity.x = hvel.x
	player.velocity.z = hvel.y
