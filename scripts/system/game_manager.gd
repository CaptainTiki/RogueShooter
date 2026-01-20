#game_manager.gd
extends Node
class_name GameManager

signal game_changed(new_game: Game)

var game: Game = null

func _ready() -> void:
	# Decide how you want to boot:
	# - show main menu first
	# - or auto-start new game for dev
	# For now, do nothing automatically unless you want dev speed.
	pass

func new_game() -> Game:
	_discard_game()

	game = Game.new()
	game.reset_for_new_game()
	game.make_current()
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
