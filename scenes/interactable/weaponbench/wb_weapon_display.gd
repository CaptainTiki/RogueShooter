extends Control
class_name WB_WeaponDisplay

signal slot_selected(slot_id: int)

@export var debug: bool = false
@export var min_cam_dist : float = 0.3
@export var max_cam_dist : float = 3.0
@export var padding : float = 2.0

@onready var weapon_name_label: Label = %WeaponName_Label
@onready var slots_top_container: HBoxContainer = %SlotsTopContainer
@onready var slots_bottom_container: HBoxContainer = %SlotsBottomContainer

@onready var sub_viewport: SubViewport = %SubViewport
@onready var world_root: Node3D = %WorldRoot
@onready var preview_camera: Camera3D = %PreviewCamera
@onready var lines_overlay: WBLinesOverlay = %LinesOverlay

# Parent container that displays the SubViewport. We keep the SubViewport's internal size
# in sync with this rect so projection math (unproject/project) is stable across window sizes
# and scene-open timing.
@onready var _sub_viewport_container: SubViewportContainer = sub_viewport.get_parent() as SubViewportContainer

const SLOT_BUTTON_SCENE := preload("res://scenes/interactable/weaponbench/slot_button.tscn")

var _slot_ui_entries: Array[Dictionary] = []
# each: { "slot_id": int, "slot_type": int, "btn": SlotButton, "marker": Marker3D, "marker_pos": Vector3 }

var _slot_map: Array[Dictionary] = []
var _selected_slot_id: int = -1
var _receiver_inst: Node3D = null
var _preview_center: Vector3 = Vector3.ZERO

# Part instance refs (used to resolve markers that live on non-receiver parts, e.g. muzzle on barrel)
var _barrel_inst: Node3D = null
var _grip_inst: Node3D = null
var _mag_inst: Node3D = null
var _optic_inst: Node3D = null

func _ready() -> void:
	# Keep line positions correct after UI layout changes (containers, resizing, etc.)
	# NOTE: We intentionally do NOT position/size UI elements in code. Layout is driven by the scene (anchors/containers).
	set_process(true)

	# IMPORTANT: SubViewportContainer will often report a tiny (or zero) size on the first frame,
	# especially when opening the bench UI. If we build slot buttons before the viewport has its
	# real size, containers can lay out against that tiny rect and everything ends up piled in the
	# top-left. We avoid that by syncing SubViewport.size to the container and waiting for a valid size.
	if _sub_viewport_container != null:
		_sub_viewport_container.resized.connect(_on_sub_viewport_container_resized)
		_on_sub_viewport_container_resized()

func set_weapon(weapon: Weapon, slot_map: Array[Dictionary]) -> void:
	_slot_map = slot_map
	weapon_name_label.text = weapon.weapon_name if weapon != null else "Weapon"

	_clear_preview()
	_receiver_inst = _spawn_parts(weapon)  # <-- return receiver instance (also sets part refs)
	_frame_preview()

	# Wait for the UI + SubViewportContainer to have a real size before building buttons.
	# This prevents the "sometimes top-left" layout instability.
	await _wait_for_viewport_ready()

	_rebuild_slot_buttons(_receiver_inst)
	# Let containers sort after we add children.
	await get_tree().process_frame
	_update_slot_lines()
	
	# preselect receiver
	var receiver_slot := _find_first_slot_of_type(Enums.PartType.RECEIVER)
	if receiver_slot != -1:
		_select_slot(receiver_slot)
	elif _slot_map.size() > 0:
		_select_slot(int(_slot_map[0].get("slot_id", -1)))


func _on_sub_viewport_container_resized() -> void:
	if _sub_viewport_container == null:
		return
	var s: Vector2 = _sub_viewport_container.size
	if s.x < 2.0 or s.y < 2.0:
		return
	# Keep the render target size in sync with the displayed rect.
	# This stabilizes unproject/project math and prevents jitter when opening/resizing.
	var new_size := Vector2i(int(s.x), int(s.y))
	if sub_viewport.size != new_size:
		sub_viewport.size = new_size

	# If we already built the slot UI, ask containers to re-layout against the new size.
	if _slot_ui_entries.size() > 0:
		slots_top_container.queue_sort()
		slots_bottom_container.queue_sort()
		call_deferred("_update_slot_lines")


