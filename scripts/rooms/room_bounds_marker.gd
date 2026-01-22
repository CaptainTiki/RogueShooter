@tool
extends CSGBox3D
class_name RoomBoundsMarker

## Author-time bounds helper for a room.
## These bounds are used for procedural placement overlap tests.
##
## You *want* this to represent gameplay space, not prop decoration.

@export var center: Vector3 = Vector3(0, 2.5, 0)

func get_aabb_local() -> AABB:
	var half := size * 0.5
	var min_corner := center - half
	return AABB(min_corner, size)
