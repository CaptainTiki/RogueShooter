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
			
			if part.part_type == Enums.PartType.RECEIVER:
				stats.ammo_type = part.ammo_type
				stats.trigger_mode = part.trigger_mode
				stats.burst_per_shot = part.burst_per_shot
				stats.burst_size = part.burst_size
				stats.burst_seperation = part.burst_seperation
				stats.shot_interval = part.shot_interval
				
		
	stats.burst_seperation += total_burst_seperation
	stats.shot_interval += total_shot_interval
	
	#prevent negative ammo, firerate, and burst interval
	stats.ammo_capacity = max(0.0, stats.ammo_capacity) #stay zero or positive
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

static func build_name(parts: Dictionary) -> String:
	# --- Helper: find receiver
	var receiver = null
	for p in parts.values():
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
	
	var prefix : String = first_token(parts, &"name_prefix", prefix_order)
	var descriptor : String = first_token(parts, &"name_descriptor", descriptor_order)
	var suffix : String = first_token(parts, &"name_suffix", suffix_order)
	
	# --- Rarity label (only Rare+), calculated from parts
	var rarity : int = calc_weapon_rarity(parts)
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
	var slots: Array[Dictionary] = []
	var next_slot_num: int = 0

	# 1) Get all equipped parts
	var parts: Array = weapon.equipped_parts.values()
	if parts.is_empty():
		return slots

	# 2) Sort parts deterministically using WeaponCalc.order and a stable tie-breaker (resource_path)
	parts.sort_custom(func(a, b):
		var ia := order.find(a.part_type)
		var ib := order.find(b.part_type)
		if ia != ib:
			return ia < ib
		# Fallback stable sort
		return a.resource_path < b.resource_path
	)

	# 3) Receiver "slot 0" convention:
	var receiver : WeaponPart = _find_receiver(parts)
	if receiver != null:
		slots.append({
			"slot_num": next_slot_num,
			"slot_type": Enums.PartType.RECEIVER,
			"host_part": null,
			"host_part_id": "",
			"host_slot_index": 0,
			"filled_part": receiver,
			"filled_part_id": receiver.resource_path
		})
		next_slot_num += 1

	# 4) Build slot instances from each host part’s adds_slots.
	var host_counters: Dictionary = {} # host_id -> Dictionary(slot_type -> count)

	for host in parts:
		if next_slot_num >= max_slots:
			break

		var host_id : int = host.resource_path
		if not host_counters.has(host_id):
			host_counters[host_id] = {}

		# Deterministic: process adds_slots in the order stored on the resource.
		for slot_type in host.adds_slots:
			if next_slot_num >= max_slots:
				break

			var per_type: Dictionary = host_counters[host_id]
			var idx: int = int(per_type.get(slot_type, 0))
			per_type[slot_type] = idx + 1
			host_counters[host_id] = per_type

			var filled : WeaponPart = _get_filled_part_for_slot(weapon, next_slot_num)

			slots.append({
				"slot_num": next_slot_num,
				"slot_type": slot_type,
				"host_part": host,
				"host_part_id": host_id,
				"host_slot_index": idx,
				"filled_part": filled,
				"filled_part_id": (filled.resource_path if filled != null else "")
			})

			next_slot_num += 1

	return slots


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
	
	if weapon.parts_graph.has(slot_num):
		return weapon.parts_graph.get(slot_num)

	return null
