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
	# Prefer seed loadout from Game.
	current_weapon = _get_seed_weapon_or_fallback()
	_on_weapon_changed() # do the first setup of the weapon.
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
	if weapon_stats == null:
		return

	# If ammo type is ANY, treat as 'infinite / test ammo' for now.
	if int(weapon_stats.ammo_type) == int(Enums.AmmoType.ANY):
		current_ammo = weapon_stats.ammo_capacity
		if debug:
			print("reloaded weapon (ANY ammo, infinite test pool)")
		return

	var inv: Inventory = null
	if Game.current != null:
		inv = Game.current.player_inventory
	if inv == null:
		# No game/inventory context; fall back to infinite.
		current_ammo = weapon_stats.ammo_capacity
		if debug:
			print("reloaded weapon (no inventory context)")
		return

	var cap : int= int(weapon_stats.ammo_capacity)
	var cur : int= int(current_ammo)
	var need : int = max(0, cap - cur)
	if need <= 0:
		return

	var have := inv.get_ammo(weapon_stats.ammo_type)
	if have <= 0:
		if debug:
			print("reload failed: no ammo in pool for type:", int(weapon_stats.ammo_type))
		return

	var to_load : int = min(need, have)
	inv.consume_ammo(weapon_stats.ammo_type, to_load)
	current_ammo = float(cur + to_load)

	if debug:
		print("reloaded weapon. loaded:", to_load, " pool_left:", inv.get_ammo(weapon_stats.ammo_type), " mag:", int(current_ammo), "/", cap)

func cycle_weapon(step: int) -> void:
	if Game.current == null:
		return

	var inv := Game.current.player_inventory
	if inv == null:
		return

	var count := inv.owned_weapons.size()
	if count <= 0:
		return

	var idx := Game.current.game_state.equipped_weapon_index
	idx = (idx + step) % count
	if idx < 0:
		idx += count

	Game.current.game_state.equipped_weapon_index = idx

	var w := inv.owned_weapons[idx] as Weapon
	if w == null:
		return

	current_weapon = w
	weapon_changed.emit()

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
		spawn_weapon_model()

		if debug:
			debug_print()


func _get_seed_weapon_or_fallback() -> Weapon:
	if Game.current != null:
		var inv := Game.current.player_inventory
		if inv != null and inv.owned_weapons.size() > 0:
			var idx : int = clamp(Game.current.game_state.equipped_weapon_index, 0, inv.owned_weapons.size() - 1)
			var w := inv.owned_weapons[idx] as Weapon
			if w != null:
				return w

	push_warning("WeaponController: no seeded weapon found; using fallback blueprint")
	var fallback := load("res://assets/weapons/blueprints/pistol_rusty_sidearm.tres") as Weapon
	if fallback != null:
		return fallback.clone_weapon()
	
	printerr("no weapons found!")
	return null
