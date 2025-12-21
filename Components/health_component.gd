extends Node
class_name HealthComponent

signal Damaged(amount : float)
signal Died

@export var max_health : float = 100
var current_health : float

func _ready() -> void:
	current_health = max_health

#TODO: use damage type to create vul and resistances
func take_damage(amount : float) -> void:
	current_health -= amount
	
	if current_health <= 0:
		die()
	else:
		Damaged.emit(amount)

func heal(amount) -> void:
	current_health = min(current_health+amount, max_health)

func die() -> void:
	Died.emit()
