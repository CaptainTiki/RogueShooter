extends Node3D
class_name MainScene

static var instance : MainScene = null

signal main_loaded

@onready var ui: UserInterface = $UserInterface

func _ready() -> void:
	PartsCatalog.rebuild_catalog()
	
	MainScene.instance = self
	main_loaded.emit()

func quit_game() -> void:
	get_tree().quit()
