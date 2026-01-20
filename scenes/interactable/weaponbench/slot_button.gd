extends Control
class_name SlotButton

signal pressed(slot_id: int)

@export var slot_id: int = -1

@onready var slot_btn: TextureButton = $MarginContainer/SlotBtn
@onready var icon: TextureRect = $MarginContainer/Content/Icon
@onready var part_type_label: Label = $MarginContainer/Content/SlotTypeLabel
@onready var part_name_label: Label = $MarginContainer/Content/PartLabel


var _pending_type: String = ""
var _pending_name: String = ""
var _pending_icon: Texture2D = null
var _has_pending := false
var _pending_selected := false
var _has_pending_selected := false

func _ready() -> void:
	slot_btn.pressed.connect(func(): pressed.emit(slot_id))
	_apply_pending()

func set_data(_slot_id: int, slot_type: String, slot_name: String, part_icon: Texture2D) -> void:
	slot_id = _slot_id
	_pending_type = slot_type
	_pending_name = slot_name
	_pending_icon = part_icon
	_has_pending = true

	# If we're already in the tree, apply immediately.
	if is_inside_tree():
		_apply_pending()

func _apply_pending() -> void:
	if not _has_pending:
		return
	if _pending_type:
		part_type_label.text = _pending_type
	if _pending_name:
		part_name_label.text = _pending_name
	if icon:
		icon.texture = _pending_icon

func set_selected(v: bool) -> void:
	_pending_selected = v
	_has_pending_selected = true
	if is_inside_tree():
		_apply_selected()

func _apply_selected() -> void:
	if not _has_pending_selected:
		return

	# MVP visual: tint the whole control
	modulate = Color(0.8, 0.9, 1.0, 1.0) if _pending_selected else Color(1, 1, 1, 1)


# Returns a point in CANVAS coordinates suitable for drawing a line to this button.
# For top-row buttons, we use bottom-middle.
# For bottom-row buttons, we use top-middle.
func get_line_anchor_canvas(is_top_row: bool) -> Vector2:
	# The TextureButton is the true visible/clickable rect.
	# The SlotButton control may be larger due to container sizing/expansion.
	if slot_btn == null:
		return get_global_rect().get_center()
	var r := slot_btn.get_global_rect()
	if is_top_row:
		return Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y)
	else:
		return Vector2(r.position.x + r.size.x * 0.5, r.position.y)
