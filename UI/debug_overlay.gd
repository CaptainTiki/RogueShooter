extends CanvasLayer
class_name DebugOverlay

@onready var build_label: Label = $Top_Left_Dock/Build_Label


func _ready() -> void:
	build_label.text = str("Build: ", ProjectSettings.get_setting("application/config/version", "  "))
