extends Resource
class_name GunPartDef

enum Type {NONE, BARREL, FRAME, MAG, CHAMBER, OPTICS}
enum Platform {NONE, ALL, PISTOL, SHOTGUN, SMG, ASSAULT, HMG, SNIPER}
enum AmmoFamily {NONE, ALL, BULLET_SM, BULLET_LG}

enum Tags {NONE} #any tag that doesn't fit into the above enums

@export_category("Identity")
@export var id : String = "default_part"
@export var display_name : String = "Default Part"
@export var slot_type : Type = Type.NONE
@export var description : String = "Optional Fluff Text"

@export_category("Compatability")
@export var platform : Platform = Platform.NONE
@export var ammo_family : AmmoFamily = AmmoFamily.NONE

@export_category("Modifiers")
@export var mods : Dictionary = {}

@export_category("Future Compatability")
@export var tags : Array[Tags] = []
@export var requires_tags : Array[Tags] = []

@export_category("Visuals")
var visual_scene : PackedScene = null
