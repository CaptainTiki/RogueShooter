extends Interactable
class_name GunBench

@onready var gun_bench_menu: CanvasLayer = $GunBenchMenu
@onready var exit: Button = $GunBenchMenu/Exit
@onready var parts_container: VBoxContainer = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Right_Panel/VBoxContainer/PartsContainer
@onready var parts_type_label: Label = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Right_Panel/VBoxContainer/PartsTypeLabel

@onready var barrel_button: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/BarrelButton
@onready var frame: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/Frame
@onready var magazine: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/Magazine
@onready var chamber: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/Chamber
@onready var optics: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/Optics

var selected_slot : GunPartDef.Type = GunPartDef.Type.NONE
var selected_platform : GunPartDef.Platform = GunPartDef.Platform.PISTOL
var parts : Array[GunPartDef] = []
var filtered_parts : Array[GunPartDef] = []

var current_build := {
	GunPartDef.Type.BARREL: null,
	GunPartDef.Type.FRAME: null,
	GunPartDef.Type.MAG: null,
	GunPartDef.Type.CHAMBER: null,
	GunPartDef.Type.OPTICS: null
}

var button_dict : Dictionary[GunPartDef.Type, Button] = {}

const BARREL_STANDARD : GunPartDef = preload("uid://3emgej4jklwe")
const CHAMBER_BULLET_SM : GunPartDef = preload("uid://b78y2ptm76xq1")
const FRAME_LIGHT : GunPartDef = preload("uid://dvtf708j4ex0s")
const MAG_STANDARD : GunPartDef = preload("uid://2i06kevqxdtj")
const OPTIC_IRON : GunPartDef = preload("uid://cr0xnv73y4g3k")

func _ready() -> void:
	super()
	_load_gunparts()
	button_dict = {
		GunPartDef.Type.BARREL : barrel_button,
		GunPartDef.Type.FRAME : frame,
		GunPartDef.Type.MAG : magazine,
		GunPartDef.Type.CHAMBER : chamber,
		GunPartDef.Type.OPTICS : optics,
		}
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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	gun_bench_menu.show()
	interacted.emit()

func _close_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	gun_bench_menu.hide()

func _unhandled_input(event: InputEvent) -> void:	
	if not in_range:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_close_menu()
	
	if event.is_action_pressed("interact"):
		if not gun_bench_menu.visible:
			_do_interaction()

func list_parts() -> void:
	for child in parts_container.get_children():
		child.queue_free()
	
	for part in filtered_parts:
		var new_button = Button.new()
		new_button.text = part.display_name
		new_button.pressed.connect(_on_part_button_pressed.bind(part))
		parts_container.add_child(new_button)

func _on_part_button_pressed(part: GunPartDef) -> void:
	current_build[selected_slot] = part
	button_dict[part.slot_type].text = part.display_name

func _on_barrel_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.BARREL
	filtered_parts = []
	for part in parts:
		if part.slot_type == GunPartDef.Type.BARREL:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Barrels"
	list_parts()

func _on_frame_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.FRAME
	filtered_parts = []
	for part in parts:
		if part.slot_type == GunPartDef.Type.FRAME:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Frames"
	list_parts()

func _on_magazine_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.MAG
	filtered_parts = []
	for part in parts:
		if part.slot_type == GunPartDef.Type.MAG:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Magazines"
	list_parts()

func _on_chamber_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.CHAMBER
	filtered_parts = []
	for part in parts:
		if part.slot_type == GunPartDef.Type.CHAMBER:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Chambers"
	list_parts()

func _on_optics_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.OPTICS
	filtered_parts = []
	for part in parts:
		if part.slot_type == GunPartDef.Type.OPTICS:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Optics"
	list_parts()
