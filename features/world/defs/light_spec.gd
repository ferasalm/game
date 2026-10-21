class_name LightSpec
extends RefCounted
## One practical light: where it is, its colour, a real OmniLight (energy, range; only the nearest few are alive at
## once) and a fake light pool (an additive quad on the floor or a wall, radius in metres, cheap and always on).
## flicker (0..1) and flicker_speed make it wobble. The pool lies flat unless facing is "wall".

var pos: Vector3 = Vector3.ZERO
var color: Color = Color.WHITE
var energy: float = 1.0
var range_m: float = 4.0
var pool_radius: float = 0.0
var pool_energy: float = 0.6
var pool_y: float = 0.0
var upright: bool = false
var yaw: float = 0.0
var flicker: float = 0.0
var flicker_speed: float = 6.0
var real: bool = true


func read(r: DefReader) -> void:
	pos = Vector3(r.number("x", -500.0, 500.0, 0.0, false), r.number("y", -50.0, 100.0, 0.0, false),
		r.number("z", -500.0, 500.0, 0.0, false))
	color = r.color("color")
	energy = r.number("energy", 0.0, 16.0, 1.0, false)
	range_m = r.number("range", 0.5, 30.0, 4.0, false)
	pool_radius = r.number("pool", 0.0, 20.0, 0.0, false)
	pool_energy = r.number("pool_energy", 0.0, 8.0, 0.6, false)
	pool_y = r.number("pool_y", -50.0, 100.0, 0.0, false)
	upright = r.text("facing", "floor", false) == "wall"
	yaw = r.number("yaw", -360.0, 360.0, 0.0, false)
	flicker = r.number("flicker", 0.0, 1.0, 0.0, false)
	flicker_speed = r.number("flicker_speed", 0.1, 40.0, 6.0, false)
	real = r.flag("real", true)


## A copy moved by offset and turned by yaw degrees around the origin (a prop's light follows its placement).
func placed(offset: Vector3, turn_deg: float) -> LightSpec:
	var out := LightSpec.new()
	out.pos = offset + pos.rotated(Vector3.UP, deg_to_rad(turn_deg))
	out.color = color
	out.energy = energy
	out.range_m = range_m
	out.pool_radius = pool_radius
	out.pool_energy = pool_energy
	out.pool_y = offset.y + pool_y
	out.upright = upright
	out.yaw = yaw + turn_deg
	out.flicker = flicker
	out.flicker_speed = flicker_speed
	out.real = real
	return out
