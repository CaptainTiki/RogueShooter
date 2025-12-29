# enums.gd (Autoload name: Enums)
extends Node

enum PartType { RECEIVER, BARREL, GRIP, STOCK, MAGAZINE, OPTIC, MUZZLE, FOREGRIP }  # add more later
enum WeaponSize { SMALL, MEDIUM, LARGE }
enum TriggerMode { SEMI, BURST, AUTO }
enum AmmoType {ANY, FIVE_FIVE_SIX, SEVEN_SIX_TWO, NINE_MM, FIFTY_CAL, TWELVE_GAUGE}
enum StatType { DAMAGE, RANGE, RECOIL, ADS_SPEED, SPREAD, AMMO_COUNT, RELOAD_SPEED }
enum FirePattern { HITSCAN, PROJECTILE, BEAM }
