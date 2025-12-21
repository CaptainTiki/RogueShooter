extends Node
class_name GunCalc

func calculate_stats(build : GunBuild) -> GunStats:
	var stats : GunStats = GunStats.new()
	
	stats.damage = build.chamber.damage
	stats.fire_rate = build.frame.fire_rate
	stats.mag_size = build.mag.capacity
	stats.reload_time = build.mag.reload_time
	stats.spread = build.barrel.spread + build.optics.spread
	stats.recoil = build.frame.recoil
	stats.dps = build.damage * build.fire_rate
	
	return stats
