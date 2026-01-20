extends RefCounted
class_name Game

static var current: Game = null

# Core state (start tiny)
var profile_stats : ProfileStats = ProfileStats.new()
var game_state : GameState = GameState.new()
var inventory : Inventory = Inventory.new()

var save_slot_id: String = ""  # optional: which save this came from

func _init() -> void:
	# If you want, initialize defaults here
	pass

func make_current() -> void:
	Game.current = self

func clear_current_if_self() -> void:
	if Game.current == self:
		Game.current = null

func reset_for_new_game() -> void:
	profile_stats = ProfileStats.new()
	game_state = GameState.new()
	inventory = Inventory.new()
	save_slot_id = ""

# Convenience: a single recompute point if you want
func on_loaded_or_reset() -> void:
	# e.g. validate inventory, clamp stats, rebuild caches
	inventory.sanitize()
