extends Resource
class_name Weapon

@export var weapon_name : String = "Pistol"
@export var damage: float = 25.0
@export var max_ammo : int = 12
@export var range: float = 25.0
@export var is_hitscan: bool = true
@export var weapon_model : PackedScene

@export var projectile_scene: PackedScene
@export var weapon_position: Vector3 = Vector3(0.2, -0.2, -0.3)

@export var rarity : Enums.Rarity = Enums.Rarity.COMMON
@export var equipped_parts: Dictionary[Enums.PartType, WeaponPart]
@export var icon : Texture2D

var stats : WeaponStats

func recalculate() -> void:
	stats = WeaponCalc.calculate_stats(equipped_parts)
	rarity = WeaponCalc.calc_weapon_rarity(equipped_parts) as Enums.Rarity
	weapon_name = WeaponCalc.build_name(equipped_parts)
