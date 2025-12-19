extends Node3D
class_name CameraRig

var player : Player

func _ready() -> void:
	player = World.player
