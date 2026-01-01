# parts_catalog.gd
extends Node
class_name Parts_Catalog

signal catalog_rebuilt

# Where your .tres/.res WeaponPart resources live
@export var part_folders: Array[String] = [
	"res://assets/weapons/parts/" # <- change to your actual folder
]

# PartType -> Array[WeaponPart]
var _parts_by_type: Dictionary = {}

# Optional: quick lookup by unique id / resource_path
var _parts_by_id: Dictionary = {} # String -> WeaponPart


func rebuild_catalog() -> void:
	_parts_by_type.clear()
	_parts_by_id.clear()

	for folder in part_folders:
		_load_parts_from_folder(folder)

	for part_type in _parts_by_type.keys():
		_parts_by_type[part_type].sort_custom(_sort_parts)

	emit_signal("catalog_rebuilt")
	#print(_parts_by_id)


func get_parts(part_type: int) -> Array:
	# Returns a COPY so callers don't mutate the catalog accidentally
	if not _parts_by_type.has(part_type):
		return []
	return _parts_by_type[part_type].duplicate()


func get_all_parts() -> Array:
	var out: Array = []
	for arr in _parts_by_type.values():
		out.append_array(arr)
	return out


func get_part_by_id(id: String) -> Resource:
	# Use resource_path as id by default, or a custom id field on WeaponPart later
	return _parts_by_id.get(id, null)


func has_part_type(part_type: int) -> bool:
	return _parts_by_type.has(part_type) and _parts_by_type[part_type].size() > 0


# -------------------------
# Internal loading helpers
# -------------------------

func _load_parts_from_folder(folder_path: String) -> void:
	if not DirAccess.dir_exists_absolute(folder_path):
		push_warning("PartsCatalog: folder not found: %s" % folder_path)
		return

	var dir := DirAccess.open(folder_path)
	if dir == null:
		push_warning("PartsCatalog: could not open folder: %s" % folder_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		var full_path := folder_path.path_join(file_name)

		# Recurse into subfolders
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				_load_parts_from_folder(full_path)
		else:
			_try_load_part_resource(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()


func _try_load_part_resource(path: String) -> void:
	# Only try resource files you expect
	if not (path.ends_with(".tres") or path.ends_with(".res")):
		return

	var res := load(path)
	if res == null:
		return

	# Replace WeaponPart with your actual class_name if different
	if res is WeaponPart:
		_register_part(res, path)

func _register_part(part: WeaponPart, id: String) -> void:
	# Ensure part_type exists
	var part_type := part.part_type # <- adjust property name if needed

	if not _parts_by_type.has(part_type):
		_parts_by_type[part_type] = []

	_parts_by_type[part_type].append(part)

	# By default, id is resource path. Later you can swap to part.guid or similar.
	_parts_by_id[id] = part

func _sort_parts(a: WeaponPart, b: WeaponPart) -> bool:
	# Example: rarity DESC, then name ASC
	# Adjust to your rarity field/type
	if a.rarity != b.rarity:
		return a.rarity > b.rarity
	return a.part_name < b.part_name
