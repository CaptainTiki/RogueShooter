extends Resource
class_name Weapon

@export var weapon_name : String = "Pistol"
@export var damage: float = 25.0
@export var max_ammo : int = 12
@export var distance: float = 25.0
@export var is_hitscan: bool = true
@export var weapon_model : PackedScene

@export var projectile_scene: PackedScene
@export var weapon_position: Vector3 = Vector3(0.2, -0.2, -0.3)

@export var rarity : Enums.Rarity = Enums.Rarity.COMMON
@export var icon : Texture2D

var root_part_id : int = -1

var stats : WeaponStats

var parts_by_id: Dictionary[int, WeaponPart] = {}
var slots_by_id: Dictionary[int, SlotRecord] = {}

var next_part_id: int = 0
var next_slot_id: int = 0

func recalculate() -> void:
	#stats = WeaponCalc.calculate_stats(equipped_parts)
	#rarity = WeaponCalc.calc_weapon_rarity(equipped_parts) as Enums.Rarity
	#weapon_name = WeaponCalc.build_name(equipped_parts)
	pass

class SlotRecord:
	var slot_id: int
	var slot_type: Enums.PartType
	var host_part_id: int
	var child_part_id: int = -1
	
	func _init(_slot_id: int, _slot_type: Enums.PartType, _host_part_id: int) -> void:
		slot_id = _slot_id
		slot_type = _slot_type
		host_part_id = _host_part_id

# ----------------------------
# Creation / Setup
# ----------------------------

func clear_graph() -> void:
	root_part_id = -1
	parts_by_id.clear()
	slots_by_id.clear()
	next_part_id = 0
	next_slot_id = 0


func initialize_with_receiver(receiver: WeaponPart) -> void:
	clear_graph()

	var rid := _alloc_part_id()
	parts_by_id[rid] = receiver
	root_part_id = rid

	# Receiver may add slots (barrel, grip, optic, etc.)
	_add_slots_from_host_part(rid, receiver)


# ----------------------------
# Public operations (Bench + Loot)
# ----------------------------

func get_slot(slot_id: int) -> SlotRecord:
	return slots_by_id.get(slot_id, null)


func get_child_part_id_for_slot(slot_id: int) -> int:
	var s : SlotRecord = slots_by_id.get(slot_id, null)
	return s.child_part_id if s != null else -1


func add_part_to_slot(slot_id: int, part: WeaponPart) -> int:
	if not slots_by_id.has(slot_id):
		return -1

	var s: SlotRecord = slots_by_id[slot_id]

	if s.child_part_id != -1:
		return -1

	if part.part_type != s.slot_type:
		return -1

	var pid := _alloc_part_id()
	parts_by_id[pid] = part

	s.child_part_id = pid

	_add_slots_from_host_part(pid, part)
	return pid



func remove_part_subtree(part_id: int) -> void:
	# Removes part + all descendant parts and their slots.
	# Also clears the parent slot that referenced this part.

	if part_id == -1:
		return
	if part_id == root_part_id:
		# MVP rule: removing root wipes weapon
		clear_graph()
		return
	if not parts_by_id.has(part_id):
		return

	# 1) Find and clear the parent slot that points to this part_id
	for sid in slots_by_id.keys():
		var s: SlotRecord = slots_by_id[sid]
		if s.child_part_id == part_id:
			s.child_part_id = -1
			break

	# 2) Recursively remove all children by scanning slots hosted by this part
	var hosted_slots := _get_slots_hosted_by_part(part_id)
	for sid in hosted_slots:
		var child_id := get_child_part_id_for_slot(sid)
		if child_id != -1:
			remove_part_subtree(child_id)
		# Remove the slot itself
		slots_by_id.erase(sid)

	# 3) Remove the part
	parts_by_id.erase(part_id)


func get_open_slot_ids() -> Array[int]:
	var out: Array[int] = []
	for sid in slots_by_id.keys():
		var s: SlotRecord = slots_by_id[sid]
		if s.child_part_id == -1:
			out.append(int(sid))
	return out


# ----------------------------
# Internal helpers
# ----------------------------

func _alloc_part_id() -> int:
	var id := next_part_id
	next_part_id += 1
	return id


func _alloc_slot_id() -> int:
	var id := next_slot_id
	next_slot_id += 1
	return id


func _add_slots_from_host_part(host_part_id: int, host_part: WeaponPart) -> void:
	for slot_type in host_part.adds_slots:
		var sid := _alloc_slot_id()
		slots_by_id[sid] = SlotRecord.new(sid, slot_type, host_part_id)


func _get_slots_hosted_by_part(host_part_id: int) -> Array[int]:
	var out: Array[int] = []
	for sid in slots_by_id.keys():
		var s: SlotRecord = slots_by_id[sid]
		if s.host_part_id == host_part_id:
			out.append(int(sid))
	return out

func find_first_open_slot_of_type(slot_type: Enums.PartType) -> int:
	for sid in slots_by_id.keys():
		var s: SlotRecord = slots_by_id[sid]
		if s.child_part_id == -1 and s.slot_type == slot_type:
			return int(sid)
	return -1

##Remeber to recalc stats after copy
func clone_weapon_graph() -> Weapon:
	var w := Weapon.new()

	# Copy exported “identity” fields
	w.weapon_name = weapon_name
	w.damage = damage
	w.max_ammo = max_ammo
	w.distance = distance
	w.is_hitscan = is_hitscan
	w.weapon_model = weapon_model
	w.projectile_scene = projectile_scene
	w.weapon_position = weapon_position
	w.rarity = rarity
	w.icon = icon

	# Copy runtime graph state
	w.root_part_id = root_part_id
	w.next_part_id = next_part_id
	w.next_slot_id = next_slot_id

	# Deep copy parts_by_id
	w.parts_by_id = {}
	for pid in parts_by_id.keys():
		w.parts_by_id[int(pid)] = parts_by_id[pid]

	# Deep copy slots_by_id
	w.slots_by_id = {}
	for sid in slots_by_id.keys():
		var s: SlotRecord = slots_by_id[sid]
		var ns := SlotRecord.new(s.slot_id, s.slot_type, s.host_part_id)
		ns.child_part_id = s.child_part_id
		w.slots_by_id[int(sid)] = ns

	return w

func debug_print_graph() -> void:
	print("Parts:", parts_by_id.keys())
	for sid in slots_by_id.keys():
		var s: SlotRecord = slots_by_id[sid]
		print("Slot", sid, " type:", s.slot_type, " host:", s.host_part_id, " child:", s.child_part_id)
