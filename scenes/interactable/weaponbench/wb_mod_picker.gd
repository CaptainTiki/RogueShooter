extends Control
class_name WB_ModPicker

signal install_requested(mod: WeaponMod)
signal remove_requested
signal closed

@onready var title_label: Label = %TitleLabel
@onready var list_vbox: VBoxContainer = %ListVBox
@onready var details_label: Label = %DetailsLabel
@onready var install_button: Button = %InstallButton
@onready var remove_button: Button = %RemoveButton
@onready var close_button: Button = %CloseButton

var _slot_type: Enums.ModSlotType = Enums.ModSlotType.UTILITY
var _mods: Array[WeaponMod] = []
var _installed: WeaponMod = null
var _selected: WeaponMod = null

func _ready() -> void:
	install_button.pressed.connect(_on_install_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	close_button.pressed.connect(_on_close_pressed)
	_hide_self()

func open_for(slot_type: Enums.ModSlotType, compatible_mods: Array[WeaponMod], installed_mod: WeaponMod) -> void:
	_slot_type = slot_type
	_mods = compatible_mods
	_installed = installed_mod
	_selected = null

	visible = true
	install_button.disabled = true
	remove_button.disabled = (installed_mod == null)

	var slot_name : String = Enums.ModSlotType.keys()[int(slot_type)]
	title_label.text = "Compatible Mods: %s" % slot_name

	_rebuild_list()
	_show_details(null)

func close() -> void:
	_hide_self()
	closed.emit()

func _hide_self() -> void:
	visible = false

func _rebuild_list() -> void:
	for c in list_vbox.get_children():
		c.queue_free()

	if _mods == null or _mods.is_empty():
		var l := Label.new()
		l.text = "No compatible mods owned."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list_vbox.add_child(l)
		return

	for i in range(_mods.size()):
		var m := _mods[i]
		var b := Button.new()
		b.text = _format_mod_list_label(m)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.toggle_mode = true
		b.pressed.connect(func():
			_select_mod(m)
			# untoggle other buttons
			for other in list_vbox.get_children():
				if other is Button and other != b:
					(other as Button).button_pressed = false
		)
		list_vbox.add_child(b)

		# mark installed mod
		if _installed != null and m == _installed:
			b.text = "%s  (Installed)" % b.text

func _select_mod(m: WeaponMod) -> void:
	_selected = m
	install_button.disabled = (_selected == null)
	_show_details(m)

func _show_details(m: WeaponMod) -> void:
	if m == null:
		if _installed != null:
			details_label.text = "Installed: %s\n\nSelect a mod to preview and install." % _installed.mod_name
		else:
			details_label.text = "Select a mod to preview and install."
		return

	var lines: Array[String] = []
	lines.append(m.mod_name)
	lines.append("Type: %s" % Enums.ModSlotType.keys()[int(m.slot_type)])
	lines.append("Rarity: %s" % Enums.Rarity.keys()[int(m.rarity)])
	lines.append("")
	lines.append("Effects:")
	for e in _build_effect_lines(m):
		lines.append("- %s" % e)

	if _installed != null and m == _installed:
		lines.append("")
		lines.append("This mod is currently installed in this slot.")

	details_label.text = "\n".join(lines)

func _build_effect_lines(m: WeaponMod) -> Array[String]:
	var out: Array[String] = []
	_add_if_nonzero(out, "Damage", m.damage_add, m.damage_mul)
	_add_if_nonzero(out, "Range", m.distance_add, m.distance_mul)
	_add_if_nonzero(out, "Recoil", m.recoil_add, m.recoil_mul, true)
	_add_if_nonzero(out, "Spread", m.spread_add, m.spread_mul, true)
	_add_if_nonzero(out, "Reload", m.reload_speed_add, m.reload_speed_mul, true)
	_add_if_nonzero(out, "Fire Interval", m.shot_interval_add, m.shot_interval_mul, true)
	if m.ammo_capacity_add != 0.0:
		out.append("Ammo +%s" % _fmt(m.ammo_capacity_add))
	if m.fov_amount_add != 0.0:
		out.append("FOV %+s" % _fmt(m.fov_amount_add))
	if m.override_trigger_mode:
		out.append("Trigger -> %s" % Enums.TriggerMode.keys()[int(m.trigger_mode)])
	if m.override_ammo_type:
		out.append("Ammo -> %s" % Enums.AmmoType.keys()[int(m.ammo_type)])
	if out.is_empty():
		out.append("(No stat changes)")
	return out

func _add_if_nonzero(out: Array[String], label: String, add: float, mul: float, lower_is_better: bool = false) -> void:
	var had := false
	if mul != 1.0:
		var pct := (mul - 1.0) * 100.0
		out.append("%s %+.0f%%" % [label, pct])
		had = true
	if add != 0.0:
		out.append("%s %+.2f" % [label, add])
		had = true

func _format_mod_list_label(m: WeaponMod) -> String:
	# quick 1-line summary for the list
	var bits: Array[String] = []
	if m.recoil_add != 0.0 or m.recoil_mul != 1.0:
		bits.append("Recoil")
	if m.spread_add != 0.0 or m.spread_mul != 1.0:
		bits.append("Spread")
	if m.distance_add != 0.0 or m.distance_mul != 1.0:
		bits.append("Range")
	if m.damage_add != 0.0 or m.damage_mul != 1.0:
		bits.append("Damage")
	if m.reload_speed_add != 0.0 or m.reload_speed_mul != 1.0:
		bits.append("Reload")
	if m.shot_interval_add != 0.0 or m.shot_interval_mul != 1.0:
		bits.append("ROF")

	var suffix := ""
	if not bits.is_empty():
		suffix = "  [" + ", ".join(bits) + "]"
	return m.mod_name + suffix

func _on_install_pressed() -> void:
	if _selected == null:
		return
	install_requested.emit(_selected)

func _on_remove_pressed() -> void:
	remove_requested.emit()

func _on_close_pressed() -> void:
	close()

func _fmt(v: float) -> String:
	# keeps + / - sign readable
	if abs(v) >= 10.0:
		return "%.0f" % v
	return "%.2f" % v
