extends Resource
class_name WeaponPart

# Basic info
@export_category("Basic Info")
@export var part_name: String = "Unnamed Part"
@export var icon: Texture2D
@export var part_type: Enums.PartType
@export var size: Enums.WeaponSize = Enums.WeaponSize.MEDIUM
@export var ammo_type : Enums.AmmoType

@export_category("Connection Slots")
# What extra slots this part adds (for chaining)
@export var adds_slots: Array[Enums.PartType] = []

# Additive stats – all start at 0
@export_category("Part Stats")
@export var damage_add: float = 0.0
@export var shot_interval_add: float = 0.0 # lower is faster "1.0 sec / rounds"
@export var burst_interval_add: float = 0.0 # spacing inside burst "1.0 second / rounds"
@export var range_add: float = 0.0
@export var recoil_add: float = 0.0
@export var ads_speed_add: float = 0.0   # lower = faster aiming
@export var spread_add: float = 0.0
@export var ammo_add: int = 0
@export var reload_speed_add: float = 0.0   # lower = faster reload

# Receiver-only fields (only fill these on receiver parts)
@export_category("Reciever Only Fields")
@export var trigger_mode: Enums.TriggerMode = Enums.TriggerMode.SEMI
@export var projectiles_per_shot: int = 1               # projectiles per shot
@export var burst_count: int = 1              # shots per trigger pull (for BURST)
@export var base_ammo_cost: float = 1.0
@export var hands_required: int = 1
