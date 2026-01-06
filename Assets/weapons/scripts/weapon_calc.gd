#weapon_calc.gd
extends Node
class_name WeaponCalc

static var order = [
	Enums.PartType.RECEIVER,
	Enums.PartType.BARREL,
	Enums.PartType.GRIP,
	Enums.PartType.MAGAZINE,
	Enums.PartType.OPTIC,
	Enums.PartType.MUZZLE,
	Enums.PartType.STOCK,
	Enums.PartType.FOREGRIP
	]


static func calculate_stats(weap : Weapon) -> WeaponStats:
	var stats : WeaponStats = WeaponStats.new()
	var total_burst_seperation : float= 0.0
	var total_shot_interval : float = 0.0
	var total_bps : float = 0.0
	var total_multi : float = 0.0
	
	for part in weap.parts_by_id.values():
		if part == null:
			continue
		
		if part is WeaponPart:
			# additive stats (always apply)
			stats.damage += part.damage_add
			stats.distance += part.distance_add
			stats.recoil += part.recoil_add
			stats.ads_speed += part.ads_speed_add
			stats.spread += part.spread_add
			stats.ammo_capacity += part.ammo_add
			stats.reload_speed += part.reload_speed_add
			stats.fov_amount += part.fov_ammount_add
			
			total_shot_interval += part.shot_interval_add
			total_burst_seperation += part.burst_seperation_add
			total_bps += part.burst_per_shot_add
			total_multi += part.multishot_add
			
			if part.part_type == Enums.PartType.RECEIVER:
				stats.ammo_type = part.ammo_type
				stats.trigger_mode = part.trigger_mode
				stats.burst_per_shot = part.burst_per_shot
				stats.burst_size = part.burst_size
				stats.burst_seperation = part.burst_seperation
				stats.shot_interval = part.shot_interval
				stats.multishot = part.multishot
				
		
	stats.burst_seperation += total_burst_seperation
	stats.shot_interval += total_shot_interval
	stats.burst_per_shot += total_bps
	stats.multishot += total_multi
	
	#prevent negative ammo, firerate, and burst interval
	stats.ammo_capacity = max(0.0, stats.ammo_capacity) #stay zero or positive
	stats.multishot = max(1.0, stats.multishot) #always at least 1 round per shot
	stats.burst_per_shot = max(1.0, stats.burst_per_shot) #always at least 1 round per trigger
	stats.burst_size = max(1.0, stats.burst_size) #always at least 1 round per trigger
	stats.burst_seperation = max(0.0, stats.burst_seperation) #zero is ok, for shotgun type
	stats.shot_interval = max(0.01, stats.shot_interval) #prevent zero
	
	return stats

static func calc_weapon_rarity(equipped_parts: Dictionary) -> int:
	var total : float = 0
	var count : float = 0
	
	for p in equipped_parts.values():
		if p == null:
			continue
		total += int(p.rarity)
		count += 1
	
	if count == 0:
		return Enums.Rarity.COMMON
	
	var avg : float = float(total) / float(count)
	var result : int = int(floor(avg))
	
	# Clamp to valid enum range just in case
	result = clamp(result, int(Enums.Rarity.COMMON), int(Enums.Rarity.LEGENDARY))
	return result

