extends Control
class_name WB_PartStats

@onready var damage_h_box: HBoxContainer = %Damage_HBox
@onready var damage_value_label: Label = %Damage_Value_Label

@onready var ammo_h_box: HBoxContainer = %Ammo_HBox
@onready var ammo_value_label: Label = %Ammo_Value_Label

@onready var range_h_box: HBoxContainer = %Range_HBox
@onready var range_value_label: Label = %Range_Value_Label

@onready var fire_rate_h_box: HBoxContainer = %FireRate_HBox
@onready var fire_rate_value_label: Label = %FireRate_Value_Label

@onready var reload_speed_h_box: HBoxContainer = %ReloadSpeed_HBox
@onready var reload_value_label: Label = %Reload_Value_Label

@onready var recoil_h_box: HBoxContainer = %Recoil_HBox
@onready var recoil_value_label: Label = %Recoil_Value_Label

@onready var spread_h_box: HBoxContainer = %Spread_HBox
@onready var spread_value_label: Label = %Spread_Value_Label

@onready var ads_speed_h_box: HBoxContainer = %ADS_Speed_HBox
@onready var ads_speed_value_label: Label = %ADSSpeed_Value_Label

@onready var ads_zoom_h_box: HBoxContainer = %ADS_Zoom_HBox
@onready var ads_zoom_value_label: Label = %ADSZoom_Value_Label


func _ready() -> void:
	_hide_all()

func show_part(part: WeaponPart) -> void:
	if part == null:
		_hide_all()
		return

	_set_row(damage_h_box, damage_value_label, part.damage_add)
	_set_row(ammo_h_box, ammo_value_label, part.ammo_add)
	_set_row(range_h_box, range_value_label, part.distance_add)
	_set_row(fire_rate_h_box, fire_rate_value_label, part.shot_interval_add)
	_set_row(reload_speed_h_box, reload_value_label, part.reload_speed_add)
	_set_row(recoil_h_box, recoil_value_label, part.recoil_add)
	_set_row(spread_h_box, spread_value_label, part.spread_add)
	_set_row(ads_zoom_h_box, ads_speed_value_label, part.ads_speed_add)
	_set_row(ads_speed_h_box, ads_zoom_value_label, part.fov_ammount_add)

	## Receiver-only
	#var is_receiver := part.part_type == Enums.PartType.RECEIVER
	#burst_row.visible = is_receiver
	#trigger_row.visible = is_receiver
	## etc...


func _set_row(row: Control, value_label: Label, value: float) -> void:
	if is_zero_approx(value):
		row.visible = false
		return
	row.visible = true
	value_label.text = ("%+.2f" % value)  # shows + and -

func _hide_all() -> void:
	damage_h_box.visible = false
	ammo_h_box.visible = false
	range_h_box.visible = false
	fire_rate_h_box.visible = false
	reload_speed_h_box.visible = false
	recoil_h_box.visible = false
	spread_h_box.visible = false
	ads_zoom_h_box.visible = false
	ads_speed_h_box.visible = false
	
