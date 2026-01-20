extends Control
class_name WB_ModSlots

signal slot_selected(slot_index: int)

@onready var slots_vbox: VBoxContainer = %SlotsVBox

const SLOT_BUTTON_SCENE := preload("res://scenes/interactable/weaponbench/slot_button.tscn")

var _weapon: Weapon = null
var _buttons: Array[SlotButton] = []
var _selected: int = -1

func set_weapon(weapon: Weapon) -> void:
	_weapon = weapon
	_rebuild()

func _rebuild() -> void:
	for c in slots_vbox.get_children():
		c.queue_free()
	_buttons.clear()
	_selected = -1

	if _weapon == null:
		return

	# Ensure installed_mods matches slot count
	if _weapon.installed_mods.size() < _weapon.mod_slots.size():
		while _weapon.installed_mods.size() < _weapon.mod_slots.size():
			_weapon.installed_mods.append(null)

	for i in range(_weapon.mod_slots.size()):
		var slot_type := _weapon.mod_slots[i]
		var slot_name : String = Enums.ModSlotType.keys()[int(slot_type)]
		var m: WeaponMod = _weapon.installed_mods[i]
		var mod_name := m.mod_name if m != null else "Empty"
		var sb := SLOT_BUTTON_SCENE.instantiate() as SlotButton
		sb.custom_minimum_size = Vector2(220, 64)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.size_flags_vertical = Control.SIZE_FILL
		sb.set_data(i, slot_name, mod_name, m.icon if m != null else null)
		sb.pressed.connect(_on_slot_pressed)
		slots_vbox.add_child(sb)
		_buttons.append(sb)

func _on_slot_pressed(slot_index: int) -> void:
	_selected = slot_index
	for i in range(_buttons.size()):
		_buttons[i].set_selected(i == _selected)
	slot_selected.emit(slot_index)
