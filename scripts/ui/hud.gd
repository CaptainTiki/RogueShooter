extends Control
class_name HUD

@onready var weapon_name_label: Label = $Margin/BottomRight/AmmoPanel/VBox/WeaponName
@onready var ammo_label: Label = $Margin/BottomRight/AmmoPanel/VBox/AmmoText
@onready var health_bar: ProgressBar = $Margin/TopLeft/HealthPanel/VBox/HealthBar
@onready var health_label: Label = $Margin/TopLeft/HealthPanel/VBox/HealthText

var _player: Node = null
var _weapon_controller: WeaponController = null
var _health: HealthComponent = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_find_player_refs()
	_update_all()

func _process(_delta: float) -> void:
	# Cheap + reliable: update every frame for now.
	_update_all()

func _find_player_refs() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		# Fallback: try to find by name in current level.
		_player = get_tree().current_scene.find_child("PlayerController", true, false)

	if _player != null:
		_weapon_controller = _player.get_node_or_null("Components/WeaponController")
		_health = _player.get_node_or_null("Health")
		if _weapon_controller != null:
			_weapon_controller.weapon_changed.connect(_update_all)
		if _health != null:
			_health.health_changed.connect(func(_c:int, _m:int): _update_all())

func _update_all() -> void:
	_update_weapon()
	_update_health()

func _update_weapon() -> void:
	if _weapon_controller == null:
		weapon_name_label.text = "Weapon: —"
		ammo_label.text = "Ammo: —"
		return

	var w: Weapon = _weapon_controller.current_weapon
	var s: WeaponStats = _weapon_controller.weapon_stats
	if w == null or s == null:
		weapon_name_label.text = "Weapon: —"
		ammo_label.text = "Ammo: —"
		return

	weapon_name_label.text = w.weapon_name

	var mag_cur: int = int(_weapon_controller.current_ammo)
	var mag_cap: int = int(s.ammo_capacity)

	var reserve: int = 0
	var ammo_name := ""
	if int(s.ammo_type) == int(Enums.AmmoType.ANY):
		reserve = 999
		ammo_name = "TEST"
	else:
		ammo_name = Enums.AmmoType.keys()[int(s.ammo_type)]
		if Game.current != null and Game.current.player_inventory != null:
			reserve = Game.current.player_inventory.get_ammo(s.ammo_type)

	ammo_label.text = "%s  %d/%d  |  %d" % [ammo_name, mag_cur, mag_cap, reserve]

func _update_health() -> void:
	var cur: int = 100
	var mx: int = 100
	if _health != null:
		cur = _health.current_health
		mx = _health.max_health

	health_bar.max_value = mx
	health_bar.value = cur
	health_label.text = "HP  %d / %d" % [cur, mx]
