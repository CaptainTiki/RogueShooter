extends Interactable
class_name GunBench

@onready var gun_bench_menu: CanvasLayer = $GunBenchMenu
@onready var exit: Button = $GunBenchMenu/Exit

var selected_slot : GunPart.Type = GunPart.Type.NONE

func _ready() -> void:
	super()
	exit.pressed.connect(_close_menu)

func _do_interaction() -> void:
	gun_bench_menu.show()
	pass


func _close_menu() -> void:
	gun_bench_menu.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not in_range:
		return
	
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_close_menu()
	
	if event.is_action_pressed("interact"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		interacted.emit()
		_do_interaction()
