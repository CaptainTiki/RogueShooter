extends RefCounted
class_name GameState

var run_kills: int = 0
var run_time_seconds: float = 0.0
var seed: int = 0
var is_in_run: bool = false

func start_new_run(new_seed: int) -> void:
	seed = new_seed
	run_kills = 0
	run_time_seconds = 0.0
	is_in_run = true

func end_run() -> void:
	is_in_run = false
