# enums.gd (Autoload name: Enums)
extends Node

enum ModSlotType { BARREL, OPTIC, UTILITY, RECEIVER }
enum WeaponSize { SMALL, MEDIUM, LARGE, HUGE }
enum TriggerMode { SEMI, AUTO, PUMP, SINGLE, CHARGESS }
enum AmmoType {ANY, FIVE_FIVE_SIX, SEVEN_SIX_TWO, NINE_MM, FIFTY_CAL, TWELVE_GAUGE, BATTERY}
enum StatType { DAMAGE, DISTANCE, RECOIL, ADS_SPEED, SPREAD, AMMO_COUNT, RELOAD_SPEED }
enum FirePattern { HITSCAN, PROJECTILE, BEAM }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY}

# Rooms / ProcGen
enum RoomConnectorType { A, B, C, TREASURE, BOSS }