func _wait_for_viewport_ready(max_frames: int = 10) -> void:
	# Wait up to N frames for the SubViewportContainer to report a sane size.
	# We also force-sync the SubViewport size each frame.
	for _i in range(max_frames):
		_on_sub_viewport_container_resized()
		if _sub_viewport_container != null:
			var s := _sub_viewport_container.size
			if s.x >= 64.0 and s.y >= 64.0:
				return
		await get_tree().process_frame

	
func _rebuild_slot_buttons(receiver_inst: Node3D) -> void:
	for c in slots_top_container.get_children():
		c.queue_free()
	for c in slots_bottom_container.get_children():
		c.queue_free()

	_slot_ui_entries.clear()

	for s in _slot_map:
		var slot_id := int(s.get("slot_id", -1))
		var slot_type := int(s.get("slot_type", -1))

		var sb := SLOT_BUTTON_SCENE.instantiate() as SlotButton
		sb.name = "SlotBtn_%s" % slot_id
		# Ensure the container can always lay these out (prevents 0-width collapse when using Shrink).
		# We are NOT positioning these in code; we're only setting minimum readability + size flags.
		sb.custom_minimum_size = Vector2(96, 48)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.size_flags_vertical = Control.SIZE_FILL

		var type_name : String = Enums.PartType.keys()[slot_type] if slot_type >= 0 else "UNKNOWN"
		var part_name := str(s.get("child_part_name", s.get("filled_part_name", "Filled")))
		sb.set_data(slot_id,type_name,part_name, null) # icon later
		sb.pressed.connect(_on_slot_button_pressed)

		var marker: Marker3D = null
		var marker_pos: Vector3 = Vector3.ZERO
		# Resolve the correct marker host (muzzle marker lives on the barrel part, etc.)
		var resolved := _resolve_marker_for_slot(slot_type)
		marker = resolved.get("marker", null)
		marker_pos = resolved.get("pos", Vector3.ZERO)

		# Determine which row this slot should appear in.
		# Prefer receiver-local marker Y (stable, independent of camera framing).
		# Fallback to a deterministic mapping when we don't have a marker.
		var is_top := true
		if receiver_inst != null and marker_pos != Vector3.ZERO:
			var local := receiver_inst.to_local(marker_pos)
			is_top = local.y >= 0.0
		else:
			match slot_type:
				int(Enums.PartType.GRIP), int(Enums.PartType.MAGAZINE):
					is_top = false
				_:
					is_top = true

		_slot_ui_entries.append({
			"slot_id": slot_id,
			"slot_type": slot_type,
			"btn": sb,
			"marker": marker,
			"marker_pos": marker_pos,
			"is_top": is_top,
		})

	# Order buttons based on receiver-local marker X (stable) and then add them to the correct row.
	set_button_order(receiver_inst)

	# Let the scene (containers/anchors) handle sizing and spacing.
	slots_top_container.queue_sort()
	slots_bottom_container.queue_sort()
	queue_redraw()


