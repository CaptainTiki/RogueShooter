# ImpactManager.gd
extends Node3D
class_name ImpactManager

@export var max_impacts : int = 80
@export var impact_scene : PackedScene

var _active : Array[ImpactDecal] = []
var _pool : Array[ImpactDecal] = []

func spawn_impact(hit_pos : Vector3, hit_normal : Vector3) -> void:
	if impact_scene == null:
		push_warning("ImpactManager: impact_scene not assigned.")
		return

	# Reuse from pool if possible
	var decal : ImpactDecal
	if _pool.size() > 0:
		decal = _pool.pop_back()
	else:
		decal = impact_scene.instantiate() as ImpactDecal
		add_child(decal)

	# If we’re at max, recycle the oldest active one (FIFO)
	if _active.size() >= max_impacts:
		var oldest : ImpactDecal = _active.pop_front()
		_recycle(oldest)

	# Activate & place
	decal.visible = true
	decal.set_process(true)
	decal.place_decal(hit_pos, hit_normal)
	#decal.reset_and_place(hit_pos, hit_normal)

	_active.append(decal)

func _recycle(decal: ImpactDecal) -> void:
	if decal == null:
		return
	decal.visible = false
	decal.set_process(false)
	_pool.append(decal)
