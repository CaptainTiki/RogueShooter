@tool
extends Resource
class_name WeaponPart

# Basic info
@export_category("Basic Info")
@export var part_name: String = "Unnamed Part"
@export var rarity : Enums.Rarity = Enums.Rarity.COMMON
@export var part_type: Enums.PartType
@export var size: Enums.WeaponSize = Enums.WeaponSize.SMALL
@export var ammo_type : Enums.AmmoType = Enums.AmmoType.ANY
@export var icon: Texture2D
@export var scene: PackedScene
@export_category("Connection Slots")
# What extra slots this part adds (for chaining)
@export var adds_slots: Array[Enums.PartType] = []

# Additive stats – all start at 0
@export_category("Part Stats")
@export var damage_add: float = 0.0
@export var shot_interval_add: float = 0.0 # lower is faster "1.0 sec / rounds"
@export var multishot_add: float = 0.0
@export var burst_seperation_add: float = 0.0 # spacing inside burst "1.0 second / rounds"
@export var burst_size_add: float = 0.0
@export var burst_per_shot_add: float = 0.0
@export var distance_add: float = 0.0
@export var recoil_add: float = 0.0
@export var ads_speed_add: float = 0.0   # lower = faster aiming
@export var spread_add: float = 0.0
@export var ammo_add: float = 0
@export var reload_speed_add: float = 0.0   # lower = faster reload
@export var fov_ammount_add: float = 0.0 # zero is none, higher is more zoom

@export_category("Part Naming")
@export var name_prefix : String = ""      # "Iron", "Rusty", "Prototype"
@export var name_core : String = ""        # "Stinger", "Ripper", "Pulse"
@export var name_suffix : String = ""      # "Mk II", "of the Deep", "XR"
@export var name_descriptor : String = ""  # "Auto", "Burst", "Heavy"

# Receiver-only fields (only fill these on receiver parts)
@export_category("Reciever Only Fields")
@export var trigger_mode: Enums.TriggerMode = Enums.TriggerMode.SEMI
@export var multishot: float = 1.0
@export var burst_per_shot: float = 1.0 #5 bursts of 1, with zero sep = shotgun
@export var burst_size: float = 1.0 #1 burst per shot, 3 burst size = typical assault rifle
@export var burst_seperation: float = 0.0 #0 is all at once
@export var shot_interval: float = 0.0 #time between allowed trigger pulls (or between auto fire)
@export var cycle_time: float = 0.0 #pump shotugn syle time betwen trigger pulls ((not reload)
