extends RefCounted
class_name Inventory

var owned_mods: Array[WeaponMod] = []      # later: Array[WeaponMod]
var owned_weapons: Array = []   # later: Array[WeaponInstance] or blueprint ids

func sanitize() -> void:
	# placeholder for future validation
	pass
