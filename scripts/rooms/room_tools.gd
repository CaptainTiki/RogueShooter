@tool
extends Node
class_name RoomTools

## Drop this into a room scene (ideally on the root) to generate/update RoomData.
##
## Workflow:
## 1) Duplicate room template scene.
## 2) Place BoundsMarker + RoomConnector markers.
## 3) Click "Generate/Update RoomData".
## 4) A .tres RoomData file is created/updated under output_dir.

@export var output_dir: String = "res://rooms/data"

@export_tool_button("Generate/Update RoomData")
var generate_room_data_button := _generate_room_data

@export var default_tags: PackedStringArray = PackedStringArray([])
@export var default_base_weight: float = 1.0
@export var default_min_depth: int = 0
@export var default_max_depth: int = 999

## Quick authoring toggle: hide/show BoundsMarker + Connector geometry (CSG boxes, etc.)
## so your room isn't a soup of debug shapes.
@export var author_markers_visible: bool = true:
	set(value):
		author_markers_visible = value
		if Engine.is_editor_hint():
			_apply_author_markers_visible()

func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_author_markers_visible()

func _generate_room_data() -> void:
	if not Engine.is_editor_hint():
		return

	var root := get_tree().edited_scene_root
	if root == null:
		push_error("RoomTools: No edited_scene_root. Open the room scene before generating.")
		return

	var scene_path := root.scene_file_path
	if scene_path == "":
		push_error("RoomTools: Scene has no path. Save the room scene first, then generate.")
		return

	# Collect author-time nodes
	var bounds_marker := root.find_child("BoundsMarker", true, false)
	if bounds_marker == null:
		# Fallback: search by script class
		bounds_marker = _find_first_bounds_marker(root)
	if bounds_marker == null:
		push_error("RoomTools: Could not find BoundsMarker (RoomBoundsMarker). Add one named 'BoundsMarker'.")
		return

	var connectors := root.get_tree().get_nodes_in_group("room_connector")
	# Only keep connectors that are within this edited scene.
	connectors = connectors.filter(func(n): return root.is_ancestor_of(n) or n == root)
	if connectors.size() == 0:
		push_warning("RoomTools: No connectors found (group 'room_connector'). You probably want at least 1.")

	# Build RoomData resource
	var room_data := RoomData.new()
	room_data.id = _scene_basename(scene_path)
	room_data.display_name = room_data.id
	room_data.packed_scene = load(scene_path)
	room_data.bounds_local = bounds_marker.get_aabb_local()
	room_data.tags = default_tags
	room_data.base_weight = default_base_weight
	room_data.min_depth = default_min_depth
	room_data.max_depth = default_max_depth

	room_data.connectors.clear()
	for c in connectors:
		if not c.has_method("get_forward_local"):
			continue
		var cd := RoomConnectorData.new()
		# Connector script provides an exported int property named 'connector_type'
		cd.connector_type = int(c.get("connector_type"))
		cd.position_local = c.position
		cd.forward_local = c.get_forward_local()
		room_data.connectors.append(cd)

	# Validate
	var problems := _validate(room_data)
	for p in problems:
		push_warning(p)

	# Ensure output dir exists
	_ensure_dir(output_dir)

	var tres_path := output_dir.path_join("%s.tres" % room_data.id)
	var err := ResourceSaver.save(room_data, tres_path)
	if err != OK:
		push_error("RoomTools: Failed to save RoomData to %s (err=%s)" % [tres_path, str(err)])
		return

	# Optional: debug JSON to eyeball/diff
	_ensure_dir("res://rooms/debug")
	var json_path := "res://rooms/debug/%s.roomdata.json" % room_data.id
	_write_json_debug(room_data, json_path)

	print("RoomTools: Generated RoomData -> ", tres_path)

func _validate(rd: RoomData) -> PackedStringArray:
	var issues: PackedStringArray = PackedStringArray([])
	if rd.packed_scene == null:
		issues.append("RoomData missing packed_scene")
	if rd.bounds_local.size.x <= 0 or rd.bounds_local.size.y <= 0 or rd.bounds_local.size.z <= 0:
		issues.append("RoomData bounds_local has non-positive size")
	for i in range(rd.connectors.size()):
		var c := rd.connectors[i]
		if c.forward_local.length_squared() < 0.0001:
			issues.append("Connector %d forward vector is near-zero" % i)
	return issues

func _ensure_dir(dir_path: String) -> void:
	var d := DirAccess.open("res://")
	if d == null:
		return
	# Make recursive
	var parts := dir_path.replace("res://", "").split("/", false)
	var cur := "res://"
	for part in parts:
		cur = cur.path_join(part)
		if not DirAccess.dir_exists_absolute(cur):
			DirAccess.make_dir_recursive_absolute(cur)

func _scene_basename(scene_path: String) -> String:
	var fname := scene_path.get_file()
	return fname.get_basename()

func _find_first_bounds_marker(n: Node) -> Node:
	if n is RoomBoundsMarker:
		return n
	for child in n.get_children():
		var found := _find_first_bounds_marker(child)
		if found != null:
			return found
	return null

func _apply_author_markers_visible() -> void:
	if not Engine.is_editor_hint():
		return
	var root := get_tree().edited_scene_root
	if root == null:
		return

	var bounds_marker := root.find_child("BoundsMarker", true, false)
	if bounds_marker != null and _has_property(bounds_marker, "visible"):
		bounds_marker.set("visible", author_markers_visible)

	var connectors := root.get_tree().get_nodes_in_group("room_connector")
	connectors = connectors.filter(func(n): return root.is_ancestor_of(n) or n == root)
	for c in connectors:
		if _has_property(c, "visible"):
			c.set("visible", author_markers_visible)
		# If the connector is a Marker3D with a child visual gizmo, handle that too.
		for child in c.get_children():
			if _has_property(child, "visible"):
				child.set("visible", author_markers_visible)

func _has_property(o: Object, prop: String) -> bool:
	for p in o.get_property_list():
		if p.name == prop:
			return true
	return false

func _write_json_debug(rd: RoomData, path: String) -> void:
	var data := {
		"id": rd.id,
		"display_name": rd.display_name,
		"packed_scene": rd.packed_scene.resource_path if rd.packed_scene != null else "",
		"bounds_local": {
			"position": [rd.bounds_local.position.x, rd.bounds_local.position.y, rd.bounds_local.position.z],
			"size": [rd.bounds_local.size.x, rd.bounds_local.size.y, rd.bounds_local.size.z],
		},
		"tags": rd.tags,
		"base_weight": rd.base_weight,
		"min_depth": rd.min_depth,
		"max_depth": rd.max_depth,
		"connectors": [],
	}
	for c in rd.connectors:
		data["connectors"].append({
			"type": c.connector_type,
			"pos": [c.position_local.x, c.position_local.y, c.position_local.z],
			"fwd": [c.forward_local.x, c.forward_local.y, c.forward_local.z],
		})
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
