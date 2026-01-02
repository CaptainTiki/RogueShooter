extends Control
class_name WB_WeaponDisplay

signal slot_selected(slot_id: int)

@export var debug: bool = false

@onready var weapon_name_label: Label = %WeaponName_Label
@onready var slots_top_container: HBoxContainer = %SlotsTopContainer
@onready var slots_bottom_container: HBoxContainer = %SlotsBottomContainer


var _slot_map: Array[Dictionary] = []
var _selected_slot_id: int = -1

func set_weapon(weapon: Weapon, slot_map: Array[Dictionary]) -> void:
	_slot_map = slot_map
	weapon_name_label.text = weapon.weapon_name if weapon != null else "Weapon"

	_rebuild_slot_buttons()

	# Preselect receiver slot (first RECEIVER we find)
	var receiver_slot := _find_first_slot_of_type(Enums.PartType.RECEIVER)
	if receiver_slot != -1:
		_select_slot(receiver_slot)
	elif _slot_map.size() > 0:
		_select_slot(int(_slot_map[0].get("slot_id", -1)))

func _rebuild_slot_buttons() -> void:
	# clear old
	for c in slots_top_container.get_children():
		c.queue_free()
	for c in slots_bottom_container.get_children():
		c.queue_free()

	for s in _slot_map:
		var slot_id := int(s.get("slot_id", -1))
		var slot_type := int(s.get("slot_type", -1))
		var child_part_id := int(s.get("child_part_id", -1))
		
		var btn := Button.new()
		btn.name = "SlotBtn_%s" % slot_id
		btn.focus_mode = Control.FOCUS_ALL

		btn.text = _format_slot_button_text(slot_type, child_part_id, s)
		btn.pressed.connect(_on_slot_button_pressed.bind(slot_id))
		
		if slots_top_container.get_child_count() <= slots_bottom_container.get_child_count():
			slots_top_container.add_child(btn)
		else:
			slots_bottom_container.add_child(btn)

func _format_slot_button_text(slot_type: int, child_part_id: int, slot_dict: Dictionary) -> String:
	var type_name : String = Enums.PartType.keys()[slot_type] if slot_type >= 0 else "UNKNOWN"
	if child_part_id == -1:
		return "%s (empty)" % [type_name]

	# If your slot_map includes a name, use it
	var part_name := str(slot_dict.get("child_part_name", slot_dict.get("filled_part_name", "Filled")))
	return "%s: %s" % [ type_name, part_name]

func _on_slot_button_pressed(slot_id: int) -> void:
	_select_slot(slot_id)

func _select_slot(slot_id: int) -> void:
	_selected_slot_id = slot_id

	# Optional MVP highlight: disable the selected button (cheap “selected” look)
	for c in slots_top_container.get_children():
		if c is Button:
			var is_selected := (c.name == "SlotBtn_%s" % slot_id)
			c.disabled = is_selected
	for c in slots_bottom_container.get_children():
		if c is Button:
			var is_selected := (c.name == "SlotBtn_%s" % slot_id)
			c.disabled = is_selected
	slot_selected.emit(slot_id)

func _find_first_slot_of_type(part_type: Enums.PartType) -> int:
	for s in _slot_map:
		if int(s.get("slot_type", -1)) == int(part_type):
			return int(s.get("slot_id", -1))
	return -1