static func build_name(weap: Weapon) -> String:
	# --- Helper: find receiver
	var receiver = null
	for p in weap.parts_by_id.values():
		if p == null:
			continue
		if p.part_type == Enums.PartType.RECEIVER:
			receiver = p
			break
	
	var core : String = ""
	if receiver != null:
		core = receiver.name_core.strip_edges()
	if core == "":
		core = "Blaster" # fallback so you never get empty names
	
	# Your deterministic “slot priority” orders
	var prefix_order : Array[Enums.PartType] = [
		Enums.PartType.STOCK,
		Enums.PartType.GRIP,
		Enums.PartType.OPTIC,
		Enums.PartType.MUZZLE,
		Enums.PartType.FOREGRIP,
		Enums.PartType.BARREL,
	]
	
	var descriptor_order : Array[Enums.PartType] = [
		Enums.PartType.BARREL,
		Enums.PartType.FOREGRIP,
		Enums.PartType.MUZZLE,
		Enums.PartType.OPTIC,
	]
	
	var suffix_order : Array[Enums.PartType] = [
		Enums.PartType.MAGAZINE,
		Enums.PartType.MUZZLE,
		Enums.PartType.OPTIC,
		Enums.PartType.STOCK,
		Enums.PartType.GRIP,
	]
	
	var prefix : String = first_token(weap.parts_by_id, &"name_prefix", prefix_order)
	var descriptor : String = first_token(weap.parts_by_id, &"name_descriptor", descriptor_order)
	var suffix : String = first_token(weap.parts_by_id, &"name_suffix", suffix_order)
	
	# --- Rarity label (only Rare+), calculated from parts
	var rarity : int = calc_weapon_rarity(weap.parts_by_id)
	var rarity_label : String = ""
	match rarity:
		Enums.Rarity.RARE:
			rarity_label = "Mk II"
		Enums.Rarity.EPIC:
			rarity_label = "EX"
		Enums.Rarity.LEGENDARY:
			rarity_label = "Prime"
		_:
			rarity_label = ""  # Common/Uncommon show nothing
	
	# --- Assemble in your chosen order
	var words: Array[String] = []
	if prefix != "": words.append(prefix)
	if descriptor != "": words.append(descriptor)
	words.append(core)
	if suffix != "": words.append(suffix)
	if rarity_label != "": words.append(rarity_label)
	
	return " ".join(words)

# --- Helper: first token in given part-type order for a given field
static func first_token(parts: Dictionary, field: StringName, type_order: Array) -> String:
	for t in type_order:
		for p in parts.values():
			if p == null:
				continue
			if p.part_type != t:
				continue
			var v: String = str(p.get(field)).strip_edges()
			if v != "":
				return v
	return ""

## Returns: Array[Dictionary] where each dictionary describes a unique slot instance.
static func build_slot_map(weapon: Weapon, max_slots: int = 30) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if weapon == null:
		return out
	
	# Add receiver "pseudo-slot" for UI selection
	var receiver_part: WeaponPart = weapon.parts_by_id.get(weapon.root_part_id, null)
	if receiver_part != null:
		out.append({
			"slot_id": -100,
			"slot_type": int(Enums.PartType.RECEIVER),
			"host_part_id": int(weapon.root_part_id),
			"child_part_id": int(weapon.root_part_id), # receiver is itself
			"host_part_name": "",
			"child_part_name": receiver_part.part_name
		})
	
	# Iterate real slot IDs (unique per weapon)
	var slot_ids: Array[int] = []
	for sid in weapon.slots_by_id.keys():
		slot_ids.append(int(sid))
		
	# Deterministic order: by your PartType order, then by slot_id
	slot_ids.sort_custom(func(a, b):
		var sa: Weapon.SlotRecord = weapon.slots_by_id[a]
		var sb: Weapon.SlotRecord = weapon.slots_by_id[b]
		var ia := order.find(sa.slot_type)
		var ib := order.find(sb.slot_type)
		if ia != ib:
			return ia < ib
		return a < b
	)
	
	for sid in slot_ids:
		if out.size() >= max_slots:
			break
			
		var s: Weapon.SlotRecord = weapon.slots_by_id[sid]
		var host_part: WeaponPart = weapon.parts_by_id.get(s.host_part_id, null)
		var filled_part: WeaponPart = weapon.parts_by_id.get(s.child_part_id, null) if s.child_part_id != -1 else null
		
		out.append({
			"slot_id": sid,
			"slot_type": int(s.slot_type),
			"host_part_id": int(s.host_part_id),
			"child_part_id": int(s.child_part_id),
			"host_part_name": (host_part.part_name if host_part != null else ""),
			"child_part_name": (filled_part.part_name if filled_part != null else "")
		})
		
	return out

# ----------------------------
# Helpers
# ----------------------------

static func _find_receiver(parts: Array) -> Resource:
	for p in parts:
		if p.part_type == Enums.PartType.RECEIVER:
			return p
	return null

static func _get_filled_part_for_slot(weapon: Weapon, slot_num: int) -> Resource:
	if weapon == null:
		return null
	
	if weapon.slots_by_id.has(slot_num):
		var record : Weapon.SlotRecord = weapon.slots_by_id[slot_num]
		return weapon.parts_by_id[record.slot_id]

	return null
