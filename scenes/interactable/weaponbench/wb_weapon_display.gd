extends Control
class_name WB_WeaponDisplay

signal slot_selected(slot_id: int)

@export var debug: bool = false
@export var min_cam_dist : float = 0.3
@export var max_cam_dist : float = 3.0
@export var padding : float = 1.2

@onready var weapon_name_label: Label = %WeaponName_Label
@onready var slots_top_container: HBoxContainer = %SlotsTopContainer
@onready var slots_bottom_container: HBoxContainer = %SlotsBottomContainer

@onready var sub_viewport: SubViewport = %SubViewport
@onready var world_root: Node3D = %WorldRoot
@onready var preview_camera: Camera3D = %PreviewCamera

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
	
	_clear_preview()
	_spawn_parts(weapon)
	_frame_preview()
	
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

func _clear_preview() -> void:
	for child in world_root.get_children():
		child.queue_free()

func _spawn_receiver(weapon: Weapon) -> Node3D:
	if weapon == null:
		return null

	var receiver := _find_receiver_part(weapon)
	if receiver == null:
		return null

	if receiver.scene == null:
		push_warning("Receiver has no part_scene: " + receiver.part_name)
		return null

	var inst := receiver.scene.instantiate() as Node3D
	world_root.add_child(inst)
	return inst

func _spawn_parts(weapon: Weapon)-> void:
	# Receiver
	var receiver_part := _find_part_type(weapon, Enums.PartType.RECEIVER)
	var receiver_inst := _spawn_part_instance(receiver_part)
	if receiver_inst == null:
		return
	world_root.add_child(receiver_inst)
	# Barrel
	var barrel_part := _find_part_type(weapon, Enums.PartType.BARREL)
	if barrel_part != null:
		var barrel_inst := _spawn_part_instance(barrel_part)
		if barrel_inst != null:
			var m := _get_slot_marker(receiver_inst, "Slot_BARREL_0")
			_attach_to_marker(barrel_inst, receiver_inst, m)

	# Grip
	var grip_part := _find_part_type(weapon, Enums.PartType.GRIP)
	if grip_part != null:
		var grip_inst := _spawn_part_instance(grip_part)
		if grip_inst != null:
			var m := _get_slot_marker(receiver_inst, "Slot_GRIP_0")
			_attach_to_marker(grip_inst, receiver_inst, m)

	# Magazine
	var mag_part := _find_part_type(weapon, Enums.PartType.MAGAZINE)
	if mag_part != null:
		var mag_inst := _spawn_part_instance(mag_part)
		if mag_inst != null:
			var m := _get_slot_marker(receiver_inst, "Slot_MAGAZINE_0")
			_attach_to_marker(mag_inst, receiver_inst, m)

	# Optic (optional)
	var optic_part := _find_part_type(weapon, Enums.PartType.OPTIC)
	if optic_part != null:
		var optic_inst := _spawn_part_instance(optic_part)
		if optic_inst != null:
			var m := _get_slot_marker(receiver_inst, "Slot_OPTIC_0")
			_attach_to_marker(optic_inst, receiver_inst, m)

func _find_part_type(weapon: Weapon, t: Enums.PartType) -> WeaponPart:
	if weapon == null:
		return null
	for p in weapon.parts_by_id.values():
		if p != null and p.part_type == t:
			return p
	return null

func _attach_to_marker(child: Node3D, host_parent: Node3D, marker: Marker3D) -> void:
	if child == null or host_parent == null or marker == null:
		return

	# Match marker pose
	child.global_transform = marker.global_transform

	# Parent under host so it follows it
	host_parent.add_child(child)
	
func _find_receiver_part(weapon: Weapon) -> WeaponPart:
	for p in weapon.parts_by_id.values():
		if p != null and p.part_type == Enums.PartType.RECEIVER:
			return p
	return null

func _compute_preview_aabb(root: Node3D) -> AABB:
	var has_any := false
	var total := AABB()

	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var a := m.get_aabb()  # local
		# Convert to world-ish by transforming corners (simple approach)
		var xform := m.global_transform
		var pts := [
			a.position,
			a.position + Vector3(a.size.x, 0, 0),
			a.position + Vector3(0, a.size.y, 0),
			a.position + Vector3(0, 0, a.size.z),
			a.position + Vector3(a.size.x, a.size.y, 0),
			a.position + Vector3(a.size.x, 0, a.size.z),
			a.position + Vector3(0, a.size.y, a.size.z),
			a.position + a.size,
		]

		var wa := AABB(xform * pts[0], Vector3.ZERO)
		for p in pts:
			wa = wa.expand(xform * p)

		if not has_any:
			total = wa
			has_any = true
		else:
			total = total.merge(wa)

	return total if has_any else AABB(Vector3.ZERO, Vector3.ONE)

func _frame_preview() -> void:
	var aabb := _compute_preview_aabb(world_root)
	var center := aabb.position + aabb.size * 0.5
	var radius := aabb.size.length() * 0.5
	radius = max(radius, 0.1)

	# camera sits to the right (+X), slightly up (+Y), slightly forward/back (+Z)
	preview_camera.global_position = center + Vector3(1.2, 0.25, 0.0)

	# look back toward center
	preview_camera.look_at(center, Vector3.UP)

	# Use vertical FOV for distance estimate
	var fov_rad := deg_to_rad(preview_camera.fov)
	var dist := (radius * padding) / tan(fov_rad * 0.5)
	dist = clamp(dist, min_cam_dist, max_cam_dist)

	# Place camera: look at center from a consistent angle
	var dir := Vector3(0.35, 0.15, 1.0).normalized() # tweak later
	preview_camera.global_position = center + dir * dist
	preview_camera.look_at(center, Vector3.UP)

func _get_slot_marker(host_instance: Node3D, marker_name: String) -> Marker3D:
	if host_instance == null:
		return null
	var path := "SlotMarkers/%s" % marker_name
	var node := host_instance.get_node_or_null(path)
	return node as Marker3D

func _spawn_part_instance(part: WeaponPart) -> Node3D:
	if part == null or part.scene == null:
		return null
	var inst := part.scene.instantiate() as Node3D
	return inst
