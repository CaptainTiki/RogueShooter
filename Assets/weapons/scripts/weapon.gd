extends Resource
class_name Weapon

@export_category("Identity")
@export var weapon_name : String = "Pistol"
@export var rarity : Enums.Rarity = Enums.Rarity.COMMON
@export var icon : Texture2D

@export_category("Visual")
@export var weapon_model : PackedScene
@export var weapon_position: Vector3 = Vector3(0.2, -0.2, -0.3)

@export_category("Firing")
@export var is_hitscan: bool = true
@export var projectile_scene: PackedScene

@export_category("Stats")
@export var base_stats: WeaponStats = WeaponStats.new()

@export_category("Mods")
# Slot layout for this weapon. One entry == one slot.
@export var mod_slots: Array[Enums.ModSlotType] = [Enums.ModSlotType.BARREL, Enums.ModSlotType.OPTIC, Enums.ModSlotType.UTILITY]
# Installed mods; indices align with mod_slots.
@export var installed_mods: Array[WeaponMod] = []

# Cached final stats used by WeaponController
var stats: WeaponStats = null

func recalculate() -> void:
	stats = get_final_stats()

func get_final_stats() -> WeaponStats:
	var out := _clone_stats(base_stats)

	# Apply each installed mod
	for i in range(installed_mods.size()):
		var m := installed_mods[i]
		if m == null:
			continue
		out = m.apply_to(out)

	# Clamp sanity
	out.damage = max(out.damage, 0.0)
	out.distance = max(out.distance, 0.0)
	out.recoil = max(out.recoil, 0.0)
	out.spread = max(out.spread, 0.0)
	out.ads_speed = max(out.ads_speed, 0.0)
	out.reload_speed = max(out.reload_speed, 0.0)
	out.ammo_capacity = max(out.ammo_capacity, 0.0)
	out.shot_interval = max(out.shot_interval, 0.01)
	out.multishot = max(out.multishot, 1.0)
	out.burst_per_shot = max(out.burst_per_shot, 1.0)
	out.burst_size = max(out.burst_size, 1.0)
	out.burst_seperation = max(out.burst_seperation, 0.0)

	return out

func clone_weapon() -> Weapon:
	# Deep-ish copy that keeps refs to mod resources (mods are immutable data)
	var w := Weapon.new()
	w.weapon_name = weapon_name
	w.rarity = rarity
	w.icon = icon
	w.weapon_model = weapon_model
	w.weapon_position = weapon_position
	w.is_hitscan = is_hitscan
	w.projectile_scene = projectile_scene
	w.base_stats = _clone_stats(base_stats)
	w.mod_slots = mod_slots.duplicate()
	w.installed_mods = installed_mods.duplicate()
	w.recalculate()
	return w

func _clone_stats(s: WeaponStats) -> WeaponStats:
	if s == null:
		return WeaponStats.new()
	var n := WeaponStats.new()
	# Combat
	n.damage = s.damage
	n.distance = s.distance
	n.recoil = s.recoil
	n.spread = s.spread
	# ADS
	n.ads_speed = s.ads_speed
	n.fov_amount = s.fov_amount
	# Ammo
	n.ammo_type = s.ammo_type
	n.ammo_capacity = s.ammo_capacity
	n.reload_speed = s.reload_speed
	# Firing
	n.trigger_mode = s.trigger_mode
	n.multishot = s.multishot
	n.burst_per_shot = s.burst_per_shot
	n.burst_size = s.burst_size
	n.burst_seperation = s.burst_seperation
	n.shot_interval = s.shot_interval
	return n
