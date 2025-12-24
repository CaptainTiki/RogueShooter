#reticle_draw.gd
@tool
extends Control
class_name ReticleDraw

@export var radius : float = 30.0 : set = set_crosshair_radius
@export var thickness : float = 1.0 : set = set_crosshair_thickness
@export var color : Color = Color.WHITE : set = set_crosshair_color
@export var gap_angle : float = 45.0 : set = set_crosshair_gap_angle
@export var segments : int = 32 : set = set_crosshair_segments


func _draw() -> void:
	draw_circle_crosshair()

func draw_circle_crosshair():
	var gap_rad = deg_to_rad(gap_angle)

	var arc_segments = [
		#Bottom-Right Quadrant
		[gap_rad / 2, PI / 2 - gap_rad / 2],
		#Bottom-Left Quadrant
		[PI / 2 + gap_rad / 2, PI - gap_rad / 2],
		#Top-Left Quadrant
		[PI + gap_rad / 2, 3 * PI / 2 - gap_rad / 2],
		#Top-Right Quadrant
		[3 * PI / 2 + gap_rad / 2, 2 * PI - gap_rad / 2]
	]
	
	for arc in arc_segments:
		var start_angle = arc[0]
		var end_angle = arc[1]
		
		var points = []
		var angle_step = (end_angle - start_angle) / segments
	
		for i in range(segments +1):
			var angle = start_angle + i * angle_step
			var point = Vector2(radius * cos(angle), radius * sin(angle))
			points.append(point)
		
		if points.size() > 1:
			draw_polyline(points, color, thickness, true)
	
func update_crosshair():
	queue_redraw()
	
func set_crosshair_radius(new_radius : float) -> void:
	radius = new_radius
	update_crosshair()

func set_crosshair_thickness(new_thick : float) -> void:
	thickness = new_thick
	update_crosshair()

func set_crosshair_color(new_color : Color) -> void:
	color = new_color
	update_crosshair()

func set_crosshair_gap_angle(new_angle : float) -> void:
	gap_angle = new_angle
	update_crosshair()

func set_crosshair_segments(new_seg : int) -> void:
	segments = new_seg
	update_crosshair()