# Orders slot buttons by what the player actually sees in the preview (screen-space).
# We project each slot marker into the preview camera, then:
#   - split into TOP/BOTTOM rows by a Y threshold (prefer receiver Y, fallback to median Y)
#   - sort each row left-to-right by screen X
# This stays correct even if the weapon/camera orientation changes.
func set_button_order(receiver_inst: Node3D) -> void:
	var items: Array = []
	var receiver_y: float = NAN

	for entry in _slot_ui_entries:
		var sb := entry.get("btn", null) as SlotButton
		if sb == null:
			continue

		var slot_type := int(entry.get("slot_type", -1))
		var marker_pos: Vector3 = entry.get("marker_pos", Vector3.ZERO)

		var sp := Vector2(99999, 99999)
		var has_sp := false
		if marker_pos != Vector3.ZERO:
			sp = preview_camera.unproject_position(marker_pos)
			has_sp = true

		entry["screen_pos"] = sp
		entry["has_screen"] = has_sp

		if slot_type == int(Enums.PartType.RECEIVER) and has_sp:
			receiver_y = sp.y

		items.append({
			"entry": entry,
			"btn": sb,
			"slot_type": slot_type,
			"sp": sp,
			"has_sp": has_sp,
		})

	# Choose the split line between top/bottom rows.
	# Prefer receiver Y (keeps receiver in the top row), fallback to median Y.
	var split_y: float
	if receiver_y == receiver_y:  # NAN check
		split_y = receiver_y + 8.0
	else:
		var ys: Array[float] = []
		for it in items:
			if it["has_sp"]:
				ys.append(float(it["sp"].y))
		if ys.size() == 0:
			split_y = 0.0
		else:
			ys.sort()
			split_y = ys[ys.size() / 2]

	var top_items: Array = []
	var bot_items: Array = []

	for it in items:
		var entry: Dictionary = it["entry"]
		var slot_type: int = it["slot_type"]
		var sp: Vector2 = it["sp"]
		var has_sp: bool = it["has_sp"]

		var is_top := true
		if has_sp:
			is_top = sp.y < split_y
		else:
			# Deterministic fallback when a marker is missing
			match slot_type:
				int(Enums.PartType.GRIP), int(Enums.PartType.MAGAZINE):
					is_top = false
				_:
					is_top = true

		entry["is_top"] = is_top

		var sort_x := sp.x if has_sp else float(_slot_type_priority(slot_type)) * 1000.0
		var item := { "x": sort_x, "slot_type": slot_type, "btn": it["btn"] }
		if is_top:
			top_items.append(item)
		else:
			bot_items.append(item)

	# Sort left-to-right with a stable tie-breaker.
	top_items.sort_custom(func(a, b):
		var ax := float(a["x"])
		var bx := float(b["x"])
		if abs(ax - bx) > 2.0:
			return ax < bx
		return _slot_type_priority(int(a["slot_type"])) < _slot_type_priority(int(b["slot_type"]))
	)
	bot_items.sort_custom(func(a, b):
		var ax := float(a["x"])
		var bx := float(b["x"])
		if abs(ax - bx) > 2.0:
			return ax < bx
		return _slot_type_priority(int(a["slot_type"])) < _slot_type_priority(int(b["slot_type"]))
	)

	# Clear any existing children (in case we're re-ordering without a full rebuild)
	for c in slots_top_container.get_children():
		slots_top_container.remove_child(c)
	for c in slots_bottom_container.get_children():
		slots_bottom_container.remove_child(c)

	for it2 in top_items:
		slots_top_container.add_child(it2["btn"])
	for it2 in bot_items:
		slots_bottom_container.add_child(it2["btn"])


func _slot_type_priority(slot_type: int) -> int:
	# Lower comes first when two slots land in nearly the same screen X.
	match slot_type:
		int(Enums.PartType.OPTIC): return 0
		int(Enums.PartType.RECEIVER): return 1
		int(Enums.PartType.BARREL): return 2
		int(Enums.PartType.MUZZLE): return 3
		int(Enums.PartType.GRIP): return 4
		int(Enums.PartType.MAGAZINE): return 5
		_: return 100 + slot_type

func _process(_delta: float) -> void:
	# Recompute line endpoints as the UI lays out / resizes.
	if _receiver_inst != null and is_visible_in_tree():
		_update_slot_lines()

func _update_slot_lines() -> void:
	if _receiver_inst == null:
		lines_overlay.set_lines([])
		return

	var new_lines: Array[Dictionary] = []

	for entry in _slot_ui_entries:
		var sb := entry["btn"] as SlotButton
		var marker := entry["marker"] as Marker3D
		var marker_pos: Vector3 = entry.get("marker_pos", Vector3.ZERO)
		if sb == null:
			continue

		var is_top := bool(entry.get("is_top", true))
		var a_canvas := sb.get_line_anchor_canvas(is_top)
		var a: Vector2 = lines_overlay.make_canvas_position_local(a_canvas)

		var p_sv := preview_camera.unproject_position(marker_pos)
		var b := _subviewport_to_preview_local(p_sv)

		new_lines.append({ "a": a, "b": b })

	lines_overlay.set_lines(new_lines)

