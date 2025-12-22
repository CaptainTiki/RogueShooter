extends Node3D
class_name Weapon

@export var player : Player
@export var camera : Camera3D

@onready var muzzle: Marker3D = $Muzzle
@onready var fire_timer: Timer = $FireTimer


var gun : GunBuild = GunBuild.new()
var stats : GunStats = GunStats.new()

var fire_just_pressed : bool = false
var fire_held : bool = false
var fire_released : bool = false
var ads : bool = false

var time_to_fire : float = 0

func _ready() -> void:
	setup_weapon()
	player.weapon_changed.connect(_on_weapon_changed)
	pass

func _process(_delta: float) -> void:
	check_inputs()
	process_firing_weapon()
	

func setup_weapon() -> void:
	print("setup weapon")
	gun = player.current_gun
	stats = GunCalc.calculate_stats(gun)
	fire_timer.stop()
	fire_timer.wait_time = 1.0 /stats.fire_rate

func process_firing_weapon() -> void:
	if not fire_timer.is_stopped():
		return
	#TODO: Check for enough ammo here - or return if not enough
	match stats.fire_mode:
		GunPartDef.FireMode.SEMI:
			if fire_just_pressed:
				_fire_weapon()
		GunPartDef.FireMode.AUTO:
			if fire_held:
				_fire_weapon()
		GunPartDef.FireMode.CHARGE:
			if fire_held:
				#TODO: build up charge, removing ammo
				pass
			if fire_released:
				#TODO: launch our big blast
				pass
			pass



func _fire_weapon() -> void:
	fire_timer.start()
	#TODO: Expend ammo - do animations, fire sound effects
	
	var origin: Vector3 = camera.global_position
	var dir: Vector3 = -camera.global_transform.basis.z
	#TODO: use the stats.range (need to put that in calc)
	var _range: float = 100.0
	var to: Vector3 = origin + dir * _range
	var query := PhysicsRayQueryParameters3D.create(origin, to)
	query.exclude = [player] #TODO: add the weapon mesh's to this exclusion
	query.collide_with_areas = false
	query.collide_with_bodies = true
	#TODO: use collision mask for raycast?
	# query.collision_mask = 1 << 0 | 1 << 2
	var space_state: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var hit: Dictionary = space_state.intersect_ray(query)

	if hit.is_empty():
		return
	
	var collider: Object = hit["collider"]
	var hit_pos: Vector3 = hit["position"]
	var hit_norm: Vector3 = hit["normal"]
	
	if collider is Node:
		var hc := (collider as Node).get_node_or_null("HealthComponent")
		if hc and hc.has_method("take_damage"):
			hc.take_damage(stats.damage)
	
	World.impact_manager.spawn_impact(hit_pos, hit_norm)
	
	



func reload_weapon() -> void:
	pass

func _on_weapon_changed() -> void:
	print("weapon: on weapon changed")
	setup_weapon()

func check_inputs() -> void:
	fire_just_pressed = Input.is_action_just_pressed("fire")
	fire_held = Input.is_action_pressed("fire")
	fire_released = Input.is_action_just_released("fire")
		
	if Input.is_action_pressed("reload"):
		reload_weapon()
	
	#TODO: Setup for ADS
	ads = Input.is_action_just_released("ads")
