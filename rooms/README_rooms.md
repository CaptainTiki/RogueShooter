# Rooms (Data-Driven ProcGen)

This folder seeds the room pipeline.

## Authoring Workflow
1. Duplicate `res://rooms/scenes/room_template.tscn` and rename it (e.g. `small_rock_room_1.tscn`).
2. Dress the room using CSG (for now), later swap the Geometry to a Blender-exported mesh.
3. Place/rotate `RoomConnector` markers (children of `Connectors`).
   - Forward is the marker's **-Z** direction (Godot's forward).
   - `connector_type` uses `Enums.RoomConnectorType`.
4. Adjust `BoundsMarker` to the gameplay footprint (NOT props).
5. Click the `RoomTools -> Generate/Update RoomData` button in the inspector.
   - Outputs: `res://rooms/data/<room_id>.tres`
   - Also writes a debug JSON: `res://rooms/debug/<room_id>.roomdata.json`

## Seed Room
- `res://rooms/scenes/small_rock_room_1.tscn`
- `res://rooms/data/small_rock_room_1.tres`

These are a starting reference for the generator.
