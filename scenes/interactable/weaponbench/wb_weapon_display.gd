extends Control
class_name WB_WeaponDisplay

@export var debug: bool = false
@export var min_cam_dist : float = 0.35
@export var max_cam_dist : float = 3.0
@export var rotate_speed : float = 0.01
@export var zoom_speed : float = 0.15

@onready var weapon_name_label: Label = %WeaponName_Label
@onready var sub_viewport: SubViewport = %SubViewport
@onready var preview_camera: Camera3D = %PreviewCamera
@onready var world_root: Node3D = %WorldRoot
@onready var weapon_pivot: Node3D = %WeaponPivot

@onready var _sub_viewport_container: SubViewportContainer = sub_viewport.get_parent() as SubViewportContainer

var _dragging := false
var _last_mouse: Vector2 = Vector2.ZERO
var _cam_dist: float = 1.2
var _spawned_model: Node3D = null

func _ready() -> void:
	set_process_unhandled_input(true)
	if _sub_viewport_container != null:
		_sub_viewport_container.resized.connect(_on_sub_viewport_container_resized)
		_on_sub_viewport_container_resized()
	_set_camera_distance(_cam_dist)

func set_weapon(weapon: Weapon) -> void:
	weapon_name_label.text = weapon.weapon_name if weapon != null else "Weapon"
	_clear_preview()
	_spawn_weapon_model(weapon)
	_frame_preview()

func _on_sub_viewport_container_resized() -> void:
	if _sub_viewport_container == null:
		return
	var s: Vector2 = _sub_viewport_container.size
	if s.x < 2.0 or s.y < 2.0:
		return
	var new_size := Vector2i(int(s.x), int(s.y))
	if sub_viewport.size != new_size:
		sub_viewport.size = new_size

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Only respond when the mouse is over the viewport rect
	if _sub_viewport_container == null:
		return
	var r := _sub_viewport_container.get_global_rect()

	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed and r.has_point(e.global_position):
				_dragging = true
				_last_mouse = e.global_position
				get_viewport().set_input_as_handled()
			elif not e.pressed:
				_dragging = false
		if r.has_point(e.global_position):
			if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
				_set_camera_distance(_cam_dist - zoom_speed)
				get_viewport().set_input_as_handled()
			elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
				_set_camera_distance(_cam_dist + zoom_speed)
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		var m := event as InputEventMouseMotion
		if _dragging:
			var delta := m.global_position - _last_mouse
			_last_mouse = m.global_position
			# Yaw around Y, slight pitch around X
			weapon_pivot.rotate_y(-delta.x * rotate_speed)
			weapon_pivot.rotate_x(-delta.y * rotate_speed * 0.5)
			get_viewport().set_input_as_handled()

func _set_camera_distance(d: float) -> void:
	_cam_dist = clamp(d, min_cam_dist, max_cam_dist)
	if preview_camera:
		var t := preview_camera.transform
		t.origin = Vector3(0, 0, _cam_dist)
		preview_camera.transform = t

func _clear_preview() -> void:
	if _spawned_model and is_instance_valid(_spawned_model):
		_spawned_model.queue_free()
	_spawned_model = null
	weapon_pivot.rotation = Vector3.ZERO

func _spawn_weapon_model(weapon: Weapon) -> void:
	# Prefer a real model if assigned. Otherwise spawn a simple placeholder box.
	var node: Node3D = null
	if weapon != null and weapon.weapon_model != null:
		node = weapon.weapon_model.instantiate() as Node3D
	else:
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.3, 0.15, 0.8)
		mi.mesh = box
		node = mi

	weapon_pivot.add_child(node)
	_spawned_model = node

func _frame_preview() -> void:
	# Simple framing: reset pivot and keep camera at a reasonable distance.
	weapon_pivot.position = Vector3.ZERO
	weapon_pivot.rotation = Vector3.ZERO
	_set_camera_distance(_cam_dist)
