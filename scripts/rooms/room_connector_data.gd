@tool
extends Resource
class_name RoomConnectorData

## Pure data describing a connector in ROOM-LOCAL space.
## Position is room-local.
## Forward is a normalized direction in room-local space.

@export var connector_type: int = 0 # Enums.RoomConnectorType
@export var position_local: Vector3 = Vector3.ZERO
@export var forward_local: Vector3 = Vector3.FORWARD

func _init() -> void:
	# Ensure a sane default
	forward_local = Vector3.FORWARD
