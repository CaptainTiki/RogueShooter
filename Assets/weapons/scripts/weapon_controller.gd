extends Node
class_name WeaponController

@export var debug : bool = false
@export var camera: CameraEffects
@export var weapon_model_parent: Node3D
@export var weapon_state_chart : StateChart

const SPREAD_SCALE : float = 0.02

var current_weapon: Weapon
var weapon_stats : WeaponStats
var current_weapon_model: Node3D
var current_ammo: float

func _ready() -> void:
	current_weapon = build_default_pistol()
	current_weapon.stats = WeaponCalc.calculate_stats(current_weapon)
	if current_weapon:
		weapon_stats = current_weapon.stats
		current_ammo = weapon_stats.ammo_capacity
		#TODO: spawn weapon models for visual, attatch to hands
		#spawn_weapon_model()
	#debug_print()

func debug_print()-> void:
	print("Equipped:", current_weapon.weapon_name,
	" dmg:", weapon_stats.damage,
	" range:", weapon_stats.distance,
	" ammo:", weapon_stats.ammo_capacity,
	" burst_per_shot:", weapon_stats.burst_per_shot,
	" burst_size:", weapon_stats.burst_size,
	" sep:", weapon_stats.burst_seperation,
	" interval:", weapon_stats.shot_interval,
	" spread:", weapon_stats.spread, 
	" recoil:", weapon_stats.recoil)


func spawn_weapon_model():
	if current_weapon_model:
		current_weapon_model.queue_free()
	
	if current_weapon.weapon_model:
		current_weapon_model = current_weapon.weapon_model.instantiate()
		weapon_model_parent.add_child(current_weapon_model)
		current_weapon_model.position = current_weapon.weapon_position

func can_fire() -> bool:
	if weapon_stats == null:
		return false
	
	return current_ammo >= 1

func fire_weapon() -> void:
	if not can_fire():
		return

	# snapshot local vars so they don't change mid-burst
	var bursts_per_trigger : int = int(weapon_stats.burst_per_shot)
	var bullets_per_burst : int = int(weapon_stats.burst_size)
	var sep : float = weapon_stats.burst_seperation

	for b in bursts_per_trigger:
		for i in bullets_per_burst:
			# spend 1 ammo unit per bullet, and return early if we run out during the burst
			if current_ammo < 1.0:
				return
			current_ammo -= 1.0

			# Fire one "bullet"
			if current_weapon.is_hitscan:
				_perform_hitscan()
			else:
				# spawn projectile later
				pass
				
			_apply_recoil()
			
			if sep > 0.0:
				await get_tree().create_timer(sep).timeout
				
	if debug:
		print("Fired! Ammo units:", current_ammo, " | timefired ticks_msec: ", Time.get_ticks_msec())

func _apply_recoil() -> void:
	if camera and camera is CameraEffects:
		var recoil := weapon_stats.recoil
		camera.add_weapon_kick(
			recoil,            # pitch
			recoil * 0.5,      # yaw (smaller)
			recoil * 0.25      # roll (tiny)
		)

func _perform_hitscan() -> void:
	if not camera:
		printerr("no Camera Assigned to Weapon Controller")
		return
	
	var space_state = camera.get_world_3d().direct_space_state
	var from = camera.global_position
	var forward = -camera.global_transform.basis.z
	
	var basis = camera.global_transform.basis

	var spread_strength : float = weapon_stats.spread * SPREAD_SCALE
	var angle := randf() * TAU
	var radius := randf() * spread_strength
	var offset = camera.global_transform.basis.x * cos(angle) * radius \
			   + camera.global_transform.basis.y * sin(angle) * radius
	var spread_dir = (forward + offset).normalized()
	var to = from + spread_dir * weapon_stats.distance
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result:
		print("Hit: ", result.collider.name, " at ", result.position)
		_spawn_impact_marker(result.position)

func _spawn_impact_marker(position : Vector3) -> void:
	var marker = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 0.1)
	marker.mesh = box
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	marker.set_surface_override_material(0, material)
	
	get_tree().current_scene.add_child(marker)
	marker.global_position = position
	
	get_tree().create_timer(2.0).timeout.connect(marker.queue_free)


func build_default_pistol() -> Weapon:
	var receiver: WeaponPart = load("res://assets/weapons/parts/receivers/plain_energy_receiver.tres")
	var barrel: WeaponPart   = load("res://assets/weapons/parts/barrels/stabilized_short_barrel.tres")
	var grip: WeaponPart     = load("res://assets/weapons/parts/grips/polymer_pistol_grip.tres")
	var mag: WeaponPart      = load("res://assets/weapons/parts/magazines/compact_cell_magazine.tres")
	var optic: WeaponPart    = load("res://assets/weapons/parts/optics/lowprofile_iron_optics.tres")

	var w := Weapon.new()
	w.initialize_with_receiver(receiver)

	var barrel_slot := w.find_first_open_slot_of_type(Enums.PartType.BARREL)
	w.add_part_to_slot(barrel_slot, barrel)

	var grip_slot := w.find_first_open_slot_of_type(Enums.PartType.GRIP)
	w.add_part_to_slot(grip_slot, grip)

	var mag_slot := w.find_first_open_slot_of_type(Enums.PartType.MAGAZINE)
	w.add_part_to_slot(mag_slot, mag)

	# Optional attachment
	var optic_slot := w.find_first_open_slot_of_type(Enums.PartType.OPTIC)
	if optic_slot != -1:
		w.add_part_to_slot(optic_slot, optic)

	if debug:
		w.debug_print_graph()
	#ResourceSaver.save(w, "user://debug_blaster.weapon.tres")
	return w
