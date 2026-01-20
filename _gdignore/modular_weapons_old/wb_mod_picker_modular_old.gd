extends Control
class_name WB_PartsDisplay

signal part_highlighted(part: WeaponPart)
signal part_selected(part: WeaponPart)

@export var debug: bool = false

@onready var parts_grid: GridContainer = %PartsGrid

var _current_parts: Array[WeaponPart] = []

func show_parts(parts: Array[WeaponPart]) -> void:
	_current_parts = parts
	_rebuild()

func clear() -> void:
	_current_parts = []
	_rebuild()

func _rebuild() -> void:
	# clear old
	for c in parts_grid.get_children():
		c.queue_free()

	if _current_parts.is_empty():
		var lbl := Label.new()
		lbl.text = "No parts available"
		parts_grid.add_child(lbl)
		return

	for p in _current_parts:
		if p == null:
			continue

		var btn := Button.new()
		btn.text = p.part_name
		
		btn.focus_mode = Control.FOCUS_ALL

		btn.mouse_entered.connect(func():
			part_highlighted.emit(p)
		)

		btn.focus_entered.connect(func():
			part_highlighted.emit(p)
		)

		btn.pressed.connect(func():
			part_selected.emit(p)
		)

		parts_grid.add_child(btn)

func _on_part_pressed(part: WeaponPart) -> void:
	part_selected.emit(part)
