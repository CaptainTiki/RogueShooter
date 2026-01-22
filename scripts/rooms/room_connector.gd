@tool
extends CSGBox3D
class_name RoomConnector

## Author-time connector marker.
## The generator uses the connector's position + forward vector (room-local).

@export var connector_type: int = 0 # Enums.RoomConnectorType

func _ready() -> void:
	# Keep connectors discoverable.
	if not is_in_group("room_connector"):
		add_to_group("room_connector")

func get_forward_local() -> Vector3:
	# In Godot, "forward" is -Z.
	var fwd := transform.basis * Vector3.FORWARD
	if fwd.length_squared() < 0.000001:
		return Vector3.FORWARD
	return fwd.normalized()
