extends Node
class_name WeaponController

signal weapon_changed

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
	_on_weapon_changed() #do the first setup of the weapon.
	weapon_changed.connect(_on_weapon_changed)

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

func reload_weapon() -> void:
	current_ammo = weapon_stats.ammo_capacity
	if debug:
		print("reloaded weapon")

func fire_weapon() -> void:
	if not can_fire():
		return

	# snapshot local vars so they don't change mid-burst
	var bursts_per_trigger : int = int(weapon_stats.burst_per_shot)
	var burst_size : int = int(weapon_stats.burst_size)
	var multisize : int = int(weapon_stats.multishot)
	var sep : float = weapon_stats.burst_seperation

	for b in bursts_per_trigger:
		for i in burst_size:
			if current_ammo < 1.0:
				return
			current_ammo -= 1.0

			for m in multisize:
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

func _on_weapon_changed() -> void:
	if current_weapon:
		current_weapon.recalculate()
		weapon_stats = current_weapon.stats
		current_ammo = weapon_stats.ammo_capacity
		if debug:
			debug_print()

func build_default_pistol() -> Weapon:
	# Temporary hard-coded weapon until we hook up blueprints + crafting.
	var w := Weapon.new()
	w.weapon_name = "Blaster"
	w.is_hitscan = true
	w.weapon_model = load("res://assets/weapons/blaster-a.glb") as PackedScene

	var s := WeaponStats.new()
	s.damage = 4.5
	s.distance = 16.0
	s.ammo_capacity = 24.0
	s.reload_speed = 1.4
	s.shot_interval = 0.16
	s.spread = 2.1
	s.recoil = 3.3
	s.trigger_mode = Enums.TriggerMode.SEMI
	s.multishot = 1
	s.burst_per_shot = 1
	s.burst_size = 1
	s.burst_seperation = 0.0
	w.base_stats = s
	w.mod_slots = [Enums.ModSlotType.BARREL, Enums.ModSlotType.OPTIC, Enums.ModSlotType.UTILITY]
	w.installed_mods = [null, null, null]
	w.recalculate()
	return w
