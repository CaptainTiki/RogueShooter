extends Node
class_name HealthComponent

signal health_changed(current: int, max: int)
signal died

@export var max_health: int = 100
@export var current_health: int = 100

func _ready() -> void:
	max_health = max(1, max_health)
	current_health = clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func set_max_health(value: int, keep_percent: bool = true) -> void:
	value = max(1, value)
	var pct: float = 1.0
	if max_health > 0:
		pct = float(current_health) / float(max_health)
	max_health = value
	if keep_percent:
		current_health = int(round(pct * float(max_health)))
	current_health = clamp(current_health, 0, max_health)
	health_changed.emit(current_health, max_health)

func set_health(value: int) -> void:
	current_health = clamp(value, 0, max_health)
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	if amount <= 0:
		return
	set_health(current_health + amount)

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	set_health(current_health - amount)
