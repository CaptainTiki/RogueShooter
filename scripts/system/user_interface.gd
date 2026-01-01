extends CanvasLayer
class_name UserInterface

@onready var reticle: ReticleDraw = $CenterContainer/ReticleDraw
@onready var screens: Control = $Screens

func _ready() -> void:
	for child in screens.get_children():
		child.visible = false

func push_ui(screen: Control) -> void:
	print("adding: ", screen.name)
	screens.add_child(screen)
