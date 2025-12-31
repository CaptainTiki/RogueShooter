extends Resource
class_name WeaponStats

@export_category("Combat Stats")
@export var damage: float = 0.0
@export var range: float = 0.0
@export var recoil: float = 0.0
@export var spread: float = 0.0

@export_category("Aiming / Sights")
@export var ads_speed: float = 0.0
@export var fov_amount : float = 0.0

@export_category("Ammo & Reload")
@export var ammo_type: Enums.AmmoType = Enums.AmmoType.ANY
@export var ammo_capacity: float = 0
@export var reload_speed: float = 0.0

@export_category("Firing Behavior")
@export var trigger_mode: Enums.TriggerMode = Enums.TriggerMode.SEMI
@export var burst_per_shot: float = 1 #5 bursts of 1, with zero sep = shotgun
@export var burst_size: float = 1 #1 burst per shot, 3 burst size = typical assault rifle
@export var burst_seperation: float = 0.0 #0 is all at once
@export var shot_interval: float = 0.0 #time between allowed trigger pulls (or between auto fire)
