class_name NeonRoofRulesDef
extends Def
## purpose: numbers for prison roof exploration (hero/guard speeds, radii, timings).

var hero_speed: float = 330.0
var guard_speed: float = 90.0
var guard_pause: float = 1.2
var touch_radius: float = 70.0
var burst_shake_time: float = 0.25
var burst_shake_intensity: float = 8.0
var flash_time: float = 0.2
var move_hint_seconds: float = 4.0
var floodlight_fade_seconds: float = 0.6
var interact_radius: float = 90.0
## Opening: seconds before the hatch bursts, then the hop out of it (seconds, height in plate px).
var burst_delay: float = 0.6
var hop_seconds: float = 0.35
var hop_height: float = 40.0


func read(r: DefReader) -> void:
	id = r.id()
	hero_speed = r.number("hero_speed", 10.0, 1000.0, 330.0)
	guard_speed = r.number("guard_speed", 10.0, 1000.0, 90.0)
	guard_pause = r.number("guard_pause", 0.0, 10.0, 1.2)
	touch_radius = r.number("touch_radius", 1.0, 500.0, 70.0)
	burst_shake_time = r.number("burst_shake_time", 0.0, 5.0, 0.25)
	burst_shake_intensity = r.number("burst_shake_intensity", 0.0, 100.0, 8.0)
	flash_time = r.number("flash_time", 0.0, 5.0, 0.2)
	move_hint_seconds = r.number("move_hint_seconds", 0.0, 20.0, 4.0)
	floodlight_fade_seconds = r.number("floodlight_fade_seconds", 0.0, 10.0, 0.6)
	interact_radius = r.number("interact_radius", 1.0, 500.0, 90.0)
	burst_delay = r.number("burst_delay", 0.0, 10.0, 0.6)
	hop_seconds = r.number("hop_seconds", 0.0, 5.0, 0.35)
	hop_height = r.number("hop_height", 0.0, 400.0, 40.0)


func references() -> Array[Array]:
	return []
