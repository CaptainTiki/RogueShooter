@tool
extends Resource
class_name RoomData

## Data-driven room template consumed by the run generator.
## All geometry / connector info is stored in ROOM-LOCAL space.

@export var id: String = ""
@export var display_name: String = ""

@export var packed_scene: PackedScene

## Room bounds used for overlap tests in generation.
## Stored as an AABB in room-local space.
@export var bounds_local: AABB = AABB(Vector3(-5, 0, -5), Vector3(10, 5, 10))

## Array of RoomConnectorData resources.
@export var connectors: Array[RoomConnectorData] = []

## Flexible tags to drive selection rules ("small", "hall", "biome_rock", etc.)
@export var tags: PackedStringArray = []

## Optional weighting hooks for later.
@export var base_weight: float = 1.0
@export var min_depth: int = 0
@export var max_depth: int = 999
