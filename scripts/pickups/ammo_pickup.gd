extends Area3D
class_name AmmoPickup

@export var ammo_type: Enums.AmmoType = Enums.AmmoType.NINE_MM
@export var amount: int = 15

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var player := body as PlayerController
	if player == null:
		return

	if Game.current == null:
		return

	var inv := Game.current.player_inventory
	if inv == null:
		return

	inv.add_ammo(ammo_type, amount)


	print("Picked up ammo:", amount, " type:", Enums.AmmoType.keys()[int(ammo_type)], " ->", "player")

	queue_free()
