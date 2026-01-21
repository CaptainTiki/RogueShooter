extends RefCounted
class_name Inventory

# Simple inventory MVP:
# - ammo pools by AmmoType
# - owned weapons (Weapon resources cloned at runtime)
# - owned mods (WeaponMod resources)

var ammo: Dictionary = {} # key: int(Enums.AmmoType), value: int
var owned_mods: Array[WeaponMod] = []
var owned_weapons: Array[Weapon] = []

func sanitize() -> void:
	# Ensure ammo counts are ints >= 0
	for k in ammo.keys():
		ammo[k] = max(0, int(ammo[k]))
	# Remove null refs from arrays (optional)
	owned_mods = owned_mods.filter(func(m): return m != null)
	owned_weapons = owned_weapons.filter(func(w): return w != null)

func get_ammo(ammo_type: Enums.AmmoType) -> int:
	return int(ammo.get(int(ammo_type), 0))

func add_ammo(ammo_type: Enums.AmmoType, amount: int) -> void:
	if amount <= 0:
		return
	var key := int(ammo_type)
	ammo[key] = get_ammo(ammo_type) + int(amount)

func consume_ammo(ammo_type: Enums.AmmoType, amount: int) -> int:
	# Returns how much was actually consumed.
	if amount <= 0:
		return 0
	var key : int= int(ammo_type)
	var have : int= get_ammo(ammo_type)
	var take : int= min(have, int(amount))
	ammo[key] = have - take
	return take

func transfer_ammo_to(other: Inventory, ammo_type: Enums.AmmoType, amount: int) -> int:
	if other == null:
		return 0
	var taken := consume_ammo(ammo_type, amount)
	if taken > 0:
		other.add_ammo(ammo_type, taken)
	return taken

func transfer_all_ammo_to(other: Inventory) -> void:
	if other == null:
		return
	for k in ammo.keys():
		var amt := int(ammo[k])
		if amt > 0:
			other.add_ammo(Enums.AmmoType.values()[int(k)], amt)
	ammo.clear()

func transfer_all_mods_to(other: Inventory) -> void:
	if other == null:
		return
	for m in owned_mods:
		if m != null:
			other.owned_mods.append(m)
	owned_mods.clear()
