extends CharacterBody3D
class_name Player

signal weapon_changed

@export_category("Movement Vars")
@export var speed_run : float = 8
@export var speed_sprint : float = 12
@export var speed_in_air : float = 4

@export var accel_grounded : float = 30
@export var accel_in_air : float = 10

@export var friction_ground : float = 44
@export var friction_air : float = 34

@export var jump_velocity : float = 6
@export var jump_cut_multiplier : float = 0.5
@export var jump_coyote_time : float = 0.15
@export var jump_buffer_time : float = 0.10
@export var gravity_rise_mult : float = 1.0
@export var gravity_fall_mult : float = 1.6

@onready var yaw_pivot: Node3D = $MeshRig/YawPivot
@onready var pitch_pivot: Node3D = $MeshRig/YawPivot/PitchPivot

var jump_buffer_triggered : bool = false

var current_gun : GunBuild = GunBuild.new()

func set_weapon(build : GunBuild) -> void:
	print("Player: weapon changed")
	current_gun = build
	weapon_changed.emit()
