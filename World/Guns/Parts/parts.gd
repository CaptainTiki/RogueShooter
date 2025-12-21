extends Node

var parts : Array[GunPartDef] = []

func _ready() -> void:
	_load_gunparts()

func _load_gunparts() -> void:
	#TODO: load these in to a global instance at runtime - so we dont ahve to manually build this array
	parts = [
		#barrels
		BARREL_PRECISION,
		BARREL_SHORT,
		#chambers
		CHAMBER_BULLET_LG,
		CHAMBER_BULLET_SM,
		#frames
		FRAME_HEAVY,
		FRAME_LIGHT,
		#mags
		MAG_EXTENDED,
		MAG_SMALL,
		#optics
		OPTIC_IRONSIGHTS,
		OPTIC_TIGHT
		]

#barrels
const BARREL_PRECISION = preload("uid://c8mrong5ldr5v")
const BARREL_SHORT = preload("uid://0ewltxxxg7ei")
#chambers
const CHAMBER_BULLET_LG = preload("uid://11i4gtgfc11d")
const CHAMBER_BULLET_SM = preload("uid://b78y2ptm76xq1")
#frames
const FRAME_HEAVY = preload("uid://dcfqtriq8rloh")
const FRAME_LIGHT = preload("uid://dydlfqehexc0k")
#mags
const MAG_EXTENDED = preload("uid://ddb4bevuxap4o")
const MAG_SMALL = preload("uid://cxi8ua2cmnloc")
#optics
const OPTIC_IRONSIGHTS = preload("uid://cp0rx5157kbnv")
const OPTIC_TIGHT = preload("uid://bx1v3pjfrw1mq")
