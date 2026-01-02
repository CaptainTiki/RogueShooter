extends Control
class_name WeaponBenchUI

@export var debug : bool = true

@onready var weapon_display: WB_WeaponDisplay = %WbWeaponDisplay
@onready var weapon_stats: WB_WeaponStats = %WbWeaponStats
@onready var part_stats: WB_PartStats = %WbPartStats
@onready var parts_display: WB_PartsDisplay = %WbPartsDisplay

var _slot_map: Array[Dictionary] = []
var _weapon_preview: Weapon = null
var _selected_slot_id: int = -1

var bench: WeaponBench = null
var actor: PlayerController = null

func _ready() -> void:
	# connect once (guard against double-connect if UI reused)
	if not weapon_display.slot_selected.is_connected(_on_slot_selected):
		weapon_display.slot_selected.connect(_on_slot_selected)
		
	if not parts_display.part_selected.is_connected(_on_part_selected):
		parts_display.part_selected.connect(_on_part_selected)
		
	if not parts_display.part_highlighted.is_connected(_on_part_highlighted):
		parts_display.part_highlighted.connect(_on_part_highlighted)

func setup_ui() -> void:
	_slot_map = WeaponCalc.build_slot_map(_weapon_preview)
	weapon_display.set_weapon(_weapon_preview, _slot_map)
	weapon_stats.show_weapon(_weapon_preview)

func open_for(player: Node3D, _bench: WeaponBench) -> void:
	actor = player as PlayerController
	_weapon_preview = actor.weapon_controller.current_weapon.clone_weapon_graph()
	_weapon_preview.stats = WeaponCalc.calculate_stats(_weapon_preview)
	bench = _bench
	setup_ui()
	visible = true

func _get_slot_dict(slot_id: int) -> Dictionary:
	for s in _slot_map:
		if int(s.get("slot_id", -9999)) == slot_id:
			return s
	return {}

func _on_slot_selected(slot_id: int) -> void:
	_selected_slot_id = slot_id

	var slot := _get_slot_dict(slot_id)
	if slot.is_empty():
		parts_display.clear()
		return

	var slot_type := int(slot.get("slot_type", -1))
	if slot_type < 0:
		parts_display.clear()
		return

	# MVP filter: by PartType only
	var parts: Array[WeaponPart] = PartsCatalog.get_parts_for_type(slot_type)
	parts_display.show_parts(parts)

func _on_part_highlighted(part: WeaponPart) -> void:
	part_stats.show_part(part)

func _on_part_selected(part: WeaponPart) -> void:
	if part == null:
		return
	if _weapon_preview == null:
		return
	if _selected_slot_id == -1:
		return

	# Receiver pseudo-slot special case
	if _selected_slot_id == -100:
		print("Receiver swap not MVP yet")
		return

	# If slot already has a child, remove it first (and its subtree)
	var slot := _get_slot_dict(_selected_slot_id)
	var existing_child_id := int(slot.get("child_part_id", -1))
	if existing_child_id != -1:
		_weapon_preview.remove_part_subtree(existing_child_id)

	# Add new part into slot
	_weapon_preview.add_part_to_slot(_selected_slot_id, part)

	# Recalc stats on preview weapon
	_weapon_preview.stats = WeaponCalc.calculate_stats(_weapon_preview)
	_weapon_preview.weapon_name = WeaponCalc.build_name(_weapon_preview)

	# Rebuild slot map and refresh UI
	_slot_map = WeaponCalc.build_slot_map(_weapon_preview)
	weapon_display.set_weapon(_weapon_preview, _slot_map)

	weapon_stats.show_weapon(_weapon_preview)

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
		_slot_map.clear()
		bench.close_ui()


func _on_accept_bn_pressed() -> void:
	if actor == null or _weapon_preview == null:
		return
	actor.weapon_controller.current_weapon = _weapon_preview
	actor.weapon_controller.weapon_changed.emit()
	bench.close_ui()
