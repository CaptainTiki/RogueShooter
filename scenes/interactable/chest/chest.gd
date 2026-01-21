extends Interactable
class_name StorageChest

# MVP behavior:
# - Interact = deposit all ammo + mods from player -> base storage
# - Interact while holding Sprint = withdraw all ammo + mods from base -> player
# (Weapons stay with player for now.)

@export var chest_screen_scene: PackedScene = preload("res://UI/chest_screen.tscn")

func interact(node: Node3D) -> void:
	super.interact(node)

	if Game.current == null:
		return
	var player_inv := Game.current.player_inventory
	var base_inv := Game.current.base_inventory
	if player_inv == null or base_inv == null:
		print("player or base inv null")
		return

	# Fast path for testing: hold Sprint to instantly withdraw everything.
	var withdraw : bool = Input.is_action_pressed("sprint")
	if withdraw:
		base_inv.transfer_all_ammo_to(player_inv)
		base_inv.transfer_all_mods_to(player_inv)
		print("Chest: withdrew all ammo+mods from BASE -> PLAYER")
		return

	_open_chest_ui()

func _open_chest_ui() -> void:
	if MainScene.instance == null:
		return
	if MainScene.instance.ui == null:
		return

	var screens := MainScene.instance.ui.get_node_or_null("Screens")
	if screens != null:
		for c in screens.get_children():
			if c is ChestScreen:
				# Already open.
				return

	if chest_screen_scene == null:
		return
	var screen := chest_screen_scene.instantiate()
	MainScene.instance.ui.push_ui(screen)
	if screen is ChestScreen:
		screen.open()
