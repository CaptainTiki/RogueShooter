extends Node3D

@onready var p_scene : PackedScene = preload("uid://bk8ddt7gcjun8")
@onready var b_scene : PackedScene = preload("res://World/Basement/Basement.tscn")
@onready var l_scene : PackedScene = preload("res://World/Level/level_debug_1.tscn")
@onready var c_scene : PackedScene = preload("res://Utilities/camera_rig.tscn")
@onready var d_scene : PackedScene = preload("uid://1cot5nx5hi81")

@onready var pause_scene : PackedScene = preload("res://UI/pause_menu.tscn")

@onready var ui_layer: CanvasLayer = $UILayer

var player : Player
var basement: Basement
var level : Level
var camera_rig : CameraRig
var debug_overlay : DebugOverlay

var pause_menu : PauseMenu

func _ready() -> void:
	pass
	
func setup_world() -> void:
	basement = b_scene.instantiate() as Basement
	add_child(basement)
	level = l_scene.instantiate() as Level
	add_child(level)
	player = p_scene.instantiate() as Player
	add_child(player)
	camera_rig = c_scene.instantiate() as CameraRig
	add_child(camera_rig)
	debug_overlay = d_scene.instantiate() as DebugOverlay
	add_child(debug_overlay)
	
	player.global_position = basement.player_spawn.global_position
	player.global_basis = basement.player_spawn.global_basis
	level.global_position.y += -4.8
	level.global_position.x += 9.2
	level.global_position.z += 22.8

func setup_menus() -> void:
	pause_menu = pause_scene.instantiate() as PauseMenu
	pause_menu.hide()
	ui_layer.add_child(pause_menu)
