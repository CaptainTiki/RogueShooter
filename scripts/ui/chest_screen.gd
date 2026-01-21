extends Control
class_name ChestScreen

@onready var mods_vbox: VBoxContainer = %ModsVBox
@onready var ammo_vbox: VBoxContainer = %AmmoVBox
@onready var close_bn: Button = %CloseBn
@onready var deposit_bn: Button = %DepositBn
@onready var withdraw_bn: Button = %WithdrawBn

func _ready() -> void:
	deposit_bn.pressed.connect(_on_deposit)
	withdraw_bn.pressed.connect(_on_withdraw)
	close_bn.pressed.connect(close)
	refresh()
	close()

func open() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	refresh()

func close() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func refresh() -> void:
	if Game.current == null:
		return
	var base_inv := Game.current.base_inventory
	var player_inv := Game.current.player_inventory
	if base_inv == null or player_inv == null:
		return

	# Mods
	for c in mods_vbox.get_children():
		c.queue_free()
	for m in base_inv.owned_mods:
		var mod := m as WeaponMod
		if mod == null:
			continue
		var label := Label.new()
		label.text = "%s  (%s)" % [mod.mod_name, Enums.ModSlotType.keys()[int(mod.slot_type)]]
		mods_vbox.add_child(label)

	# Ammo
	for c in ammo_vbox.get_children():
		c.queue_free()
	for k in Enums.AmmoType.keys().size():
		var ammo_type: int = k
		var t: Enums.AmmoType = Enums.AmmoType.values()[ammo_type]
		var amount: int = base_inv.get_ammo(t)
		if ammo_type == int(Enums.AmmoType.ANY):
			continue
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := Label.new()
		l.text = Enums.AmmoType.keys()[ammo_type]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var r := Label.new()
		r.text = str(amount)
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(l)
		row.add_child(r)
		ammo_vbox.add_child(row)

func _on_deposit() -> void:
	if Game.current == null:
		return
	Game.current.player_inventory.transfer_all_ammo_to(Game.current.base_inventory)
	Game.current.player_inventory.transfer_all_mods_to(Game.current.base_inventory)
	refresh()

func _on_withdraw() -> void:
	if Game.current == null:
		return
	Game.current.base_inventory.transfer_all_ammo_to(Game.current.player_inventory)
	Game.current.base_inventory.transfer_all_mods_to(Game.current.player_inventory)
	refresh()
