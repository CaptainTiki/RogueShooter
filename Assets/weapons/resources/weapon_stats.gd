extends Resource
class_name WeaponStats

@export_category("Combat Stats")
@export var damage: float = 0.0
@export var range: float = 0.0
@export var recoil: float = 0.0
@export var ads_speed: float = 0.0
@export var spread: float = 0.0

@export_category("Ammo & Reload")
@export var ammo_type: Enums.AmmoType = Enums.AmmoType.ANY
@export var ammo_capacity: float = 0
@export var reload_speed: float = 0.0

@export_category("Firing Behavior")
@export var trigger_mode: Enums.TriggerMode = Enums.TriggerMode.SEMI
@export var projectiles_per_shot: float = 1
@export var burst_count: float = 1
@export var ammo_per_projectile: float = 1
@export var ammo_cost_mult: float = 1.0

@export_category("Timing (seconds)")
@export var shot_cooldown: float = 0.0
@export var burst_interval: float = 0.0
