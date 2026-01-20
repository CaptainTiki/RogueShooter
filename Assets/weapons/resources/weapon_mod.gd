extends Resource
class_name WeaponMod

@export_category("Identity")
@export var mod_name: String = "Mod"
@export var slot_type: Enums.ModSlotType = Enums.ModSlotType.UTILITY
@export var icon: Texture2D
@export var rarity: Enums.Rarity = Enums.Rarity.COMMON

@export_category("Stat Adds")
@export var damage_add: float = 0.0
@export var distance_add: float = 0.0
@export var recoil_add: float = 0.0
@export var spread_add: float = 0.0
@export var ads_speed_add: float = 0.0
@export var fov_amount_add: float = 0.0
@export var ammo_capacity_add: float = 0.0
@export var reload_speed_add: float = 0.0
@export var shot_interval_add: float = 0.0

@export_category("Stat Multipliers")
@export var damage_mul: float = 1.0
@export var distance_mul: float = 1.0
@export var recoil_mul: float = 1.0
@export var spread_mul: float = 1.0
@export var ads_speed_mul: float = 1.0
@export var reload_speed_mul: float = 1.0
@export var shot_interval_mul: float = 1.0

@export_category("Overrides")
@export var override_trigger_mode: bool = false
@export var trigger_mode: Enums.TriggerMode = Enums.TriggerMode.SEMI
@export var override_ammo_type: bool = false
@export var ammo_type: Enums.AmmoType = Enums.AmmoType.ANY

func apply_to(s: WeaponStats) -> WeaponStats:
	# Applies this mod to a COPY of the provided stats and returns it.
	var out := WeaponStats.new()
	# Start as a copy
	out.damage = s.damage
	out.distance = s.distance
	out.recoil = s.recoil
	out.spread = s.spread
	out.ads_speed = s.ads_speed
	out.fov_amount = s.fov_amount
	out.ammo_type = s.ammo_type
	out.ammo_capacity = s.ammo_capacity
	out.reload_speed = s.reload_speed
	out.trigger_mode = s.trigger_mode
	out.multishot = s.multishot
	out.burst_per_shot = s.burst_per_shot
	out.burst_size = s.burst_size
	out.burst_seperation = s.burst_seperation
	out.shot_interval = s.shot_interval

	# Multipliers first (feels nicer), then adds
	out.damage = out.damage * damage_mul + damage_add
	out.distance = out.distance * distance_mul + distance_add
	out.recoil = out.recoil * recoil_mul + recoil_add
	out.spread = out.spread * spread_mul + spread_add
	out.ads_speed = out.ads_speed * ads_speed_mul + ads_speed_add
	out.reload_speed = out.reload_speed * reload_speed_mul + reload_speed_add
	out.shot_interval = out.shot_interval * shot_interval_mul + shot_interval_add
	out.fov_amount = out.fov_amount + fov_amount_add
	out.ammo_capacity = out.ammo_capacity + ammo_capacity_add

	if override_trigger_mode:
		out.trigger_mode = trigger_mode
	if override_ammo_type:
		out.ammo_type = ammo_type

	return out