func _marker_name_for_slot_type(slot_type: int) -> String:
	match slot_type:
		int(Enums.PartType.BARREL): return "Slot_BARREL_0"
		int(Enums.PartType.GRIP): return "Slot_GRIP_0"
		int(Enums.PartType.MAGAZINE): return "Slot_MAGAZINE_0"
		int(Enums.PartType.OPTIC): return "Slot_OPTIC_0"
		int(Enums.PartType.MUZZLE): return "Slot_MUZZLE_0"
		int(Enums.PartType.RECEIVER): return "" # receiver button can be treated special
		_: return ""

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

	for entry in _slot_ui_entries:
		var sb := entry["btn"] as SlotButton
		var is_selected := int(entry["slot_id"]) == slot_id
		#sb.modulate = Color(0.8, 0.9, 1.0, 1.0) if is_selected else Color(1, 1, 1, 1)
		sb.set_selected(is_selected)

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

func _spawn_parts(weapon: Weapon)-> Node3D:
	# Reset part refs for marker resolution
	_barrel_inst = null
	_grip_inst = null
	_mag_inst = null
	_optic_inst = null

	# Receiver
	var receiver_part := _find_part_type(weapon, Enums.PartType.RECEIVER)
	var receiver_inst := _spawn_part_instance(receiver_part)
	if receiver_inst == null:
		return null
		
	world_root.add_child(receiver_inst)
	# Barrel
	var barrel_part := _find_part_type(weapon, Enums.PartType.BARREL)
	if barrel_part != null:
		var barrel_inst := _spawn_part_instance(barrel_part)
		if barrel_inst != null:
			var m := _get_slot_marker(receiver_inst, "Slot_BARREL_0")
			_attach_to_marker(barrel_inst, receiver_inst, m)
			_barrel_inst = barrel_inst

	# Grip
	var grip_part := _find_part_type(weapon, Enums.PartType.GRIP)
	if grip_part != null:
		var grip_inst := _spawn_part_instance(grip_part)
		if grip_inst != null:
			var m := _get_slot_marker(receiver_inst, "Slot_GRIP_0")
			_attach_to_marker(grip_inst, receiver_inst, m)
			_grip_inst = grip_inst

	# Magazine
	var mag_part := _find_part_type(weapon, Enums.PartType.MAGAZINE)
	if mag_part != null:
		var mag_inst := _spawn_part_instance(mag_part)
		if mag_inst != null:
			var m := _get_slot_marker(receiver_inst, "Slot_MAGAZINE_0")
			_attach_to_marker(mag_inst, receiver_inst, m)
			_mag_inst = mag_inst

	# Optic (optional)
	var optic_part := _find_part_type(weapon, Enums.PartType.OPTIC)
	if optic_part != null:
		var optic_inst := _spawn_part_instance(optic_part)
		if optic_inst != null:
			var m := _get_slot_marker(receiver_inst, "Slot_OPTIC_0")
			_attach_to_marker(optic_inst, receiver_inst, m)
			_optic_inst = optic_inst
	
	return receiver_inst

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
	var aabb_local := _compute_preview_aabb(world_root)
	var center := aabb_local.position + aabb_local.size * 0.5
	_preview_center = center
	var dist := _fit_distance_for_aabb(aabb_local, preview_camera, padding)
	dist = clamp(dist, min_cam_dist, max_cam_dist)

	var dir := Vector3(1.0, 0.20, 0.0).normalized() # right side view
	preview_camera.global_position = center + dir * dist
	preview_camera.look_at(center, Vector3.UP)

func _fit_distance_for_aabb(aabb_local: AABB, cam: Camera3D, fill: float) -> float:
	var vfov := deg_to_rad(cam.fov)
	var vp := cam.get_viewport().get_visible_rect().size
	var aspect : float = vp.x / max(1.0, vp.y)
	var hfov := 2.0 * atan(tan(vfov * 0.5) * aspect)

	var half := aabb_local.size * 0.5
	# In a side view (+X), screen axes are Y (up/down) and Z (left/right)
	var half_h : float = max(half.y, 0.001)
	var half_w : float = max(half.z, 0.001)

	var dist_v : float = half_h / tan(vfov * 0.5)
	var dist_h : float = half_w / tan(hfov * 0.5)
	var dist : float = max(dist_v, dist_h)

	# fill 0.9 => slightly closer. fill 0.5 => much closer.
	dist *= (1.0 / max(fill, 0.05))
	return dist



func _get_slot_marker(host_instance: Node3D, marker_name: String) -> Marker3D:
	if host_instance == null:
		return null
	var path := "SlotMarkers/%s" % marker_name
	var node := host_instance.get_node_or_null(path)
	return node as Marker3D

