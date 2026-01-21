#game_manager.gd
extends Node
class_name GameManager

signal game_changed(new_game: Game)

var game: Game = null

func _enter_tree() -> void:
	# Ensure a Game exists BEFORE the level/player _ready().
	if Game.current == null:
		new_game()

func _ready() -> void:
	# Nothing needed here right now; _enter_tree handles boot.
	pass

func new_game() -> Game:
	_discard_game()

	game = Game.new()
	game.reset_for_new_game()
	game.make_current()

	_seed_default_loadout(game)
	game.on_loaded_or_reset()

	emit_signal("game_changed", game)
	return game

func load_game(from_data: Dictionary) -> Game:
	_discard_game()

	game = Game.new()
	# TODO: hydrate from_data into game/profile/run/inventory
	game.make_current()
	game.on_loaded_or_reset()

	emit_signal("game_changed", game)
	return game

func unload_game() -> void:
	_discard_game()
	emit_signal("game_changed", null)

func _discard_game() -> void:
	if game != null:
		game.clear_current_if_self()
	game = null

func _exit_tree() -> void:
	# Safety: if the manager dies, don't leave a zombie singleton behind
	_discard_game()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dev_exit"):
		get_tree().quit()
	if event.is_action_pressed("dev_reload"):
		get_tree().reload_current_scene()

func _seed_default_loadout(g: Game) -> void:
	# Weapons: runtime instances (clone) so mods don't mutate the blueprint resources.
	var weapon_paths := [
		"res://assets/weapons/blueprints/pistol_rusty_sidearm.tres",
		"res://assets/weapons/blueprints/pistol_handcannon.tres",
		"res://assets/weapons/blueprints/rifle_hunting.tres",
		"res://assets/weapons/blueprints/shotgun_pump.tres",
		"res://assets/weapons/blueprints/smg_sprayer.tres",
		"res://assets/weapons/blueprints/rifle_assault.tres",
		"res://assets/weapons/blueprints/shotgun_benelli_auto.tres",
	]

	g.player_inventory.owned_weapons.clear()
	for path in weapon_paths:
		var blueprint := load(path) as Weapon
		if blueprint == null:
			push_error("Seed: missing weapon blueprint: %s" % path)
			continue
		g.player_inventory.owned_weapons.append(blueprint.clone_weapon())

	# Mods: treat resources as immutable data (safe to share references).
	var mod_paths := [
		"res://assets/weapons/mods/mod_barrel_extension.tres",
		"res://assets/weapons/mods/mod_ported_compensator.tres",
		"res://assets/weapons/mods/mod_suppressor.tres",
		"res://assets/weapons/mods/mod_choke_tube.tres",
		"res://assets/weapons/mods/mod_optic_red_dot.tres",
		"res://assets/weapons/mods/mod_optic_scope_4x.tres",
		"res://assets/weapons/mods/mod_gyro_stabilizer.tres",
		"res://assets/weapons/mods/mod_quick_reload_kit.tres",
		"res://assets/weapons/mods/mod_overclock_actuator.tres",
		"res://assets/weapons/mods/mod_extended_mag.tres",
		"res://assets/weapons/mods/mod_auto_trigger_pack.tres",
		"res://assets/weapons/mods/mod_caliber_converter_556.tres",
	]

	g.base_inventory.owned_mods.clear()
	for path in mod_paths:
		var m := load(path) as WeaponMod
		if m == null:
			push_error("Seed: missing weapon mod: %s" % path)
			continue
		g.base_inventory.owned_mods.append(m)

	g.game_state.equipped_weapon_index = 0
