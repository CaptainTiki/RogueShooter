extends Interactable
class_name GunBench

signal BuildChanged(build : GunBuild)

@export var stats_panel : GunBenchStatsPanel

@onready var gun_bench_menu: CanvasLayer = $GunBenchMenu
@onready var cancel_bn: Button = $GunBenchMenu/MarginContainer/HBoxContainer/Cancel
@onready var apply_bn: Button = $GunBenchMenu/MarginContainer/HBoxContainer/Apply
@onready var parts_container: VBoxContainer = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Right_Panel/VBoxContainer/PartsContainer
@onready var parts_type_label: Label = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Right_Panel/VBoxContainer/PartsTypeLabel

@onready var barrel_bn: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/BarrelButton
@onready var frame_bn: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/Frame
@onready var magazine_bn: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/Magazine
@onready var chamber_bn: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/Chamber
@onready var optics_bn: Button = $GunBenchMenu/MarginContainer/VBox_Main/HBox_Top/Left_Panel/HBoxContainer/Optics

var selected_slot : GunPartDef.Type = GunPartDef.Type.NONE
var selected_platform : GunPartDef.Platform = GunPartDef.Platform.PISTOL

var filtered_parts : Array[GunPartDef] = []

var current_build : GunBuild = GunBuild.new()

var button_dict : Dictionary[GunPartDef.Type, Button] = {}

func _ready() -> void:
	super()
	button_dict = {
		GunPartDef.Type.BARREL : barrel_bn,
		GunPartDef.Type.FRAME : frame_bn,
		GunPartDef.Type.MAG : magazine_bn,
		GunPartDef.Type.CHAMBER : chamber_bn,
		GunPartDef.Type.OPTICS : optics_bn,
		}
		
	cancel_bn.pressed.connect(_close_menu)
	apply_bn.pressed.connect(_on_apply_pressed)



func _do_interaction() -> void:
	var player = interactor as Player
	current_build = player.current_gun
	setup_gun_from_player()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	gun_bench_menu.show()
	interacted.emit()

func _close_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	gun_bench_menu.hide()

func _unhandled_input(event: InputEvent) -> void:	
	if not in_range or not interactor:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_close_menu()
	
	if event.is_action_pressed("interact"):
		if not gun_bench_menu.visible:
			_do_interaction()

func setup_gun_from_player() -> void:
	current_build = (interactor as Player).current_gun
	
	barrel_bn.text = current_build.barrel.display_name
	frame_bn.text = current_build.frame.display_name
	chamber_bn.text = current_build.chamber.display_name
	optics_bn.text = current_build.optics.display_name
	magazine_bn.text = current_build.mag.display_name
	
	BuildChanged.emit(current_build)

func list_parts() -> void:
	for child in parts_container.get_children():
		child.queue_free()
	
	for part in filtered_parts:
		var new_button = Button.new()
		new_button.text = part.display_name
		new_button.pressed.connect(_on_part_button_pressed.bind(part))
		parts_container.add_child(new_button)

func _on_part_button_pressed(part: GunPartDef) -> void:
	
	match part.slot_type:
		GunPartDef.Type.BARREL:
			current_build.barrel = part
		GunPartDef.Type.MAG:
			current_build.mag = part
		GunPartDef.Type.FRAME:
			current_build.frame = part
		GunPartDef.Type.CHAMBER:
			current_build.chamber = part
		GunPartDef.Type.OPTICS:
			current_build.optics = part
			
	button_dict[part.slot_type].text = part.display_name
	BuildChanged.emit(current_build)

func _on_barrel_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.BARREL
	filtered_parts = []
	for part in Parts.parts:
		if part.slot_type == GunPartDef.Type.BARREL:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Barrels"
	list_parts()

func _on_frame_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.FRAME
	filtered_parts = []
	for part in Parts.parts:
		if part.slot_type == GunPartDef.Type.FRAME:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Frames"
	list_parts()

func _on_magazine_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.MAG
	filtered_parts = []
	for part in Parts.parts:
		if part.slot_type == GunPartDef.Type.MAG:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Magazines"
	list_parts()

func _on_chamber_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.CHAMBER
	filtered_parts = []
	for part in Parts.parts:
		if part.slot_type == GunPartDef.Type.CHAMBER:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Chambers"
	list_parts()

func _on_optics_bn_pressed() -> void:
	selected_slot = GunPartDef.Type.OPTICS
	filtered_parts = []
	for part in Parts.parts:
		if part.slot_type == GunPartDef.Type.OPTICS:
			if (part.platform == GunPartDef.Platform.ALL) or (part.platform == selected_platform):
				filtered_parts.append(part)
	parts_type_label.text = "Available Optics"
	list_parts()


func _on_apply_pressed() -> void:
	(interactor as Player).set_weapon(current_build)
