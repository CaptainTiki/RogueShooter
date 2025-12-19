extends Interactable
class_name GunBench

@onready var gun_bench_menu: CanvasLayer = $GunBenchMenu
@onready var exit: Button = $GunBenchMenu/Exit

var selected_slot : GunPartDef.Type = GunPartDef.Type.NONE
var parts : Array[GunPartDef] = []

const BARREL_STANDARD : Resource = preload("uid://3emgej4jklwe")
const CHAMBER_BULLET_SM : Resource= preload("uid://b78y2ptm76xq1")
const FRAME_LIGHT : Resource= preload("uid://dvtf708j4ex0s")
const MAG_STANDARD : Resource= preload("uid://2i06kevqxdtj")
const OPTIC_IRON : Resource= preload("uid://cr0xnv73y4g3k")

func _ready() -> void:
	super()
	exit.pressed.connect(_close_menu)

func _load_gunparts() -> void:
	#TODO: load these in to a global instance at runtime - so we dont ahve to manually build this array
	parts = [
		BARREL_STANDARD,
		CHAMBER_BULLET_SM,
		FRAME_LIGHT,
		MAG_STANDARD,
		OPTIC_IRON
	]

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