func _find_marker_anywhere(host: Node3D, marker_name: String) -> Marker3D:
	if host == null:
		return null
	# Try the expected path first
	var m := _get_slot_marker(host, marker_name)
	if m != null:
		return m
	# Fallback: search by name (helps if someone rearranges the scene)
	var found := host.find_child(marker_name, true, false)
	return found as Marker3D

func _resolve_marker_for_slot(slot_type: int) -> Dictionary:
	# Returns { "marker": Marker3D?, "pos": Vector3 }
	var marker: Marker3D = null
	var pos := Vector3.ZERO

	match slot_type:
		int(Enums.PartType.MUZZLE):
			# Muzzle marker lives on the barrel instance in our current authoring setup.
			if _barrel_inst != null:
				marker = _find_marker_anywhere(_barrel_inst, "Slot_MUZZLE_0")
			if marker == null and _receiver_inst != null:
				marker = _find_marker_anywhere(_receiver_inst, "Slot_MUZZLE_0")
			if marker == null and _receiver_inst != null:
				# last resort: aim at barrel attach point so line doesn't disappear
				marker = _find_marker_anywhere(_receiver_inst, "Slot_BARREL_0")
		int(Enums.PartType.BARREL):
			if _receiver_inst != null:
				marker = _find_marker_anywhere(_receiver_inst, "Slot_BARREL_0")
		int(Enums.PartType.GRIP):
			if _receiver_inst != null:
				marker = _find_marker_anywhere(_receiver_inst, "Slot_GRIP_0")
		int(Enums.PartType.MAGAZINE):
			if _receiver_inst != null:
				marker = _find_marker_anywhere(_receiver_inst, "Slot_MAGAZINE_0")
		int(Enums.PartType.OPTIC):
			if _receiver_inst != null:
				marker = _find_marker_anywhere(_receiver_inst, "Slot_OPTIC_0")
		int(Enums.PartType.RECEIVER):
			# Prefer an explicit receiver marker if you add one, otherwise use a computed anchor
			if _receiver_inst != null:
				marker = _find_marker_anywhere(_receiver_inst, "Slot_RECEIVER_0")
				if marker != null:
					pos = marker.global_position
				else:
					pos = _compute_receiver_anchor_pos()
			return {"marker": marker, "pos": pos}
		_:
			if _receiver_inst != null:
				var name := _marker_name_for_slot_type(slot_type)
				if name != "":
					marker = _find_marker_anywhere(_receiver_inst, name)

	if marker != null:
		pos = marker.global_position

	return {"marker": marker, "pos": pos}

func _compute_receiver_anchor_pos() -> Vector3:
	# Try to anchor to the receiver body rather than pinning the label to a corner.
	if _receiver_inst == null:
		return Vector3.ZERO

	var slot_markers := _receiver_inst.get_node_or_null("SlotMarkers")
	if slot_markers != null:
		var sum := Vector3.ZERO
		var count := 0
		for c in slot_markers.get_children():
			if c is Marker3D:
				sum += (c as Marker3D).global_position
				count += 1
		if count > 0:
			return sum / float(count)

	# Fallback
	return _receiver_inst.global_position

func _spawn_part_instance(part: WeaponPart) -> Node3D:
	if part == null or part.scene == null:
		return null
	var inst := part.scene.instantiate() as Node3D
	return inst

func _get_part_icon_from_slot_dict(slot_dict: Dictionary) -> Texture2D:
	# If slot_dict already contains an icon, use it
	if slot_dict.has("child_part_icon") and slot_dict["child_part_icon"] is Texture2D:
		return slot_dict["child_part_icon"]

	# Otherwise: no icon yet (return null and TextureRect just stays empty)
	return null


func _subviewport_to_preview_local(p_sv: Vector2) -> Vector2:
	var sv_size := sub_viewport.size
	if sv_size.x <= 0 or sv_size.y <= 0:
		return Vector2.ZERO

	var svc := sub_viewport.get_parent() as SubViewportContainer
	var rect_size := svc.size
	var sv_scale := Vector2(rect_size.x / sv_size.x, rect_size.y / sv_size.y)

	# LinesOverlay is anchored to fill the SubViewportContainer, so its local space matches
	# the container's local space.
	return p_sv * sv_scale
