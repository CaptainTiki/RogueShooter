# res://ui/weaponbench/wb_display_lines_overlay.gd
extends Control
class_name WBLinesOverlay

var lines: Array[Dictionary] = [] 
# each: { "a": Vector2, "b": Vector2 }

func set_lines(new_lines: Array[Dictionary]) -> void:
	lines = new_lines
	queue_redraw()

func _draw() -> void:
	for l in lines:
		draw_line(l.a, l.b, Color(1, 1, 1, 0.85), 0.5, true)
		# optional endpoint dot:
		draw_circle(l.b, 3.0, Color(1, 1, 1, 1.25))
