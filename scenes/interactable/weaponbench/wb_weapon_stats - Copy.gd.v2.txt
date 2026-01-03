extends Control
class_name WB_WeaponStats

@onready var damage_value_label: Label = %Damage_Value_Label
@onready var ammo_value_label: Label = %Ammo_Value_Label
@onready var range_value_label: Label = %Range_Value_Label
@onready var fire_rate_value_label: Label = %FireRate_Value_Label
@onready var reload_value_label: Label = %Reload_Value_Label
@onready var recoil_value_label: Label = %Recoil_Value_Label
@onready var spread_value_label: Label = %Spread_Value_Label
@onready var ads_speed_value_label: Label = %ADSSpeed_Value_Label
@onready var ads_zoom_value_label: Label = %ADSZoom_Value_Label

func show_weapon(weapon: Weapon) -> void:
	var s : WeaponStats = weapon.stats
	damage_value_label.text = "%.1f" % s.damage
	fire_rate_value_label.text = "%.2f" % (1.0 / s.shot_interval)
	range_value_label.text = "%.1f" % s.distance
	ammo_value_label.text = str(s.ammo_capacity)
	reload_value_label.text = "%.2f" % s.reload_speed
	recoil_value_label.text = "%.2f" % s.recoil
	spread_value_label.text = "%.2f" % s.spread
	ads_speed_value_label.text = "%.2f" % s.ads_speed
	ads_zoom_value_label.text = "%.2f" % s.fov_amount
	
	#update reciever only stats here:
