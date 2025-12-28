extends MeshInstance3D
class_name DebugRay3D

var _mesh := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()

func _ready():
	mesh = _mesh
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.vertex_color_use_as_albedo = true
	material_override = _mat

func draw_line(from: Vector3, to: Vector3, color: Color):
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(from)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(to)
	_mesh.surface_end()
