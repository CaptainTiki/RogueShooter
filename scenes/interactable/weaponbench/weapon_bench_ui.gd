extends Control
class_name WeaponBenchUI

@export var debug : bool = true

@onready var weapon_display: WB_WeaponDisplay = %WbWeaponDisplay
@onready var weapon_stats: WB_WeaponStats = %WbWeaponStats
@onready var mod_slots: WB_ModSlots = %WbModSlots
@onready var mod_picker: WB_ModPicker = %WbModPicker

var _weapon_preview: Weapon = null
var _selected_slot_index: int = -1
var _owned_mods: Array[WeaponMod] = []

var bench: WeaponBench = null
var actor: PlayerController = null

func _ready() -> void:
	if mod_slots != null and not mod_slots.slot_selected.is_connected(_on_mod_slot_selected):
		mod_slots.slot_selected.connect(_on_mod_slot_selected)
	if mod_picker != null:
		if not mod_picker.install_requested.is_connected(_on_mod_install_requested):
			mod_picker.install_requested.connect(_on_mod_install_requested)
		if not mod_picker.remove_requested.is_connected(_on_mod_remove_requested):
			mod_picker.remove_requested.connect(_on_mod_remove_requested)
		if not mod_picker.closed.is_connected(_on_mod_picker_closed):
			mod_picker.closed.connect(_on_mod_picker_closed)

	_owned_mods = _build_debug_owned_mods()

func open_for(player: Node3D, _bench: WeaponBench) -> void:
	actor = player as PlayerController
	bench = _bench

	# Work on a copy so Cancel is safe
	_weapon_preview = actor.weapon_controller.current_weapon.clone_weapon()
	_weapon_preview.recalculate()

	weapon_display.set_weapon(_weapon_preview)
	weapon_stats.show_weapon(_weapon_preview)
	mod_slots.set_weapon(_weapon_preview)

	_selected_slot_index = -1
	if mod_picker != null:
		mod_picker.close()
	visible = true

func _on_mod_slot_selected(slot_index: int) -> void:
	_selected_slot_index = slot_index
	if _weapon_preview == null or slot_index < 0 or slot_index >= _weapon_preview.mod_slots.size():
		return
	var slot_type := _weapon_preview.mod_slots[slot_index]
	var installed: WeaponMod = null
	if slot_index < _weapon_preview.installed_mods.size():
		installed = _weapon_preview.installed_mods[slot_index]
	var compatible := _get_compatible_mods(slot_type)
	mod_picker.open_for(slot_type, compatible, installed)

func _get_compatible_mods(slot_type: Enums.ModSlotType) -> Array[WeaponMod]:
	var out: Array[WeaponMod] = []
	for m in _owned_mods:
		if m == null:
			continue
		if m.slot_type == slot_type:
			out.append(m)
	return out

func _on_mod_install_requested(m: WeaponMod) -> void:
	if _weapon_preview == null or _selected_slot_index < 0:
		return
	# Ensure array sized
	while _weapon_preview.installed_mods.size() < _weapon_preview.mod_slots.size():
		_weapon_preview.installed_mods.append(null)
	_weapon_preview.installed_mods[_selected_slot_index] = m
	_weapon_preview.recalculate()
	weapon_stats.show_weapon(_weapon_preview)
	mod_slots.set_weapon(_weapon_preview)
	# keep picker open so you can swap quickly
	_on_mod_slot_selected(_selected_slot_index)

func _on_mod_remove_requested() -> void:
	if _weapon_preview == null or _selected_slot_index < 0:
		return
	if _selected_slot_index < _weapon_preview.installed_mods.size():
		_weapon_preview.installed_mods[_selected_slot_index] = null
	_weapon_preview.recalculate()
	weapon_stats.show_weapon(_weapon_preview)
	mod_slots.set_weapon(_weapon_preview)
	_on_mod_slot_selected(_selected_slot_index)

func _on_mod_picker_closed() -> void:
	# no-op for now
	pass

func _build_debug_owned_mods() -> Array[WeaponMod]:
	# Temporary stub inventory so the picker has something to show.
	# Later: replace with player inventory.
	var mods: Array[WeaponMod] = []

	var barrel_ext := WeaponMod.new()
	barrel_ext.mod_name = "Barrel Extension"
	barrel_ext.slot_type = Enums.ModSlotType.BARREL
	barrel_ext.distance_add = 6.0
	barrel_ext.spread_mul = 0.9
	mods.append(barrel_ext)

	var ported := WeaponMod.new()
	ported.mod_name = "Ported Compensator"
	ported.slot_type = Enums.ModSlotType.BARREL
	ported.recoil_mul = 0.8
	ported.spread_add = 0.2
	mods.append(ported)

	var red_dot := WeaponMod.new()
	red_dot.mod_name = "Red Dot Optic"
	red_dot.slot_type = Enums.ModSlotType.OPTIC
	red_dot.ads_speed_mul = 0.85
	red_dot.spread_mul = 0.92
	mods.append(red_dot)

	var gyro := WeaponMod.new()
	gyro.mod_name = "Gyro Stabilizer"
	gyro.slot_type = Enums.ModSlotType.UTILITY
	gyro.recoil_add = -0.8
	mods.append(gyro)

	var quick_reload := WeaponMod.new()
	quick_reload.mod_name = "Quick-Reload Kit"
	quick_reload.slot_type = Enums.ModSlotType.UTILITY
	quick_reload.reload_speed_mul = 0.8
	mods.append(quick_reload)

	var overclock := WeaponMod.new()
	overclock.mod_name = "Overclocked Actuator"
	overclock.slot_type = Enums.ModSlotType.UTILITY
	overclock.shot_interval_mul = 0.9
	overclock.recoil_add = 0.3
	mods.append(overclock)

	return mods

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if bench != null:
			bench.close_ui()
		get_viewport().set_input_as_handled()

func _on_cancel_bn_pressed() -> void:
	if bench != null:
		_weapon_preview = null
		bench.close_ui()

func _on_accept_bn_pressed() -> void:
	if actor == null or _weapon_preview == null:
		return
	actor.weapon_controller.current_weapon = _weapon_preview
	actor.weapon_controller.weapon_changed.emit()
	actor.weapon_controller.reload_weapon()
	bench.close_ui()
