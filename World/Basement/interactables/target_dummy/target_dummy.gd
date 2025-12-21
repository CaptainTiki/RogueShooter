extends StaticBody3D
class_name TargetDummy

@onready var health_comp: HealthComponent = $HealthComponent
@onready var label_3d: Label3D = $Label3D
@onready var reset_timer: Timer = $ResetTimer
@onready var damage_timer: Timer = $DamageTimer

@export var hit_flash_mat : StandardMaterial3D

var flash_time : float = 0.05
var total_damage : float = 0
var damage_timer_time : float = 0.5

func _ready() -> void:
	health_comp.Damaged.connect(_on_take_damage)
	health_comp.Died.connect(_on_died)
	label_3d.text = str(total_damage)
	reset_timer.timeout.connect(_reset_mats)
	damage_timer.timeout.connect(_reset_damage)

func _on_take_damage(amount: float) -> void:
	for child in get_children():
		if child is CSGCylinder3D:
			child.material_override = hit_flash_mat
			
	if reset_timer.is_stopped():
		reset_timer.start(flash_time)
	else:
		reset_timer.wait_time += flash_time
	
	total_damage += amount
	label_3d.text = str(total_damage)
	if damage_timer.is_stopped():
		total_damage = 0
		damage_timer.start(damage_timer_time)
	else:
		damage_timer.wait_time = damage_timer_time
	


func _on_died() -> void:
	#normally we'd queuefree - but this is a dummy - we basically just want to reset the health
	health_comp.heal(health_comp.max_health)

func _reset_damage() -> void:
	total_damage = 0

func _reset_mats() -> void:
	for child in get_children():
		if child is CSGCylinder3D:
			child.material_override = null
